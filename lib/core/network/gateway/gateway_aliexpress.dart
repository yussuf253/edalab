import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase_gateway.dart';
import 'gateway_router.dart';

/// `/aliexpress/*` — the AliExpress catalogue proxy.
///
/// AliExpress only answers HMAC-SHA256 requests signed with the app secret, so
/// the signing lives in the `aliexpress` Edge Function
/// (`supabase/functions/aliexpress`). These handlers keep the REST surface the
/// app already calls and forward it to that function, translating its failures
/// into the same messages the retired backend produced.
void register() {
  GatewayRouter.get('/aliexpress/products/search', _search);
  GatewayRouter.get('/aliexpress/products/:productId', _productDetail);
  GatewayRouter.get('/aliexpress/categories', _categories);
  GatewayRouter.get('/aliexpress/feed', _feed);
}

const String _functionName = 'aliexpress';

Future<dynamic> _call(Map<String, dynamic> body) async {
  try {
    final response = await SupabaseGateway.client.functions.invoke(
      _functionName,
      body: body,
    );

    final status = response.status;
    final data = response.data;

    if (status >= 400) {
      throw GatewayError(
        _messageFrom(data, status),
        status: status >= 500 ? 502 : status,
      );
    }
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const GatewayError(
      'AliExpress returned an unexpected response.',
      status: 502,
    );
  } on GatewayError {
    rethrow;
  } on FunctionException catch (error) {
    // 404 here means the function was never deployed; supabase_flutter reports
    // an unreachable function through FunctionException too.
    throw GatewayError(
      error.status == 404
          ? 'AliExpress is not available right now.'
          : _messageFrom(error.details, error.status),
      status: error.status,
    );
  }
}

/// Reads the `{ "error": "…" }` body the Edge Function returns.
String _messageFrom(dynamic details, int status) {
  if (details is Map) {
    final message = details['error']?.toString().trim() ?? '';
    if (message.isNotEmpty) return message;
  }
  if (details is String && details.trim().isNotEmpty) return details.trim();
  if (status == 404) return 'AliExpress is not available right now.';
  return 'AliExpress is unavailable right now. Please try again later.';
}

Future<dynamic> _search(GatewayRequest request) async {
  final query = request.optionalString('q');
  if (query == null) {
    throw const GatewayError('Search query is required.');
  }

  return _call(<String, dynamic>{
    'action': 'search',
    'q': query,
    'page': request.optionalString('page') ?? '1',
    'pageSize': request.optionalString('pageSize') ?? '20',
    'sort': request.optionalString('sort') ?? 'DEFAULT',
    if (request.optionalString('targetCurrency') != null)
      'targetCurrency': request.optionalString('targetCurrency'),
    if (request.optionalString('targetLanguage') != null)
      'targetLanguage': request.optionalString('targetLanguage'),
  });
}

Future<dynamic> _productDetail(GatewayRequest request) async {
  final productId = request.requireSegment(2, 'productId');
  return _call(<String, dynamic>{'action': 'product', 'productId': productId});
}

Future<dynamic> _categories(GatewayRequest request) async {
  return _call(<String, dynamic>{
    'action': 'categories',
    'parentId': request.optionalString('parentId') ?? '0',
  });
}

/// The browsable storefront feed — real pagination plus a category filter, so
/// the tab can keep loading products instead of stopping after one page.
Future<dynamic> _feed(GatewayRequest request) async {
  return _call(<String, dynamic>{
    'action': 'feed',
    'page': request.optionalString('page') ?? '1',
    'pageSize': request.optionalString('pageSize') ?? '20',
    if (request.optionalString('categoryId') != null)
      'categoryId': request.optionalString('categoryId'),
    if (request.optionalString('sort') != null)
      'sort': request.optionalString('sort'),
  });
}
