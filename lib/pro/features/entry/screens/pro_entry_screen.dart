import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/providers/pro_auth_provider.dart';
import '../../auth/screens/pro_signup_screen.dart';
import '../../delivery/screens/delivery_dashboard_screen.dart';
import '../../doctor/screens/doctor_dashboard_screen.dart';
import '../../provider/screens/provider_dashboard_screen.dart';
import '../../rider/screens/rider_dashboard_screen.dart';
import '../../shop/screens/shop_dashboard_screen.dart';
import 'pro_welcome_screen.dart';

class ProEntryScreen extends StatefulWidget {
  const ProEntryScreen({super.key});

  @override
  State<ProEntryScreen> createState() => _ProEntryScreenState();
}

class _ProEntryScreenState extends State<ProEntryScreen> {
  String? _requestedUserId;
  String? _resolvedUserId;

  void _ensureProfileLoaded(
    AuthProvider authProvider,
    ProAuthProvider proAuthProvider,
  ) {
    final userId = authProvider.user?.id;

    if (userId == null || userId.isEmpty) {
      _requestedUserId = null;
      _resolvedUserId = null;
      return;
    }

    if (proAuthProvider.currentProfile?.userId == userId ||
        proAuthProvider.isLoading ||
        _requestedUserId == userId ||
        _resolvedUserId == userId) {
      return;
    }

    _requestedUserId = userId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<ProAuthProvider>().fetchProfile(userId);
      if (!mounted) return;
      _requestedUserId = null;
      _resolvedUserId = userId;
    });
  }

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

  bool _isResolvingInitialProfile(
    AuthProvider authProvider,
    ProAuthProvider proAuthProvider,
  ) {
    final userId = authProvider.user?.id;
    if (userId == null || userId.isEmpty) {
      return false;
    }

    return proAuthProvider.currentProfile == null &&
        proAuthProvider.isLoading &&
        _requestedUserId == userId &&
        _resolvedUserId != userId;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final proAuthProvider = context.watch<ProAuthProvider>();

    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!authProvider.isLoggedIn || authProvider.user == null) {
      return const ProWelcomeScreen();
    }

    _ensureProfileLoaded(authProvider, proAuthProvider);

    if (_isResolvingInitialProfile(authProvider, proAuthProvider)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (proAuthProvider.currentProfile == null) {
      return const ProSignupScreen();
    }

    return _buildModuleHome(proAuthProvider.currentProfile!);
  }
}
