import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../network/api_client.dart';

/// A top-level AliExpress category offered as a chip in the shopping tab.
///
/// The ids come from `aliexpress.ds.category.get`; the label is short so the
/// chip row stays readable.
class AliExpressCategory {
  /// `null` means "All" — no category filter.
  final String? id;
  final String label;

  const AliExpressCategory({this.id, required this.label});
}

/// Provides access to AliExpress product data through the backend proxy.
///
/// All AliExpress API calls are routed through the backend which handles
/// HMAC-SHA256 signing and credential management. The Flutter app never
/// sees the App Secret.
class AliExpressProvider extends ChangeNotifier {
  /// Browse chips for the AliExpress tab.
  static const List<AliExpressCategory> browseCategories = [
    AliExpressCategory(label: 'All'),
    AliExpressCategory(id: '509', label: 'Phones'),
    AliExpressCategory(id: '44', label: 'Electronics'),
    AliExpressCategory(id: '7', label: 'Computers'),
    AliExpressCategory(id: '3', label: 'Fashion'),
    AliExpressCategory(id: '15', label: 'Home & Garden'),
    AliExpressCategory(id: '66', label: 'Beauty'),
    AliExpressCategory(id: '26', label: 'Toys'),
    AliExpressCategory(id: '18', label: 'Sports'),
    AliExpressCategory(id: '34', label: 'Auto'),
    AliExpressCategory(id: '1511', label: 'Watches'),
    AliExpressCategory(id: '1524', label: 'Bags'),
    AliExpressCategory(id: '322', label: 'Shoes'),
  ];

  static const int _pageSize = 20;

  List<ProductModel> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalRecords = 0;
  String _lastQuery = '';

  List<ProductModel> _feedProducts = [];
  bool _isLoadingFeed = false;
  bool _feedHasMore = true;
  String? _feedError;
  int _feedPage = 1;
  String? _selectedCategoryId;

  // Search state
  List<ProductModel> get searchResults => List.unmodifiable(_searchResults);
  bool get isSearching => _isSearching;
  String? get searchError => _searchError;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalRecords => _totalRecords;
  String get lastQuery => _lastQuery;
  bool get hasMorePages => _currentPage < _totalPages;

  // Browse feed state
  List<ProductModel> get feedProducts => List.unmodifiable(_feedProducts);
  bool get isLoadingFeed => _isLoadingFeed;
  bool get hasMoreFeed => _feedHasMore;
  String? get feedError => _feedError;
  String? get selectedCategoryId => _selectedCategoryId;

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

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
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

  /// Clears search state so the tab falls back to the browse feed.
  void resetSearch() {
    if (_lastQuery.isEmpty && _searchResults.isEmpty) return;
    _lastQuery = '';
    _searchResults = [];
    _searchError = null;
    _currentPage = 1;
    _totalPages = 1;
    _totalRecords = 0;
    notifyListeners();
  }

  /// Loads the browse feed, or the feed filtered by the selected category.
  ///
  /// Pass [refresh] to start again from page 1 (tab opened, category changed).
  /// Repeated calls append the next page, de-duplicated by product id.
  Future<void> loadFeed({bool refresh = false}) async {
    if (refresh) {
      _feedProducts = [];
      _feedPage = 1;
      _feedHasMore = true;
      _feedError = null;
    }
    if (_isLoadingFeed || !_feedHasMore) return;

    _isLoadingFeed = true;
    notifyListeners();

    try {
      final response = await ApiClient.get(
        _feedPath(_feedPage),
        cacheDuration: const Duration(minutes: 10),
        forceRefresh: _feedPage == 1,
      );

      final data = Map<String, dynamic>.from(response as Map);
      final pageProducts = (data['products'] as List? ?? [])
          .map(
            (entry) =>
                ProductModel.fromApi(Map<String, dynamic>.from(entry as Map)),
          )
          .where((product) => product.id.isNotEmpty)
          .toList();

      final knownIds = _feedProducts.map((product) => product.id).toSet();
      _feedProducts = [
        ..._feedProducts,
        ...pageProducts.where((product) => !knownIds.contains(product.id)),
      ];

      final pagination =
          data['pagination'] as Map<String, dynamic>? ?? const {};
      _feedHasMore = pagination['hasMore'] == true && pageProducts.isNotEmpty;
      _feedPage += 1;
      _feedError = null;
    } catch (e) {
      debugPrint('[AliExpress] Feed failed: $e');
      _feedError = 'Unable to load AliExpress products. Please try again.';
    } finally {
      _isLoadingFeed = false;
      notifyListeners();
    }
  }

  /// Appends the next feed page; safe to call repeatedly while scrolling.
  Future<void> loadMoreFeed() async {
    if (_isLoadingFeed || !_feedHasMore || _feedError != null) return;
    await loadFeed();
  }

  /// Switches browsing to [categoryId] (`null` for all categories).
  Future<void> selectCategory(String? categoryId) async {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    notifyListeners();
    await loadFeed(refresh: true);
  }

  String _feedPath(int page) {
    final params = <String, String>{
      'page': '$page',
      'pageSize': '$_pageSize',
      'categoryId': ?_selectedCategoryId,
    };
    return '/aliexpress/feed?'
        '${params.entries.map((entry) => '${entry.key}=${entry.value}').join('&')}';
  }

  /// Fetch a single product detail by AliExpress product ID.
  Future<ProductModel?> getProductDetail(String productId) async {
    try {
      final response = await ApiClient.get(
        '/aliexpress/products/$productId',
        forceRefresh: false,
      );
      return ProductModel.fromApi(Map<String, dynamic>.from(response as Map));
    } catch (e) {
      debugPrint('[AliExpress] Product detail failed: $e');
      return null;
    }
  }

  /// Clear all cached data and reset state.
  void clear() {
    _searchResults = [];
    _searchError = null;
    _currentPage = 1;
    _totalPages = 1;
    _totalRecords = 0;
    _lastQuery = '';

    _feedProducts = [];
    _feedHasMore = true;
    _feedError = null;
    _feedPage = 1;
    _selectedCategoryId = null;
    notifyListeners();
  }
}
