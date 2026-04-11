import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
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
          ModernCard(
            backgroundColor: profileColor,
            borderRadius: ProDesignSystem.radiusLarge,
            shadows: ProDesignSystem.shadowElevation3,
            padding: const EdgeInsets.all(ProDesignSystem.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(ProDesignSystem.spacing8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(
                          ProDesignSystem.radiusMedium,
                        ),
                      ),
                      child: Icon(
                        ProModuleHelper.getProfileIcon(currentProfile.type),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: ProDesignSystem.spacing16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentProfile.businessName,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: ProDesignSystem.spacing4),
                          Text(
                            _profileDescriptor(currentProfile),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
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
                  children: currentProfile.activeModules
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
                  currentProfile.isVerified
                      ? '✓ Verified account'
                      : '⏳ Verification pending',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: ProDesignSystem.spacing6),
                Text(
                  currentAccount == null
                      ? 'Workspace ID: ${currentProfile.id}'
                      : 'Signed in as ${currentAccount.email}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
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
