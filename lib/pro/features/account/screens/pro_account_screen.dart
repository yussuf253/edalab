import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/providers/pro_auth_provider.dart';
import '../../../core/router/pro_route_paths.dart';
import '../../../core/utils/pro_module_helper.dart';
import '../../../core/widgets/pro_drawer.dart';

class ProAccountScreen extends StatelessWidget {
  const ProAccountScreen({super.key, required this.profile});

  final ProProfile profile;

  Future<void> _open(BuildContext context, String route) {
    return context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final proAuth = context.watch<ProAuthProvider>();
    final currentProfile = proAuth.currentProfile ?? profile;
    final profileColor = ProModuleHelper.getProfileColor(currentProfile.type);

    return Scaffold(
      drawer: const ProDrawer(),
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: profileColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [profileColor, profileColor.withValues(alpha: 0.82)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      child: Icon(
                        ProModuleHelper.getProfileIcon(currentProfile.type),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
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
                          Text(
                            ProModuleHelper.getProfileName(currentProfile.type),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: currentProfile.activeModules
                      .map(
                        (module) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            ProModuleHelper.getModuleName(module),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  currentProfile.isVerified
                      ? 'Verified account'
                      : 'Verification pending',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Linked user account: ${currentProfile.userId}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          if (currentProfile.type == ProProfileType.delivery ||
              currentProfile.type == ProProfileType.rider) ...[
            const SizedBox(height: 16),
            Card(
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
          const SizedBox(height: 16),
          Text(
            'Management',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ..._buildManagementTiles(context, currentProfile),
          const SizedBox(height: 16),
          Text(
            'Module Access',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...currentProfile.activeModules.map(
            (module) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: ProModuleHelper.getModuleColor(
                    module,
                  ).withValues(alpha: 0.12),
                  child: Icon(
                    ProModuleHelper.getModuleIcon(module),
                    color: ProModuleHelper.getModuleColor(module),
                  ),
                ),
                title: Text(ProModuleHelper.getModuleName(module)),
                subtitle: Text(ProModuleHelper.getModuleDescription(module)),
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
            icon: Icons.storefront_outlined,
            color: AppColors.shopping,
            title: 'Catalog & Availability',
            subtitle: 'Open store, restaurant, and pharmacy controls.',
            onTap: () => _open(context, ProRoutePaths.shopCatalog),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ),
    );
  }
}
