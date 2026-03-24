import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../storage/app_preferences.dart';

class ApiClient {
  static const _defaultPort = '5050';
  static const String _configuredHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '127.0.0.1',
  );
  static const Duration _requestTimeout = Duration(seconds: 12);
  static String? _token;

  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:$_defaultPort/api';
    if (Platform.isAndroid) {
      final host = _configuredHost == '127.0.0.1' ? '10.0.2.2' : _configuredHost;
      return 'http://$host:$_defaultPort/api';
    }
    return 'http://$_configuredHost:$_defaultPort/api';
  }

  static Future<void> initialize() async {
    _token = await AppPreferences.getAuthToken();
  }

  static Future<void> setToken(String? token) async {
    _token = token;
    if (token == null || token.isEmpty) {
      await AppPreferences.clearAuthToken();
      return;
    }
    await AppPreferences.setAuthToken(token);
  }

  static Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final token = _token ?? await AppPreferences.getAuthToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  static String get _connectionHint {
    if (kIsWeb) {
      return 'For web, make sure the backend is running on localhost:$_defaultPort.';
    }

    if (Platform.isAndroid) {
      return _configuredHost == '127.0.0.1'
          ? 'Android emulator uses 10.0.2.2 automatically. If you are on a real phone, run Flutter with --dart-define=API_HOST=YOUR_MAC_IP.'
          : 'If you are on a real phone, confirm $_configuredHost is your Mac\'s LAN IP and the backend is reachable on port $_defaultPort.';
    }

    return _configuredHost == '127.0.0.1'
        ? '127.0.0.1 works for iOS simulator and desktop. If you are on a physical iPhone/iPad, run Flutter with --dart-define=API_HOST=YOUR_MAC_IP.'
        : 'Confirm $_configuredHost is reachable from this device on port $_defaultPort.';
  }

  static Exception _connectionException(Object error) {
    return Exception(
      'Could not reach the API at $baseUrl. $_connectionHint Original error: $error',
    );
  }

  static Future<dynamic> get(String endpoint) async {
    late http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _headers(),
          )
          .timeout(_requestTimeout);
    } on TimeoutException catch (error) {
      throw _connectionException(error);
    } on SocketException catch (error) {
      throw _connectionException(error);
    }

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final body = response.body.trim();
      if (body.isNotEmpty) {
        final errorDecoded = json.decode(body);
        throw Exception(errorDecoded['error'] ?? 'Failed to load data: ${response.statusCode}');
      }
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    late http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _headers(),
            body: json.encode(data),
          )
          .timeout(_requestTimeout);
    } on TimeoutException catch (error) {
      throw _connectionException(error);
    } on SocketException catch (error) {
      throw _connectionException(error);
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final errorDecoded = json.decode(response.body);
      throw Exception(errorDecoded['error'] ?? 'Failed to post data: ${response.statusCode}');
    }
  }

  static Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    late http.Response response;
    try {
      response = await http
          .patch(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _headers(),
            body: json.encode(data),
          )
          .timeout(_requestTimeout);
    } on TimeoutException catch (error) {
      throw _connectionException(error);
    } on SocketException catch (error) {
      throw _connectionException(error);
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final errorDecoded = json.decode(response.body);
      throw Exception(errorDecoded['error'] ?? 'Failed to patch data: ${response.statusCode}');
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    late http.Response response;
    try {
      response = await http
          .delete(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _headers(),
          )
          .timeout(_requestTimeout);
    } on TimeoutException catch (error) {
      throw _connectionException(error);
    } on SocketException catch (error) {
      throw _connectionException(error);
    }

    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.body.isEmpty) {
        return null;
      }
      return json.decode(response.body);
    } else {
      final errorDecoded = json.decode(response.body);
      throw Exception(errorDecoded['error'] ?? 'Failed to delete data: ${response.statusCode}');
    }
  }
}
