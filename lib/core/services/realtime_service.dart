import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../network/api_client.dart';

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  http.Client? _client;
  final Map<String, List<Function(dynamic)>> _subscribers = {};
  bool _isConnected = false;
  bool _isReconnecting = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const Duration _baseReconnectDelay = Duration(seconds: 2);
  static const Duration _maxReconnectDelay = Duration(minutes: 2);

  /// Connect to the SSE server
  Future<void> connect() async {
    if (_isConnected || _isReconnecting) return;

    try {
      final sseUrl = '${ApiClient.baseUrl}/realtime/events';
      print('Connecting to SSE: $sseUrl');

      _client = http.Client();
      final request = http.Request('GET', Uri.parse(sseUrl));
      request.headers.addAll(await ApiClient.authHeaders());

      final response = await _client!.send(request);

      if (response.statusCode == 200) {
        _isConnected = true;
        _isReconnecting = false;
        _reconnectTimer?.cancel();
        _reconnectAttempts = 0;
        print('SSE connected successfully');

        // Listen to the stream
        response.stream
            .transform(const Utf8Decoder())
            .transform(const LineSplitter())
            .listen(
              (line) {
                if (line.startsWith('data: ')) {
                  final data = line.substring(6).trim();
                  if (data.isNotEmpty) {
                    _handleMessage(data);
                  }
                }
              },
              onDone: () {
                _isConnected = false;
                print('SSE connection closed');
                _scheduleReconnect();
              },
              onError: (error) {
                print('SSE error: $error');
                _isConnected = false;
                _scheduleReconnect();
              },
            );
      } else {
        throw Exception('Failed to connect to SSE: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to connect SSE: $e');
      _isConnected = false;
      _client?.close();
      _client = null;
      _scheduleReconnect();
    }
  }

  /// Reconnect with exponential backoff so a downed backend cannot pin the
  /// CPU with a tight 5-second retry loop while also re-authenticating each
  /// attempt with the freshest session token.
  void _scheduleReconnect() {
    if (_isReconnecting || _reconnectTimer?.isActive == true) return;
    _isReconnecting = true;

    final delay = Duration(
      milliseconds: (_baseReconnectDelay.inMilliseconds *
              (1 << _reconnectAttempts.clamp(0, 6)))
          .clamp(
            _baseReconnectDelay.inMilliseconds,
            _maxReconnectDelay.inMilliseconds,
          ),
    );
    _reconnectAttempts += 1;

    _reconnectTimer = Timer(delay, () async {
      _isReconnecting = false;
      await connect();
    });
  }

  /// Handle incoming SSE messages
  void _handleMessage(String message) {
    try {
      final data = json.decode(message);
      final table = data['table'] as String?;

      if (table != null && _subscribers.containsKey(table)) {
        for (final callback in _subscribers[table]!) {
          callback(data);
        }
      }
    } catch (e) {
      print('Error handling SSE message: $e');
    }
  }

  /// Subscribe to changes for a specific table
  void subscribeToTable(String table, Function(dynamic) callback) {
    if (!_subscribers.containsKey(table)) {
      _subscribers[table] = [];
    }
    _subscribers[table]!.add(callback);

    // Also subscribe on the backend
    _subscribeOnBackend(table);
  }

  /// Unsubscribe from changes for a specific table
  void unsubscribeFromTable(String table, Function(dynamic) callback) {
    if (_subscribers.containsKey(table)) {
      _subscribers[table]!.remove(callback);
      if (_subscribers[table]!.isEmpty) {
        _subscribers.remove(table);
        // Also unsubscribe on the backend
        _unsubscribeOnBackend(table);
      }
    }
  }

  /// Subscribe to a table on the backend
  Future<void> _subscribeOnBackend(String table) async {
    try {
      await ApiClient.post('/realtime/subscribe', {'table': table});
    } catch (e) {
      print('Failed to subscribe to $table on backend: $e');
    }
  }

  /// Unsubscribe from a table on the backend
  Future<void> _unsubscribeOnBackend(String table) async {
    try {
      await ApiClient.post('/realtime/unsubscribe', {'table': table});
    } catch (e) {
      print('Failed to unsubscribe from $table on backend: $e');
    }
  }

  /// Disconnect from the SSE server
  void disconnect() {
    _reconnectTimer?.cancel();
    _isReconnecting = false;
    _reconnectAttempts = 0;
    _client?.close();
    _client = null;
    _isConnected = false;
    _subscribers.clear();
  }

  /// Check if connected to SSE server
  bool get isConnected => _isConnected;
}
