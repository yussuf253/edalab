import '/pro/features/auth/screens/pro_register_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/pro_auth_provider.dart';
import '../../../core/utils/pro_module_helper.dart';
import '../../auth/screens/pro_signup_screen.dart';
import '../../dashboard/screens/pro_dashboard_screen.dart';
import '../../super_admin/screens/pro_super_admin_home_screen.dart';
import 'pro_pending_verification_screen.dart';

class ProEntryScreen extends StatelessWidget {
  const ProEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final proAuthProvider = context.watch<ProAuthProvider>();

    if (!proAuthProvider.isInitialized || proAuthProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!proAuthProvider.isAuthenticated ||
        proAuthProvider.currentAccount == null) {
      return const ProRegisterScreen();
    }

    if (proAuthProvider.currentProfile == null) {
      // Super admins have no pro profile by design — give them a dedicated
      // admin home instead of forcing pro-profile signup.
      if (proAuthProvider.isSuperAdmin) {
        return const ProSuperAdminHomeScreen();
      }
      return const ProSignupScreen();
    }

    final profile = proAuthProvider.currentProfile!;

    // Check if account is verified
    if (!profile.isVerified) {
      return ProPendingVerificationScreen(
        businessName: profile.businessName,
        profileType: ProModuleHelper.getProfileName(profile.type),
      );
    }

    return const ProDashboardScreen();
  }
}
