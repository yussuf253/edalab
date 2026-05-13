import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../network/api_client.dart';

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  WebSocketChannel? _channel;
  final Map<String, List<Function(dynamic)>> _subscribers = {};
  bool _isConnected = false;

  /// Connect to the WebSocket server
  Future<void> connect() async {
    if (_isConnected) return;

    try {
      // Replace with your actual WebSocket URL
      final wsUrl = ApiClient.baseUrl.replaceFirst('http', 'ws') + '/ws';
      _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel?.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onDone: () {
          _isConnected = false;
          _reconnect();
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          _reconnect();
        },
      );

      _isConnected = true;
      print('WebSocket connected');
    } catch (e) {
      print('Failed to connect WebSocket: $e');
      _isConnected = false;
      await Future.delayed(Duration(seconds: 5));
      await connect();
    }
  }

  /// Reconnect to the WebSocket server
  Future<void> _reconnect() async {
    print('Attempting to reconnect...');
    await Future.delayed(Duration(seconds: 5));
    await connect();
  }

  /// Handle incoming WebSocket messages
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
      print('Error handling WebSocket message: $e');
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

  /// Disconnect from the WebSocket server
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _subscribers.clear();
  }

  /// Check if connected to WebSocket server
  bool get isConnected => _isConnected;
}