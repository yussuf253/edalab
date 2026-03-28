import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_shimmer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _isLoading = false;
  List<_SearchItem> _results = const [];
  List<String> _trending = const [
    'Pizza',
    'Doctor',
    'Hotel',
    'Vitamins',
    'Fresh Fruits',
    'Laundry',
  ];

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  Future<void> _loadTrending() async {
    try {
      final responses = await Future.wait([
        ApiClient.get('/catalog/restaurants'),
        ApiClient.get('/catalog/doctors'),
        ApiClient.get('/catalog/products?moduleType=shopping'),
      ]);
      final restaurantNames = (responses[0] as List)
          .take(2)
          .map(
            (item) => Map<String, dynamic>.from(item as Map)['name'].toString(),
          );
      final doctorNames = (responses[1] as List)
          .take(2)
          .map(
            (item) =>
                Map<String, dynamic>.from(item as Map)['specialty'].toString(),
          );
      final productNames = (responses[2] as List)
          .take(2)
          .map(
            (item) => Map<String, dynamic>.from(item as Map)['name'].toString(),
          );
      if (!mounted) return;
      setState(() {
        _trending = [...restaurantNames, ...doctorNames, ...productNames];
      });
    } catch (_) {}
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
      _search();
    });
  }

  Future<void> _search() async {
    if (_query.isEmpty) {
      setState(() => _results = const []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final responses = await Future.wait([
        ApiClient.get('/catalog/restaurants'),
        ApiClient.get('/catalog/doctors'),
        ApiClient.get('/catalog/products?moduleType=shopping'),
        ApiClient.get('/catalog/products?moduleType=pharmacy'),
        ApiClient.get('/catalog/hotels'),
      ]);

      final query = _query.toLowerCase();
      final results =
          <_SearchItem>[
            ...(responses[0] as List).map((item) {
              final data = Map<String, dynamic>.from(item as Map);
              return _SearchItem(
                title: data['name']?.toString() ?? '',
                subtitle: data['cuisine']?.toString() ?? context.l10n.t('search.restaurant'),
                route: '/food/restaurant/${data['id']}',
                color: AppColors.food,
                icon: Icons.restaurant_rounded,
              );
            }),
            ...(responses[1] as List).map((item) {
              final data = Map<String, dynamic>.from(item as Map);
              return _SearchItem(
                title: data['name']?.toString() ?? '',
                subtitle: data['specialty']?.toString() ?? context.l10n.t('search.doctor'),
                route: '/doctor/detail/${data['id']}',
                color: AppColors.doctor,
                icon: Icons.medical_services_rounded,
              );
            }),
            ...(responses[2] as List).map((item) {
              final data = Map<String, dynamic>.from(item as Map);
              return _SearchItem(
                title: data['name']?.toString() ?? '',
                subtitle: data['category']?.toString() ?? context.l10n.t('search.product'),
                route: '/shopping/product/${data['id']}',
                color: AppColors.shopping,
                icon: Icons.shopping_bag_rounded,
              );
            }),
            ...(responses[3] as List).map((item) {
              final data = Map<String, dynamic>.from(item as Map);
              return _SearchItem(
                title: data['name']?.toString() ?? '',
                subtitle: data['category']?.toString() ?? context.l10n.t('search.medicine'),
                route: '/pharmacy/medicine/${data['id']}',
                color: AppColors.pharmacy,
                icon: Icons.medication_rounded,
              );
            }),
            ...(responses[4] as List).map((item) {
              final data = Map<String, dynamic>.from(item as Map);
              return _SearchItem(
                title: data['name']?.toString() ?? '',
                subtitle: data['city']?.toString() ?? context.l10n.t('search.hotel'),
                route: '/hotel/detail/${data['id']}',
                color: AppColors.hotel,
                icon: Icons.hotel_rounded,
              );
            }),
          ].where((item) {
            return item.title.toLowerCase().contains(query) ||
                item.subtitle.toLowerCase().contains(query);
          }).toList();

      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final showSearchResults = _query.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: l10n.t('search.title'),
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.mediumGrey,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showSearchResults) ...[
              Text(l10n.t('search.results'), style: AppTextStyles.h4),
              const SizedBox(height: 12),
              if (_isLoading)
                const InlineSectionListShimmer(itemCount: 6)
              else if (_results.isEmpty)
                Text(
                  l10n.t('search.no_matches', params: {'query': _query}),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.grey,
                  ),
                )
              else
                ..._results.map(
                  (item) => GestureDetector(
                    onTap: () => context.push(item.route),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppSpacing.shadowSm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(item.icon, color: item.color, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: AppTextStyles.labelMedium,
                                ),
                                Text(
                                  item.subtitle,
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: AppColors.mediumGrey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ] else ...[
              Text(l10n.t('search.trending'), style: AppTextStyles.h4),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _trending.map((item) {
                  return GestureDetector(
                    onTap: () {
                      _controller.text = item;
                      _onChanged(item);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.lightGrey),
                      ),
                      child: Text(
                        item,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(l10n.t('search.quick_access'), style: AppTextStyles.h4),
              const SizedBox(height: 12),
              ...[
                (
                  l10n.t('search.order_food'),
                  Icons.restaurant_rounded,
                  AppColors.food,
                  '/food',
                ),
                (
                  l10n.t('search.book_ride'),
                  Icons.directions_car_rounded,
                  AppColors.ride,
                  '/ride',
                ),
                (
                  l10n.t('search.find_doctor'),
                  Icons.medical_services_rounded,
                  AppColors.doctor,
                  '/doctor',
                ),
                (
                  l10n.t('search.shop_online'),
                  Icons.shopping_bag_rounded,
                  AppColors.shopping,
                  '/shopping',
                ),
              ].map(
                (item) => GestureDetector(
                  onTap: () => context.push(item.$4),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppSpacing.shadowSm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: item.$3.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(item.$2, color: item.$3, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item.$1,
                            style: AppTextStyles.labelMedium,
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppColors.mediumGrey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchItem {
  final String title;
  final String subtitle;
  final String route;
  final Color color;
  final IconData icon;

  const _SearchItem({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.color,
    required this.icon,
  });
}
