import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../network/api_client.dart';

/// Provides access to AliExpress product data through the backend proxy.
///
/// All AliExpress API calls are routed through the backend which handles
/// HMAC-SHA256 signing and credential management. The Flutter app never
/// sees the App Secret.
class AliExpressProvider extends ChangeNotifier {
  List<ProductModel> _searchResults = [];
  List<ProductModel> _trendingProducts = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isSearching = false;
  bool _isLoadingTrending = false;
  bool _isLoadingCategories = false;
  String? _searchError;
  String? _trendingError;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalRecords = 0;
  String _lastQuery = '';

  // Getters
  List<ProductModel> get searchResults => List.unmodifiable(_searchResults);
  List<ProductModel> get trendingProducts =>
      List.unmodifiable(_trendingProducts);
  List<Map<String, dynamic>> get categories =>
      List.unmodifiable(_categories);
  bool get isSearching => _isSearching;
  bool get isLoadingTrending => _isLoadingTrending;
  bool get isLoadingCategories => _isLoadingCategories;
  String? get searchError => _searchError;
  String? get trendingError => _trendingError;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalRecords => _totalRecords;
  String get lastQuery => _lastQuery;
  bool get hasMorePages => _currentPage < _totalPages;

  /// Search AliExpress products by keyword.
  ///
  /// [page] starts at 1. Pass 1 for a new search, or [currentPage + 1]
  /// for pagination.
  Future<void> searchProducts(
    String query, {
    int page = 1,
    String sort = 'DEFAULT',
  }) async {
    if (query.trim().isEmpty) return;

    final trimmedQuery = query.trim();
    _lastQuery = trimmedQuery;

    if (page == 1) {
      _searchResults = [];
      _searchError = null;
    }
    _isSearching = true;
    notifyListeners();

    try {
      final queryParams = <String, String>{
        'q': Uri.encodeComponent(trimmedQuery),
        'page': page.toString(),
        'pageSize': '20',
        'sort': sort,
      };

      final queryString =
          queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      final response = await ApiClient.get(
        '/aliexpress/products/search?$queryString',
        forceRefresh: page == 1,
      );

      final data = Map<String, dynamic>.from(response as Map);
      final productsList = (data['products'] as List? ?? [])
          .map(
            (entry) =>
                ProductModel.fromApi(Map<String, dynamic>.from(entry as Map)),
          )
          .toList();

      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

      _searchResults = page == 1
          ? productsList
          : [..._searchResults, ...productsList];
      _currentPage = page;
      _totalPages = (pagination['totalPages'] as num?)?.toInt() ?? 1;
      _totalRecords = (pagination['totalRecords'] as num?)?.toInt() ?? 0;
      _searchError = null;
    } catch (e) {
      debugPrint('[AliExpress] Search failed: $e');
      _searchError = 'Unable to search AliExpress. Please try again.';
      if (page == 1) {
        _searchResults = [];
      }
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Load next page of search results.
  Future<void> loadMoreSearchResults() async {
    if (_isSearching || !hasMorePages || _lastQuery.isEmpty) return;
    await searchProducts(_lastQuery, page: _currentPage + 1);
  }

  /// Fetch trending/hot products from AliExpress.
  Future<void> loadTrendingProducts() async {
    _isLoadingTrending = true;
    _trendingError = null;
    notifyListeners();

    try {
      final response = await ApiClient.get(
        '/aliexpress/products/search?q=trending&page=1&pageSize=10&sort=DEFAULT',
        cacheDuration: const Duration(minutes: 15),
      );

      final data = Map<String, dynamic>.from(response as Map);
      _trendingProducts = (data['products'] as List? ?? [])
          .map(
            (entry) =>
                ProductModel.fromApi(Map<String, dynamic>.from(entry as Map)),
          )
          .toList();
      _trendingError = null;
    } catch (e) {
      debugPrint('[AliExpress] Trending products failed: $e');
      _trendingError = 'Unable to load trending products.';
      _trendingProducts = const [];
    } finally {
      _isLoadingTrending = false;
      notifyListeners();
    }
  }

  /// Fetch AliExpress category tree.
  Future<void> loadCategories({int parentId = 0}) async {
    _isLoadingCategories = true;
    notifyListeners();

    try {
      final response = await ApiClient.get(
        '/aliexpress/categories?parentId=$parentId',
        cacheDuration: const Duration(hours: 1),
      );

      final data = Map<String, dynamic>.from(response as Map);
      _categories = (data['categories'] as List? ?? [])
          .map((entry) => Map<String, dynamic>.from(entry as Map))
          .toList();
    } catch (e) {
      debugPrint('[AliExpress] Categories failed: $e');
      _categories = [];
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  /// Fetch a single product detail by AliExpress product ID.
  Future<ProductModel?> getProductDetail(String productId) async {
    try {
      final response = await ApiClient.get(
        '/aliexpress/products/$productId',
        forceRefresh: false,
      );
      return ProductModel.fromApi(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (e) {
      debugPrint('[AliExpress] Product detail failed: $e');
      return null;
    }
  }

  /// Clear all cached data and reset state.
  void clear() {
    _searchResults = [];
    _trendingProducts = [];
    _categories = [];
    _searchError = null;
    _trendingError = null;
    _currentPage = 1;
    _totalPages = 1;
    _totalRecords = 0;
    _lastQuery = '';
    notifyListeners();
  }
}
