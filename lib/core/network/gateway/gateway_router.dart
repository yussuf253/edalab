import 'dart:async';

/// A decoded request handed to a gateway route handler.
///
/// `path` never contains a query string; query parameters are parsed into
/// [query] so handlers can read them without re-splitting.
class GatewayRequest {
  final String method;
  final String path;
  final List<String> segments;
  final Map<String, String> query;
  final Map<String, dynamic>? body;

  const GatewayRequest({
    required this.method,
    required this.path,
    required this.segments,
    required this.query,
    this.body,
  });

  /// Path segment at [index], or `''` when out of range.
  String segment(int index) => index < segments.length ? segments[index] : '';

  String requireSegment(int index, String name) {
    final value = segment(index).trim();
    if (value.isEmpty) {
      throw GatewayError('Missing $name.');
    }
    return value;
  }

  String? param(String name) => query[name];

  String? optionalString(String name) {
    final raw = query[name]?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw == 'null') return null;
    return raw;
  }

  T requireBody<T>(String name) {
    final value = body?[name];
    if (value is! T) {
      throw GatewayError('$name is required.');
    }
    return value;
  }
}

typedef GatewayHandler = Future<dynamic> Function(GatewayRequest request);

/// An application-level failure that maps onto the backend's JSON error body.
///
/// The gateway throws this; [SupabaseGateway] converts it to the same
/// `Exception(message)` the ApiClient used to build from `{"error": ...}`.
class GatewayError implements Exception {
  final String message;
  final int status;
  final bool banned;
  final String? banReason;

  const GatewayError(
    this.message, {
    this.status = 400,
    this.banned = false,
    this.banReason,
  });

  @override
  String toString() => message;
}

/// Thrown when no gateway route matches — the caller may fall back to the
/// legacy HTTP backend while a domain is still being migrated.
class GatewayUnrouted implements Exception {
  final String method;
  final String path;

  const GatewayUnrouted(this.method, this.path);

  @override
  String toString() => 'No Supabase gateway route for $method $path';
}

class _Route {
  final String method;
  final List<String> parts;
  final GatewayHandler handler;

  const _Route(this.method, this.parts, this.handler);
}

/// Registry of legacy-API paths → Supabase handlers.
///
/// Patterns use `:name` placeholders for dynamic segments, e.g.
/// `GET /users/:userId/addresses/:addressId`.
class GatewayRouter {
  GatewayRouter._();

  static final List<_Route> _routes = [];

  static void add(String method, String pattern, GatewayHandler handler) {
    final parts = pattern
        .split('/')
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    _routes.add(_Route(method.toUpperCase(), parts, handler));
  }

  static void get(String pattern, GatewayHandler handler) =>
      add('GET', pattern, handler);

  static void post(String pattern, GatewayHandler handler) =>
      add('POST', pattern, handler);

  static void patch(String pattern, GatewayHandler handler) =>
      add('PATCH', pattern, handler);

  static void put(String pattern, GatewayHandler handler) =>
      add('PUT', pattern, handler);

  static void delete(String pattern, GatewayHandler handler) =>
      add('DELETE', pattern, handler);

  /// Resolves [method]/[path] to a handler, filling [params] with the values
  /// captured from `:name` placeholders.
  static GatewayHandler? resolve(
    String method,
    List<String> segments,
    Map<String, String> params,
  ) {
    final normalizedMethod = method.toUpperCase();

    for (final route in _routes) {
      if (route.method != normalizedMethod) continue;
      if (route.parts.length != segments.length) continue;

      final captured = <String, String>{};
      var matched = true;

      for (var i = 0; i < route.parts.length; i++) {
        final part = route.parts[i];
        final segment = segments[i];
        if (part.startsWith(':')) {
          if (segment.isEmpty) {
            matched = false;
            break;
          }
          captured[part.substring(1)] = Uri.decodeComponent(segment);
        } else if (part != segment) {
          matched = false;
          break;
        }
      }

      if (!matched) continue;

      params
        ..clear()
        ..addAll(captured);
      return route.handler;
    }

    return null;
  }
}
