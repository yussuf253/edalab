import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();

  factory DeepLinkService() => _instance;

  DeepLinkService._internal();

  bool _initialized = false;
  late AppLinks _appLinks;

  Future<void> initialize(BuildContext context) async {
    if (_initialized) return;
    _initialized = true;

    _appLinks = AppLinks();

    // Handle initial link if app was launched from a deep link
    try {
      final initialLink = await _appLinks.getInitialAppLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink.toString(), context);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Listen for incoming links while the app is running
    _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          _handleDeepLink(uri.toString(), context);
        }
      },
      onError: (err) {
        debugPrint('Error in link stream: $err');
      },
    );
  }

  void _handleDeepLink(String link, BuildContext context) {
    debugPrint('Received deep link: $link');

    final uri = Uri.parse(link);
    final path = uri.path;
    final queryParams = uri.queryParameters;

    // Handle payment success deep link
    if (path == '/payment/success') {
      final orderId = queryParams['orderId'];
      if (orderId != null) {
        _navigateToPaymentSuccess(context, orderId);
        return;
      }
    }

    // Handle payment failure deep link
    if (path == '/payment/failed') {
      final message = queryParams['message'] ?? 'Payment failed';
      _navigateToPaymentFailed(context, message);
      return;
    }

    // Handle other deep links if needed
    debugPrint('Unhandled deep link: $path');
  }

  void _navigateToPaymentSuccess(BuildContext context, String orderId) {
    // Get the current route to avoid duplicate navigation
    final currentRoute = GoRouterState.of(context).uri.toString();

    if (!currentRoute.contains('/payment/success')) {
      context.push(
        '/payment/success',
        extra: {
          'orderId': orderId,
          'moduleName': 'Order',
          'amount': 0.0, // Will be fetched from order details
        },
      );
    }
  }

  void _navigateToPaymentFailed(BuildContext context, String message) {
    // Get the current route to avoid duplicate navigation
    final currentRoute = GoRouterState.of(context).uri.toString();

    if (!currentRoute.contains('/payment/failed')) {
      context.push(
        '/payment/failed',
        extra: {
          'message': message,
          'orderId': '',
          'moduleName': 'Order',
          'amount': 0.0,
        },
      );
    }
  }
}
