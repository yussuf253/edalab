import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
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

  Set<String> _enabledModules = const {};

  @override
  void initState() {
    super.initState();
    // Defer trending load to after first build so _enabledModules is populated.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrending();
    });
  }

  Future<void> _loadTrending() async {
    try {
      final futures = <Future<dynamic>>[];
      final moduleIds = <String>[];

      if (_enabledModules.contains('food')) {
        futures.add(ApiClient.get('/catalog/restaurants'));
        moduleIds.add('food');
      }
      if (_enabledModules.contains('doctor')) {
        futures.add(ApiClient.get('/catalog/doctors'));
        moduleIds.add('doctor');
      }
      if (_enabledModules.contains('shopping')) {
        futures.add(ApiClient.get('/catalog/products?moduleType=shopping'));
        moduleIds.add('shopping');
      }
      if (_enabledModules.contains('pharmacy')) {
        futures.add(ApiClient.get('/catalog/products?moduleType=pharmacy'));
        moduleIds.add('pharmacy');
      }
      if (_enabledModules.contains('hotel')) {
        futures.add(ApiClient.get('/catalog/hotels'));
        moduleIds.add('hotel');
      }
      if (_enabledModules.contains('grocery')) {
        futures.add(ApiClient.get('/catalog/products?moduleType=grocery'));
        moduleIds.add('grocery');
      }

      if (futures.isEmpty) return;
      final responses = await Future.wait(futures);

      final names = <String>[];
      for (var i = 0; i < responses.length; i++) {
        final moduleId = moduleIds[i];
        final items = (responses[i] as List).take(2);
        for (final item in items) {
          final data = Map<String, dynamic>.from(item as Map);
          switch (moduleId) {
            case 'food':
              names.add(data['name']?.toString() ?? '');
            case 'doctor':
              names.add(data['specialty']?.toString() ?? '');
            case 'shopping':
            case 'pharmacy':
            case 'grocery':
              names.add(data['name']?.toString() ?? '');
            case 'hotel':
              names.add(data['name']?.toString() ?? '');
            default:
              names.add(data['name']?.toString() ?? '');
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _trending = names.where((n) => n.isNotEmpty).toList();
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
      final futures = <Future<dynamic>>[];
      final moduleIds = <String>[];

      if (_enabledModules.contains('food')) {
        futures.add(ApiClient.get('/catalog/restaurants'));
        moduleIds.add('food');
      }
      if (_enabledModules.contains('doctor')) {
        futures.add(ApiClient.get('/catalog/doctors'));
        moduleIds.add('doctor');
      }
      if (_enabledModules.contains('shopping')) {
        futures.add(ApiClient.get('/catalog/products?moduleType=shopping'));
        moduleIds.add('shopping');
      }
      if (_enabledModules.contains('pharmacy')) {
        futures.add(ApiClient.get('/catalog/products?moduleType=pharmacy'));
        moduleIds.add('pharmacy');
      }
      if (_enabledModules.contains('hotel')) {
        futures.add(ApiClient.get('/catalog/hotels'));
        moduleIds.add('hotel');
      }
      if (_enabledModules.contains('grocery')) {
        futures.add(ApiClient.get('/catalog/products?moduleType=grocery'));
        moduleIds.add('grocery');
      }

      if (futures.isEmpty) {
        if (!mounted) return;
        setState(() {
          _results = const [];
          _isLoading = false;
        });
        return;
      }
      final responses = await Future.wait(futures);

      final query = _query.toLowerCase();
      final results = <_SearchItem>[];

      for (var i = 0; i < responses.length; i++) {
        final moduleId = moduleIds[i];
        for (final item in (responses[i] as List)) {
          final data = Map<String, dynamic>.from(item as Map);
          _SearchItem searchItem;
          switch (moduleId) {
            case 'food':
              searchItem = _SearchItem(
                title: data['name']?.toString() ?? '',
                subtitle: data['cuisine']?.toString() ?? context.l10n.t('search.restaurant'),
                route: '/food/restaurant/${data['id']}',
                color: AppColors.food,
                icon: Icons.restaurant_rounded,
              );
            case 'doctor':
              searchItem = _SearchItem(
                title: data['name']?.toString() ?? '',
                subtitle: data['specialty']?.toString() ?? context.l10n.t('search.doctor'),
                route: '/doctor/detail/${data['id']}',
                color: AppColors.doctor,
                icon: Icons.medical_services_rounded,
              );
            case 'shopping':
              searchItem = _SearchItem(
                title: data['name']?.toString() ?? '',
                subtitle: data['category']?.toString() ?? context.l10n.t('search.product'),
                route: '/shopping/product/${data['id']}',
                color: AppColors.shopping,
                icon: Icons.shopping_bag_rounded,
              );
            case 'pharmacy':
              searchItem = _SearchItem(
                title: data['name']?.toString() ?? '',
                subtitle: data['category']?.toString() ?? context.l10n.t('search.medicine'),
                route: '/pharmacy/medicine/${data['id']}',
                color: AppColors.pharmacy,
                icon: Icons.medication_rounded,
              );
            case 'hotel':
              searchItem = _SearchItem(
                title: data['name']?.toString() ?? '',
                subtitle: data['city']?.toString() ?? context.l10n.t('search.hotel'),
                route: '/hotel/detail/${data['id']}',
                color: AppColors.hotel,
                icon: Icons.hotel_rounded,
              );
            case 'grocery':
              searchItem = _SearchItem(
                title: data['name']?.toString() ?? '',
                subtitle: data['category']?.toString() ?? context.l10n.t('module.grocery'),
                route: '/grocery/product/${data['id']}',
                color: AppColors.grocery,
                icon: Icons.local_grocery_store_rounded,
              );
            default:
              continue;
          }
          if (searchItem.title.toLowerCase().contains(query) ||
              searchItem.subtitle.toLowerCase().contains(query)) {
            results.add(searchItem);
          }
        }
      }

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
    final moduleProvider = context.watch<ModuleProvider>();
    _enabledModules = moduleProvider.enabledModuleIds;

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
                if (_enabledModules.contains('food')) (
                  l10n.t('search.order_food'),
                  Icons.restaurant_rounded,
                  AppColors.food,
                  '/food',
                ),
                if (_enabledModules.contains('ride')) (
                  l10n.t('search.book_ride'),
                  Icons.directions_car_rounded,
                  AppColors.ride,
                  '/ride',
                ),
                if (_enabledModules.contains('doctor')) (
                  l10n.t('search.find_doctor'),
                  Icons.medical_services_rounded,
                  AppColors.doctor,
                  '/doctor',
                ),
                if (_enabledModules.contains('shopping')) (
                  l10n.t('search.shop_online'),
                  Icons.shopping_bag_rounded,
                  AppColors.shopping,
                  '/shopping',
                ),
                if (_enabledModules.contains('pharmacy')) (
                  l10n.t('module.pharmacy'),
                  Icons.medication_rounded,
                  AppColors.pharmacy,
                  '/pharmacy',
                ),
                if (_enabledModules.contains('grocery')) (
                  l10n.t('module.grocery'),
                  Icons.local_grocery_store_rounded,
                  AppColors.grocery,
                  '/grocery',
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
