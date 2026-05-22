import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../core/constants/pro_design_system.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/providers/pro_auth_provider.dart';
import '../../../core/router/pro_route_paths.dart';
import '../../../core/utils/pro_module_helper.dart';
import '../../shop/screens/shop_store_setup_screen.dart';
import '../../../l10n/app_localizations.dart';

class ProProfileManagementScreen extends StatefulWidget {
  const ProProfileManagementScreen({super.key, required this.profile});

  final ProProfile profile;

  @override
  State<ProProfileManagementScreen> createState() =>
      _ProProfileManagementScreenState();
}

class _ProProfileManagementScreenState
    extends State<ProProfileManagementScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  late final TextEditingController _businessNameController;
  late Set<ProModule> _selectedModules;
  bool _isSavingProfile = false;
  bool _isUploadingAvatar = false;
  Uint8List? _pickedAvatarBytes;
  String? _latestAvatarUrl;
  // _insightsFuture removed as profile snapshot UI is no longer needed
  Future<_ShopProfileDetails>? _shopProfileFuture;
  Future<List<Map<String, dynamic>>>? _providerSettingsFuture;
  Future<Map<String, dynamic>>? _providerAvailabilityFuture;
  Future<List<Map<String, dynamic>>>? _doctorSettingsFuture;
  Future<List<Map<String, dynamic>>>? _deliveryQueueFuture;
  Future<List<Map<String, dynamic>>>? _rideQueueFuture;
  final Set<String> _quickActionBusyIds = <String>{};

  List<ProModule> get _allowedModules =>
      ProModuleHelper.getModulesForProfile(widget.profile.type);

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(
      text: widget.profile.businessName,
    );
    _selectedModules = {...widget.profile.activeModules};
    // _insightsFuture initialization removed
    if (widget.profile.type == ProProfileType.shop) {
      _shopProfileFuture = _loadShopProfileDetails();
    } else if (widget.profile.type == ProProfileType.provider) {
      _providerSettingsFuture = _loadProviderSettings();
      _providerAvailabilityFuture = _loadProviderAvailability();
    } else if (widget.profile.type == ProProfileType.doctor) {
      _doctorSettingsFuture = _loadDoctorSettings();
    } else if (widget.profile.type == ProProfileType.delivery) {
      _deliveryQueueFuture = _loadDeliveryQueue();
    } else if (widget.profile.type == ProProfileType.rider) {
      _rideQueueFuture = _loadRideQueue();
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_isUploadingAvatar) return;

    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      imageQuality: 88,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      _pickedAvatarBytes = bytes;
      _isUploadingAvatar = true;
    });

    try {
      final uploaded = await MediaUploadService.uploadImage(
        scope: MediaUploadScope.proAvatar,
        ownerId: widget.profile.userId,
        fileName: file.name,
        mimeType: file.mimeType,
        bytes: bytes,
      );

      await ApiClient.post('/pro/${widget.profile.userId}/avatar', {
        'avatarUrl': uploaded.url,
      });

      if (!mounted) return;
      setState(() {
        _latestAvatarUrl = uploaded.url;
      });

      await context.read<ProAuthProvider>().refreshSession();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profilePhotoUpdated)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiClient.userFacingError(error))));
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_isSavingProfile) return;

    final l10n = AppLocalizations.of(context)!;
    final businessName = _businessNameController.text.trim();
    if (businessName.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.businessNameMinChars)));
      return;
    }

    if (_selectedModules.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.enableAtLeastOneModule)));
      return;
    }

    setState(() => _isSavingProfile = true);

    try {
      await context.read<ProAuthProvider>().updateProfileSettings(
        businessName: businessName,
        activeModules: _selectedModules.toList(growable: false),
      );
      if (!mounted) return;
      final updatedProfile = context.read<ProAuthProvider>().currentProfile;
      setState(() {
        if (updatedProfile != null) {
          _businessNameController.text = updatedProfile.businessName;
          _selectedModules = {...updatedProfile.activeModules};
        }
        // _insightsFuture refresh removed
        final refreshedProfile = updatedProfile ?? widget.profile;
        if (refreshedProfile.type == ProProfileType.shop) {
          _shopProfileFuture = _loadShopProfileDetails();
          _providerSettingsFuture = null;
          _doctorSettingsFuture = null;
          _providerAvailabilityFuture = null;
          _deliveryQueueFuture = null;
          _rideQueueFuture = null;
        } else if (refreshedProfile.type == ProProfileType.provider) {
          _providerSettingsFuture = _loadProviderSettings();
          _providerAvailabilityFuture = _loadProviderAvailability();
          _shopProfileFuture = null;
          _doctorSettingsFuture = null;
          _deliveryQueueFuture = null;
          _rideQueueFuture = null;
        } else if (refreshedProfile.type == ProProfileType.doctor) {
          _doctorSettingsFuture = _loadDoctorSettings();
          _shopProfileFuture = null;
          _providerSettingsFuture = null;
          _providerAvailabilityFuture = null;
          _deliveryQueueFuture = null;
          _rideQueueFuture = null;
        } else if (refreshedProfile.type == ProProfileType.delivery) {
          _deliveryQueueFuture = _loadDeliveryQueue();
          _shopProfileFuture = null;
          _providerSettingsFuture = null;
          _providerAvailabilityFuture = null;
          _doctorSettingsFuture = null;
          _rideQueueFuture = null;
        } else if (refreshedProfile.type == ProProfileType.rider) {
          _rideQueueFuture = _loadRideQueue();
          _shopProfileFuture = null;
          _providerSettingsFuture = null;
          _providerAvailabilityFuture = null;
          _doctorSettingsFuture = null;
          _deliveryQueueFuture = null;
        } else {
          _shopProfileFuture = null;
          _providerSettingsFuture = null;
          _providerAvailabilityFuture = null;
          _doctorSettingsFuture = null;
          _deliveryQueueFuture = null;
          _rideQueueFuture = null;
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.profileSettingsUpdated)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiClient.userFacingError(error))));
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _refreshInsights() async {
    final future = _loadInsights();
    setState(() {
      // _insightsFuture update removed
      final profile =
          context.read<ProAuthProvider>().currentProfile ?? widget.profile;
      if (profile.type == ProProfileType.shop) {
        _shopProfileFuture = _loadShopProfileDetails();
        _providerSettingsFuture = null;
        _doctorSettingsFuture = null;
      } else if (profile.type == ProProfileType.provider) {
        _providerSettingsFuture = _loadProviderSettings();
        _providerAvailabilityFuture = _loadProviderAvailability();
        _shopProfileFuture = null;
        _doctorSettingsFuture = null;
        _deliveryQueueFuture = null;
        _rideQueueFuture = null;
      } else if (profile.type == ProProfileType.doctor) {
        _doctorSettingsFuture = _loadDoctorSettings();
        _shopProfileFuture = null;
        _providerSettingsFuture = null;
        _providerAvailabilityFuture = null;
        _deliveryQueueFuture = null;
        _rideQueueFuture = null;
      } else if (profile.type == ProProfileType.delivery) {
        _deliveryQueueFuture = _loadDeliveryQueue();
        _shopProfileFuture = null;
        _providerSettingsFuture = null;
        _providerAvailabilityFuture = null;
        _doctorSettingsFuture = null;
        _rideQueueFuture = null;
      } else if (profile.type == ProProfileType.rider) {
        _rideQueueFuture = _loadRideQueue();
        _shopProfileFuture = null;
        _providerSettingsFuture = null;
        _providerAvailabilityFuture = null;
        _doctorSettingsFuture = null;
        _deliveryQueueFuture = null;
      } else {
        _shopProfileFuture = null;
        _providerSettingsFuture = null;
        _providerAvailabilityFuture = null;
        _doctorSettingsFuture = null;
        _deliveryQueueFuture = null;
        _rideQueueFuture = null;
      }
    });
    await future;
  }

  Future<_ShopProfileDetails> _loadShopProfileDetails() async {
    final profile =
        context.read<ProAuthProvider>().currentProfile ?? widget.profile;
    if (profile.type != ProProfileType.shop) {
      return const _ShopProfileDetails(
        storefrontData: <String, dynamic>{},
        pharmacyBusinesses: <String>[],
      );
    }

    final userId = profile.userId;
    final storefrontData = Map<String, dynamic>.from(
      await ApiClient.get('/pro/$userId/shop-availability', forceRefresh: true)
          as Map,
    );

    final pharmacyProductsResponse = Map<String, dynamic>.from(
      await ApiClient.get(
            '/pro/$userId/shopping-products?module=pharmacy',
            forceRefresh: true,
          )
          as Map,
    );
    final pharmacyBusinesses =
        (pharmacyProductsResponse['stores'] as List<dynamic>? ?? const [])
            .map((entry) => Map<String, dynamic>.from(entry as Map))
            .map((entry) => entry['name']?.toString().trim() ?? '')
            .where((entry) => entry.isNotEmpty)
            .toSet()
            .toList(growable: false);

    return _ShopProfileDetails(
      storefrontData: storefrontData,
      pharmacyBusinesses: pharmacyBusinesses,
    );
  }

  Map<String, dynamic>? _primaryShoppingStoreFromData(
    Map<String, dynamic> data,
  ) {
    final stores = (data['shopping'] as List<dynamic>? ?? const [])
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);
    return stores.isEmpty ? null : stores.first;
  }

  Map<String, dynamic>? _primaryRestaurantFromData(Map<String, dynamic> data) {
    final restaurants = (data['food'] as List<dynamic>? ?? const [])
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);
    return restaurants.isEmpty ? null : restaurants.first;
  }

  Future<void> _openShoppingStoreSetupEditor(
    Map<String, dynamic>? existingStore,
  ) async {
    final profile =
        context.read<ProAuthProvider>().currentProfile ?? widget.profile;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ShopStoreSetupScreen(
          userId: profile.userId,
          businessName: profile.businessName,
          initialStore: existingStore,
        ),
      ),
    );
    if (updated != true || !mounted) return;
    await _refreshInsights();
  }

  Future<void> _openRestaurantEditor(
    Map<String, dynamic>? existingRestaurant,
  ) async {
    final profile =
        context.read<ProAuthProvider>().currentProfile ?? widget.profile;
    if (profile.type != ProProfileType.shop) return;

    final nameController = TextEditingController(
      text: existingRestaurant?['name']?.toString().trim().isNotEmpty == true
          ? existingRestaurant!['name'].toString().trim()
          : profile.businessName,
    );
    final cuisineController = TextEditingController(
      text: existingRestaurant?['cuisine']?.toString().trim().isNotEmpty == true
          ? existingRestaurant!['cuisine'].toString().trim()
          : existingRestaurant?['subtitle']?.toString().trim() ?? '',
    );
    var uploadedImageUrl =
        existingRestaurant?['imageUrl']?.toString().trim() ?? '';
    Uint8List? pickedImageBytes;
    var isUploadingImage = false;
    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final l10n = AppLocalizations.of(context)!;
            Future<void> pickAndUploadImage() async {
              if (isUploadingImage) return;
              final picker = ImagePicker();
              final file = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1800,
                imageQuality: 88,
              );
              if (file == null) return;

              final bytes = await file.readAsBytes();
              if (!mounted) return;
              setModalState(() {
                pickedImageBytes = bytes;
                isUploadingImage = true;
              });

              try {
                final uploaded = await MediaUploadService.uploadImage(
                  scope: MediaUploadScope.restaurant,
                  ownerId: profile.userId,
                  fileName: file.name,
                  mimeType: file.mimeType,
                  bytes: bytes,
                );
                if (!mounted) return;
                setModalState(() {
                  uploadedImageUrl = uploaded.url;
                });
              } catch (error) {
                if (!mounted || !sheetContext.mounted) return;
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(ApiClient.userFacingError(error))),
                );
              } finally {
                if (mounted) {
                  setModalState(() => isUploadingImage = false);
                }
              }
            }

            Future<void> submit() async {
              if (isSubmitting || isUploadingImage) return;
              if (nameController.text.trim().length < 2) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(l10n.enterValidRestaurantName)),
                );
                return;
              }
              setModalState(() => isSubmitting = true);
              try {
                final response = Map<String, dynamic>.from(
                  await ApiClient.post('/pro/${profile.userId}/restaurant', {
                        'name': nameController.text.trim(),
                        'imageUrl': uploadedImageUrl,
                        if (cuisineController.text.trim().isNotEmpty)
                          'cuisine': cuisineController.text.trim(),
                      })
                      as Map,
                );
                if (!mounted || !sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      (response['created'] as bool? ?? false)
                          ? l10n.restaurantConnectedProfile
                          : l10n.restaurantDetailsUpdated,
                    ),
                  ),
                );
                await _refreshInsights();
              } catch (error) {
                if (!mounted || !sheetContext.mounted) return;
                setModalState(() => isSubmitting = false);
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(ApiClient.userFacingError(error))),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                18,
                16,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      existingRestaurant == null
                          ? l10n.connectRestaurant
                          : l10n.editRestaurant,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: l10n.restaurantName,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cuisineController,
                      decoration: InputDecoration(
                        labelText: l10n.cuisine,
                        hintText: l10n.cuisineHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 156,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: pickedImageBytes != null
                          ? Image.memory(pickedImageBytes!, fit: BoxFit.cover)
                          : (uploadedImageUrl.isNotEmpty
                                ? Image.network(
                                    uploadedImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                              child: Icon(
                                                Icons.restaurant_outlined,
                                                size: 38,
                                              ),
                                            ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.restaurant_outlined,
                                      size: 38,
                                    ),
                                  )),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: isUploadingImage ? null : pickAndUploadImage,
                      icon: isUploadingImage
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_outlined),
                      label: Text(
                        isUploadingImage
                            ? l10n.uploadingImage
                            : l10n.uploadRestaurantImage,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isSubmitting || isUploadingImage
                            ? null
                            : submit,
                        icon: isSubmitting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          isSubmitting
                              ? l10n.saving
                              : existingRestaurant == null
                              ? l10n.connectRestaurant
                              : l10n.saveRestaurant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    nameController.dispose();
    cuisineController.dispose();
  }

  Future<void> _openPharmacyEditor({
    required List<String> businesses,
    required String suggestedName,
  }) async {
    final profile =
        context.read<ProAuthProvider>().currentProfile ?? widget.profile;
    if (profile.type != ProProfileType.shop) return;

    final nameController = TextEditingController(
      text: businesses.isNotEmpty ? businesses.first : suggestedName,
    );
    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final l10n = AppLocalizations.of(context)!;
            Future<void> submit() async {
              if (isSubmitting) return;
              if (nameController.text.trim().length < 2) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(l10n.enterValidPharmacyBusinessName)),
                );
                return;
              }

              setModalState(() => isSubmitting = true);
              try {
                await ApiClient.post(
                  '/pro/${profile.userId}/pharmacy-business',
                  {'name': nameController.text.trim()},
                );
                if (!mounted || !sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(l10n.pharmacyBusinessConnected)),
                );
                await _refreshInsights();
              } catch (error) {
                if (!mounted || !sheetContext.mounted) return;
                setModalState(() => isSubmitting = false);
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(ApiClient.userFacingError(error))),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                18,
                16,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    businesses.isEmpty
                        ? l10n.connectPharmacyBusiness
                        : l10n.updatePharmacyBusiness,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.pharmacyBusinessName,
                    ),
                  ),
                  if (businesses.length > 1) ...[
                    const SizedBox(height: 10),
                    Text(
                      l10n.connectedBusinesses(businesses.length),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isSubmitting ? null : submit,
                      icon: isSubmitting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        isSubmitting
                            ? l10n.saving
                            : businesses.isEmpty
                            ? l10n.connectPharmacy
                            : l10n.savePharmacy,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    nameController.dispose();
  }

  List<String> _splitTextList(String raw) {
    return raw
        .split(RegExp(r'[\n,]'))
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _loadProviderSettings() async {
    final profile =
        context.read<ProAuthProvider>().currentProfile ?? widget.profile;
    if (profile.type != ProProfileType.provider) {
      return const <Map<String, dynamic>>[];
    }
    final response = await ApiClient.get(
      '/pro/${profile.userId}/provider-settings',
      forceRefresh: true,
    );
    return (response as List<dynamic>)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _loadProviderAvailability() async {
    final profile =
        context.read<ProAuthProvider>().currentProfile ?? widget.profile;
    if (profile.type != ProProfileType.provider) {
      return const <String, dynamic>{};
    }
    final response = await ApiClient.get(
      '/pro/${profile.userId}/provider-availability',
      forceRefresh: true,
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<Map<String, dynamic>>> _loadDoctorSettings() async {
    final profile =
        context.read<ProAuthProvider>().currentProfile ?? widget.profile;
    if (profile.type != ProProfileType.doctor) {
      return const <Map<String, dynamic>>[];
    }
    final response = await ApiClient.get(
      '/pro/${profile.userId}/doctor-settings',
      forceRefresh: true,
    );
    return (response as List<dynamic>)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _loadDeliveryQueue() async {
    final profile =
        context.read<ProAuthProvider>().currentProfile ?? widget.profile;
    if (profile.type != ProProfileType.delivery) {
      return const <Map<String, dynamic>>[];
    }
    final response = await ApiClient.get(
      '/pro/${profile.userId}/delivery-queue',
      forceRefresh: true,
    );
    return (response as List<dynamic>)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _loadRideQueue() async {
    final profile =
        context.read<ProAuthProvider>().currentProfile ?? widget.profile;
    if (profile.type != ProProfileType.rider) {
      return const <Map<String, dynamic>>[];
    }
    final response = await ApiClient.get(
      '/pro/${profile.userId}/ride-queue',
      forceRefresh: true,
    );
    return (response as List<dynamic>)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);
  }

  String _queueStatusLabel(String? raw, AppLocalizations l10n) {
    if (raw == null || raw.trim().isEmpty) return l10n.unknown;
    return raw
        .trim()
        .toLowerCase()
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String _dispatchModuleLabel(String raw, AppLocalizations l10n) {
    switch (raw.trim().toLowerCase()) {
      case 'shopping':
        return l10n.moduleShopping;
      case 'food':
        return l10n.moduleFood;
      case 'pharmacy':
        return l10n.modulePharmacy;
      default:
        return l10n.moduleDelivery(raw);
    }
  }

  Future<void> _claimDeliveryQueueItem(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final profile =
        context.read<ProAuthProvider>().currentProfile ?? widget.profile;
    if (profile.type != ProProfileType.delivery) return;
    final orderId = item['id']?.toString() ?? '';
    if (orderId.isEmpty) return;

    setState(() => _quickActionBusyIds.add(orderId));
    try {
      await ApiClient.post('/pro/${profile.userId}/claim-delivery', {
        'orderId': orderId,
      });
      if (!mounted) return;
      setState(() {
        _deliveryQueueFuture = _loadDeliveryQueue();
        // _insightsFuture reload removed
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.deliveryRequestClaimed)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiClient.userFacingError(error))));
    } finally {
      if (mounted) {
        setState(() => _quickActionBusyIds.remove(orderId));
      }
    }
  }

  Future<void> _claimRideQueueItem(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final profile =
        context.read<ProAuthProvider>().currentProfile ?? widget.profile;
    if (profile.type != ProProfileType.rider) return;
    final rideId = item['id']?.toString() ?? '';
    if (rideId.isEmpty) return;

    setState(() => _quickActionBusyIds.add(rideId));
    try {
      await ApiClient.post('/pro/${profile.userId}/claim-ride', {
        'rideId': rideId,
      });
      if (!mounted) return;
      setState(() {
        _rideQueueFuture = _loadRideQueue();
        // _insightsFuture reload removed
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.rideRequestClaimed)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ApiClient.userFacingError(error))));
    } finally {
      if (mounted) {
        setState(() => _quickActionBusyIds.remove(rideId));
      }
    }
  }

  Future<void> _openProviderCreateEditor() async {
    final l10n = AppLocalizations.of(context)!;
    final profile =
        context.read<ProAuthProvider>().currentProfile ?? widget.profile;
    if (profile.type != ProProfileType.provider) return;
    if (!profile.activeModules.contains(ProModule.services)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.enableServicesModule)));
      return;
    }

    // Navigate to the provider availability screen where the proper listing creation happens
    if (!context.mounted) return;
    context.push(ProRoutePaths.providerAvailability);
  }

  Future<void> _openProviderSettingsEditor(Map<String, dynamic> item) async {
    final profile =
        context.read<ProAuthProvider>().currentProfile ?? widget.profile;
    if (profile.type != ProProfileType.provider) return;
    final providerId = item['id']?.toString() ?? '';
    if (providerId.isEmpty) return;

    final locationController = TextEditingController(
      text: item['location']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: item['contactPhone']?.toString() ?? '',
    );
    final responseTimeController = TextEditingController(
      text: item['responseTime']?.toString() ?? '',
    );
    final servicesController = TextEditingController(
      text: (item['services'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .where((entry) => entry.trim().isNotEmpty)
          .join('\n'),
    );
    final bookingModesController = TextEditingController(
      text: (item['bookingModes'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .where((entry) => entry.trim().isNotEmpty)
          .join('\n'),
    );
    final availability = Map<String, dynamic>.from(
      (item['availability'] as Map?) ?? const <String, dynamic>{},
    );
    final weekdaysController = TextEditingController(
      text: availability['weekdays']?.toString() ?? '08:00 AM - 06:00 PM',
    );
    final saturdayController = TextEditingController(
      text: availability['saturday']?.toString() ?? '09:00 AM - 02:00 PM',
    );
    final sundayController = TextEditingController(
      text: availability['sunday']?.toString() ?? 'Closed',
    );
    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final l10n = AppLocalizations.of(context)!;
            Future<void> submit() async {
              if (isSubmitting) return;
              final services = _splitTextList(servicesController.text);
              if (services.isEmpty) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(l10n.addAtLeastOneService)),
                );
                return;
              }

              setModalState(() => isSubmitting = true);
              try {
                await ApiClient.post(
                  '/pro/${profile.userId}/provider-settings',
                  {
                    'providerId': providerId,
                    'location': locationController.text.trim(),
                    'contactPhone': phoneController.text.trim(),
                    'responseTime': responseTimeController.text.trim(),
                    'services': services,
                    'bookingModes': _splitTextList(bookingModesController.text),
                    'availability': {
                      'weekdays': weekdaysController.text.trim(),
                      'saturday': saturdayController.text.trim(),
                      'sunday': sundayController.text.trim(),
                    },
                  },
                );
                if (!mounted || !sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(l10n.providerSettingsUpdated)),
                );
                await _refreshInsights();
              } catch (error) {
                if (!mounted || !sheetContext.mounted) return;
                setModalState(() => isSubmitting = false);
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(ApiClient.userFacingError(error))),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                18,
                16,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.editProviderProfile,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: l10n.locationServiceArea,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(labelText: l10n.phone),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: responseTimeController,
                      decoration: InputDecoration(labelText: l10n.responseTime),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: servicesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: l10n.services,
                        hintText: l10n.commaOrNewlineSeparated,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: bookingModesController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.bookingModes,
                        hintText: l10n.bookingModesHint,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: weekdaysController,
                      decoration: InputDecoration(
                        labelText: l10n.weekdaysHours,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: saturdayController,
                      decoration: InputDecoration(
                        labelText: l10n.saturdayHours,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: sundayController,
                      decoration: InputDecoration(labelText: l10n.sundayHours),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isSubmitting ? null : submit,
                        icon: isSubmitting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          isSubmitting
                              ? l10n.saving
                              : l10n.saveProviderSettings,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    locationController.dispose();
    phoneController.dispose();
    responseTimeController.dispose();
    servicesController.dispose();
    bookingModesController.dispose();
    weekdaysController.dispose();
    saturdayController.dispose();
    sundayController.dispose();
  }

  Future<void> _openLaundryServiceEditor({
    Map<String, dynamic>? service,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final profile =
        context.read<ProAuthProvider>().currentProfile ?? widget.profile;
    if (profile.type != ProProfileType.provider) return;

    final supportsLaundry = profile.activeModules.contains(ProModule.laundry);
    final serviceId = service?['id']?.toString() ?? '';
    final isEdit = serviceId.isNotEmpty;
    if (!supportsLaundry && !isEdit) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.enableLaundryModuleFirst)));
      return;
    }

    final bookingConfig = Map<String, dynamic>.from(
      (service?['bookingConfig'] as Map?) ?? const <String, dynamic>{},
    );
    final itemCatalog =
        (bookingConfig['itemCatalog'] as List<dynamic>? ?? const [])
            .map((entry) => Map<String, dynamic>.from(entry as Map))
            .toList(growable: false);
    final pickupSlots =
        (bookingConfig['pickupSlots'] as List<dynamic>? ?? const [])
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);

    String formatNumber(num? value) {
      if (value == null) return '';
      final normalized = value.toDouble();
      return normalized % 1 == 0
          ? normalized.toStringAsFixed(0)
          : normalized.toStringAsFixed(2);
    }

    final nameController = TextEditingController(
      text: service?['name']?.toString().trim().isNotEmpty == true
          ? service!['name'].toString().trim()
          : l10n.washAndFold,
    );
    final descriptionController = TextEditingController(
      text: service?['description']?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: formatNumber((service?['price'] as num?)?.toDouble()),
    );
    final unitController = TextEditingController(
      text: service?['unit']?.toString().trim().isNotEmpty == true
          ? service!['unit'].toString().trim()
          : l10n.kg,
    );
    final itemCatalogController = TextEditingController(
      text: itemCatalog.isNotEmpty
          ? itemCatalog
                .map((entry) {
                  final label = entry['label']?.toString().trim() ?? '';
                  final price = formatNumber(
                    (entry['price'] as num?)?.toDouble(),
                  );
                  final category =
                      entry['category']?.toString().trim().toLowerCase() ==
                          'group'
                      ? 'group'
                      : 'unit';
                  final spec = entry['spec']?.toString().trim() ?? '';
                  return category == 'group'
                      ? '$label|$price|$category|$spec'
                      : '$label|$price|$category';
                })
                .join('\n')
          : 'Shirt|2|unit\nBedsheet|8|group|per sheet',
    );
    final pickupSlotsController = TextEditingController(
      text: pickupSlots.isNotEmpty
          ? pickupSlots.join('\n')
          : '08:00 - 10:00\n10:00 - 12:00',
    );
    final turnaroundHoursController = TextEditingController(
      text:
          formatNumber(
                (bookingConfig['turnaroundHours'] as num?)?.toDouble(),
              ) ==
              ''
          ? '24'
          : formatNumber(
              (bookingConfig['turnaroundHours'] as num?)?.toDouble(),
            ),
    );
    final minNoticeHoursController = TextEditingController(
      text:
          formatNumber((bookingConfig['minNoticeHours'] as num?)?.toDouble()) ==
              ''
          ? '2'
          : formatNumber((bookingConfig['minNoticeHours'] as num?)?.toDouble()),
    );
    final maxAdvanceDaysController = TextEditingController(
      text:
          formatNumber((bookingConfig['maxAdvanceDays'] as num?)?.toDouble()) ==
              ''
          ? '7'
          : formatNumber((bookingConfig['maxAdvanceDays'] as num?)?.toDouble()),
    );
    final taxRateController = TextEditingController(
      text:
          formatNumber((bookingConfig['taxRatePercent'] as num?)?.toDouble()) ==
              ''
          ? '0'
          : formatNumber((bookingConfig['taxRatePercent'] as num?)?.toDouble()),
    );
    final deliveryFeeController = TextEditingController(
      text:
          formatNumber((bookingConfig['deliveryFee'] as num?)?.toDouble()) == ''
          ? '0'
          : formatNumber((bookingConfig['deliveryFee'] as num?)?.toDouble()),
    );
    var enabled = service?['enabled'] as bool? ?? true;
    var uploadedIconUrl = service?['iconUrl']?.toString().trim() ?? '';
    Uint8List? pickedIconBytes;
    var isUploadingImage = false;
    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickAndUploadImage() async {
              if (isUploadingImage) return;
              final picker = ImagePicker();
              final file = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1800,
                imageQuality: 88,
              );
              if (file == null) return;

              final bytes = await file.readAsBytes();
              if (!mounted) return;
              setModalState(() {
                pickedIconBytes = bytes;
                isUploadingImage = true;
              });

              try {
                final uploaded = await MediaUploadService.uploadImage(
                  scope: MediaUploadScope.provider,
                  ownerId: profile.userId,
                  fileName: file.name,
                  mimeType: file.mimeType,
                  bytes: bytes,
                );
                if (!mounted) return;
                setModalState(() {
                  uploadedIconUrl = uploaded.url;
                });
              } catch (error) {
                if (!mounted || !sheetContext.mounted) return;
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(ApiClient.userFacingError(error))),
                );
              } finally {
                if (mounted) {
                  setModalState(() => isUploadingImage = false);
                }
              }
            }

            Future<void> submit() async {
              if (isSubmitting || isUploadingImage) return;
              final name = nameController.text.trim();
              final unit = unitController.text.trim();
              final price = double.tryParse(priceController.text.trim());
              if (name.length < 2) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(l10n.laundryServiceNameMustBeValid)),
                );
                return;
              }
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(l10n.priceMustBeGreaterThanZero)),
                );
                return;
              }
              if (unit.length < 2) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(l10n.unitMustBeAtLeast2Chars)),
                );
                return;
              }

              final rawCatalogLines = itemCatalogController.text
                  .split('\n')
                  .map((entry) => entry.trim())
                  .where((entry) => entry.isNotEmpty)
                  .toList(growable: false);
              final parsedCatalog = <Map<String, dynamic>>[];
              for (final line in rawCatalogLines) {
                final parts = line
                    .split('|')
                    .map((entry) => entry.trim())
                    .toList();
                if (parts.length < 2) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(content: Text(l10n.invalidItemCatalogLine(line))),
                  );
                  return;
                }
                final label = parts[0];
                final parsedPrice = double.tryParse(parts[1]);
                final category =
                    parts.length >= 3 &&
                        parts[2].toLowerCase().trim() == 'group'
                    ? 'group'
                    : 'unit';
                final spec = parts.length >= 4
                    ? parts.sublist(3).join('|').trim()
                    : '';
                if (label.isEmpty || parsedPrice == null || parsedPrice <= 0) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(
                      content: Text(l10n.invalidItemCatalogRequired(line)),
                    ),
                  );
                  return;
                }
                if (category == 'group' && spec.isEmpty) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(content: Text(l10n.groupItemNeedsSpec(label))),
                  );
                  return;
                }
                final normalizedId = label
                    .toLowerCase()
                    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
                    .replaceAll(RegExp(r'^_+|_+$'), '');
                parsedCatalog.add({
                  'id': normalizedId.isEmpty
                      ? 'item_${parsedCatalog.length + 1}'
                      : normalizedId,
                  'label': label,
                  'price': parsedPrice,
                  'category': category,
                  if (category == 'group') 'spec': spec,
                });
              }
              if (parsedCatalog.isEmpty) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(l10n.addItemCatalogEntry)),
                );
                return;
              }

              final slots = _splitTextList(pickupSlotsController.text);
              if (slots.isEmpty) {
                ScaffoldMessenger.of(
                  sheetContext,
                ).showSnackBar(SnackBar(content: Text(l10n.addPickupSlot)));
                return;
              }

              final turnaroundHours = int.tryParse(
                turnaroundHoursController.text.trim(),
              );
              final minNoticeHours = int.tryParse(
                minNoticeHoursController.text.trim(),
              );
              final maxAdvanceDays = int.tryParse(
                maxAdvanceDaysController.text.trim(),
              );
              final taxRate = double.tryParse(taxRateController.text.trim());
              final deliveryFee = double.tryParse(
                deliveryFeeController.text.trim(),
              );

              if (turnaroundHours == null ||
                  turnaroundHours < 1 ||
                  turnaroundHours > 168) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(l10n.turnaroundHoursRange)),
                );
                return;
              }
              if (minNoticeHours == null ||
                  minNoticeHours < 0 ||
                  minNoticeHours > 72) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(l10n.minNoticeHoursBetween)),
                );
                return;
              }
              if (maxAdvanceDays == null ||
                  maxAdvanceDays < 1 ||
                  maxAdvanceDays > 30) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(l10n.maxAdvanceDaysBetween)),
                );
                return;
              }
              if (taxRate == null || taxRate < 0 || taxRate > 40) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(l10n.taxRateMustBeBetween)),
                );
                return;
              }
              if (deliveryFee == null ||
                  deliveryFee < 0 ||
                  deliveryFee > 100000) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(l10n.deliveryFeeMustBeBetween)),
                );
                return;
              }

              setModalState(() => isSubmitting = true);
              try {
                final payload = <String, dynamic>{
                  'name': name,
                  'description': descriptionController.text.trim(),
                  'price': price,
                  'unit': unit,
                  if (uploadedIconUrl.isNotEmpty) 'iconUrl': uploadedIconUrl,
                  'bookingConfig': {
                    'itemCatalog': parsedCatalog,
                    'pickupSlots': slots,
                    'turnaroundHours': turnaroundHours,
                    'minNoticeHours': minNoticeHours,
                    'maxAdvanceDays': maxAdvanceDays,
                    'taxRatePercent': taxRate,
                    'deliveryFee': deliveryFee,
                  },
                  if (isEdit) 'active': enabled,
                };
                final endpoint = isEdit
                    ? '/pro/${profile.userId}/laundry-services/$serviceId'
                    : '/pro/${profile.userId}/laundry-services';
                await ApiClient.post(endpoint, payload);
                if (!mounted || !sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEdit
                          ? l10n.laundryServiceUpdated
                          : l10n.laundryServiceCreated,
                    ),
                  ),
                );
                await _refreshInsights();
              } catch (error) {
                if (!mounted || !sheetContext.mounted) return;
                setModalState(() => isSubmitting = false);
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(ApiClient.userFacingError(error))),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                18,
                16,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit
                          ? l10n.editLaundryService
                          : l10n.createLaundryService,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: l10n.serviceName),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: l10n.description),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(labelText: l10n.price),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: unitController,
                            decoration: InputDecoration(labelText: l10n.unit),
                          ),
                        ),
                      ],
                    ),
                    if (isEdit) ...[
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.serviceEnabled),
                        value: enabled,
                        onChanged: (value) =>
                            setModalState(() => enabled = value),
                      ),
                    ],
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: itemCatalogController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        labelText: l10n.itemCatalog,
                        hintText: l10n.itemCatalogHint,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: pickupSlotsController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: l10n.pickupSlots,
                        hintText: l10n.commaOrNewlineSeparated,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: turnaroundHoursController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.turnaroundHours,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: minNoticeHoursController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.minNoticeHours,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: maxAdvanceDaysController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.maxAdvanceDays,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: taxRateController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.taxRate,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: deliveryFeeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(labelText: l10n.deliveryFee),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: pickedIconBytes != null
                          ? Image.memory(pickedIconBytes!, fit: BoxFit.cover)
                          : (uploadedIconUrl.isNotEmpty
                                ? Image.network(
                                    uploadedIconUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                              child: Icon(
                                                Icons.local_laundry_service,
                                                size: 34,
                                              ),
                                            ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.local_laundry_service,
                                      size: 34,
                                    ),
                                  )),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: isUploadingImage ? null : pickAndUploadImage,
                      icon: isUploadingImage
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_outlined),
                      label: Text(
                        isUploadingImage
                            ? l10n.uploadingImage
                            : l10n.uploadServiceImage,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isSubmitting || isUploadingImage
                            ? null
                            : submit,
                        icon: isSubmitting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          isSubmitting
                              ? l10n.saving
                              : isEdit
                              ? l10n.saveLaundryService
                              : l10n.createLaundryService,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    unitController.dispose();
    itemCatalogController.dispose();
    pickupSlotsController.dispose();
    turnaroundHoursController.dispose();
    minNoticeHoursController.dispose();
    maxAdvanceDaysController.dispose();
    taxRateController.dispose();
    deliveryFeeController.dispose();
  }

  Future<void> _openDoctorSettingsEditor(Map<String, dynamic> item) async {
    final l10n = AppLocalizations.of(context)!;
    final profile =
        context.read<ProAuthProvider>().currentProfile ?? widget.profile;
    if (profile.type != ProProfileType.doctor) return;
    final doctorId = item['id']?.toString() ?? '';
    if (doctorId.isEmpty) return;

    final locationController = TextEditingController(
      text: item['location']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: item['contactPhone']?.toString() ?? '',
    );
    final whatsappController = TextEditingController(
      text: item['contactWhatsApp']?.toString() ?? '',
    );
    final careModesController = TextEditingController(
      text: (item['careModes'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .where((entry) => entry.trim().isNotEmpty)
          .join('\n'),
    );
    final hours = Map<String, dynamic>.from(
      (item['workingHours'] as Map?) ?? const <String, dynamic>{},
    );
    final weekdaysController = TextEditingController(
      text: hours['weekdays']?.toString() ?? '09:00 AM - 05:00 PM',
    );
    final saturdayController = TextEditingController(
      text: hours['saturday']?.toString() ?? '10:00 AM - 02:00 PM',
    );
    final sundayController = TextEditingController(
      text: hours['sunday']?.toString() ?? 'Closed',
    );
    var uploadedImageUrl = item['imageUrl']?.toString().trim() ?? '';
    Uint8List? pickedImageBytes;
    var isUploadingImage = false;
    var isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickAndUploadImage() async {
              if (isUploadingImage) return;
              final picker = ImagePicker();
              final file = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1800,
                imageQuality: 88,
              );
              if (file == null) return;

              final bytes = await file.readAsBytes();
              if (!mounted) return;
              setModalState(() {
                pickedImageBytes = bytes;
                isUploadingImage = true;
              });

              try {
                final uploaded = await MediaUploadService.uploadImage(
                  scope: MediaUploadScope.doctor,
                  ownerId: profile.userId,
                  fileName: file.name,
                  mimeType: file.mimeType,
                  bytes: bytes,
                );
                if (!mounted) return;
                setModalState(() {
                  uploadedImageUrl = uploaded.url;
                });
              } catch (error) {
                if (!mounted || !sheetContext.mounted) return;
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(ApiClient.userFacingError(error))),
                );
              } finally {
                if (mounted) {
                  setModalState(() => isUploadingImage = false);
                }
              }
            }

            Future<void> submit() async {
              if (isSubmitting || isUploadingImage) return;

              setModalState(() => isSubmitting = true);
              try {
                await ApiClient.post('/pro/${profile.userId}/doctor-settings', {
                  'doctorId': doctorId,
                  'location': locationController.text.trim(),
                  'contactPhone': phoneController.text.trim(),
                  'contactWhatsApp': whatsappController.text.trim(),
                  'imageUrl': uploadedImageUrl,
                  'careModes': _splitTextList(careModesController.text),
                  'workingHours': {
                    'weekdays': weekdaysController.text.trim(),
                    'saturday': saturdayController.text.trim(),
                    'sunday': sundayController.text.trim(),
                  },
                });
                if (!mounted || !sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(l10n.doctorProfileUpdated)),
                );
                await _refreshInsights();
              } catch (error) {
                if (!mounted || !sheetContext.mounted) return;
                setModalState(() => isSubmitting = false);
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(ApiClient.userFacingError(error))),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                18,
                16,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.editDoctorProfile,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: l10n.clinicOrServiceArea,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(labelText: l10n.phone),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: whatsappController,
                      decoration: InputDecoration(labelText: l10n.whatsapp),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: careModesController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: l10n.careModesLabel,
                        hintText: l10n.commaOrNewlineSeparated,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: weekdaysController,
                      decoration: InputDecoration(
                        labelText: l10n.weekdaysHoursLabel,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: saturdayController,
                      decoration: InputDecoration(
                        labelText: l10n.saturdayHoursLabel,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: sundayController,
                      decoration: InputDecoration(
                        labelText: l10n.sundayHoursLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: pickedImageBytes != null
                          ? Image.memory(pickedImageBytes!, fit: BoxFit.cover)
                          : (uploadedImageUrl.isNotEmpty
                                ? Image.network(
                                    uploadedImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                              child: Icon(
                                                Icons.medical_services_outlined,
                                                size: 34,
                                              ),
                                            ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.medical_services_outlined,
                                      size: 34,
                                    ),
                                  )),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: isUploadingImage ? null : pickAndUploadImage,
                      icon: isUploadingImage
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library_outlined),
                      label: Text(
                        isUploadingImage
                            ? l10n.uploadingImage
                            : l10n.uploadDoctorImage,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isSubmitting || isUploadingImage
                            ? null
                            : submit,
                        icon: isSubmitting
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          isSubmitting ? l10n.saving : l10n.saveDoctorProfile,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    locationController.dispose();
    phoneController.dispose();
    whatsappController.dispose();
    careModesController.dispose();
    weekdaysController.dispose();
    saturdayController.dispose();
    sundayController.dispose();
  }

  Future<_ProfileInsights> _loadInsights() async {
    final profile =
        context.read<ProAuthProvider>().currentProfile ?? widget.profile;
    final userId = profile.userId;

    try {
      switch (profile.type) {
        case ProProfileType.shop:
          final shoppingModuleEnabled = profile.activeModules.contains(
            ProModule.shopping,
          );
          final pharmacyModuleEnabled = profile.activeModules.contains(
            ProModule.pharmacy,
          );

          final shoppingData = shoppingModuleEnabled
              ? await ApiClient.get(
                      '/pro/$userId/shopping-products?module=shopping',
                      forceRefresh: true,
                    )
                    as Map
              : const <String, dynamic>{};
          final pharmacyData = pharmacyModuleEnabled
              ? await ApiClient.get(
                      '/pro/$userId/shopping-products?module=pharmacy',
                      forceRefresh: true,
                    )
                    as Map
              : const <String, dynamic>{};

          final stores =
              (shoppingData['stores'] as List<dynamic>? ?? const []).length;
          final products =
              (shoppingData['products'] as List<dynamic>? ?? const []).length;
          final pharmacyBusinesses =
              (pharmacyData['stores'] as List<dynamic>? ?? const []).length;
          final medicines =
              (pharmacyData['products'] as List<dynamic>? ?? const []).length;

          return _ProfileInsights(
            title: l10n.storefrontSnapshot,
            subtitle: l10n.storefrontSnapshotSubtitle,
            metrics: [
              _ProfileMetric(label: l10n.stores, value: '$stores'),
              _ProfileMetric(label: l10n.products, value: '$products'),
              _ProfileMetric(
                label: l10n.pharmacyBusinesses,
                value: '$pharmacyBusinesses',
              ),
              _ProfileMetric(label: l10n.medicines, value: '$medicines'),
            ],
          );
        case ProProfileType.provider:
          final availability = Map<String, dynamic>.from(
            await ApiClient.get(
                  '/pro/$userId/provider-availability',
                  forceRefresh: true,
                )
                as Map,
          );
          final providerSettings =
              (await ApiClient.get(
                        '/pro/$userId/provider-settings',
                        forceRefresh: true,
                      )
                      as List<dynamic>)
                  .map((entry) => Map<String, dynamic>.from(entry as Map))
                  .toList(growable: false);

          final serviceListings =
              (availability['services'] as List<dynamic>? ?? const []).length;
          final laundryListings =
              (availability['laundry'] as List<dynamic>? ?? const []).length;
          final withLocation = providerSettings
              .where(
                (entry) =>
                    (entry['location']?.toString().trim() ?? '').isNotEmpty,
              )
              .length;

          return _ProfileInsights(
            title: l10n.providerSnapshot,
            subtitle: l10n.providerSnapshotSubtitle,
            metrics: [
              _ProfileMetric(
                label: l10n.serviceListings,
                value: '$serviceListings',
              ),
              _ProfileMetric(
                label: l10n.laundryListings,
                value: '$laundryListings',
              ),
              _ProfileMetric(
                label: l10n.listingsWithLocation,
                value: '$withLocation',
              ),
              _ProfileMetric(
                label: l10n.enabledModules,
                value: '${profile.activeModules.length}',
              ),
            ],
          );
        case ProProfileType.doctor:
          final settings =
              (await ApiClient.get(
                        '/pro/$userId/doctor-settings',
                        forceRefresh: true,
                      )
                      as List<dynamic>)
                  .map((entry) => Map<String, dynamic>.from(entry as Map))
                  .toList(growable: false);
          final availability =
              (await ApiClient.get(
                        '/pro/$userId/doctor-availability',
                        forceRefresh: true,
                      )
                      as List<dynamic>)
                  .map((entry) => Map<String, dynamic>.from(entry as Map))
                  .toList(growable: false);

          final availableDoctors = availability
              .where((entry) => entry['enabled'] == true)
              .length;
          final withLocation = settings
              .where(
                (entry) =>
                    (entry['location']?.toString().trim() ?? '').isNotEmpty,
              )
              .length;

          return _ProfileInsights(
            title: l10n.doctorSnapshot,
            subtitle: l10n.doctorSnapshotSubtitle,
            metrics: [
              _ProfileMetric(label: l10n.doctors, value: '${settings.length}'),
              _ProfileMetric(
                label: l10n.availableNow,
                value: '$availableDoctors',
              ),
              _ProfileMetric(
                label: l10n.profilesWithLocation,
                value: '$withLocation',
              ),
              _ProfileMetric(
                label: l10n.careModes,
                value: '${_countDoctorModes(settings)}',
              ),
            ],
          );
        case ProProfileType.delivery:
          return _ProfileInsights(
            title: l10n.dispatchSnapshot,
            subtitle: l10n.dispatchSnapshotSubtitle,
            metrics: [
              _ProfileMetric(
                label: l10n.online,
                value: profile.isOnline ? l10n.yes : l10n.no,
              ),
              _ProfileMetric(
                label: l10n.deliveryModules,
                value: '${profile.activeModules.length}',
              ),
              _ProfileMetric(
                label: l10n.businessNameLength,
                value: '${profile.businessName.trim().length}',
              ),
            ],
          );
        case ProProfileType.rider:
          return _ProfileInsights(
            title: l10n.riderSnapshot,
            subtitle: l10n.riderSnapshotSubtitle,
            metrics: [
              _ProfileMetric(
                label: l10n.online,
                value: profile.isOnline ? l10n.yes : l10n.no,
              ),
              _ProfileMetric(
                label: l10n.rideModules,
                value: '${profile.activeModules.length}',
              ),
              _ProfileMetric(
                label: l10n.businessNameLength,
                value: '${profile.businessName.trim().length}',
              ),
            ],
          );
      }
    } catch (error) {
      return _ProfileInsights(
        title: l10n.profileSnapshot,
        subtitle: l10n.couldNotLoadLiveProfileInsights,
        metrics: [
          _ProfileMetric(
            label: l10n.status,
            value: l10n.temporarilyUnavailable,
          ),
        ],
      );
    }
  }

  int _countDoctorModes(List<Map<String, dynamic>> settings) {
    final modes = <String>{};
    for (final item in settings) {
      final careModes = item['careModes'] as List<dynamic>? ?? const [];
      for (final mode in careModes) {
        final value = mode.toString().trim();
        if (value.isNotEmpty) {
          modes.add(value);
        }
      }
    }
    return modes.length;
  }

  // _actionsForProfile method removed as its UI has been eliminated.

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentProfile =
        context.watch<ProAuthProvider>().currentProfile ?? widget.profile;
    final profileColor = ProModuleHelper.getProfileColor(currentProfile.type);
    if (currentProfile.type == ProProfileType.shop &&
        _shopProfileFuture == null) {
      _shopProfileFuture = _loadShopProfileDetails();
    }
    if (currentProfile.type == ProProfileType.provider &&
        _providerSettingsFuture == null) {
      _providerSettingsFuture = _loadProviderSettings();
    }
    if (currentProfile.type == ProProfileType.provider &&
        _providerAvailabilityFuture == null) {
      _providerAvailabilityFuture = _loadProviderAvailability();
    }
    if (currentProfile.type == ProProfileType.doctor &&
        _doctorSettingsFuture == null) {
      _doctorSettingsFuture = _loadDoctorSettings();
    }
    if (currentProfile.type == ProProfileType.delivery &&
        _deliveryQueueFuture == null) {
      _deliveryQueueFuture = _loadDeliveryQueue();
    }
    if (currentProfile.type == ProProfileType.rider &&
        _rideQueueFuture == null) {
      _rideQueueFuture = _loadRideQueue();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileManagement),
        backgroundColor: profileColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshInsights,
        child: ListView(
          padding: const EdgeInsets.all(ProDesignSystem.spacing16),
          children: [
            ModernCard(
              backgroundColor: Colors.white,
              child: Text(
                l10n.manageProProfileIdentity,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: ProDesignSystem.spacing16),
            _ProfileIdentityCard(
              profile: currentProfile,
              profileColor: profileColor,
              businessNameController: _businessNameController,
              selectedModules: _selectedModules,
              allowedModules: _allowedModules,
              isSavingProfile: _isSavingProfile,
              isUploadingAvatar: _isUploadingAvatar,
              pickedAvatarBytes: _pickedAvatarBytes,
              displayAvatarUrl: _latestAvatarUrl?.trim().isNotEmpty == true
                  ? _latestAvatarUrl
                  : currentProfile.avatarUrl,
              onUploadAvatar: _pickAndUploadAvatar,
              // Module toggling disabled – modules are immutable after signup.
              onSave: _saveProfile,
            ),
            if (currentProfile.type == ProProfileType.shop) ...[
              const SizedBox(height: ProDesignSystem.spacing16),
              ModernHeader(title: l10n.shopProfileDetails),
              FutureBuilder<_ShopProfileDetails>(
                future: _shopProfileFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const ModernCard(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(ProDesignSystem.spacing16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.couldNotLoadShopProfileDetails,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: ProDesignSystem.spacing12),
                          OutlinedButton.icon(
                            onPressed: _refreshInsights,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  }

                  final details = snapshot.data;
                  if (details == null) {
                    return const SizedBox.shrink();
                  }

                  final store = _primaryShoppingStoreFromData(
                    details.storefrontData,
                  );
                  final restaurant = _primaryRestaurantFromData(
                    details.storefrontData,
                  );
                  final storeName =
                      store?['name']?.toString() ?? l10n.notConnected;
                  final restaurantName =
                      restaurant?['name']?.toString() ?? l10n.notConnected;
                  final restaurantCuisine =
                      restaurant?['subtitle']?.toString() ??
                      restaurant?['cuisine']?.toString() ??
                      '';
                  final pharmacyName = details.pharmacyBusinesses.isNotEmpty
                      ? details.pharmacyBusinesses.first
                      : l10n.notConnected;

                  return Column(
                    children: [
                      _InlineProfileEditorCard(
                        icon: Icons.store_mall_directory_outlined,
                        title: l10n.shoppingStoreProfile,
                        value: storeName,
                        subtitle: l10n.editStoreNameTaglineDescription,
                        onTap: () => _openShoppingStoreSetupEditor(store),
                      ),
                      const SizedBox(height: ProDesignSystem.spacing12),
                      _InlineProfileEditorCard(
                        icon: Icons.restaurant_menu_outlined,
                        title: l10n.restaurantProfile,
                        value: restaurantName,
                        subtitle: restaurantCuisine.isNotEmpty
                            ? l10n.cuisinePrefix(restaurantCuisine)
                            : l10n.editRestaurantNameCuisineImage,
                        onTap: () => _openRestaurantEditor(restaurant),
                      ),
                      const SizedBox(height: ProDesignSystem.spacing12),
                      _InlineProfileEditorCard(
                        icon: Icons.local_pharmacy_outlined,
                        title: l10n.pharmacyProfile,
                        value: pharmacyName,
                        subtitle: details.pharmacyBusinesses.length > 1
                            ? l10n.pharmacyBusinessesConnected(
                                details.pharmacyBusinesses.length,
                              )
                            : l10n.editPharmacyBusinessName,
                        onTap: () => _openPharmacyEditor(
                          businesses: details.pharmacyBusinesses,
                          suggestedName: currentProfile.businessName,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
            if (currentProfile.type == ProProfileType.provider) ...[
              const SizedBox(height: ProDesignSystem.spacing16),
              ModernHeader(title: l10n.providerProfileDetails),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _providerSettingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const ModernCard(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(ProDesignSystem.spacing16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.couldNotLoadProviderProfileDetails,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: ProDesignSystem.spacing12),
                          OutlinedButton.icon(
                            onPressed: _refreshInsights,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  }

                  final items = snapshot.data ?? const <Map<String, dynamic>>[];
                  final supportsServices = currentProfile.activeModules
                      .contains(ProModule.services);
                  if (items.isEmpty) {
                    return ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supportsServices
                                ? l10n.noProviderListingLinkedYet
                                : l10n.enableServicesModuleToCreateOne,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: ProDesignSystem.spacing12),
                          FilledButton.icon(
                            onPressed: supportsServices
                                ? _openProviderCreateEditor
                                : null,
                            icon: const Icon(Icons.add_business_outlined),
                            label: Text(l10n.createProviderListing),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      ...items.map((item) {
                        final name =
                            item['name']?.toString().trim().isNotEmpty == true
                            ? item['name'].toString()
                            : l10n.providerListing;
                        final title =
                            item['title']?.toString().trim().isNotEmpty == true
                            ? item['title'].toString()
                            : l10n.providerProfile;
                        final servicesCount =
                            (item['services'] as List<dynamic>? ?? const [])
                                .length;
                        final location =
                            item['location']?.toString().trim() ?? '';
                        final responseTime =
                            item['responseTime']?.toString().trim() ?? '';
                        final detailParts = <String>[
                          if (location.isNotEmpty) location,
                          if (responseTime.isNotEmpty) responseTime,
                          l10n.servicesCount(servicesCount),
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: ProDesignSystem.spacing12,
                          ),
                          child: _InlineProfileEditorCard(
                            icon: Icons.home_repair_service_outlined,
                            title: name,
                            value: title,
                            subtitle: detailParts.join(' • '),
                            onTap: () => _openProviderSettingsEditor(item),
                          ),
                        );
                      }),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: supportsServices
                              ? _openProviderCreateEditor
                              : null,
                          icon: const Icon(Icons.add_business_outlined),
                          label: Text(l10n.addProviderListing),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: ProDesignSystem.spacing16),
              ModernHeader(title: l10n.laundryProfileDetails),
              FutureBuilder<Map<String, dynamic>>(
                future: _providerAvailabilityFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const ModernCard(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(ProDesignSystem.spacing16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.couldNotLoadLaundryProfileDetails,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: ProDesignSystem.spacing12),
                          OutlinedButton.icon(
                            onPressed: _refreshInsights,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  }

                  final data = snapshot.data ?? const <String, dynamic>{};
                  final supportsLaundry = currentProfile.activeModules.contains(
                    ProModule.laundry,
                  );
                  final laundry =
                      (data['laundry'] as List<dynamic>? ?? const [])
                          .map(
                            (entry) => Map<String, dynamic>.from(entry as Map),
                          )
                          .toList(growable: false);

                  if (laundry.isEmpty) {
                    return ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            supportsLaundry
                                ? l10n.noLaundryServiceListingYet
                                : l10n.laundryModuleNotEnabled,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: ProDesignSystem.spacing12),
                          FilledButton.icon(
                            onPressed: supportsLaundry
                                ? () => _openLaundryServiceEditor()
                                : null,
                            icon: const Icon(
                              Icons.local_laundry_service_outlined,
                            ),
                            label: Text(l10n.createLaundryService),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      ...laundry.map((service) {
                        final name =
                            service['name']?.toString().trim().isNotEmpty ==
                                true
                            ? service['name'].toString()
                            : l10n.laundryService;
                        final price =
                            (service['price'] as num?)?.toDouble() ?? 0;
                        final unit = service['unit']?.toString().trim() ?? '';
                        final bookingConfig = Map<String, dynamic>.from(
                          (service['bookingConfig'] as Map?) ??
                              const <String, dynamic>{},
                        );
                        final itemCatalogCount =
                            (bookingConfig['itemCatalog'] as List<dynamic>? ??
                                    const [])
                                .length;
                        final pickupSlotsCount =
                            (bookingConfig['pickupSlots'] as List<dynamic>? ??
                                    const [])
                                .length;
                        final detailParts = <String>[
                          '\$${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)} ${unit.isNotEmpty ? '/ $unit' : ''}',
                          l10n.itemsCount(itemCatalogCount),
                          l10n.slotsCount(pickupSlotsCount),
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: ProDesignSystem.spacing12,
                          ),
                          child: _InlineProfileEditorCard(
                            icon: Icons.local_laundry_service_outlined,
                            title: name,
                            value: service['enabled'] == true
                                ? l10n.enabled
                                : l10n.paused,
                            subtitle: detailParts.join(' • '),
                            onTap: () =>
                                _openLaundryServiceEditor(service: service),
                          ),
                        );
                      }),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: supportsLaundry
                              ? () => _openLaundryServiceEditor()
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          label: Text(l10n.addLaundryService),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
            if (currentProfile.type == ProProfileType.doctor) ...[
              const SizedBox(height: ProDesignSystem.spacing16),
              ModernHeader(title: l10n.doctorProfileDetails),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _doctorSettingsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const ModernCard(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(ProDesignSystem.spacing16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.couldNotLoadDoctorProfileDetails,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: ProDesignSystem.spacing12),
                          OutlinedButton.icon(
                            onPressed: _refreshInsights,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  }

                  final items = snapshot.data ?? const <Map<String, dynamic>>[];
                  if (items.isEmpty) {
                    return ModernCard(
                      child: Text(
                        l10n.noDoctorProfileBound,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }

                  return Column(
                    children: items
                        .map((item) {
                          final name =
                              item['name']?.toString().trim().isNotEmpty == true
                              ? item['name'].toString()
                              : l10n.moduleDoctor;
                          final specialty =
                              item['specialty']?.toString().trim().isNotEmpty ==
                                  true
                              ? item['specialty'].toString()
                              : l10n.generalPractice;
                          final location =
                              item['location']?.toString().trim() ?? '';
                          final detail = location.isNotEmpty
                              ? '$specialty • $location'
                              : specialty;
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: ProDesignSystem.spacing12,
                            ),
                            child: _InlineProfileEditorCard(
                              icon: Icons.medical_services_outlined,
                              title: name,
                              value: l10n.moduleDoctor,
                              subtitle: detail,
                              onTap: () => _openDoctorSettingsEditor(item),
                            ),
                          );
                        })
                        .toList(growable: false),
                  );
                },
              ),
            ],
            if (currentProfile.type == ProProfileType.delivery) ...[
              const SizedBox(height: ProDesignSystem.spacing16),
              ModernHeader(title: l10n.deliveryProfileDetails),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _deliveryQueueFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const ModernCard(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(ProDesignSystem.spacing16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.couldNotLoadDispatchProfileDetails,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: ProDesignSystem.spacing12),
                          OutlinedButton.icon(
                            onPressed: _refreshInsights,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  }

                  final items = snapshot.data ?? const <Map<String, dynamic>>[];
                  final openCount = items
                      .where(
                        (item) =>
                            (item['queueType']?.toString() ?? '') == 'open',
                      )
                      .length;
                  final assignedCount = items
                      .where(
                        (item) =>
                            (item['queueType']?.toString() ?? '') == 'assigned',
                      )
                      .length;
                  final lanes = items
                      .map((item) => item['module']?.toString() ?? '')
                      .where((value) => value.trim().isNotEmpty)
                      .toSet()
                      .length;

                  return Column(
                    children: [
                      ModernCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.dispatchSnapshot,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: ProDesignSystem.spacing8),
                            Wrap(
                              spacing: ProDesignSystem.spacing8,
                              runSpacing: ProDesignSystem.spacing8,
                              children: [
                                _MetricPill(
                                  label: l10n.openRequests,
                                  value: '$openCount',
                                ),
                                _MetricPill(
                                  label: l10n.assignedLabel,
                                  value: '$assignedCount',
                                ),
                                _MetricPill(
                                  label: l10n.lanesLabel,
                                  value: '$lanes',
                                ),
                              ],
                            ),
                            const SizedBox(height: ProDesignSystem.spacing12),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  context.push(ProRoutePaths.deliveryQueue),
                              icon: const Icon(Icons.local_shipping_outlined),
                              label: Text(l10n.openDispatchQueue),
                            ),
                          ],
                        ),
                      ),
                      if (items.isNotEmpty) ...[
                        const SizedBox(height: ProDesignSystem.spacing12),
                        ...items.take(4).map((item) {
                          final orderId = item['id']?.toString() ?? '';
                          final queueType =
                              item['queueType']?.toString() ?? 'open';
                          final module = _dispatchModuleLabel(
                            item['module']?.toString() ?? '',
                            l10n,
                          );
                          final status = _queueStatusLabel(
                            item['status']?.toString(),
                            l10n,
                          );
                          final customer =
                              item['customerName']?.toString() ?? '';
                          final subtitleParts = <String>[
                            module,
                            if (customer.trim().isNotEmpty) customer,
                            status,
                          ];
                          final isBusy = _quickActionBusyIds.contains(orderId);
                          return Padding(
                            padding: const EdgeInsets.only(
                              top: ProDesignSystem.spacing12,
                            ),
                            child: ModernTile(
                              leadingIcon: Icons.local_shipping_outlined,
                              title:
                                  item['title']?.toString() ??
                                  l10n.deliveryRequest,
                              subtitle: subtitleParts.join(' • '),
                              trailing: SizedBox(
                                height: 34,
                                child: FilledButton(
                                  onPressed: isBusy
                                      ? null
                                      : () {
                                          if (queueType == 'open') {
                                            _claimDeliveryQueueItem(item);
                                          } else if (orderId.isNotEmpty) {
                                            context.push(
                                              ProRoutePaths.deliveryActive(
                                                orderId,
                                              ),
                                            );
                                          }
                                        },
                                  child: Text(
                                    isBusy
                                        ? '...'
                                        : queueType == 'open'
                                        ? l10n.claim
                                        : l10n.openLabel,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  );
                },
              ),
            ],
            if (currentProfile.type == ProProfileType.rider) ...[
              const SizedBox(height: ProDesignSystem.spacing16),
              ModernHeader(title: l10n.riderProfileDetails),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _rideQueueFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const ModernCard(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(ProDesignSystem.spacing16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return ModernCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.couldNotLoadRiderProfileDetails,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: ProDesignSystem.spacing12),
                          OutlinedButton.icon(
                            onPressed: _refreshInsights,
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(l10n.retry),
                          ),
                        ],
                      ),
                    );
                  }

                  final items = snapshot.data ?? const <Map<String, dynamic>>[];
                  final openCount = items
                      .where(
                        (item) =>
                            (item['queueType']?.toString() ?? '') == 'open',
                      )
                      .length;
                  final assignedCount = items
                      .where(
                        (item) =>
                            (item['queueType']?.toString() ?? '') == 'assigned',
                      )
                      .length;
                  final liveCount = items.where((item) {
                    final status =
                        item['status']?.toString().toUpperCase() ?? '';
                    return status != 'COMPLETED' && status != 'CANCELLED';
                  }).length;

                  return Column(
                    children: [
                      ModernCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.rideSnapshot,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: ProDesignSystem.spacing8),
                            Wrap(
                              spacing: ProDesignSystem.spacing8,
                              runSpacing: ProDesignSystem.spacing8,
                              children: [
                                _MetricPill(
                                  label: l10n.openRequests,
                                  value: '$openCount',
                                ),
                                _MetricPill(
                                  label: l10n.assignedLabel,
                                  value: '$assignedCount',
                                ),
                                _MetricPill(
                                  label: l10n.liveTrips,
                                  value: '$liveCount',
                                ),
                              ],
                            ),
                            const SizedBox(height: ProDesignSystem.spacing12),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  context.push(ProRoutePaths.riderQueue),
                              icon: const Icon(Icons.local_taxi_outlined),
                              label: Text(l10n.openRideQueue),
                            ),
                          ],
                        ),
                      ),
                      if (items.isNotEmpty) ...[
                        const SizedBox(height: ProDesignSystem.spacing12),
                        ...items.take(4).map((item) {
                          final rideId = item['id']?.toString() ?? '';
                          final queueType =
                              item['queueType']?.toString() ?? 'open';
                          final status = _queueStatusLabel(
                            item['status']?.toString(),
                            l10n,
                          );
                          final amount =
                              item['amount']?.toString().trim() ?? '';
                          final subtitle = amount.isNotEmpty
                              ? '$status • $amount'
                              : status;
                          final isBusy = _quickActionBusyIds.contains(rideId);
                          return Padding(
                            padding: const EdgeInsets.only(
                              top: ProDesignSystem.spacing12,
                            ),
                            child: ModernTile(
                              leadingIcon: Icons.local_taxi_outlined,
                              title:
                                  item['title']?.toString() ?? l10n.rideRequest,
                              subtitle: subtitle,
                              trailing: SizedBox(
                                height: 34,
                                child: FilledButton(
                                  onPressed: isBusy
                                      ? null
                                      : () {
                                          if (queueType == 'open') {
                                            _claimRideQueueItem(item);
                                          } else if (rideId.isNotEmpty) {
                                            context.push(
                                              ProRoutePaths.riderActiveTrip(
                                                rideId,
                                              ),
                                            );
                                          }
                                        },
                                  child: Text(
                                    isBusy
                                        ? '...'
                                        : queueType == 'open'
                                        ? l10n.claim
                                        : l10n.openLabel,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  );
                },
              ),
            ],
            // Profile frontend sections removed as per request
          ],
        ),
      ),
    );
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({
    required this.profile,
    required this.profileColor,
    required this.businessNameController,
    required this.selectedModules,
    required this.allowedModules,
    required this.isSavingProfile,
    required this.isUploadingAvatar,
    required this.pickedAvatarBytes,
    required this.displayAvatarUrl,
    required this.onUploadAvatar,
    // onToggleModule removed – modules are read‑only after signup
    required this.onSave,
  });

  final ProProfile profile;
  final Color profileColor;
  final TextEditingController businessNameController;
  final Set<ProModule> selectedModules;
  final List<ProModule> allowedModules;
  final bool isSavingProfile;
  final bool isUploadingAvatar;
  final Uint8List? pickedAvatarBytes;
  final String? displayAvatarUrl;
  final VoidCallback onUploadAvatar;
  // final ValueChanged<ProModule> onToggleModule; // removed
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: isUploadingAvatar ? null : onUploadAvatar,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: profileColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(
                          ProDesignSystem.radiusMedium,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: pickedAvatarBytes != null
                          ? Image.memory(pickedAvatarBytes!, fit: BoxFit.cover)
                          : ((displayAvatarUrl?.isNotEmpty ?? false)
                                ? Image.network(
                                    displayAvatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          ProModuleHelper.getProfileIcon(
                                            profile.type,
                                          ),
                                          color: profileColor,
                                          size: 28,
                                        ),
                                  )
                                : Icon(
                                    ProModuleHelper.getProfileIcon(
                                      profile.type,
                                    ),
                                    color: profileColor,
                                    size: 28,
                                  )),
                    ),
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: isUploadingAvatar
                            ? const Padding(
                                padding: EdgeInsets.all(5),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: profileColor,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ProDesignSystem.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ProModuleHelper.getProfileName(profile.type),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: ProDesignSystem.spacing4),
                    Text(
                      ProModuleHelper.getProfileDescription(profile.type),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ProDesignSystem.spacing16),
          TextField(
            controller: businessNameController,
            enabled: !isSavingProfile,
            decoration: ProDesignSystem.inputDecoration(
              label: l10n.businessName,
              hint: l10n.nameShownToCustomers,
              prefixIcon: Icons.storefront_outlined,
            ),
          ),
          const SizedBox(height: ProDesignSystem.spacing12),
          Text(
            l10n.enabledModulesLower,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: ProDesignSystem.spacing8),
          Wrap(
            spacing: ProDesignSystem.spacing8,
            runSpacing: ProDesignSystem.spacing8,
            children: allowedModules
                .map(
                  (module) => FilterChip(
                    label: Text(ProModuleHelper.getModuleName(module)),
                    selected: selectedModules.contains(module),
                    selectedColor: ProModuleHelper.getModuleColor(
                      module,
                    ).withValues(alpha: 0.18),
                    showCheckmark: true,
                    // Modules are read‑only after signup; disable toggling.
                    onSelected: null,
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: ProDesignSystem.spacing16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: isSavingProfile ? null : onSave,
              icon: isSavingProfile
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(isSavingProfile ? l10n.saving : l10n.saveProfile),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ProDesignSystem.spacing12,
        vertical: ProDesignSystem.spacing8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(ProDesignSystem.radiusCircle),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

// _ProfileAction class removed as it is no longer used.

class _ProfileMetric {
  const _ProfileMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class _ProfileInsights {
  const _ProfileInsights({
    required this.title,
    required this.subtitle,
    required this.metrics,
  });

  final String title;
  final String subtitle;
  final List<_ProfileMetric> metrics;
}

class _ShopProfileDetails {
  const _ShopProfileDetails({
    required this.storefrontData,
    required this.pharmacyBusinesses,
  });

  final Map<String, dynamic> storefrontData;
  final List<String> pharmacyBusinesses;
}

class _InlineProfileEditorCard extends StatelessWidget {
  const _InlineProfileEditorCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ModernTile(
      leadingIcon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Flexible(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }
}
