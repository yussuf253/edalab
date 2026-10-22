import 'package:flutter_test/flutter_test.dart';

import 'package:edalab/core/network/gateway/gateway_admin.dart' as admin;
import 'package:edalab/core/network/gateway/gateway_catalog.dart' as catalog;
import 'package:edalab/core/network/gateway/gateway_media.dart' as media;
import 'package:edalab/core/network/gateway/gateway_messages.dart'
    as messages;
import 'package:edalab/core/network/gateway/gateway_misc.dart' as misc;
import 'package:edalab/core/network/gateway/gateway_notifications.dart'
    as notifications;
import 'package:edalab/core/network/gateway/gateway_orders.dart' as orders;
import 'package:edalab/core/network/gateway/gateway_payments.dart'
    as payments;
import 'package:edalab/core/network/gateway/gateway_pro.dart' as pro;
import 'package:edalab/core/network/gateway/gateway_router.dart';
import 'package:edalab/core/network/gateway/gateway_users.dart' as users;

/// Paths are handed to the gateway exactly as `ApiClient` receives them, so
/// the test mirrors that: query strings stripped, `:name` slots filled with a
/// realistic value.
List<String> _segments(String path) => Uri.parse(path)
    .pathSegments
    .where((segment) => segment.isNotEmpty)
    .toList(growable: false);

GatewayHandler? _resolve(String method, String path) {
  final params = <String, String>{};
  return GatewayRouter.resolve(method, _segments(path), params);
}

void main() {
  setUpAll(() {
    misc.register();
    notifications.register();
    users.register();
    catalog.register();
    orders.register();
    pro.register();
    messages.register();
    admin.register();
    media.register();
    payments.register();
  });

  // Every path the customer app calls today must be served by Supabase.
  // Anything missing here silently falls back to Render — which is exactly the
  // 1-minute cold start this migration exists to remove — so the list is the
  // contract: add a path here when you port its handler, and the test fails
  // loudly if a registered route disappears.
  const routed = <(String, String)>[
    ('GET', '/health'),
    ('GET', '/modules'),
    ('GET', '/modules/zones'),
    ('GET', '/modules/zones/resolve'),
    ('GET', '/modules/zones/djibouti_ville/modules'),
    ('GET', '/modules/enabled'),
    ('GET', '/promotions'),
    ('GET', '/version/check'),
    ('POST', '/version/report-action'),
    ('POST', '/realtime/subscribe'),
    ('POST', '/realtime/unsubscribe'),

    ('GET', '/notifications/cmabc123'),
    ('POST', '/notifications'),
    ('PATCH', '/notifications/cmabc123/read'),
    ('POST', '/notifications/device-tokens'),

    ('GET', '/users/cmus123'),
    ('GET', '/users/me'),
    ('PATCH', '/users/cmus123'),
    ('POST', '/users/cmus123/addresses'),
    ('PATCH', '/users/cmus123/addresses/cmaddr1'),
    ('PATCH', '/users/cmus123/addresses/cmaddr1/default'),
    ('DELETE', '/users/cmus123/addresses/cmaddr1'),
    ('GET', '/users/cmus123/payment-methods'),
    ('POST', '/users/cmus123/payment-methods'),
    ('PATCH', '/users/cmus123/payment-methods/cmpm1/default'),
    ('DELETE', '/users/cmus123/payment-methods/cmpm1'),
    ('GET', '/users/cmus123/wishlist'),
    ('POST', '/users/cmus123/wishlist'),
    ('DELETE', '/users/cmus123/wishlist/cmprod1'),
    ('GET', '/users/cmus123/coupons'),

    ('GET', '/catalog/products'),
    ('GET', '/catalog/products/cmprod1'),
    ('GET', '/catalog/categories'),
    ('GET', '/catalog/pharmacies'),
    ('GET', '/catalog/shopping-stores'),
    ('GET', '/catalog/shopping-stores/my-store'),
    ('GET', '/catalog/doctors'),
    ('GET', '/catalog/doctors/d1'),
    ('GET', '/catalog/home-service-categories'),
    ('GET', '/catalog/home-service-providers'),
    ('GET', '/catalog/home-service-providers/cmprov1'),
    ('GET', '/catalog/restaurants'),
    ('GET', '/catalog/restaurants/cmrest1'),
    ('GET', '/catalog/hotels'),
    ('GET', '/catalog/hotels/h1'),
    ('GET', '/catalog/ride-categories'),
    ('GET', '/catalog/laundry-services'),
    ('GET', '/catalog/health-services/tests'),
    ('GET', '/catalog/health-services/physiotherapy'),

    ('GET', '/rides/user/cmus123'),
    ('GET', '/rides/cmride1'),
    ('POST', '/rides'),
    // Note: there is no bare `GET /rides` — neither the app nor the backend
    // ever served one (`/rides/user/:userId` and `/:rideId` only).

    ('GET', '/appointments/cmus123'),
    ('GET', '/appointments/home-care/cmus123'),
    ('POST', '/appointments'),
    ('POST', '/appointments/home-care'),
    ('PATCH', '/appointments/cmapp1/status'),

    ('GET', '/orders/cmus123'),
    ('GET', '/orders/detail/cmorder1'),
    ('POST', '/orders'),
    ('POST', '/orders/hotel-bookings'),
    ('POST', '/orders/pharmacy-prescription'),
    ('GET', '/parcels/user/cmus123'),
    ('GET', '/parcels/pricing'),
    ('POST', '/parcels'),
    ('POST', '/parcels/cmparc1/cancel'),
    ('GET', '/car-rentals'),
    ('GET', '/car-rentals/cmrent1'),
    ('GET', '/car-rentals/bookings/user/cmus123'),
    ('POST', '/car-rentals/bookings'),
    ('POST', '/car-rentals/bookings/cmbk1/cancel'),

    ('GET', '/messages/user/cmus123'),
    ('GET', '/messages/conversations/cmconv1'),
    ('POST', '/messages/conversations/start'),
    ('POST', '/messages/conversations/cmconv1/messages'),
    ('PATCH', '/messages/conversations/cmconv1/read'),

    ('POST', '/media/upload'),
  ];

  test('every customer-app path routes to Supabase (no Render fallback)', () {
    final unrouted = <String>[];
    for (final (method, path) in routed) {
      if (_resolve(method, path) == null) unrouted.add('$method $path');
    }
    expect(
      unrouted,
      isEmpty,
      reason: 'These paths would fall back to the Render backend: $unrouted',
    );
  });

  // Domains that are deliberately still on the backend while they are being
  // ported. When one lands in the gateway, remove it here so the split stays
  // honest.
  const stillDeferred = <(String, String)>[
    ('GET', '/pro/cmus123/dashboard'),
    ('POST', '/pro/cmus123/claim-ride'),
    ('GET', '/admin/overview'),
    ('POST', '/payments/waafipay/initiate'),
    ('POST', '/auth/login'),
    ('POST', '/pro-auth/login'),
  ];

  test('unported domains still fall back to the backend', () {
    final routedTooEarly = <String>[];
    for (final (method, path) in stillDeferred) {
      if (_resolve(method, path) != null) routedTooEarly.add('$method $path');
    }
    expect(
      routedTooEarly,
      isEmpty,
      reason:
          'These resolve but their handlers are not implemented yet: $routedTooEarly',
    );
  });

  test('captures path parameters for the handler', () {
    final params = <String, String>{};
    final handler = GatewayRouter.resolve(
      'PATCH',
      _segments('/users/cmus123/addresses/cmaddr1'),
      params,
    );
    expect(handler, isNotNull);
    expect(params, {'userId': 'cmus123', 'addressId': 'cmaddr1'});
  });

  test('does not match a different HTTP method', () {
    // /modules is registered for GET only.
    expect(_resolve('POST', '/modules'), isNull);
    expect(_resolve('GET', '/modules'), isNotNull);
    // /notifications/device-tokens exists for POST, not GET.
    expect(_resolve('GET', '/notifications/device-tokens'), isNotNull,
        reason: 'GET /notifications/:userId legitimately matches this shape');
    expect(_resolve('POST', '/notifications/device-tokens'), isNotNull);
  });

  test('does not match paths of a different length', () {
    expect(_resolve('GET', '/catalog'), isNull);
    expect(_resolve('GET', '/catalog/products/cmprod1/extra'), isNull);
    expect(_resolve('GET', '/users'), isNull);
  });
}
