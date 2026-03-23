import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiClient {
  static const _defaultPort = '5050';
  static const _localNetworkHost = '192.168.1.2';

  static String get baseUrl {
    // Handling localhost for Android emulator vs iOS simulator / Web.
    // 10.0.2.2 is the special IP mapped to the host loopback from the Android emulator.
    if (kIsWeb) return 'http://localhost:$_defaultPort/api';
    if (Platform.isAndroid) return 'http://$_localNetworkHost:$_defaultPort/api';
    return 'http://$_localNetworkHost:$_defaultPort/api';
  }

  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl$endpoint'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final errorDecoded = json.decode(response.body);
      throw Exception(errorDecoded['error'] ?? 'Failed to post data: ${response.statusCode}');
    }
  }

  static Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final errorDecoded = json.decode(response.body);
      throw Exception(errorDecoded['error'] ?? 'Failed to patch data: ${response.statusCode}');
    }
  }

  static Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(Uri.parse('$baseUrl$endpoint'));
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
