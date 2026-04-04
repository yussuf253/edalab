import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/pro_profile.dart';
import '../../../core/providers/pro_auth_provider.dart';
import '../../auth/screens/pro_signup_screen.dart';
import '../../delivery/screens/delivery_dashboard_screen.dart';
import '../../doctor/screens/doctor_dashboard_screen.dart';
import '../../provider/screens/provider_dashboard_screen.dart';
import '../../rider/screens/rider_dashboard_screen.dart';
import '../../shop/screens/shop_dashboard_screen.dart';
import 'pro_welcome_screen.dart';

class ProEntryScreen extends StatelessWidget {
  const ProEntryScreen({super.key});

  Widget _buildModuleHome(ProProfile profile) {
    switch (profile.type) {
      case ProProfileType.shop:
        return ShopDashboardScreen(profile: profile);
      case ProProfileType.provider:
        return ProviderDashboardScreen(profile: profile);
      case ProProfileType.doctor:
        return DoctorDashboardScreen(profile: profile);
      case ProProfileType.delivery:
        return DeliveryDashboardScreen(profile: profile);
      case ProProfileType.rider:
        return RiderDashboardScreen(profile: profile);
    }
  }

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

    return _buildModuleHome(proAuthProvider.currentProfile!);
  }
}
