import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../router/pro_route_paths.dart';
import '../models/pro_profile.dart';
import '../providers/pro_auth_provider.dart';
import '../utils/pro_module_helper.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProDrawer extends StatelessWidget {
  const ProDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final proAuth = context.watch<ProAuthProvider>();
    final proProfile = proAuth.currentProfile;

    if (proProfile == null) {
      return const Drawer(child: SafeArea(child: Text('Not Signed In')));
    }

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(proProfile.businessName),
            accountEmail: Text(ProModuleHelper.getProfileName(proProfile.type)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: proProfile.avatarUrl != null
                  ? NetworkImage(proProfile.avatarUrl!)
                  : null,
              child: proProfile.avatarUrl == null
                  ? Icon(
                      ProModuleHelper.getProfileIcon(proProfile.type),
                      size: 40,
                    )
                  : null,
            ),
            decoration: const BoxDecoration(color: AppColors.primary),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(LucideIcons.verified, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  proProfile.isVerified
                      ? 'Verified Account'
                      : 'Pending Verification',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.layoutDashboard),
                  title: Text(
                    proProfile.type == ProProfileType.shop
                        ? 'Store Dashboard'
                        : 'Workspace',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(
                      ProRoutePaths.homeForProfileType(proProfile.type),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.layoutGrid),
                  title: Text(
                    proProfile.type == ProProfileType.shop
                        ? 'Store Tools'
                        : 'Operations',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(ProRoutePaths.operations);
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.messageSquare),
                  title: const Text('Inbox'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(ProRoutePaths.inbox);
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.chartLine),
                  title: Text(
                    proProfile.type == ProProfileType.shop
                        ? 'Store Insights'
                        : 'Insights',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(ProRoutePaths.insights);
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.user),
                  title: const Text('Account'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push(ProRoutePaths.account);
                  },
                ),
                if (proAuth.isSuperAdmin)
                  ListTile(
                    leading: const Icon(LucideIcons.shieldCheck),
                    title: const Text('Super Admin'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(ProRoutePaths.superAdmin);
                    },
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    proProfile.type == ProProfileType.shop
                        ? 'STORE MODULES'
                        : 'ACTIVE MODULES',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                ...proProfile.activeModules.map((module) {
                  return ListTile(
                    leading: Icon(
                      ProModuleHelper.getModuleIcon(module),
                      color: ProModuleHelper.getModuleColor(module),
                    ),
                    title: Text(ProModuleHelper.getModuleName(module)),
                    subtitle: Text(
                      ProModuleHelper.getModuleDescription(module),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(_routeForModule(module));
                    },
                  );
                }),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(LucideIcons.logOut, color: Colors.red),
            title: const Text(
              'Sign Out from Pro',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              await context.read<ProAuthProvider>().logout();
              if (!context.mounted) return;
              context.go('/');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _routeForModule(ProModule module) {
    switch (module) {
      case ProModule.shopping:
      case ProModule.food:
      case ProModule.pharmacy:
      case ProModule.services:
      case ProModule.laundry:
      case ProModule.doctor:
      case ProModule.shoppingDelivery:
      case ProModule.foodDelivery:
      case ProModule.pharmacyDelivery:
      case ProModule.parcelDelivery:
      case ProModule.ride:
      case ProModule.ecologicalCleaning:
        return ProRoutePaths.queueForModule(module);
    }
  }
}
