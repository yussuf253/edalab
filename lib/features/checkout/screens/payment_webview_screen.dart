import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:go_router/go_router.dart';
import 'payment_success_screen.dart';
import 'payment_failure_screen.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String successUrl;
  final String failureUrl;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.successUrl,
    required this.failureUrl,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;

  @override
  void initState() {
    super.initState();

    // Platform-specific setup
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(
          params,
          onPermissionRequest: (WebViewPermissionRequest request) {
            request.grant();
          },
        );

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
              _isLoading = progress < 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _checkPaymentResult(url);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            return _handleNavigationRequest(request);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));

    // #docregion platform_features
    // #enddocregion platform_features

    _controller = controller;
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final url = request.url;

    // Allow navigation to WaafiPay domains
    if (url.contains('waafipay.net') || url.contains('waafipay.com')) {
      return NavigationDecision.navigate;
    }

    // Check if this is our success or failure URL
    if (url.startsWith(widget.successUrl)) {
      _handlePaymentSuccess(url);

      return NavigationDecision.prevent;
    }

    if (url.startsWith(widget.failureUrl)) {
      _handlePaymentFailure(url);

      return NavigationDecision.prevent;
    }

    // Allow other navigation within the web view

    return NavigationDecision.navigate;
  }

  void _checkPaymentResult(String url) {
    if (url.startsWith(widget.successUrl)) {
      _handlePaymentSuccess(url);
    } else if (url.startsWith(widget.failureUrl)) {
      _handlePaymentFailure(url);
    }
  }

  void _handlePaymentSuccess(String url) {
    final uri = Uri.parse(url);
    final orderId = uri.queryParameters['orderId'] ?? '';

    context.pushReplacement(
      '/payment/success',
      extra: {
        'orderId': orderId,
        'moduleName': 'Order',
        'amount': 0.0, // You might want to pass the actual amount
      },
    );
  }

  void _handlePaymentFailure(String url) {
    final uri = Uri.parse(url);
    final message = uri.queryParameters['message'] ?? 'Payment failed';

    context.pushReplacement(
      '/payment/failed',
      extra: {
        'message': message,
        'orderId': '',
        'moduleName': 'Order',
        'amount': 0.0,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent going back during payment
      onPopInvoked: (didPop) async {
        if (didPop) return;
        // Show confirmation dialog if user tries to go back
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Payment'),
            content: const Text(
              'Are you sure you want to cancel the payment process?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continue Payment'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
        if (shouldPop ?? false) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
          automaticallyImplyLeading: false, // Remove back button
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.clearCache();
    super.dispose();
  }
}
