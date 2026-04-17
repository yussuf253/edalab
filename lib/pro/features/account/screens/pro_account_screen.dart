import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/media_upload_service.dart';
import '../../../core/constants/pro_design_system.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/providers/pro_auth_provider.dart';
import '../../../core/router/pro_route_paths.dart';
import '../../../core/utils/pro_module_helper.dart';

class ProAccountScreen extends StatelessWidget {
  const ProAccountScreen({super.key, required this.profile});

  final ProProfile profile;

  Future<void> _open(BuildContext context, String route) {
    return context.push(route);
  }

  String _profileDescriptor(ProProfile profile) {
    switch (profile.type) {
      case ProProfileType.shop:
        return 'Store owner workspace';
      case ProProfileType.provider:
        return 'Service operator workspace';
      case ProProfileType.doctor:
        return 'Clinical workspace';
      case ProProfileType.delivery:
        return 'Dispatch partner workspace';
      case ProProfileType.rider:
        return 'Ride partner workspace';
    }
  }

  String _managementTitle(ProProfileType type) {
    switch (type) {
      case ProProfileType.shop:
        return 'Store Management';
      case ProProfileType.provider:
        return 'Service Management';
      case ProProfileType.doctor:
        return 'Clinic Management';
      case ProProfileType.delivery:
        return 'Dispatch Management';
      case ProProfileType.rider:
        return 'Trip Management';
    }
  }

  String _moduleAccessTitle(ProProfileType type) {
    switch (type) {
      case ProProfileType.shop:
        return 'Store Lanes';
      case ProProfileType.provider:
        return 'Service Lanes';
      case ProProfileType.doctor:
        return 'Care Lanes';
      case ProProfileType.delivery:
        return 'Delivery Lanes';
      case ProProfileType.rider:
        return 'Ride Lanes';
    }
  }

  @override
  Widget build(BuildContext context) {
    final proAuth = context.watch<ProAuthProvider>();
    final currentProfile = proAuth.currentProfile ?? profile;
    final currentAccount = proAuth.currentAccount;
    final profileColor = ProModuleHelper.getProfileColor(currentProfile.type);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Account'),
        backgroundColor: profileColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(ProDesignSystem.spacing16),
        children: [
          _ProAccountHeaderCard(
            profile: currentProfile,
            profileDescriptor: _profileDescriptor(currentProfile),
            signedInAsText: currentAccount == null
                ? 'Workspace ID: ${currentProfile.id}'
                : 'Signed in as ${currentAccount.email}',
            profileColor: profileColor,
          ),
          if (currentProfile.type == ProProfileType.delivery ||
              currentProfile.type == ProProfileType.rider) ...[
            const SizedBox(height: ProDesignSystem.spacing16),
            ModernCard(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.all(ProDesignSystem.spacing12),
              child: SwitchListTile(
                value: currentProfile.isOnline,
                onChanged: (value) async {
                  try {
                    await context.read<ProAuthProvider>().updateOnlineStatus(
                      value,
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          error.toString().replaceFirst('Exception: ', ''),
                        ),
                      ),
                    );
                  }
                },
                activeThumbColor: profileColor,
                title: Text(currentProfile.isOnline ? 'Online' : 'Offline'),
                subtitle: Text(
                  currentProfile.type == ProProfileType.delivery
                      ? 'Receive dispatch work when online.'
                      : 'Receive ride requests when online.',
                ),
              ),
            ),
          ],
          const SizedBox(height: ProDesignSystem.spacing20),
          ModernHeader(title: _managementTitle(currentProfile.type)),
          const SizedBox(height: ProDesignSystem.spacing12),
          ..._buildManagementTiles(context, currentProfile),
          const SizedBox(height: ProDesignSystem.spacing20),
          ModernHeader(title: _moduleAccessTitle(currentProfile.type)),
          const SizedBox(height: ProDesignSystem.spacing12),
          ...currentProfile.activeModules.map(
            (module) => Padding(
              padding: const EdgeInsets.only(bottom: ProDesignSystem.spacing12),
              child: ModernTile(
                leadingIcon: ProModuleHelper.getModuleIcon(module),
                title: ProModuleHelper.getModuleName(module),
                subtitle: ProModuleHelper.getModuleDescription(module),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildManagementTiles(BuildContext context, ProProfile profile) {
    switch (profile.type) {
      case ProProfileType.shop:
        return [
          _AccountActionTile(
            icon: Icons.receipt_long_outlined,
            color: AppColors.shopping,
            title: 'Orders Queue',
            subtitle: 'Review incoming shopping, food, and pharmacy orders.',
            onTap: () => _open(context, ProRoutePaths.shopQueue),
          ),
          _AccountActionTile(
            icon: Icons.store_mall_directory_outlined,
            color: AppColors.shopping,
            title: 'Store Setup',
            subtitle: 'Configure storefront identity and availability.',
            onTap: () => _open(context, ProRoutePaths.shopProducts),
          ),
          _AccountActionTile(
            icon: Icons.inventory_2_outlined,
            color: AppColors.primary,
            title: 'Products Manager',
            subtitle: 'Manage products and stock across your stores.',
            onTap: () => _open(context, ProRoutePaths.shopProducts),
          ),
        ];
      case ProProfileType.provider:
        return [
          _AccountActionTile(
            icon: Icons.toggle_on_outlined,
            color: AppColors.homeServices,
            title: 'Provider Availability',
            subtitle: 'Pause or reopen service and laundry lanes.',
            onTap: () => _open(context, ProRoutePaths.providerAvailability),
          ),
          _AccountActionTile(
            icon: Icons.schedule_outlined,
            color: AppColors.warning,
            title: 'Scheduling Settings',
            subtitle: 'Update booking modes and weekly availability.',
            onTap: () => _open(context, ProRoutePaths.providerSchedule),
          ),
        ];
      case ProProfileType.doctor:
        return [
          _AccountActionTile(
            icon: Icons.local_hospital_outlined,
            color: AppColors.doctor,
            title: 'Doctor Availability',
            subtitle: 'Control who is accepting consultations right now.',
            onTap: () => _open(context, ProRoutePaths.doctorAvailability),
          ),
          _AccountActionTile(
            icon: Icons.schedule_outlined,
            color: AppColors.warning,
            title: 'Schedule Settings',
            subtitle: 'Update working hours and care modes.',
            onTap: () => _open(context, ProRoutePaths.doctorSchedule),
          ),
        ];
      case ProProfileType.delivery:
        return [
          _AccountActionTile(
            icon: Icons.local_shipping_outlined,
            color: AppColors.food,
            title: 'Dispatch Queue',
            subtitle: 'Open delivery dispatch and claim jobs.',
            onTap: () => _open(context, ProRoutePaths.deliveryQueue),
          ),
        ];
      case ProProfileType.rider:
        return [
          _AccountActionTile(
            icon: Icons.local_taxi_outlined,
            color: AppColors.ride,
            title: 'Ride Queue',
            subtitle: 'Open trip requests and assigned rides.',
            onTap: () => _open(context, ProRoutePaths.riderQueue),
          ),
        ];
    }
  }
}

class _ProAccountHeaderCard extends StatefulWidget {
  const _ProAccountHeaderCard({
    required this.profile,
    required this.profileDescriptor,
    required this.signedInAsText,
    required this.profileColor,
  });

  final ProProfile profile;
  final String profileDescriptor;
  final String signedInAsText;
  final Color profileColor;

  @override
  State<_ProAccountHeaderCard> createState() => _ProAccountHeaderCardState();
}

class _ProAccountHeaderCardState extends State<_ProAccountHeaderCard> {
  Uint8List? _pickedAvatarBytes;
  bool _isUploadingAvatar = false;
  String? _latestAvatarUrl;

  String? get _displayAvatarUrl => _latestAvatarUrl?.trim().isNotEmpty == true
      ? _latestAvatarUrl
      : widget.profile.avatarUrl;

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

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      backgroundColor: widget.profileColor,
      borderRadius: ProDesignSystem.radiusLarge,
      shadows: ProDesignSystem.shadowElevation3,
      padding: const EdgeInsets.all(ProDesignSystem.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(
                          ProDesignSystem.radiusMedium,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _pickedAvatarBytes != null
                          ? Image.memory(_pickedAvatarBytes!, fit: BoxFit.cover)
                          : ((_displayAvatarUrl?.isNotEmpty ?? false)
                                ? Image.network(
                                    _displayAvatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      ProModuleHelper.getProfileIcon(
                                        widget.profile.type,
                                      ),
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  )
                                : Icon(
                                    ProModuleHelper.getProfileIcon(
                                      widget.profile.type,
                                    ),
                                    color: Colors.white,
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
                        ),
                        child: _isUploadingAvatar
                            ? const Padding(
                                padding: EdgeInsets.all(4),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: widget.profileColor,
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
                      widget.profile.businessName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: ProDesignSystem.spacing4),
                    Text(
                      widget.profileDescriptor,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ProDesignSystem.spacing16),
          Wrap(
            spacing: ProDesignSystem.spacing8,
            runSpacing: ProDesignSystem.spacing8,
            children: widget.profile.activeModules
                .map(
                  (module) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ProDesignSystem.spacing12,
                      vertical: ProDesignSystem.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(
                        ProDesignSystem.radiusCircle,
                      ),
                    ),
                    child: Text(
                      ProModuleHelper.getModuleName(module),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: ProDesignSystem.spacing16),
          Text(
            widget.profile.isVerified
                ? '✓ Verified account'
                : '⏳ Verification pending',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: ProDesignSystem.spacing6),
          Text(
            widget.signedInAsText,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  const _AccountActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ProDesignSystem.spacing12),
      child: ModernTile(
        leadingIcon: icon,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}
