import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/analytics/analytics_events.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/media_upload_service.dart';
import '../../../core/utils/auth_gate.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/app_shimmer.dart';

class PharmacyScreen extends StatefulWidget {
  final String? initialSelectedPharmacyName;

  const PharmacyScreen({super.key, this.initialSelectedPharmacyName});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<PharmacyModel> _medicines = PharmacyModel.sampleItems;
  List<_PharmacyDirectoryItem> _pharmacies = const [];
  bool _isLoadingMedicines = true;
  bool _isLoadingPharmacies = true;
  bool _isSubmittingPrescription = false;
  String _searchQuery = '';
  String? _selectedPharmacyName;
  _ResolvedPharmacyLocation? _resolvedLocation;
  String _prescriptionSubmitStage = '';
  Timer? _searchDebounce;
  String _lastTrackedSearch = '';

  _PharmacyDirectoryItem? get _selectedPharmacy {
    final selectedName = _selectedPharmacyName;
    if (selectedName == null || selectedName.trim().isEmpty) {
      return null;
    }
    final normalized = selectedName.trim().toLowerCase();
    for (final pharmacy in _pharmacies) {
      if (pharmacy.name.trim().toLowerCase() == normalized) {
        return pharmacy;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSelectedPharmacyName?.trim();
    _selectedPharmacyName = initial == null || initial.isEmpty ? null : initial;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final location = await _resolveLocation(showFailureSnackBar: false);
    await Future.wait([_loadMedicines(), _loadPharmacies(location: location)]);
  }

  Future<void> _loadMedicines() async {
    try {
      final response = await ApiClient.get(
        '/catalog/products?moduleType=pharmacy',
      );
      final items = (response as List)
          .map(
            (item) =>
                PharmacyModel.fromApi(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _medicines = items.isEmpty ? PharmacyModel.sampleItems : items;
        _isLoadingMedicines = false;
      });
      AnalyticsService.instance.track(
        AnalyticsEvents.catalogResultsLoaded,
        properties: {
          'module': 'pharmacy',
          'entity_type': 'medicine',
          'result_count': _medicines.length,
          'source': 'remote',
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMedicines = false);
      AnalyticsService.instance.track(
        AnalyticsEvents.catalogResultsLoaded,
        properties: {
          'module': 'pharmacy',
          'entity_type': 'medicine',
          'result_count': _medicines.length,
          'source': 'fallback_sample',
        },
      );
    }
  }

  Future<void> _loadPharmacies({_ResolvedPharmacyLocation? location}) async {
    final queryParts = <String>[
      'sort=distance',
      'radiusKm=5',
      if (location != null) 'latitude=${location.latitude}',
      if (location != null) 'longitude=${location.longitude}',
    ];
    final query = queryParts.join('&');
    try {
      final response = await ApiClient.get('/catalog/pharmacies?$query');
      final pharmacies = (response as List)
          .map(
            (entry) => _PharmacyDirectoryItem.fromApi(
              Map<String, dynamic>.from(entry),
            ),
          )
          .toList(growable: false);
      if (!mounted) return;
      final selected = _selectedPharmacyName?.trim().toLowerCase();
      final hasSelected =
          selected != null &&
          pharmacies.any(
            (pharmacy) => pharmacy.name.trim().toLowerCase() == selected,
          );
      setState(() {
        _pharmacies = pharmacies;
        _selectedPharmacyName = pharmacies.isEmpty || !hasSelected
            ? null
            : _selectedPharmacyName;
        _isLoadingPharmacies = false;
      });
      AnalyticsService.instance.track(
        AnalyticsEvents.catalogResultsLoaded,
        properties: {
          'module': 'pharmacy',
          'entity_type': 'pharmacy',
          'result_count': _pharmacies.length,
          'source': 'remote',
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingPharmacies = false);
      AnalyticsService.instance.track(
        AnalyticsEvents.catalogResultsLoaded,
        properties: {
          'module': 'pharmacy',
          'entity_type': 'pharmacy',
          'result_count': _pharmacies.length,
          'source': 'fallback_empty',
        },
      );
    }
  }

  Future<_ResolvedPharmacyLocation?> _resolveLocation({
    bool showFailureSnackBar = true,
  }) async {
    final auth = context.read<AuthProvider>();
    final addresses = auth.user?.addresses ?? const <AddressModel>[];
    AddressModel? preferredAddress;
    for (final address in addresses) {
      if (address.isDefault) {
        preferredAddress = address;
        break;
      }
    }
    if (preferredAddress == null) {
      for (final address in addresses) {
        if (address.latitude != null && address.longitude != null) {
          preferredAddress = address;
          break;
        }
      }
    }
    preferredAddress ??= addresses.isNotEmpty ? addresses.first : null;

    if (preferredAddress?.latitude != null &&
        preferredAddress?.longitude != null) {
      final resolved = _ResolvedPharmacyLocation(
        latitude: preferredAddress!.latitude!,
        longitude: preferredAddress.longitude!,
      );
      if (mounted) {
        setState(() => _resolvedLocation = resolved);
      }
      return resolved;
    }

    try {
      final servicesEnabled = await Geolocator.isLocationServiceEnabled();
      if (!servicesEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) return null;

      final resolved = _ResolvedPharmacyLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (mounted) {
        setState(() => _resolvedLocation = resolved);
      }
      return resolved;
    } catch (_) {
      if (showFailureSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.t('common.location_access_failed')),
          ),
        );
      }
      return null;
    }
  }

  String _preferredAddressLabel() {
    final addresses =
        context.read<AuthProvider>().user?.addresses ?? const <AddressModel>[];
    if (addresses.isEmpty) return '';
    final selected = addresses.firstWhere(
      (address) => address.isDefault,
      orElse: () => addresses.first,
    );
    return '${selected.address}${selected.city != null ? ', ${selected.city}' : ''}';
  }

  int _visibleMedicinesCount({required String query}) {
    final normalizedQuery = query.trim().toLowerCase();
    final selectedPharmacyName = _selectedPharmacy?.name.trim().toLowerCase();
    return _medicines.where((medicine) {
      if (selectedPharmacyName != null && selectedPharmacyName.isNotEmpty) {
        final medicineBusiness = medicine.sourceBusiness?.trim().toLowerCase();
        if (medicineBusiness != selectedPharmacyName) return false;
      }
      if (normalizedQuery.isEmpty) return true;
      return medicine.name.toLowerCase().contains(normalizedQuery) ||
          medicine.description.toLowerCase().contains(normalizedQuery) ||
          medicine.category.toLowerCase().contains(normalizedQuery);
    }).length;
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      final normalizedQuery = value.trim().toLowerCase();
      if (normalizedQuery == _lastTrackedSearch) return;
      _lastTrackedSearch = normalizedQuery;
      if (normalizedQuery.isNotEmpty && normalizedQuery.length < 2) return;

      AnalyticsService.instance.track(
        AnalyticsEvents.searchPerformed,
        properties: {
          'module': 'pharmacy',
          'query': normalizedQuery,
          'query_length': normalizedQuery.length,
          'selected_pharmacy': _selectedPharmacyName ?? 'all',
          'result_count': _visibleMedicinesCount(query: normalizedQuery),
        },
      );
    });
  }

  Future<void> _openPrescriptionSheet() async {
    final l10n = context.l10n;
    AnalyticsService.instance.track(
      AnalyticsEvents.checkoutEntryTapped,
      properties: {
        'module': 'pharmacy',
        'source': 'pharmacy_prescription_cta',
        'entry_type': 'prescription_request',
      },
    );
    final allowed = await requireLoggedIn(
      context,
      message: l10n.t('checkout.login_required'),
    );
    if (!mounted || !allowed) return;
    if (_isSubmittingPrescription) return;

    if (_pharmacies.isEmpty) {
      AnalyticsService.instance.track(
        AnalyticsEvents.checkoutValidationFailed,
        properties: {
          'module': 'pharmacy',
          'reason': 'no_pharmacies_available',
          'source': 'pharmacy_prescription_cta',
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('pharmacy.no_pharmacies_subtitle'))),
      );
      return;
    }

    final selectedPharmacyName =
        _selectedPharmacyName ?? _pharmacies.first.name;
    final currentLocation =
        _resolvedLocation ?? await _resolveLocation(showFailureSnackBar: false);
    final selectedAddress = _preferredAddressLabel();
    if (!mounted) return;

    final draft = await showModalBottomSheet<_PrescriptionRequestDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PrescriptionRequestSheet(
        pharmacies: _pharmacies,
        initialPharmacyName: selectedPharmacyName,
        addressLabel: selectedAddress,
      ),
    );
    if (!mounted || draft == null) return;

    final auth = context.read<AuthProvider>();
    final userId = auth.user?.id;
    if (userId == null || userId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('checkout.login_required'))),
      );
      return;
    }

    setState(() => _isSubmittingPrescription = true);
    try {
      String? uploadedPrescriptionUrl;
      AnalyticsService.instance.track(
        AnalyticsEvents.orderSubmitAttempted,
        properties: {
          'module': 'pharmacy',
          'source': 'pharmacy_prescription_sheet',
          'order_type': 'prescription',
          'has_image': draft.imageBytes != null && draft.imageBytes!.isNotEmpty,
        },
      );
      setState(
        () => _prescriptionSubmitStage = l10n.t(
          'pharmacy.prescription_stage_upload',
        ),
      );
      if (draft.imageBytes != null && draft.imageBytes!.isNotEmpty) {
        final resolvedMimeType = _resolvePrescriptionMimeType(
          explicitMimeType: draft.imageMimeType,
          fileName: draft.imageFileName,
        );
        final uploaded = await MediaUploadService.uploadImage(
          scope: MediaUploadScope.prescription,
          ownerId: userId,
          fileName: draft.imageFileName?.trim().isNotEmpty == true
              ? draft.imageFileName!.trim()
              : null,
          mimeType: resolvedMimeType,
          bytes: draft.imageBytes!,
        );
        if (!mounted) return;
        uploadedPrescriptionUrl = uploaded.url;
      }

      setState(
        () => _prescriptionSubmitStage = l10n.t(
          'pharmacy.prescription_stage_submit',
        ),
      );
      final response = await ApiClient.post('/orders/pharmacy-prescription', {
        'userId': userId,
        'pharmacyName': draft.pharmacyName,
        if (draft.note.trim().isNotEmpty) 'note': draft.note.trim(),
        if (uploadedPrescriptionUrl != null &&
            uploadedPrescriptionUrl.trim().isNotEmpty)
          'prescriptionImageUrl': uploadedPrescriptionUrl.trim(),
        if (selectedAddress.isNotEmpty) 'address': selectedAddress,
        if (currentLocation != null) 'latitude': currentLocation.latitude,
        if (currentLocation != null) 'longitude': currentLocation.longitude,
      });

      if (!mounted) return;
      final order = Map<String, dynamic>.from(response as Map);
      final orderId = order['id']?.toString();
      if (orderId == null || orderId.isEmpty) {
        throw Exception('Prescription order was created without an id.');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('pharmacy.prescription_success'))),
      );
      AnalyticsService.instance.track(
        AnalyticsEvents.orderSubmitSucceeded,
        properties: {
          'module': 'pharmacy',
          'source': 'pharmacy_prescription_sheet',
          'order_type': 'prescription',
          'order_id_present': true,
        },
      );
      context.push('/pharmacy/order/$orderId', extra: order);
    } catch (error) {
      AnalyticsService.instance.track(
        AnalyticsEvents.orderSubmitFailed,
        properties: {
          'module': 'pharmacy',
          'source': 'pharmacy_prescription_sheet',
          'order_type': 'prescription',
          'reason': error.runtimeType.toString(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.t(
              'pharmacy.prescription_failed',
              params: {'error': ApiClient.userFacingError(error)},
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingPrescription = false;
          _prescriptionSubmitStage = '';
        });
      }
    }
  }

  String _resolvePrescriptionMimeType({
    required String? explicitMimeType,
    required String? fileName,
  }) {
    final direct = explicitMimeType?.trim().toLowerCase();
    if (direct != null && direct.isNotEmpty) return direct;

    final normalizedName = fileName?.trim().toLowerCase() ?? '';
    if (normalizedName.endsWith('.png')) return 'image/png';
    if (normalizedName.endsWith('.webp')) return 'image/webp';
    if (normalizedName.endsWith('.heic') || normalizedName.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cartProvider = context.watch<CartProvider>();
    final cartItemCount = cartProvider.getModuleItemCount('pharmacy');
    final moduleTotal = cartProvider.getModuleSubtotal('pharmacy');
    final query = _searchQuery.trim().toLowerCase();
    final selectedPharmacy = _selectedPharmacy;
    final selectedPharmacyName = selectedPharmacy?.name.trim().toLowerCase();
    final medicines = _medicines.where((medicine) {
      if (selectedPharmacyName != null && selectedPharmacyName.isNotEmpty) {
        final medicineBusiness = medicine.sourceBusiness?.trim().toLowerCase();
        if (medicineBusiness != selectedPharmacyName) {
          return false;
        }
      }
      if (query.isEmpty) return true;
      return medicine.name.toLowerCase().contains(query) ||
          medicine.description.toLowerCase().contains(query) ||
          medicine.category.toLowerCase().contains(query);
    }).toList();

    final isLoading = _isLoadingMedicines || _isLoadingPharmacies;

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !context.canPop()) {
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l10n.t('pharmacy.title')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          actions: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  splashRadius: 24,
                  constraints: const BoxConstraints(
                    minWidth: 52,
                    minHeight: 52,
                  ),
                  padding: const EdgeInsets.all(12),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 24),
                  onPressed: () {
                    AnalyticsService.instance.track(
                      AnalyticsEvents.viewCartTapped,
                      properties: {
                        'module': 'pharmacy',
                        'source': 'pharmacy_screen_appbar',
                        'cart_item_count': cartItemCount,
                      },
                    );
                    context.push('/pharmacy/cart');
                  },
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
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: AppSearchBar(
                      hint: l10n.t('pharmacy.search_hint'),
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.pharmacy,
                            AppColors.secondaryLight,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.t('pharmacy.hero_title'),
                                  style: AppTextStyles.h4.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedPharmacy == null
                                      ? l10n.t('pharmacy.hero_subtitle')
                                      : '${selectedPharmacy.name} • ${selectedPharmacy.distanceLabel(l10n)}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white70,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: _openPrescriptionSheet,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      l10n.t('pharmacy.upload_now'),
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: AppColors.pharmacy,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              color: AppColors.white,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.t('pharmacy.nearby_title'),
                            style: AppTextStyles.h4,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedPharmacyName = null);
                            AnalyticsService.instance.track(
                              AnalyticsEvents.filterApplied,
                              properties: {
                                'module': 'pharmacy',
                                'filter_type': 'pharmacy_name',
                                'filter_value': 'all',
                              },
                            );
                          },
                          child: Text(l10n.t('pharmacy.all_pharmacies')),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isLoadingPharmacies)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 194,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        itemCount: 2,
                        itemBuilder: (context, index) =>
                            const _PharmacyNearbySkeletonCard(),
                      ),
                    ),
                  )
                else if (_pharmacies.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppSpacing.shadowSm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.t('pharmacy.no_pharmacies_title'),
                              style: AppTextStyles.labelLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.t('pharmacy.no_pharmacies_subtitle'),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 194,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        itemCount: _pharmacies.length,
                        itemBuilder: (context, index) {
                          final pharmacy = _pharmacies[index];
                          return _PharmacyNearbyCard(
                            pharmacy: pharmacy,
                            onViewDetails: () {
                              AnalyticsService.instance.track(
                                AnalyticsEvents.entityOpened,
                                properties: {
                                  'module': 'pharmacy',
                                  'entity_type': 'pharmacy',
                                  'entity_id': pharmacy.id,
                                  'source': 'pharmacy_nearby_card',
                                },
                              );
                              context.push(
                                '/pharmacy/store/${pharmacy.id}',
                                extra: pharmacy.toMap(),
                              );
                            },
                            l10n: l10n,
                          );
                        },
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Text(
                      selectedPharmacy == null
                          ? l10n.t('pharmacy.popular_medicines')
                          : '${selectedPharmacy.name} • ${l10n.t('pharmacy.popular_medicines')}',
                      style: AppTextStyles.h4,
                    ),
                  ),
                ),
                if (isLoading)
                  const SliverSectionListShimmer(itemCount: 6)
                else if (medicines.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
                          l10n.t('pharmacy.no_results_for_pharmacy'),
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
                      final medicine = medicines[index];
                      return GestureDetector(
                        onTap: () {
                          AnalyticsService.instance.track(
                            AnalyticsEvents.entityOpened,
                            properties: {
                              'module': 'pharmacy',
                              'entity_type': 'medicine',
                              'entity_id': medicine.id,
                              'source': 'pharmacy_medicine_list',
                            },
                          );
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
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.pharmacyBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.medication_rounded,
                                  color: AppColors.pharmacy,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
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
                                    const SizedBox(height: 2),
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'DJF${medicine.price.toStringAsFixed(2)}',
                                    style: AppTextStyles.priceSmall.copyWith(
                                      color: AppColors.pharmacy,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      AnalyticsService.instance.track(
                                        AnalyticsEvents.cartAdjustmentInitiated,
                                        properties: {
                                          'module': 'pharmacy',
                                          'source': 'pharmacy_medicine_list',
                                          'action': 'add',
                                          'entity_type': 'medicine',
                                          'entity_id': medicine.id,
                                        },
                                      );
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
                                        horizontal: 14,
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
                    }, childCount: medicines.length),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
            if (_isSubmittingPrescription)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.34),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 28),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _prescriptionSubmitStage.isEmpty
                                  ? l10n.t('pharmacy.prescription_submitting')
                                  : _prescriptionSubmitStage,
                              style: AppTextStyles.labelMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: cartItemCount > 0
            ? SafeArea(
                minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: GestureDetector(
                  onTap: () {
                    AnalyticsService.instance.track(
                      AnalyticsEvents.viewCartTapped,
                      properties: {
                        'module': 'pharmacy',
                        'source': 'pharmacy_screen_fab',
                        'cart_item_count': cartItemCount,
                      },
                    );
                    context.push('/pharmacy/cart');
                  },
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
                          'DJF${moduleTotal.toStringAsFixed(2)}',
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
      ),
    );
  }
}

class _PharmacyNearbySkeletonCard extends StatelessWidget {
  const _PharmacyNearbySkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBlock(width: 40, height: 40, radius: 12),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBlock(width: 132, height: 12, radius: 8),
                      SizedBox(height: 6),
                      ShimmerBlock(width: 160, height: 10, radius: 8),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ShimmerBlock(width: 78, height: 20, radius: 999),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ShimmerBlock(
                    width: double.infinity,
                    height: 28,
                    radius: 10,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ShimmerBlock(
                    width: double.infinity,
                    height: 28,
                    radius: 10,
                  ),
                ),
              ],
            ),
            Spacer(),
            ShimmerBlock(width: double.infinity, height: 34, radius: 10),
          ],
        ),
      ),
    );
  }
}

class _PharmacyNearbyCard extends StatelessWidget {
  const _PharmacyNearbyCard({
    required this.pharmacy,
    required this.onViewDetails,
    required this.l10n,
  });

  final _PharmacyDirectoryItem pharmacy;
  final VoidCallback onViewDetails;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          ...AppSpacing.shadowSm,
          BoxShadow(
            color: AppColors.pharmacy.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.pharmacyBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    pharmacy.imageUrl != null &&
                        pharmacy.imageUrl!.trim().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          pharmacy.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.local_pharmacy_rounded,
                            color: AppColors.pharmacy,
                            size: 22,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.local_pharmacy_rounded,
                        color: AppColors.pharmacy,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pharmacy.name,
                      style: AppTextStyles.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pharmacy.address?.trim().isNotEmpty == true
                          ? pharmacy.address!
                          : l10n.t('pharmacy.distance_unknown'),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.pharmacyBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              pharmacy.distanceLabel(l10n),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.pharmacy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MiniInlineStat(
                  icon: Icons.star_rounded,
                  label:
                      '${pharmacy.rating.toStringAsFixed(1)} • ${pharmacy.reviewCount}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniInlineStat(
                  icon: Icons.medication_liquid_rounded,
                  label: l10n.t(
                    'pharmacy.medicines_count_short',
                    params: {'count': '${pharmacy.productCount}'},
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onViewDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pharmacy,
                foregroundColor: AppColors.white,
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.t('pharmacy.view_details'),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInlineStat extends StatelessWidget {
  const _MiniInlineStat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.extraLightGrey,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.pharmacy),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionRequestSheet extends StatefulWidget {
  const _PrescriptionRequestSheet({
    required this.pharmacies,
    required this.initialPharmacyName,
    required this.addressLabel,
  });

  final List<_PharmacyDirectoryItem> pharmacies;
  final String initialPharmacyName;
  final String addressLabel;

  @override
  State<_PrescriptionRequestSheet> createState() =>
      _PrescriptionRequestSheetState();
}

class _PrescriptionRequestSheetState extends State<_PrescriptionRequestSheet> {
  late String _selectedPharmacyName = widget.initialPharmacyName;
  final TextEditingController _noteController = TextEditingController();
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _selectedImageMimeType;
  bool _isPickingImage = false;

  Future<void> _pickPrescriptionImage(ImageSource source) async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1900,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = file.name;
        _selectedImageMimeType = file.mimeType;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.t('pharmacy.prescription_image_pick_failed'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('pharmacy.prescription_sheet_title'),
                  style: AppTextStyles.h4,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.t('pharmacy.prescription_sheet_subtitle'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.t('pharmacy.prescription_pharmacy_label'),
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedPharmacyName,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  items: widget.pharmacies
                      .map(
                        (pharmacy) => DropdownMenuItem<String>(
                          value: pharmacy.name,
                          child: Text(
                            pharmacy.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedPharmacyName = value);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.t('pharmacy.prescription_notes_label'),
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: l10n.t('pharmacy.prescription_notes_hint'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.t('pharmacy.prescription_image_label'),
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightGrey),
                  ),
                  child: _selectedImageBytes == null
                      ? Row(
                          children: [
                            const Icon(
                              Icons.photo_camera_back_outlined,
                              color: AppColors.pharmacy,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _isPickingImage
                                    ? l10n.t(
                                        'pharmacy.prescription_image_loading',
                                      )
                                    : l10n.t(
                                        'pharmacy.prescription_image_choose',
                                      ),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.grey,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                _selectedImageBytes!,
                                width: double.infinity,
                                height: 132,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedImageName ??
                                        l10n.t(
                                          'pharmacy.prescription_image_selected',
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedImageBytes = null;
                                      _selectedImageName = null;
                                      _selectedImageMimeType = null;
                                    });
                                  },
                                  child: Text(
                                    l10n.t(
                                      'pharmacy.prescription_image_remove',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isPickingImage
                            ? null
                            : () => _pickPrescriptionImage(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        label: Text(
                          l10n.t('pharmacy.prescription_image_camera'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isPickingImage
                            ? null
                            : () => _pickPrescriptionImage(ImageSource.gallery),
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                        ),
                        label: Text(
                          l10n.t('pharmacy.prescription_image_gallery'),
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.addressLabel.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.t('pharmacy.prescription_address_label'),
                    style: AppTextStyles.labelMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.addressLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pharmacy,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(
                        _PrescriptionRequestDraft(
                          pharmacyName: _selectedPharmacyName,
                          note: _noteController.text,
                          imageBytes: _selectedImageBytes,
                          imageFileName: _selectedImageName,
                          imageMimeType: _selectedImageMimeType,
                        ),
                      );
                    },
                    child: Text(l10n.t('pharmacy.prescription_submit')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrescriptionRequestDraft {
  const _PrescriptionRequestDraft({
    required this.pharmacyName,
    required this.note,
    this.imageBytes,
    this.imageFileName,
    this.imageMimeType,
  });

  final String pharmacyName;
  final String note;
  final Uint8List? imageBytes;
  final String? imageFileName;
  final String? imageMimeType;
}

class _ResolvedPharmacyLocation {
  const _ResolvedPharmacyLocation({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class _PharmacyDirectoryItem {
  const _PharmacyDirectoryItem({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.productCount,
    required this.prescriptionCount,
    this.minPrice,
    this.address,
    this.imageUrl,
  });

  final String id;
  final String name;
  final double rating;
  final int reviewCount;
  final double? distanceKm;
  final int productCount;
  final int prescriptionCount;
  final double? minPrice;
  final String? address;
  final String? imageUrl;

  factory _PharmacyDirectoryItem.fromApi(Map<String, dynamic> json) {
    final locationMap = json['location'] is Map
        ? Map<String, dynamic>.from(json['location'] as Map)
        : const <String, dynamic>{};
    final resolvedId = json['id']?.toString().trim();
    return _PharmacyDirectoryItem(
      id: resolvedId != null && resolvedId.isNotEmpty
          ? resolvedId
          : 'pharmacy-${(json['name'] ?? 'unknown').toString().toLowerCase().replaceAll(' ', '-')}',
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : 'Pharmacy',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
      prescriptionCount: (json['prescriptionCount'] as num?)?.toInt() ?? 0,
      minPrice: (json['minPrice'] as num?)?.toDouble(),
      address: locationMap['address']?.toString(),
      imageUrl:
          json['imageUrl']?.toString() ??
          json['profileImageUrl']?.toString() ??
          json['profileAvatarUrl']?.toString() ??
          json['avatarUrl']?.toString(),
    );
  }

  String distanceLabel(AppLocalizations l10n) {
    if (distanceKm == null) return l10n.t('pharmacy.distance_unknown');
    return l10n.t(
      'pharmacy.distance_km',
      params: {'distance': distanceKm!.toStringAsFixed(1)},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'reviewCount': reviewCount,
      'distanceKm': distanceKm,
      'productCount': productCount,
      'prescriptionCount': prescriptionCount,
      'minPrice': minPrice,
      'address': address,
      'imageUrl': imageUrl,
    };
  }
}
