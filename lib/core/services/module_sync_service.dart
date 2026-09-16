import 'dart:async';

import 'package:flutter/widgets.dart';

import '../providers/module_provider.dart';

/// Keeps the app's module configuration in sync with the backend without
/// requiring an app restart:
///
/// - refreshes when the app comes back to the foreground (covers the
///   "admin deactivated a module while the app was backgrounded" case and
///   the "connection was down at launch, network is back now" case, since
///   returning to the app after regaining connectivity fires `resumed`),
/// - polls on a timer while the app is in the foreground,
/// - retries once shortly after a failed refresh (slow/flaky connections).
///
/// The fetched configuration is also persisted by [ModuleProvider], so the
/// next cold start shows the correct modules immediately — no flash of
/// everything-enabled on fresh installs.
class ModuleSyncService with WidgetsBindingObserver {
  ModuleSyncService._();

  static final ModuleSyncService instance = ModuleSyncService._();

  ModuleProvider? _provider;
  Timer? _pollTimer;
  bool _started = false;

  /// How often the config is re-fetched while the app is foregrounded.
  static const Duration _pollInterval = Duration(minutes: 5);

  /// Delay before the single retry after a failed refresh.
  static const Duration _retryDelay = Duration(seconds: 6);

  void start(ModuleProvider provider) {
    _provider = provider;
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _pollTimer = Timer.periodic(_pollInterval, (_) => refresh());
  }

  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
      _started = false;
    }
  }

  /// Fire-and-forget refresh; safe to call from anywhere.
  Future<void> refresh() async {
    final provider = _provider;
    if (provider == null) return;
    await provider.refreshFromServer();
    // One quick retry when the first attempt failed (e.g. the network was
    // still settling after launch or a connectivity change).
    if (provider.errorMessage != null) {
      Timer(_retryDelay, () {
        final p = _provider;
        if (p == null) return;
        if (p.errorMessage != null) {
          p.refreshFromServer();
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refresh();
    }
  }
}
