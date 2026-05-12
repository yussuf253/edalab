import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../modules/module_access_service.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

void openAppRoute(String route) {
  final context = _rootNavigatorKey.currentContext;
  if (context == null) return;
  context.push(route);
}

GoRouter createAppRouter({required bool hasSeenOnboarding}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: hasSeenOnboarding ? '/' : '/onboarding',
    redirect: (context, state) {
      final moduleId = ModuleAccessService.instance.moduleForPath(
        state.uri.path,
      );
      if (moduleId == null) return null;
      if (ModuleAccessService.instance.isEnabled(moduleId)) return null;
      return '/';
    },
    routes: [
      // Onboarding
    ],
  );
}
