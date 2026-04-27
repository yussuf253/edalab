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

class ProProfileManagementScreen extends StatefulWidget {
  const ProProfileManagementScreen({super.key, required this.profile});

  final ProProfile profile;

  @override
  State<ProProfileManagementScreen> createState() =>
      _ProProfileManagementScreenState();
}

class _ProProfileManagementScreenState
    extends State<ProProfileManagementScreen> {
  late final TextEditingController _businessNameController;
  late Set<ProModule> _selectedModules;
  bool _isSavingProfile = false;
  bool _isUploadingAvatar = false;
  Uint8List? _pickedAvatarBytes;
  String? _latestAvatarUrl;
  late Future<_ProfileInsights> _insightsFuture;
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
    _insightsFuture = _loadInsights();
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
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated.')));
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

    final businessName = _businessNameController.text.trim();
    if (businessName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business name must be at least 2 characters.'),
        ),
      );
      return;
    }

    if (_selectedModules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enable at least one module.')),
      );
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
        _insightsFuture = _loadInsights();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile settings updated.')),
      );
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
      _insightsFuture = future;
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
                  const SnackBar(
                    content: Text('Enter a valid restaurant name first.'),
                  ),
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
                          ? 'Restaurant connected to your profile.'
                          : 'Restaurant details updated.',
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
                          ? 'Connect Restaurant'
                          : 'Edit Restaurant',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Restaurant name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cuisineController,
                      decoration: const InputDecoration(
                        labelText: 'Cuisine',
                        hintText: 'e.g. Djiboutian, Mixed, Seafood',
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
                            ? 'Uploading image...'
                            : 'Upload Restaurant Image',
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
                              ? 'Saving...'
                              : existingRestaurant == null
                              ? 'Connect Restaurant'
                              : 'Save Restaurant',
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
            Future<void> submit() async {
              if (isSubmitting) return;
              if (nameController.text.trim().length < 2) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid pharmacy business name.'),
                  ),
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
                  const SnackBar(content: Text('Pharmacy business connected.')),
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
                        ? 'Connect Pharmacy Business'
                        : 'Update Pharmacy Business',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Pharmacy business name',
                    ),
                  ),
                  if (businesses.length > 1) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Connected businesses: ${businesses.join(', ')}',
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
                            ? 'Saving...'
                            : businesses.isEmpty
                            ? 'Connect Pharmacy'
                            : 'Save Pharmacy',
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

  String _queueStatusLabel(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Unknown';
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

  String _dispatchModuleLabel(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'shopping':
        return 'Shopping';
      case 'food':
        return 'Food';
      case 'pharmacy':
        return 'Pharmacy';
      default:
        return 'Delivery';
    }
  }

  Future<void> _claimDeliveryQueueItem(Map<String, dynamic> item) async {
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
        _insightsFuture = _loadInsights();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery request claimed.')),
      );
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
        _insightsFuture = _loadInsights();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ride request claimed.')));
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
    final profile =
        context.read<ProAuthProvider>().currentProfile ?? widget.profile;
    if (profile.type != ProProfileType.provider) return;
    if (!profile.activeModules.contains(ProModule.services)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enable Services module first to create a provider listing.',
          ),
        ),
      );
      return;
    }

    final nameController = TextEditingController(text: profile.businessName);
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final phoneController = TextEditingController();
    final responseTimeController = TextEditingController();
    final yearsExperienceController = TextEditingController();
    final startingPriceController = TextEditingController();
    final aboutController = TextEditingController();
    final servicesController = TextEditingController();
    var uploadedImageUrl = '';
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
                  scope: MediaUploadScope.provider,
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
                  const SnackBar(
                    content: Text('Enter a valid provider name first.'),
                  ),
                );
                return;
              }

              final startingPrice = double.tryParse(
                startingPriceController.text.trim(),
              );
              if (startingPriceController.text.trim().isNotEmpty &&
                  (startingPrice == null || startingPrice <= 0)) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Starting price must be a number greater than zero.',
                    ),
                  ),
                );
                return;
              }

              setModalState(() => isSubmitting = true);
              try {
                final payload = <String, dynamic>{
                  'name': nameController.text.trim(),
                  if (titleController.text.trim().isNotEmpty)
                    'title': titleController.text.trim(),
                  if (locationController.text.trim().isNotEmpty)
                    'location': locationController.text.trim(),
                  if (phoneController.text.trim().isNotEmpty)
                    'contactPhone': phoneController.text.trim(),
                  if (responseTimeController.text.trim().isNotEmpty)
                    'responseTime': responseTimeController.text.trim(),
                  if (yearsExperienceController.text.trim().isNotEmpty)
                    'yearsExperience': yearsExperienceController.text.trim(),
                  if (aboutController.text.trim().isNotEmpty)
                    'about': aboutController.text.trim(),
                  if (servicesController.text.trim().isNotEmpty)
                    'services': _splitTextList(servicesController.text),
                  if (uploadedImageUrl.trim().isNotEmpty)
                    'imageUrl': uploadedImageUrl,
                  ...?startingPrice == null
                      ? null
                      : <String, dynamic>{'startingPrice': startingPrice},
                };
                final response = Map<String, dynamic>.from(
                  await ApiClient.post(
                        '/pro/${profile.userId}/home-service-provider',
                        payload,
                      )
                      as Map,
                );
                if (!mounted || !sheetContext.mounted) return;
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      (response['created'] as bool? ?? false)
                          ? 'Provider listing created.'
                          : 'Provider listing updated.',
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
                      'Create Provider Listing',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location / service area',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: responseTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Response time',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: yearsExperienceController,
                      decoration: const InputDecoration(
                        labelText: 'Years experience',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: startingPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Starting price',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: servicesController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Services',
                        hintText: 'Comma or newline separated',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: aboutController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'About',
                        hintText: 'Public description for customers',
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
                                                Icons.home_repair_service,
                                                size: 34,
                                              ),
                                            ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.home_repair_service,
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
                            ? 'Uploading image...'
                            : 'Upload Provider Image',
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
                              ? 'Saving...'
                              : 'Create Provider Listing',
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
    titleController.dispose();
    locationController.dispose();
    phoneController.dispose();
    responseTimeController.dispose();
    yearsExperienceController.dispose();
    startingPriceController.dispose();
    aboutController.dispose();
    servicesController.dispose();
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
            Future<void> submit() async {
              if (isSubmitting) return;
              final services = _splitTextList(servicesController.text);
              if (services.isEmpty) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('Add at least one service to continue.'),
                  ),
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
                  const SnackBar(content: Text('Provider settings updated.')),
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
                      'Edit Provider Profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location / service area',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: responseTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Response time',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: servicesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Services',
                        hintText: 'Comma or newline separated',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: bookingModesController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Booking modes',
                        hintText: 'e.g. Home Visit, Scheduled Slot',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: weekdaysController,
                      decoration: const InputDecoration(
                        labelText: 'Weekdays hours',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: saturdayController,
                      decoration: const InputDecoration(
                        labelText: 'Saturday hours',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: sundayController,
                      decoration: const InputDecoration(
                        labelText: 'Sunday hours',
                      ),
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
                          isSubmitting ? 'Saving...' : 'Save Provider Settings',
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
    final profile =
        context.read<ProAuthProvider>().currentProfile ?? widget.profile;
    if (profile.type != ProProfileType.provider) return;

    final supportsLaundry = profile.activeModules.contains(ProModule.laundry);
    final serviceId = service?['id']?.toString() ?? '';
    final isEdit = serviceId.isNotEmpty;
    if (!supportsLaundry && !isEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable Laundry module first to create a listing.'),
        ),
      );
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
          : 'Wash & Fold',
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
          : 'kg',
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
                  const SnackBar(
                    content: Text('Laundry service name must be valid.'),
                  ),
                );
                return;
              }
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('Price must be greater than zero.'),
                  ),
                );
                return;
              }
              if (unit.length < 2) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('Unit must be at least 2 characters.'),
                  ),
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
                    SnackBar(
                      content: Text(
                        'Invalid item catalog line: "$line". Use label|price|category|spec.',
                      ),
                    ),
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
                      content: Text(
                        'Invalid item catalog line: "$line". Label and price are required.',
                      ),
                    ),
                  );
                  return;
                }
                if (category == 'group' && spec.isEmpty) {
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Group item "$label" needs a spec (4th value).',
                      ),
                    ),
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
                  const SnackBar(
                    content: Text('Add at least one item catalog entry.'),
                  ),
                );
                return;
              }

              final slots = _splitTextList(pickupSlotsController.text);
              if (slots.isEmpty) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('Add at least one pickup slot.'),
                  ),
                );
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
                  const SnackBar(
                    content: Text(
                      'Turnaround hours must be between 1 and 168.',
                    ),
                  ),
                );
                return;
              }
              if (minNoticeHours == null ||
                  minNoticeHours < 0 ||
                  minNoticeHours > 72) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('Min notice hours must be between 0 and 72.'),
                  ),
                );
                return;
              }
              if (maxAdvanceDays == null ||
                  maxAdvanceDays < 1 ||
                  maxAdvanceDays > 30) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('Max advance days must be between 1 and 30.'),
                  ),
                );
                return;
              }
              if (taxRate == null || taxRate < 0 || taxRate > 40) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('Tax rate must be between 0 and 40.'),
                  ),
                );
                return;
              }
              if (deliveryFee == null ||
                  deliveryFee < 0 ||
                  deliveryFee > 100000) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('Delivery fee must be between 0 and 100000.'),
                  ),
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
                          ? 'Laundry service updated.'
                          : 'Laundry service created.',
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
                          ? 'Edit Laundry Service'
                          : 'Create Laundry Service',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Service name',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
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
                            decoration: const InputDecoration(
                              labelText: 'Price',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: unitController,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isEdit) ...[
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Service enabled'),
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
                      decoration: const InputDecoration(
                        labelText: 'Item catalog',
                        hintText:
                            'One per line: label|price|category|spec\ncategory: unit or group',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: pickupSlotsController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Pickup slots',
                        hintText: 'Comma or newline separated',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: turnaroundHoursController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Turnaround (hrs)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: minNoticeHoursController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Min notice (hrs)',
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
                            decoration: const InputDecoration(
                              labelText: 'Max advance (days)',
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
                            decoration: const InputDecoration(
                              labelText: 'Tax rate (%)',
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
                      decoration: const InputDecoration(
                        labelText: 'Delivery fee',
                      ),
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
                            ? 'Uploading image...'
                            : 'Upload Service Image',
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
                              ? 'Saving...'
                              : isEdit
                              ? 'Save Laundry Service'
                              : 'Create Laundry Service',
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
                  const SnackBar(content: Text('Doctor profile updated.')),
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
                      'Edit Doctor Profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Clinic or service area',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: whatsappController,
                      decoration: const InputDecoration(labelText: 'WhatsApp'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: careModesController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Care modes',
                        hintText: 'Comma or newline separated',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: weekdaysController,
                      decoration: const InputDecoration(
                        labelText: 'Weekdays hours',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: saturdayController,
                      decoration: const InputDecoration(
                        labelText: 'Saturday hours',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: sundayController,
                      decoration: const InputDecoration(
                        labelText: 'Sunday hours',
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
                            ? 'Uploading image...'
                            : 'Upload Doctor Image',
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
                          isSubmitting ? 'Saving...' : 'Save Doctor Profile',
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
            title: 'Storefront Snapshot',
            subtitle:
                'Manage storefront profile data for shopping, food, and pharmacy lanes.',
            metrics: [
              _ProfileMetric(label: 'Stores', value: '$stores'),
              _ProfileMetric(label: 'Products', value: '$products'),
              _ProfileMetric(
                label: 'Pharmacy Businesses',
                value: '$pharmacyBusinesses',
              ),
              _ProfileMetric(label: 'Medicines', value: '$medicines'),
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
            title: 'Provider Snapshot',
            subtitle:
                'Service and laundry listings connected to this provider profile.',
            metrics: [
              _ProfileMetric(
                label: 'Service Listings',
                value: '$serviceListings',
              ),
              _ProfileMetric(
                label: 'Laundry Listings',
                value: '$laundryListings',
              ),
              _ProfileMetric(
                label: 'Listings With Location',
                value: '$withLocation',
              ),
              _ProfileMetric(
                label: 'Enabled Modules',
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
            title: 'Doctor Snapshot',
            subtitle:
                'Consultation profile details currently active for this doctor account.',
            metrics: [
              _ProfileMetric(label: 'Doctors', value: '${settings.length}'),
              _ProfileMetric(
                label: 'Available Now',
                value: '$availableDoctors',
              ),
              _ProfileMetric(
                label: 'Profiles With Location',
                value: '$withLocation',
              ),
              _ProfileMetric(
                label: 'Care Modes',
                value: '${_countDoctorModes(settings)}',
              ),
            ],
          );
        case ProProfileType.delivery:
          return _ProfileInsights(
            title: 'Dispatch Snapshot',
            subtitle: 'Manage dispatch profile operations and online status.',
            metrics: [
              _ProfileMetric(
                label: 'Online',
                value: profile.isOnline ? 'Yes' : 'No',
              ),
              _ProfileMetric(
                label: 'Delivery Modules',
                value: '${profile.activeModules.length}',
              ),
              _ProfileMetric(
                label: 'Business Name Length',
                value: '${profile.businessName.trim().length}',
              ),
            ],
          );
        case ProProfileType.rider:
          return _ProfileInsights(
            title: 'Rider Snapshot',
            subtitle: 'Manage rider profile operations and trip availability.',
            metrics: [
              _ProfileMetric(
                label: 'Online',
                value: profile.isOnline ? 'Yes' : 'No',
              ),
              _ProfileMetric(
                label: 'Ride Modules',
                value: '${profile.activeModules.length}',
              ),
              _ProfileMetric(
                label: 'Business Name Length',
                value: '${profile.businessName.trim().length}',
              ),
            ],
          );
      }
    } catch (error) {
      return _ProfileInsights(
        title: 'Profile Snapshot',
        subtitle:
            'Could not load live profile insights right now. You can still update profile settings below.',
        metrics: [
          _ProfileMetric(label: 'Status', value: 'Temporarily unavailable'),
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

  List<_ProfileAction> _actionsForProfile(ProProfile profile) {
    switch (profile.type) {
      case ProProfileType.shop:
        return [
          const _ProfileAction(
            title: 'Storefront Setup',
            subtitle: 'Manage store name, description, and storefront image.',
            route: ProRoutePaths.shopStoreSetup,
            icon: Icons.store_mall_directory_outlined,
          ),
          const _ProfileAction(
            title: 'Products & Medicines',
            subtitle: 'Manage shopping products and pharmacy medicine catalog.',
            route: ProRoutePaths.shopProducts,
            icon: Icons.inventory_2_outlined,
          ),
          const _ProfileAction(
            title: 'Orders Queue',
            subtitle: 'Monitor all incoming orders by module lane.',
            route: ProRoutePaths.shopQueue,
            icon: Icons.receipt_long_outlined,
          ),
        ];
      case ProProfileType.provider:
        return [
          const _ProfileAction(
            title: 'Service & Laundry Profiles',
            subtitle:
                'Update listing location, zone, services, and laundry setup.',
            route: ProRoutePaths.providerAvailability,
            icon: Icons.local_laundry_service_outlined,
          ),
          const _ProfileAction(
            title: 'Schedule & Booking Modes',
            subtitle: 'Manage provider schedule and booking preferences.',
            route: ProRoutePaths.providerSchedule,
            icon: Icons.schedule_outlined,
          ),
          const _ProfileAction(
            title: 'Jobs Queue',
            subtitle: 'Track active and pending provider service jobs.',
            route: ProRoutePaths.providerQueue,
            icon: Icons.work_outline,
          ),
        ];
      case ProProfileType.doctor:
        return [
          const _ProfileAction(
            title: 'Doctor Details',
            subtitle:
                'Edit doctor location, contacts, and consultation profile image.',
            route: ProRoutePaths.doctorSchedule,
            icon: Icons.medical_services_outlined,
          ),
          const _ProfileAction(
            title: 'Doctor Availability',
            subtitle: 'Control consultation readiness for each doctor profile.',
            route: ProRoutePaths.doctorAvailability,
            icon: Icons.toggle_on_outlined,
          ),
          const _ProfileAction(
            title: 'Appointments Queue',
            subtitle: 'Review appointments and home-care requests.',
            route: ProRoutePaths.doctorAppointments,
            icon: Icons.event_note_outlined,
          ),
        ];
      case ProProfileType.delivery:
        return [
          const _ProfileAction(
            title: 'Dispatch Queue',
            subtitle: 'Manage delivery assignments and dispatch operations.',
            route: ProRoutePaths.deliveryQueue,
            icon: Icons.local_shipping_outlined,
          ),
        ];
      case ProProfileType.rider:
        return [
          const _ProfileAction(
            title: 'Ride Queue',
            subtitle: 'Manage rider trip queue and active rides.',
            route: ProRoutePaths.riderQueue,
            icon: Icons.local_taxi_outlined,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Profile Management'),
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
                'Manage pro profile identity, module access, and frontend profile sections from one place.',
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
              onToggleModule: (module) {
                setState(() {
                  if (_selectedModules.contains(module)) {
                    if (_selectedModules.length == 1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'At least one module must stay enabled.',
                          ),
                        ),
                      );
                      return;
                    }
                    _selectedModules.remove(module);
                  } else {
                    _selectedModules.add(module);
                  }
                });
              },
              onSave: _saveProfile,
            ),
            const SizedBox(height: ProDesignSystem.spacing16),
            const ModernHeader(title: 'Profile Snapshot'),
            FutureBuilder<_ProfileInsights>(
              future: _insightsFuture,
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

                final insights = snapshot.data;
                if (insights == null) {
                  return ModernCard(
                    child: Text(
                      'Could not load profile insights.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                }

                return ModernCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insights.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: ProDesignSystem.spacing6),
                      Text(
                        insights.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: ProDesignSystem.spacing12),
                      Wrap(
                        spacing: ProDesignSystem.spacing8,
                        runSpacing: ProDesignSystem.spacing8,
                        children: insights.metrics
                            .map(
                              (metric) => _MetricPill(
                                label: metric.label,
                                value: metric.value,
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (currentProfile.type == ProProfileType.shop) ...[
              const SizedBox(height: ProDesignSystem.spacing16),
              const ModernHeader(title: 'Shop Profile Details'),
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
                            'Could not load shop profile details.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: ProDesignSystem.spacing12),
                          OutlinedButton.icon(
                            onPressed: _refreshInsights,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
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
                      store?['name']?.toString() ?? 'Not connected';
                  final restaurantName =
                      restaurant?['name']?.toString() ?? 'Not connected';
                  final restaurantCuisine =
                      restaurant?['subtitle']?.toString() ??
                      restaurant?['cuisine']?.toString() ??
                      '';
                  final pharmacyName = details.pharmacyBusinesses.isNotEmpty
                      ? details.pharmacyBusinesses.first
                      : 'Not connected';

                  return Column(
                    children: [
                      _InlineProfileEditorCard(
                        icon: Icons.store_mall_directory_outlined,
                        title: 'Shopping Store Profile',
                        value: storeName,
                        subtitle:
                            'Edit store name, tagline, description, and image.',
                        onTap: () => _openShoppingStoreSetupEditor(store),
                      ),
                      const SizedBox(height: ProDesignSystem.spacing12),
                      _InlineProfileEditorCard(
                        icon: Icons.restaurant_menu_outlined,
                        title: 'Restaurant Profile',
                        value: restaurantName,
                        subtitle: restaurantCuisine.isNotEmpty
                            ? 'Cuisine: $restaurantCuisine'
                            : 'Edit restaurant name, cuisine, and image.',
                        onTap: () => _openRestaurantEditor(restaurant),
                      ),
                      const SizedBox(height: ProDesignSystem.spacing12),
                      _InlineProfileEditorCard(
                        icon: Icons.local_pharmacy_outlined,
                        title: 'Pharmacy Profile',
                        value: pharmacyName,
                        subtitle: details.pharmacyBusinesses.length > 1
                            ? '${details.pharmacyBusinesses.length} businesses connected'
                            : 'Edit pharmacy business name for pharmacy listings.',
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
              const ModernHeader(title: 'Provider Profile Details'),
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
                            'Could not load provider profile details.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: ProDesignSystem.spacing12),
                          OutlinedButton.icon(
                            onPressed: _refreshInsights,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
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
                                ? 'No provider listing is linked yet.'
                                : 'No provider listing is linked yet. Enable Services module to create one.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: ProDesignSystem.spacing12),
                          FilledButton.icon(
                            onPressed: supportsServices
                                ? _openProviderCreateEditor
                                : null,
                            icon: const Icon(Icons.add_business_outlined),
                            label: const Text('Create Provider Listing'),
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
                            : 'Provider listing';
                        final title =
                            item['title']?.toString().trim().isNotEmpty == true
                            ? item['title'].toString()
                            : 'Provider profile';
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
                          '$servicesCount services',
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
                          label: const Text('Add Provider Listing'),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: ProDesignSystem.spacing16),
              const ModernHeader(title: 'Laundry Profile Details'),
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
                            'Could not load laundry profile details.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: ProDesignSystem.spacing12),
                          OutlinedButton.icon(
                            onPressed: _refreshInsights,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
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
                                ? 'No laundry service listing yet.'
                                : 'Laundry module is not enabled for this profile.',
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
                            label: const Text('Create Laundry Service'),
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
                            : 'Laundry Service';
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
                          'DJF${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)} ${unit.isNotEmpty ? '/ $unit' : ''}',
                          '$itemCatalogCount items',
                          '$pickupSlotsCount slots',
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: ProDesignSystem.spacing12,
                          ),
                          child: _InlineProfileEditorCard(
                            icon: Icons.local_laundry_service_outlined,
                            title: name,
                            value: service['enabled'] == true
                                ? 'Enabled'
                                : 'Paused',
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
                          label: const Text('Add Laundry Service'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
            if (currentProfile.type == ProProfileType.doctor) ...[
              const SizedBox(height: ProDesignSystem.spacing16),
              const ModernHeader(title: 'Doctor Profile Details'),
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
                            'Could not load doctor profile details.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: ProDesignSystem.spacing12),
                          OutlinedButton.icon(
                            onPressed: _refreshInsights,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final items = snapshot.data ?? const <Map<String, dynamic>>[];
                  if (items.isEmpty) {
                    return ModernCard(
                      child: Text(
                        'No doctor profile is currently bound to this pro account. Update the business name or use schedule tools to sync doctor binding.',
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
                              : 'Doctor';
                          final specialty =
                              item['specialty']?.toString().trim().isNotEmpty ==
                                  true
                              ? item['specialty'].toString()
                              : 'General practice';
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
                              value: 'Doctor',
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
              const ModernHeader(title: 'Delivery Profile Details'),
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
                            'Could not load dispatch profile details.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: ProDesignSystem.spacing12),
                          OutlinedButton.icon(
                            onPressed: _refreshInsights,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
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
                              'Dispatch snapshot',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: ProDesignSystem.spacing8),
                            Wrap(
                              spacing: ProDesignSystem.spacing8,
                              runSpacing: ProDesignSystem.spacing8,
                              children: [
                                _MetricPill(
                                  label: 'Open requests',
                                  value: '$openCount',
                                ),
                                _MetricPill(
                                  label: 'Assigned',
                                  value: '$assignedCount',
                                ),
                                _MetricPill(label: 'Lanes', value: '$lanes'),
                              ],
                            ),
                            const SizedBox(height: ProDesignSystem.spacing12),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  context.push(ProRoutePaths.deliveryQueue),
                              icon: const Icon(Icons.local_shipping_outlined),
                              label: const Text('Open Dispatch Queue'),
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
                          );
                          final status = _queueStatusLabel(
                            item['status']?.toString(),
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
                                  'Delivery request',
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
                                        ? 'Claim'
                                        : 'Open',
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
              const ModernHeader(title: 'Rider Profile Details'),
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
                            'Could not load rider profile details.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: ProDesignSystem.spacing12),
                          OutlinedButton.icon(
                            onPressed: _refreshInsights,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
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
                              'Ride snapshot',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: ProDesignSystem.spacing8),
                            Wrap(
                              spacing: ProDesignSystem.spacing8,
                              runSpacing: ProDesignSystem.spacing8,
                              children: [
                                _MetricPill(
                                  label: 'Open requests',
                                  value: '$openCount',
                                ),
                                _MetricPill(
                                  label: 'Assigned',
                                  value: '$assignedCount',
                                ),
                                _MetricPill(
                                  label: 'Live trips',
                                  value: '$liveCount',
                                ),
                              ],
                            ),
                            const SizedBox(height: ProDesignSystem.spacing12),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  context.push(ProRoutePaths.riderQueue),
                              icon: const Icon(Icons.local_taxi_outlined),
                              label: const Text('Open Ride Queue'),
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
                                  item['title']?.toString() ?? 'Ride request',
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
                                        ? 'Claim'
                                        : 'Open',
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
            const SizedBox(height: ProDesignSystem.spacing16),
            const ModernHeader(title: 'Profile Frontend Sections'),
            ..._actionsForProfile(currentProfile).map(
              (action) => Padding(
                padding: const EdgeInsets.only(
                  bottom: ProDesignSystem.spacing12,
                ),
                child: ModernTile(
                  leadingIcon: action.icon,
                  title: action.title,
                  subtitle: action.subtitle,
                  onTap: () => context.push(action.route),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
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
    required this.onToggleModule,
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
  final ValueChanged<ProModule> onToggleModule;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
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
              label: 'Business name',
              hint: 'Name shown to customers across enabled modules',
              prefixIcon: Icons.storefront_outlined,
            ),
          ),
          const SizedBox(height: ProDesignSystem.spacing12),
          Text(
            'Enabled modules',
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
                    onSelected: isSavingProfile
                        ? null
                        : (_) => onToggleModule(module),
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
              label: Text(isSavingProfile ? 'Saving...' : 'Save Profile'),
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

class _ProfileAction {
  const _ProfileAction({
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
}

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
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF6B7280)),
        ],
      ),
    );
  }
}
