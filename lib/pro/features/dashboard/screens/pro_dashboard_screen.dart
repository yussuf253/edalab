import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../core/models/pro_profile.dart';
import '../../../core/providers/pro_auth_provider.dart';
import '../../account/screens/pro_account_screen.dart';
import '../../delivery/screens/delivery_dashboard_screen.dart';
import '../../doctor/screens/doctor_dashboard_screen.dart';
import '../../insights/screens/pro_insights_screen.dart';
import '../../messages/screens/pro_messages_screen.dart';
import '../../operations/screens/pro_operations_screen.dart';
import '../../provider/screens/provider_dashboard_screen.dart';
import '../../rider/screens/rider_dashboard_screen.dart';
import '../../shop/screens/shop_dashboard_screen.dart';

class ProDashboardScreen extends StatefulWidget {
  final int initialIndex;

  const ProDashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<ProDashboardScreen> createState() => _ProDashboardScreenState();
}

class _ProDashboardScreenState extends State<ProDashboardScreen> {
  late int _currentIndex;
  Timer? _inboxPollTimer;
  String? _pollingUserId;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4).toInt();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profile = context.read<ProAuthProvider>().currentProfile;
      if (profile != null) {
        _restartInboxPolling(profile);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ProDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex = widget.initialIndex.clamp(0, 4).toInt();
    if (oldWidget.initialIndex != widget.initialIndex &&
        nextIndex != _currentIndex) {
      setState(() {
        _currentIndex = nextIndex;
      });
    }
  }

  @override
  void dispose() {
    _inboxPollTimer?.cancel();
    super.dispose();
  }

  void _refreshInboxSummary() {
    if (!mounted) return;
    final proAuth = context.read<ProAuthProvider>();
    if (!proAuth.supportsInbox) return;
    proAuth.refreshInboxSummary(forceRefresh: true);
  }

  void _restartInboxPolling(ProProfile profile) {
    final proAuth = context.read<ProAuthProvider>();
    if (!proAuth.supportsInbox) {
      _inboxPollTimer?.cancel();
      _pollingUserId = null;
      return;
    }

    if (_pollingUserId == profile.userId && _inboxPollTimer?.isActive == true) {
      return;
    }

    _inboxPollTimer?.cancel();
    _pollingUserId = profile.userId;
    _refreshInboxSummary();
    _inboxPollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _refreshInboxSummary();
    });
  }

  Widget _buildInboxIcon({
    required IconData icon,
    required int unreadCount,
    bool isActive = false,
  }) {
    if (unreadCount <= 0) {
      return Icon(icon);
    }

    final label = unreadCount > 99 ? '99+' : '$unreadCount';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -10,
          top: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            constraints: const BoxConstraints(minWidth: 18),
            decoration: BoxDecoration(
              color: isActive ? AppColors.error : AppColors.primary,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.white, width: 1.5),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeView(ProProfile profile) {
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
    final proAuth = context.watch<ProAuthProvider>();
    final profile = proAuth.currentProfile;

    if (profile == null) {
      _inboxPollTimer?.cancel();
      _pollingUserId = null;
      return const Scaffold(body: Center(child: Text('No Pro Profile found.')));
    }

    if (_pollingUserId != profile.userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _restartInboxPolling(profile);
      });
    }

    final screens = [
      _buildHomeView(profile),
      ProOperationsScreen(profile: profile),
      ProMessagesScreen(profile: profile),
      ProInsightsScreen(profile: profile),
      ProAccountScreen(profile: profile),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primaryDark,
          unselectedItemColor: AppColors.mediumGrey,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.widgets_outlined),
              activeIcon: Icon(Icons.widgets),
              label: 'Operations',
            ),
            BottomNavigationBarItem(
              icon: _buildInboxIcon(
                icon: Icons.chat_bubble_outline,
                unreadCount: proAuth.unreadInboxCount,
              ),
              activeIcon: _buildInboxIcon(
                icon: Icons.chat_bubble,
                unreadCount: proAuth.unreadInboxCount,
                isActive: true,
              ),
              label: 'Inbox',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.insights_outlined),
              activeIcon: Icon(Icons.insights),
              label: 'Insights',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }
}
