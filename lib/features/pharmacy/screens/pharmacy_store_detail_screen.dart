import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/app_shimmer.dart';

class PharmacyStoreDetailScreen extends StatefulWidget {
  const PharmacyStoreDetailScreen({
    super.key,
    required this.storeId,
    this.initialStore,
  });

  final String storeId;
  final Map<String, dynamic>? initialStore;

  @override
  State<PharmacyStoreDetailScreen> createState() =>
      _PharmacyStoreDetailScreenState();
}

class _PharmacyStoreDetailScreenState extends State<PharmacyStoreDetailScreen> {
  _PharmacyStoreInfo? _store;
  List<PharmacyModel> _medicines = const [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoadingStore = true;
  bool _isLoadingMedicines = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialStore;
    if (initial != null) {
      _store = _PharmacyStoreInfo.fromMap(initial);
    }
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadStore();
    await _loadMedicines();
  }

  Future<void> _loadStore() async {
    try {
      final response = await ApiClient.get(
        '/catalog/pharmacies?sort=distance${_locationQueryForDistance()}',
      );
      final pharmacies = (response as List)
          .map(
            (entry) =>
                _PharmacyStoreInfo.fromMap(Map<String, dynamic>.from(entry)),
          )
          .toList(growable: false);
      final previousStore = _store;

      _PharmacyStoreInfo? match;
      for (final pharmacy in pharmacies) {
        if (pharmacy.id == widget.storeId) {
          match = pharmacy;
          break;
        }
      }
      if (match == null && _store != null) {
        final normalized = _store!.name.trim().toLowerCase();
        for (final pharmacy in pharmacies) {
          if (pharmacy.name.trim().toLowerCase() == normalized) {
            match = pharmacy;
            break;
          }
        }
      }
      if (match != null &&
          previousStore != null &&
          match.distanceKm == null &&
          previousStore.distanceKm != null &&
          match.id == previousStore.id) {
        match = match.copyWith(distanceKm: previousStore.distanceKm);
      }

      if (!mounted) return;
      setState(() {
        _store = match ?? previousStore;
        _isLoadingStore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingStore = false);
    }
  }

  String _locationQueryForDistance() {
    final auth = context.read<AuthProvider>();
    final addresses = auth.user?.addresses ?? const <AddressModel>[];

    AddressModel? selected;
    for (final address in addresses) {
      if (address.isDefault &&
          address.latitude != null &&
          address.longitude != null) {
        selected = address;
        break;
      }
    }
    if (selected == null) {
      for (final address in addresses) {
        if (address.latitude != null && address.longitude != null) {
          selected = address;
          break;
        }
      }
    }

    if (selected == null ||
        selected.latitude == null ||
        selected.longitude == null) {
      return '';
    }
    return '&latitude=${selected.latitude}&longitude=${selected.longitude}';
  }

  Future<void> _loadMedicines() async {
    try {
      final response = await ApiClient.get(
        '/catalog/products?moduleType=pharmacy',
      );
      final all = (response as List)
          .map(
            (item) =>
                PharmacyModel.fromApi(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false);

      final storeName = _store?.name.trim().toLowerCase();
      final filtered = storeName == null || storeName.isEmpty
          ? all
          : all
                .where((medicine) {
                  final sourceBusiness =
                      medicine.sourceBusiness?.trim().toLowerCase() ?? '';
                  return sourceBusiness == storeName;
                })
                .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _medicines = filtered;
        _isLoadingMedicines = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMedicines = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cartProvider = context.watch<CartProvider>();
    final cartItemCount = cartProvider.getModuleItemCount('pharmacy');
    final moduleTotal = cartProvider.getModuleSubtotal('pharmacy');
    final isLoading = _isLoadingStore || _isLoadingMedicines;
    final store = _store;
    final hasAddress = store?.address?.trim().isNotEmpty == true;
    final hasDistance = (store?.distanceKm ?? 0) > 0;
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final visibleMedicines = normalizedQuery.isEmpty
        ? _medicines
        : _medicines
              .where((medicine) {
                final haystack = [
                  medicine.name,
                  medicine.category,
                  medicine.size,
                  medicine.description,
                  medicine.sourceBusiness ?? '',
                ].join(' ').toLowerCase();
                return haystack.contains(normalizedQuery);
              })
              .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _store?.name ?? l10n.t('pharmacy.title'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/pharmacy');
            }
          },
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                splashRadius: 24,
                constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
                padding: const EdgeInsets.all(12),
                icon: const Icon(Icons.shopping_bag_outlined, size: 24),
                onPressed: () => context.push('/pharmacy/cart'),
              ),
              if (cartItemCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$cartItemCount',
                        style: AppTextStyles.badge.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const DetailContentShimmer(
              accentColor: AppColors.pharmacy,
              showHero: false,
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.pharmacy,
                            AppColors.secondaryLight,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pharmacy.withValues(alpha: 0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child:
                                    store?.imageUrl != null &&
                                        store!.imageUrl!.trim().isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.network(
                                          store.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(
                                            Icons.local_pharmacy_rounded,
                                            color: AppColors.white,
                                            size: 24,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.local_pharmacy_rounded,
                                        color: AppColors.white,
                                        size: 24,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      store?.name ?? l10n.t('pharmacy.title'),
                                      style: AppTextStyles.h4.copyWith(
                                        color: AppColors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      hasAddress
                                          ? store!.address!.trim()
                                          : l10n.t(
                                              'pharmacy.store_address_private',
                                            ),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _StoreMetricPill(
                                icon: Icons.verified_rounded,
                                text: l10n.t('pharmacy.store_verified'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StoreStatCard(
                                icon: Icons.star_rate_rounded,
                                title: (store?.rating ?? 0).toStringAsFixed(1),
                                subtitle: l10n.t(
                                  'pharmacy.reviews_count',
                                  params: {
                                    'count': '${store?.reviewCount ?? 0}',
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StoreStatCard(
                                icon: Icons.near_me_rounded,
                                title: hasDistance
                                    ? store!.distanceLabel(l10n)
                                    : l10n.t('pharmacy.store_distance_pending'),
                                subtitle: l10n.t(
                                  'pharmacy.store_distance_subtitle',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _StoreSearchCard(
                          controller: _searchController,
                          hint: l10n.t('pharmacy.search_hint'),
                          hasValue: _searchQuery.trim().isNotEmpty,
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          onClear: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.t('pharmacy.store_medicines_title'),
                            style: AppTextStyles.h4,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.pharmacyBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${visibleMedicines.length}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.pharmacy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (visibleMedicines.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.lightGrey.withValues(alpha: 0.65),
                          ),
                        ),
                        child: Text(
                          l10n.t('pharmacy.store_empty_medicines'),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final medicine = visibleMedicines[index];
                      return GestureDetector(
                        onTap: () {
                          context.push('/pharmacy/medicine/${medicine.id}');
                        },
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppSpacing.shadowSm,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.pharmacyBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.medication_rounded,
                                  color: AppColors.pharmacy,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      medicine.name,
                                      style: AppTextStyles.labelLarge,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      medicine.size,
                                      style: AppTextStyles.caption,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      medicine.category,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.pharmacy,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${medicine.price.toStringAsFixed(2)}',
                                    style: AppTextStyles.priceSmall.copyWith(
                                      color: AppColors.pharmacy,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      cartProvider.addItem(
                                        CartItem(
                                          id: medicine.id,
                                          name: medicine.name,
                                          price: medicine.price,
                                          moduleType: 'pharmacy',
                                          brand:
                                              medicine.sourceBusiness ??
                                              medicine.category,
                                          shopName: medicine.sourceBusiness,
                                          imageUrl: medicine.imageUrl,
                                          description: medicine.description,
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.pharmacy,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        l10n.t('pharmacy.add'),
                                        style: AppTextStyles.badge.copyWith(
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: visibleMedicines.length),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
      bottomNavigationBar: cartItemCount > 0
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GestureDetector(
                onTap: () => context.push('/pharmacy/cart'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pharmacy,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.pharmacy.withValues(alpha: 0.22),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '$cartItemCount',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.t('pharmacy.view_cart'),
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      Text(
                        '\$${moduleTotal.toStringAsFixed(2)}',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _StoreMetricPill extends StatelessWidget {
  const _StoreMetricPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreStatCard extends StatelessWidget {
  const _StoreStatCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppSpacing.shadowSm,
        border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.pharmacyBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.pharmacy, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(color: AppColors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreSearchCard extends StatelessWidget {
  const _StoreSearchCard({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.hasValue,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool hasValue;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppSpacing.shadowSm,
        border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.pharmacyBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: AppColors.pharmacy,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.mediumGrey,
                ),
                border: InputBorder.none,
              ),
              style: AppTextStyles.bodyMedium,
            ),
          ),
          if (hasValue)
            IconButton(
              onPressed: onClear,
              splashRadius: 18,
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.mediumGrey,
              ),
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}

class _PharmacyStoreInfo {
  const _PharmacyStoreInfo({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviewCount,
    required this.productCount,
    required this.prescriptionCount,
    this.distanceKm,
    this.address,
    this.imageUrl,
  });

  final String id;
  final String name;
  final double rating;
  final int reviewCount;
  final int productCount;
  final int prescriptionCount;
  final double? distanceKm;
  final String? address;
  final String? imageUrl;

  factory _PharmacyStoreInfo.fromMap(Map<String, dynamic> map) {
    final locationMap = map['location'] is Map
        ? Map<String, dynamic>.from(map['location'] as Map)
        : const <String, dynamic>{};
    return _PharmacyStoreInfo(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Pharmacy',
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      productCount: (map['productCount'] as num?)?.toInt() ?? 0,
      prescriptionCount: (map['prescriptionCount'] as num?)?.toInt() ?? 0,
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
      address: map['address']?.toString() ?? locationMap['address']?.toString(),
      imageUrl:
          map['imageUrl']?.toString() ??
          map['profileImageUrl']?.toString() ??
          map['profileAvatarUrl']?.toString() ??
          map['avatarUrl']?.toString(),
    );
  }

  String distanceLabel(AppLocalizations l10n) {
    if (distanceKm == null) return l10n.t('pharmacy.distance_unknown');
    return l10n.t(
      'pharmacy.distance_km',
      params: {'distance': distanceKm!.toStringAsFixed(1)},
    );
  }

  _PharmacyStoreInfo copyWith({double? distanceKm}) {
    return _PharmacyStoreInfo(
      id: id,
      name: name,
      rating: rating,
      reviewCount: reviewCount,
      productCount: productCount,
      prescriptionCount: prescriptionCount,
      distanceKm: distanceKm ?? this.distanceKm,
      address: address,
      imageUrl: imageUrl,
    );
  }
}
