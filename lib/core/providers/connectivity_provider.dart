import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Tracks device connectivity and exposes a single `isOffline` flag that the
/// app-level gate in `app.dart` listens to.
///
/// - Streams [ConnectivityResult] changes.
/// - Re-checks after app resume (mobile OS can drop the radio in background).
/// - `isOffline` only becomes true when the radio reports *no* connection,
///   so cellular/wifi/ethernet all count as online.
class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOffline = false;
  bool _initialized = false;

  /// True when the device reports no network interface at all.
  bool get isOffline => _isOffline;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateStatus,
      onError: (Object e) {
        // Never block the whole app because the plugin hiccuped.
        debugPrint('ConnectivityProvider stream error: $e');
      },
    );

    await checkNow();
  }

  /// Re-check the current connectivity state (used on resume and by the
  /// "Try again" button on the offline screen).
  Future<void> checkNow() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateStatus(results);
    } catch (e) {
      debugPrint('ConnectivityProvider check failed: $e');
    }
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
    if (offline == _isOffline) return;
    _isOffline = offline;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}
