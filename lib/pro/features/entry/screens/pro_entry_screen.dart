import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/pro_auth_provider.dart';
import '../../auth/screens/pro_signup_screen.dart';
import '../../dashboard/screens/pro_dashboard_screen.dart';
import 'pro_welcome_screen.dart';

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
      return const ProWelcomeScreen();
    }

    if (proAuthProvider.currentProfile == null) {
      return const ProSignupScreen();
    }

    return const ProDashboardScreen();
  }
}
