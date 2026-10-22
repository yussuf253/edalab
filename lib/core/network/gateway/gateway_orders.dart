import 'package:flutter/foundation.dart';

import '../supabase_gateway.dart';
import 'gateway_router.dart';

/// `/rides/*`, `/appointments/*`, `/orders/*`, `/parcels/*` and
/// `/car-rentals/*` — customer bookings.
///
/// Two PostgREST specifics are handled here:
///   * `RideBooking` has *two* foreign keys to `User` (rider and driver) and
///     *two* to `Address` (pickup and dropoff), so every embed carries an
///     `!Constraint_fkey` hint or PostgREST answers PGRST201/300 ambiguity.
///   * the backend's "module disabled" guard is reproduced from `AppModule`
///     (+ `ZoneModuleConfig` where the route takes a zone).
///
/// Counterparty names (courier, driver) come from the `counterparty_contact`
/// RPC: RLS hides other people's `User` rows, so a plain embed would null out.
void register() {
  GatewayRouter.get('/rides/user/:userId', _ridesForUser);
  GatewayRouter.get('/rides/:rideId', _rideDetail);
  GatewayRouter.post('/rides', _createRide);

  GatewayRouter.get('/appointments/home-care/:userId', _homeCareAppointments);
  GatewayRouter.get('/appointments/:userId', _appointmentsForUser);
  GatewayRouter.post('/appointments/home-care', _createHomeCareAppointment);
  GatewayRouter.post('/appointments', _createAppointment);
  GatewayRouter.patch(
    '/appointments/:appointmentId/status',
    _appointmentStatus,
  );

  // Orders — register the literal segments before `/:userId` shapes.
  GatewayRouter.get('/orders/detail/:orderId', _orderDetail);
  GatewayRouter.get('/orders/hotel-bookings/:bookingId', _hotelBookingDetail);
  GatewayRouter.post('/orders/hotel-bookings', _createHotelBooking);
  GatewayRouter.post('/orders/pharmacy-prescription', _pharmacyPrescription);
  GatewayRouter.post('/orders', _createOrder);
  GatewayRouter.get('/orders/:userId', _ordersHistory);

  // Parcels.
  GatewayRouter.get('/parcels/pricing', _parcelPricing);
  GatewayRouter.get('/parcels/user/:userId', _parcelsForUser);
  GatewayRouter.post('/parcels', _createParcel);
  GatewayRouter.post('/parcels/:parcelId/cancel', _cancelParcel);

  // Car rentals — the availability/user routes are longer shapes and must
  // register before `/car-rentals/:carId` could shadow them… they differ in
  // length so no shadowing, but keep the order readable.
  GatewayRouter.get('/car-rentals/bookings/availability', _availability);
  GatewayRouter.get('/car-rentals/bookings/user/:userId', _rentalBookingsForUser);
  GatewayRouter.post('/car-rentals/bookings/:bookingId/cancel', _cancelRentalBooking);
  GatewayRouter.post('/car-rentals/bookings', _createRentalBooking);
  GatewayRouter.get('/car-rentals/:carId', _rentalCarDetail);
  GatewayRouter.get('/car-rentals', _rentalCars);
}

const String _rideSelect =
    '*,'
    'user:User!RideBooking_userId_fkey(firstName,lastName,phone),'
    'rideCategory:RideCategory(id,name,description,capacity,basePrice,'
    'pricePerKm,etaLabel),'
    'paymentMethod:PaymentMethod(brand,last4,type),'
    'pickupAddress:Address!RideBooking_pickupAddressId_fkey(id,label,line1),'
    'dropoffAddress:Address!RideBooking_dropoffAddressId_fkey(id,label,line1)';

const String _appointmentSelect = '*,doctor:Doctor(id,name)';

// ── Shared helpers ──────────────────────────────────────────────────────────

num? _num(dynamic value) {
  if (value == null) return null;
  final parsed = value is num ? value : num.tryParse(value.toString());
  if (parsed == null) return null;
  if (parsed is double && parsed == parsed.roundToDouble()) {
    return parsed.toInt();
  }
  return parsed;
}

Map<String, dynamic>? _asMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

/// Mirrors `isModuleEnabled` + `moduleName`: a disabled module rejects the
/// booking with 403 before anything is written.
Future<void> _requireModule(String moduleType, String label) async {
  final rows = await SupabaseGateway.table('AppModule')
      .select('active')
      .eq('moduleType', moduleType)
      .limit(1);
  final active = rows.isNotEmpty ? rows.first['active'] == true : true;
  if (!active) {
    throw GatewayError('$label module is currently disabled.', status: 403);
  }
}

/// The actor's email, used in the admin-facing copy exactly like the
/// backend's `actorEmailFor`.
Future<String> _actorLabel(String userId) async {
  try {
    final rows = await SupabaseGateway.table('User')
      .select('email')
      .eq('id', userId)
      .limit(1);
    final email = rows.isNotEmpty ? (rows.first['email'] ?? '').toString() : '';
    return email.isEmpty ? 'A customer' : email;
  } catch (_) {
    return 'A customer';
  }
}

/// A failed notification must not roll back a booking the customer already
/// made — the backend isolated admin fan-out failures the same way.
Future<void> _bestEffort(Future<void> Function() action, String what) async {
  try {
    await action();
  } catch (error) {
    debugPrint('Notification skipped ($what): $error');
  }
}

// ── Rides ───────────────────────────────────────────────────────────────────

Map<String, dynamic> _serializeRide(Map<String, dynamic> booking) {
  final user = _asMap(booking['user']);
  final paymentMethod = _asMap(booking['paymentMethod']);
  final category = _asMap(booking['rideCategory']);
  final pickup = _asMap(booking['pickupAddress']);
  final dropoff = _asMap(booking['dropoffAddress']);

  final customerName =
      '${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}'.trim();

  String? paymentLabel;
  if (paymentMethod != null) {
    final brand = paymentMethod['brand'];
    final last4 = paymentMethod['last4'];
    paymentLabel = (brand != null &&
            brand.toString().isNotEmpty &&
            last4 != null &&
            last4.toString().isNotEmpty)
        ? '$brand •••• $last4'
        : paymentMethod['type']?.toString().toLowerCase();
  }

  return <String, dynamic>{
    'id': booking['id'],
    'userId': booking['userId'],
    'driverUserId': booking['driverUserId'],
    'rideCategoryId': booking['rideCategoryId'],
    'status': booking['status']?.toString().toLowerCase(),
    'pickup': booking['pickupLabel'],
    'destination': booking['dropoffLabel'],
    'distanceKm': _num(booking['distanceKm']),
    'estimatedFare': _num(booking['estimatedFare']),
    'tax': _num(booking['tax']),
    'total': _num(booking['total']),
    'eta': booking['etaLabel'],
    'vehicle': booking['vehicleName'],
    'driverName': booking['driverName'],
    'driverPhone': booking['driverPhone'],
    'customerName': customerName.isEmpty ? null : customerName,
    'customerPhone': user?['phone'],
    'paymentMethod': paymentLabel,
    'rideCategory': category == null
        ? null
        : <String, dynamic>{
            'id': category['id'],
            'name': category['name'],
            'description': category['description'],
            'capacity': category['capacity'],
            'basePrice': _num(category['basePrice']),
            'pricePerKm': _num(category['pricePerKm']),
            'etaLabel': category['etaLabel'],
          },
    'pickupAddress': pickup == null
        ? null
        : <String, dynamic>{
            'id': pickup['id'],
            'label': pickup['label'],
            'address': pickup['line1'],
          },
    'dropoffAddress': dropoff == null
        ? null
        : <String, dynamic>{
            'id': dropoff['id'],
            'label': dropoff['label'],
            'address': dropoff['line1'],
          },
    'trackingData': booking['trackingData'],
    'createdAt': booking['createdAt'],
    'updatedAt': booking['updatedAt'],
  };
}

Future<dynamic> _ridesForUser(GatewayRequest request) async {
  final userId = request.requireSegment(2, 'userId');
  final rows = await SupabaseGateway.table('RideBooking')
      .select(_rideSelect)
      .eq('userId', userId)
      .order('createdAt', ascending: false);
  return rows.map(_serializeRide).toList();
}

Future<dynamic> _rideDetail(GatewayRequest request) async {
  final rideId = request.requireSegment(1, 'rideId');
  final rows = await SupabaseGateway.table('RideBooking')
      .select(_rideSelect)
      .eq('id', rideId)
      .limit(1);
  if (rows.isEmpty) {
    throw const GatewayError('Ride booking not found.', status: 404);
  }
  return _serializeRide(rows.first);
}

Future<dynamic> _createRide(GatewayRequest request) async {
  final body = request.body ?? const <String, dynamic>{};

  String required(String key) {
    final value = body[key]?.toString().trim() ?? '';
    if (value.isEmpty) throw GatewayError('$key is required.');
    return value;
  }

  final userId = required('userId');
  final rideCategoryId = required('rideCategoryId');
  final pickupLabel = required('pickupLabel');
  final dropoffLabel = required('dropoffLabel');
  final vehicleName = required('vehicleName');

  num? amount(String key) {
    final raw = body[key];
    if (raw == null) return null;
    final parsed = raw is num ? raw : num.tryParse(raw.toString());
    return parsed;
  }

  final distance = amount('distanceKm');
  if (distance == null || distance <= 0) {
    throw const GatewayError('distanceKm must be a positive number.');
  }
  final estimatedFare = amount('estimatedFare') ?? 0;
  final tax = amount('tax') ?? 0;
  final total = amount('total') ?? 0;

  await _requireModule('RIDE', 'Ride');

  final created = await SupabaseGateway.table('RideBooking')
      .insert(<String, dynamic>{
        'userId': userId,
        'rideCategoryId': rideCategoryId,
        'paymentMethodId': body['paymentMethodId'],
        'pickupAddressId': body['pickupAddressId'],
        'dropoffAddressId': body['dropoffAddressId'],
        'pickupLabel': pickupLabel,
        'dropoffLabel': dropoffLabel,
        'distanceKm': distance,
        'estimatedFare': estimatedFare,
        'tax': tax,
        'total': total,
        'status': 'REQUESTED',
        'etaLabel': body['etaLabel'],
        'driverName': body['driverName'],
        'driverPhone': body['driverPhone'],
        'vehicleName': vehicleName,
        if (body['trackingData'] is Map) 'trackingData': body['trackingData'],
      })
      .select(_rideSelect)
      .single();

  final rideId = created['id'].toString();
  final actor = await _actorLabel(userId);

  // Admin inbox: "New ride requested".
  await _bestEffort(
    () => SupabaseGateway.notifyAdmins(
      title: 'New ride requested',
      body: pickupLabel.isNotEmpty
          ? '$actor requested a ride (pickup: $pickupLabel).'
          : '$actor requested a new ride.',
      module: 'RIDE',
      type: 'RIDE',
      route: '/pro/admin/rides',
      dedupeKey: 'ride-created:$rideId',
      metadata: {
        'rideId': rideId,
        'vehicleName': vehicleName,
        'pickupLabel': pickupLabel,
        'userId': userId,
      },
    ),
    'ride-created/admin',
  );

  // Rider's own inbox: "Ride confirmed".
  await _bestEffort(
    () => SupabaseGateway.createNotification(
      userId: userId,
      title: 'Ride confirmed',
      body: '$vehicleName is assigned and heading to $pickupLabel.',
      module: 'RIDE',
      type: 'RIDE',
      route: '/ride/tracking/$rideId',
      dedupeKey: 'ride:$rideId:/ride/tracking/$rideId',
      metadata: {
        'rideId': rideId,
        'vehicleName': vehicleName,
        'pickupLabel': pickupLabel,
      },
    ),
    'ride-created/self',
  );

  return _serializeRide(created);
}

// ── Appointments ────────────────────────────────────────────────────────────

const Set<String> _homeCareTypes = {
  'home_visit',
  'phone_advice',
  'video_support',
  'nursing_visit',
  'elderly_monitoring',
  'post_op_care',
};

bool _isHomeCare(dynamic raw) {
  final value = raw?.toString().trim().toLowerCase() ?? '';
  if (value.isEmpty) return false;
  return value.startsWith('home_') || _homeCareTypes.contains(value);
}

String _normalizeHomeCareType(dynamic raw) {
  final value = raw?.toString().trim().toLowerCase() ?? '';
  if (value.isEmpty) return 'home_visit';
  if (_isHomeCare(value)) return value;
  return 'home_$value';
}

String _serializeStatus(dynamic status) {
  final value = status?.toString() ?? '';
  return value == 'UPCOMING' ? 'pending' : value.toLowerCase();
}

Map<String, dynamic> _serializeAppointment(Map<String, dynamic> appointment) =>
    <String, dynamic>{
      'id': appointment['id'],
      'userId': appointment['userId'],
      'doctorId': appointment['doctorId'],
      'date': appointment['appointmentAt'],
      'timeSlot': appointment['timeSlot'],
      'type': appointment['appointmentType'],
      'status': _serializeStatus(appointment['status']),
      'notes': appointment['notes'],
      'createdAt': appointment['createdAt'],
      'updatedAt': appointment['updatedAt'],
      'isHomeCare': _isHomeCare(appointment['appointmentType']),
    };

Future<List<Map<String, dynamic>>> _loadAppointments(String userId) {
  return SupabaseGateway.table('Appointment')
      .select(_appointmentSelect)
      .eq('userId', userId)
      .order('appointmentAt', ascending: true);
}

Future<dynamic> _appointmentsForUser(GatewayRequest request) async {
  final userId = request.requireSegment(1, 'userId');
  return (await _loadAppointments(userId)).map(_serializeAppointment).toList();
}

Future<dynamic> _homeCareAppointments(GatewayRequest request) async {
  final userId = request.requireSegment(2, 'userId');
  final rows = await _loadAppointments(userId);
  return rows
      .where((row) => _isHomeCare(row['appointmentType']))
      .map(_serializeAppointment)
      .toList();
}

Future<Map<String, dynamic>> _createAppointmentRow({
  required String userId,
  required String doctorId,
  required String date,
  required String timeSlot,
  required String type,
  String? notes,
  bool homeCare = false,
}) async {
  await _requireModule('DOCTOR', 'Doctor');

  return SupabaseGateway.table('Appointment')
      .insert(<String, dynamic>{
        'userId': userId,
        'doctorId': doctorId,
        'appointmentAt': date,
        'timeSlot': timeSlot,
        'appointmentType': type,
        'status': 'PENDING',
        'notes': notes ??
            (homeCare ? 'Home care booking via EdaLab Super App' : null),
      })
      .select(_appointmentSelect)
      .single();
}

Future<void> _notifyAppointmentCreated(Map<String, dynamic> appointment) async {
  final userId = appointment['userId'].toString();
  final appointmentId = appointment['id'].toString();
  final doctor = _asMap(appointment['doctor']);
  final doctorName = doctor?['name']?.toString() ?? 'a doctor';
  final timeSlot = appointment['timeSlot']?.toString() ?? '';
  final actor = await _actorLabel(userId);

  await _bestEffort(
    () => SupabaseGateway.notifyAdmins(
      title: 'New appointment booked',
      body: '$actor booked an appointment with $doctorName at $timeSlot.',
      module: 'DOCTOR',
      type: 'APPOINTMENT',
      route: '/pro/admin/appointments',
      dedupeKey: 'appointment-created:$appointmentId',
      metadata: {
        'appointmentId': appointmentId,
        'doctorName': doctorName,
        'timeSlot': timeSlot,
        'userId': userId,
      },
    ),
    'appointment-created/admin',
  );

  await _bestEffort(
    () => SupabaseGateway.createNotification(
      userId: userId,
      title: 'Appointment booked',
      body: '$doctorName is scheduled for $timeSlot.',
      module: 'DOCTOR',
      type: 'APPOINTMENT',
      route: '/doctor/appointments',
      dedupeKey: 'appointment:$appointmentId:/doctor/appointments',
      metadata: {
        'appointmentId': appointmentId,
        'doctorName': doctorName,
        'timeSlot': timeSlot,
      },
    ),
    'appointment-created/self',
  );
}

Future<dynamic> _createAppointment(GatewayRequest request) async {
  final body = request.body ?? const <String, dynamic>{};

  String required(String key) {
    final value = body[key]?.toString().trim() ?? '';
    if (value.isEmpty) throw GatewayError('$key is required.');
    return value;
  }

  final appointment = await _createAppointmentRow(
    userId: required('userId'),
    doctorId: required('doctorId'),
    date: required('date'),
    timeSlot: required('timeSlot'),
    type: required('type'),
    notes: body['notes']?.toString(),
  );

  await _notifyAppointmentCreated(appointment);
  return _serializeAppointment(appointment);
}

Future<dynamic> _createHomeCareAppointment(GatewayRequest request) async {
  final body = request.body ?? const <String, dynamic>{};

  String required(String key) {
    final value = body[key]?.toString().trim() ?? '';
    if (value.isEmpty) throw GatewayError('$key is required.');
    return value;
  }

  final appointment = await _createAppointmentRow(
    userId: required('userId'),
    doctorId: required('doctorId'),
    date: required('date'),
    timeSlot: required('timeSlot'),
    type: _normalizeHomeCareType(body['type']),
    notes: body['notes']?.toString(),
    homeCare: true,
  );

  await _notifyAppointmentCreated(appointment);
  return _serializeAppointment(appointment);
}

// ── Shared helpers for the order domain ──────────────────────────────────────

const Map<String, String> _moduleNames = {
  'SHOPPING': 'Shopping',
  'FOOD': 'Food',
  'DOCTOR': 'Doctor',
  'HOTEL': 'Hotel',
  'RIDE': 'Ride',
  'PARCEL': 'Parcel Delivery',
  'PHARMACY': 'Pharmacy',
  'GROCERY': 'Grocery',
  'HOME_SERVICES': 'Home Services',
  'LAUNDRY': 'Laundry',
  'HOUSE_HELP': 'Home Services', // canonicalized like the backend
  'HEALTH_SERVICES': 'HEALTH_SERVICES',
};

const Set<String> _moduleTypes = {
  'SHOPPING',
  'FOOD',
  'GROCERY',
  'PHARMACY',
  'DOCTOR',
  'HOTEL',
  'RIDE',
  'LAUNDRY',
  'HOME_SERVICES',
  'HOUSE_HELP',
  'HEALTH_SERVICES',
  'PARCEL',
};

String _moduleName(String moduleType) =>
    _moduleNames[moduleType] ?? moduleType;

/// `isModuleEnabledForZone`: the global `AppModule` switch first, then the
/// per-zone `ZoneModuleConfig` override when a zone key is supplied.
Future<void> _requireModuleZone(
  String moduleType,
  String label,
  String? zoneKey,
) async {
  await _requireModule(moduleType, label);
  final zone = zoneKey?.trim();
  if (zone == null || zone.isEmpty) return;

  final zones = await SupabaseGateway.table('ServiceZone')
      .select('id')
      .eq('zoneKey', zone)
      .limit(1);
  if (zones.isEmpty) return;

  final canonical = moduleType == 'HOUSE_HELP' ? 'HOME_SERVICES' : moduleType;
  final configs = await SupabaseGateway.table('ZoneModuleConfig')
      .select('active')
      .eq('zoneId', zones.first['id'].toString())
      .eq('moduleType', canonical)
      .limit(1);
  if (configs.isNotEmpty && configs.first['active'] != true) {
    throw GatewayError('$label module is currently disabled.', status: 403);
  }
}

String? _nonEmpty(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((entry) => entry?.toString() ?? '')
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

/// `enrichOrderItemMetadata` — folds shop/product/medicine identity into the
/// item metadata so screens read one flat record, exactly like Prisma did.
Map<String, dynamic> _enrichItemMetadata(Map<String, dynamic> item) {
  final metadata = <String, dynamic>{
    if (item['metadata'] is Map) ...Map<String, dynamic>.from(item['metadata']),
  };

  final product = _asMap(item['product']);
  final shop = _asMap(product?['shop']);
  if (shop != null) {
    metadata['shopId'] ??= shop['id'];
    metadata['shopName'] ??= shop['name'];
    metadata['shopSlug'] ??= shop['slug'];
  }
  if (product != null) {
    metadata['productName'] ??= product['name'];
    metadata['productDescription'] ??= product['description'];
    final image = _stringList(product['imageUrlsJson']).firstOrNull;
    if (image != null) metadata['productImage'] ??= image;
  }

  final medicine = _asMap(item['medicine']);
  if (medicine != null) {
    final pharmacyName = _asMap(medicine['pharmacy'])?['name'];
    metadata['sourceBusiness'] ??= pharmacyName;
    metadata['shopName'] ??= pharmacyName;
    metadata['productName'] ??= medicine['name'];
    metadata['productDescription'] ??= medicine['description'];
    final image = _stringList(medicine['imageUrlsJson']).firstOrNull;
    if (image != null) metadata['productImage'] ??= image;
  }

  return metadata;
}

/// `resolveOrderModuleName` — shopping orders take the shop name, everything
/// else falls back to brand → item name → lowercase module type.
String _resolveOrderModuleName(
  String moduleType,
  List<Map<String, dynamic>> items,
) {
  if (moduleType == 'SHOPPING') {
    for (final item in items) {
      final metadata = _enrichItemMetadata(item);
      final shopName = _nonEmpty(metadata['shopName']);
      if (shopName != null) return shopName;
      final shop = _asMap(_asMap(item['product'])?['shop']);
      final productName = _nonEmpty(shop?['name']);
      if (productName != null) return productName;
    }
  }
  return _nonEmpty(items.isEmpty ? null : items.first['brand']) ??
      _nonEmpty(items.isEmpty ? null : items.first['name']) ??
      moduleType.toLowerCase();
}

String? _firstMetadataString(Map<String, dynamic>? metadata, String key) {
  if (metadata == null) return null;
  return metadata[key] is String ? metadata[key] as String : null;
}

const String _orderItemSelect =
    '*,product:Product(id,name,description,imageUrlsJson,'
    'shop:ShoppingStore(id,name,slug)),'
    'medicine:Medicine(id,name,description,imageUrlsJson,'
    'pharmacy:Pharmacy(id,name))';

const String _orderSelect =
    '*,items:OrderItem($_orderItemSelect),'
    'user:User!Order_userId_fkey(firstName,lastName,phone)';

Map<String, dynamic> _serializeOrderItem(Map<String, dynamic> item) =>
    <String, dynamic>{
      'id': item['id'],
      'productId': item['productId'],
      'externalRefId': item['externalRefId'],
      'name': item['name'],
      'brand': item['brand'],
      'quantity': item['quantity'],
      'price': _num(item['unitPrice']),
      'total': _num(item['lineTotal']),
      'color': item['color'],
      'size': item['size'],
      'metadata': _enrichItemMetadata(item),
    };

/// `deliveryAssignee` by RPC: RLS hides other people's `User` rows, so the
/// backend's embed would come back null for the courier/driver.
Future<Map<String, dynamic>?> _counterparty(String? userId) async {
  if (userId == null || userId.isEmpty) return null;
  try {
    final result = await SupabaseGateway.rpc(
      'counterparty_contact',
      params: {'p_user_id': userId},
    );
    return _asMap(result);
  } catch (error) {
    debugPrint('counterparty_contact skipped: $error');
    return null;
  }
}

// ── Order notifications (mirrors utils/notifications.ts) ───────────────────

Future<void> _customerOrderNotification({
  required String userId,
  required String orderId,
  required String moduleType,
  String? moduleName,
}) async {
  final detail = (moduleName ?? '').trim();

  String title;
  String body;
  String module;
  String type;
  String route;

  switch (moduleType) {
    case 'FOOD':
      title = 'Food order confirmed';
      body = detail.isEmpty
          ? 'Your food order is confirmed and the kitchen has started preparing it.'
          : 'Your order from $detail is confirmed and already being prepared.';
      module = 'FOOD';
      type = 'ORDER';
      route = '/food/tracking/$orderId';
    case 'HOTEL':
      title = 'Hotel stay confirmed';
      body = detail.isEmpty
          ? 'Your hotel booking is confirmed.'
          : '$detail is booked and confirmed.';
      module = 'HOTEL';
      type = 'ORDER';
      route = '/hotel/order/$orderId';
    case 'HOME_SERVICES':
      title = 'Home service scheduled';
      body = detail.isEmpty
          ? 'Your home service booking is confirmed.'
          : '$detail has been scheduled successfully.';
      module = 'HOME_SERVICES';
      type = 'SYSTEM';
      route = '/home-services/booking/$orderId';
    case 'HOUSE_HELP':
      title = 'House help scheduled';
      body = detail.isEmpty
          ? 'Your house help booking is confirmed.'
          : '$detail has been scheduled successfully.';
      module = 'HOME_SERVICES';
      type = 'SYSTEM';
      route = '/home-services/booking/$orderId';
    case 'LAUNDRY':
      title = 'Laundry pickup scheduled';
      body = detail.isEmpty
          ? 'Your laundry order is scheduled and we will keep you updated.'
          : '$detail is scheduled for pickup.';
      module = 'LAUNDRY';
      type = 'LAUNDRY';
      route = '/laundry/tracking/$orderId';
    case 'SHOPPING':
      title = 'Shopping order confirmed';
      body = detail.isEmpty
          ? 'Your shopping order is confirmed and will move through fulfillment shortly.'
          : '$detail is confirmed and will move through fulfillment shortly.';
      module = 'SHOPPING';
      type = 'ORDER';
      route = '/shopping/order/$orderId';
    case 'GROCERY':
      title = 'Grocery order confirmed';
      body = detail.isEmpty
          ? 'Your grocery order is confirmed and the store is preparing your items.'
          : '$detail is confirmed and the store is preparing your items.';
      module = 'GROCERY';
      type = 'ORDER';
      route = '/orders';
    case 'PHARMACY':
      title = 'Pharmacy order confirmed';
      body = detail.isEmpty
          ? 'Your pharmacy order is confirmed. Double-check the medicines when they arrive.'
          : '$detail is confirmed. Double-check the medicines when they arrive.';
      module = 'PHARMACY';
      type = 'ORDER';
      route = '/pharmacy/order/$orderId';
    default:
      return; // DOCTOR / RIDE notify through their own helpers (already ported).
  }

  await SupabaseGateway.createNotification(
    userId: userId,
    title: title,
    body: body,
    module: module,
    type: type,
    route: route,
    dedupeKey: 'order:$orderId:$route',
    metadata: {'orderId': orderId, 'moduleType': moduleType, 'moduleName': detail},
  );
}

Future<void> _adminOrderNotification({
  required String userId,
  required String orderId,
  required String moduleType,
  String? moduleName,
}) async {
  final detail = (moduleName ?? '').trim();
  // Booking modules use their own title, so the raw lowercase module type
  // only reaches the copy for plain orders — same as the backend.
  final label = moduleType.toLowerCase();
  final isBooking = moduleType == 'HOTEL' ||
      moduleType == 'HOME_SERVICES' ||
      moduleType == 'HOUSE_HELP';
  final actor = await _actorLabel(userId);

  final title = isBooking
      ? (moduleType == 'HOTEL' ? 'New hotel booking' : 'New service booking')
      : 'New $label order';
  final body = detail.isNotEmpty
      ? '$actor placed an order at $detail.'
      : '$actor placed a new $label ${isBooking ? 'booking' : 'order'}.';

  await SupabaseGateway.notifyAdmins(
    title: title,
    body: body,
    module: 'ORDERS',
    type: 'ORDER',
    route: '/pro/admin/orders',
    dedupeKey: 'order-created:$orderId',
    metadata: {
      'orderId': orderId,
      'moduleType': moduleType,
      'moduleName': detail.isEmpty ? null : detail,
      'userId': userId,
      'source': 'order_created',
    },
  );
}

/// `createOrderCreatedNotification`: customer inbox + admin fan-out (the
/// backend skipped the admin pass for DOCTOR/RIDE — those notify themselves).
Future<void> _notifyOrderCreated({
  required String userId,
  required String orderId,
  required String moduleType,
  String? moduleName,
}) async {
  await _bestEffort(
    () => _customerOrderNotification(
      userId: userId,
      orderId: orderId,
      moduleType: moduleType,
      moduleName: moduleName,
    ),
    'order-created/self',
  );
  if (moduleType == 'DOCTOR' || moduleType == 'RIDE') return;
  await _bestEffort(
    () => _adminOrderNotification(
      userId: userId,
      orderId: orderId,
      moduleType: moduleType,
      moduleName: moduleName,
    ),
    'order-created/admin',
  );
}

Future<void> _fanOutProviders({
  required String orderId,
  required String moduleType,
  required List<Map<String, dynamic>> items,
}) async {
  final firstMetadata =
      items.isEmpty ? <String, dynamic>{} : _enrichItemMetadata(items.first);
  final firstItem = items.isEmpty ? null : items.first;

  if (moduleType == 'HOME_SERVICES' || moduleType == 'HOUSE_HELP') {
    final pool = _stringList(firstMetadata['providerPoolIds']);
    final metadataProvider =
        _nonEmpty(firstMetadata['providerId']) ?? '';
    final direct =
        _nonEmpty(firstItem?['externalRefId']) ?? metadataProvider;
    final targets = <String>{
      if (direct.isNotEmpty) direct,
      ...pool,
    }.toList();

    final raw = await SupabaseGateway.rpc(
      'resolve_bound_profile_user_ids',
      params: {
        'p_type': 'PROVIDER',
        'p_binding_key': 'providerIds',
        'p_targets': targets,
        'p_active_module': 'SERVICES',
      },
    );
    final houseHelp = moduleType == 'HOUSE_HELP';
    for (final entry in (raw is List ? raw : const [])) {
      final recipient = entry?.toString() ?? '';
      if (recipient.isEmpty) continue;
      await _bestEffort(
        () => SupabaseGateway.createNotification(
          userId: recipient,
          title: houseHelp
              ? 'New house-help request'
              : 'New home-service request',
          body: houseHelp
              ? 'A nearby house-help booking is waiting for provider action.'
              : 'A new service booking is waiting for provider action.',
          module: 'HOME_SERVICES',
          type: 'SYSTEM',
          route: '/pro/provider/job/$orderId',
          dedupeKey: 'provider-request:$orderId:$recipient',
          metadata: {
            'orderId': orderId,
            'moduleType': moduleType,
            'source': 'order_created',
            'queueType': pool.isNotEmpty ? 'open' : 'assigned',
          },
        ),
        'order-fanout/provider',
      );
    }
  }

  if (moduleType == 'LAUNDRY') {
    final target = _nonEmpty(firstItem?['externalRefId']) ??
        _nonEmpty(firstMetadata['serviceId']) ??
        '';
    if (target.isEmpty) return;
    final raw = await SupabaseGateway.rpc(
      'resolve_bound_profile_user_ids',
      params: {
        'p_type': 'PROVIDER',
        'p_binding_key': 'laundryServiceIds',
        'p_targets': [target],
        'p_active_module': 'LAUNDRY',
      },
    );
    for (final entry in (raw is List ? raw : const [])) {
      final recipient = entry?.toString() ?? '';
      if (recipient.isEmpty) continue;
      await _bestEffort(
        () => SupabaseGateway.createNotification(
          userId: recipient,
          title: 'New laundry pickup request',
          body: 'A new laundry order is waiting for provider action.',
          module: 'LAUNDRY',
          type: 'SYSTEM',
          route: '/pro/provider/job/$orderId',
          dedupeKey: 'provider-laundry:$orderId:$recipient',
          metadata: {
            'orderId': orderId,
            'moduleType': moduleType,
            'source': 'order_created',
            'laundryServiceId': target,
          },
        ),
        'order-fanout/laundry',
      );
    }
  }
}

// ── GET /orders/:userId — merged history ────────────────────────────────────

const Set<String> _completedOrderStatuses = {'COMPLETED', 'CANCELLED', 'REFUNDED'};

Future<dynamic> _ordersHistory(GatewayRequest request) async {
  final userId = request.requireSegment(1, 'userId');

  final results = await Future.wait([
    SupabaseGateway.table('Order')
        .select('*,items:OrderItem($_orderItemSelect)')
        .eq('userId', userId),
    SupabaseGateway.table('Appointment')
        .select('*,doctor:Doctor(id,name,specialty,consultationFee)')
        .eq('userId', userId),
    SupabaseGateway.table('RideBooking')
        .select('*,rideCategory:RideCategory(id,name)')
        .eq('userId', userId),
    SupabaseGateway.table('HotelBooking')
        .select('*,hotel:Hotel(id,name)')
        .eq('userId', userId),
    SupabaseGateway.table('LaundryOrder')
        .select('*,service:LaundryService(id,name)')
        .eq('userId', userId),
  ]);

  final orders = results[0];
  final appointments = results[1];
  final rides = results[2];
  final hotels = results[3];
  final laundries = results[4];

  // Courier names for assigned deliveries (RLS hides the embed).
  final deliveryIds = <String>{};
  for (final order in orders) {
    final id = _nonEmpty(order['deliveryUserId']);
    if (id != null) deliveryIds.add(id);
  }
  final contacts = <String, Map<String, dynamic>?>{};
  for (final id in deliveryIds) {
    contacts[id] = await _counterparty(id);
  }

  final history = <Map<String, dynamic>>[
    for (final order in orders)
      () {
        final items =
            (order['items'] as List? ?? const [])
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
        final firstMetadata =
            items.isEmpty ? null : _enrichItemMetadata(items.first);
        final deliveryUserId = _nonEmpty(order['deliveryUserId']);
        final contact =
            deliveryUserId == null ? null : contacts[deliveryUserId];
        final status = order['status']?.toString() ?? '';
        return <String, dynamic>{
          'id': order['id'],
          'entryType': 'ORDER',
          'userId': order['userId'],
          'moduleType': order['moduleType'],
          'moduleName':
              _resolveOrderModuleName(order['moduleType'].toString(), items),
          'status': status,
          'subtotal': _num(order['subtotal']),
          'tax': _num(order['tax']),
          'deliveryFee': _num(order['deliveryFee']),
          'discount': _num(order['discount']),
          'total': _num(order['total']),
          'createdAt': order['createdAt'],
          'updatedAt': order['updatedAt'],
          'address': _firstMetadataString(firstMetadata, 'address'),
          'deliveryLabel': _firstMetadataString(firstMetadata, 'deliveryLabel'),
          'deliveryEta': _firstMetadataString(firstMetadata, 'deliveryEta'),
          'paymentLabel': _firstMetadataString(firstMetadata, 'paymentLabel'),
          'deliveryAssigneeName': contact?['name'],
          'deliveryAssigneePhone': contact?['phone'],
          'trackingRoute': order['moduleType'] == 'FOOD' &&
                  !_completedOrderStatuses.contains(status)
              ? '/food/tracking/${order['id']}'
              : null,
          'items': items.map(_serializeOrderItem).toList(),
        };
      }(),
    for (final appointment in appointments)
      <String, dynamic>{
        'id': appointment['id'],
        'entryType': 'APPOINTMENT',
        'userId': appointment['userId'],
        'moduleType': 'DOCTOR',
        'moduleName':
            _asMap(appointment['doctor'])?['name'] ?? 'Doctor',
        'status': appointment['status'],
        'subtotal': _num(_asMap(appointment['doctor'])?['consultationFee']) ?? 0,
        'tax': 0,
        'deliveryFee': 0,
        'discount': 0,
        'total': _num(_asMap(appointment['doctor'])?['consultationFee']) ?? 0,
        'createdAt': appointment['createdAt'],
        'updatedAt': appointment['updatedAt'],
        'trackingRoute': '/doctor/appointments',
        'items': [
          <String, dynamic>{
            'id': appointment['id'],
            'name': switch (appointment['appointmentType']) {
              'in_person' => 'In-person consultation',
              'video' => 'Video consultation',
              'chat' => 'Chat consultation',
              _ => 'Consultation',
            },
            'quantity': 1,
            'price':
                _num(_asMap(appointment['doctor'])?['consultationFee']) ?? 0,
            'total':
                _num(_asMap(appointment['doctor'])?['consultationFee']) ?? 0,
            'metadata': {
              'doctorId': appointment['doctorId'],
              'specialty': _asMap(appointment['doctor'])?['specialty'],
              'date': appointment['appointmentAt'],
              'timeSlot': appointment['timeSlot'],
            },
          },
        ],
      },
    for (final ride in rides)
      <String, dynamic>{
        'id': ride['id'],
        'entryType': 'RIDE_BOOKING',
        'userId': ride['userId'],
        'moduleType': 'RIDE',
        'moduleName': _asMap(ride['rideCategory'])?['name'] ?? 'Ride',
        'status': ride['status'],
        'subtotal': _num(ride['estimatedFare']),
        'tax': _num(ride['tax']),
        'deliveryFee': 0,
        'discount': 0,
        'total': _num(ride['total']),
        'createdAt': ride['createdAt'],
        'updatedAt': ride['updatedAt'],
        'trackingRoute': const {'COMPLETED', 'CANCELLED'}
                    .contains(ride['status']?.toString())
                ? null
                : '/ride/tracking/${ride['id']}',
        'items': [
          <String, dynamic>{
            'id': ride['id'],
            'name': ride['vehicleName'],
            'quantity': 1,
            'price': _num(ride['estimatedFare']) ?? 0,
            'total': _num(ride['total']) ?? 0,
            'metadata': {
              'pickup': ride['pickupLabel'],
              'destination': ride['dropoffLabel'],
              'eta': ride['etaLabel'],
              'distanceKm': _num(ride['distanceKm']),
            },
          },
        ],
      },
    for (final booking in hotels)
      <String, dynamic>{
        'id': booking['id'],
        'entryType': 'HOTEL_BOOKING',
        'userId': booking['userId'],
        'moduleType': 'HOTEL',
        'moduleName': _asMap(booking['hotel'])?['name'] ?? 'Hotel',
        'status': booking['status'] == 'CHECKED_OUT'
            ? 'COMPLETED'
            : booking['status'],
        'subtotal': _num(booking['subtotal']),
        'tax': _num(booking['tax']),
        'deliveryFee': _num(booking['serviceFee']),
        'discount': 0,
        'total': _num(booking['total']),
        'createdAt': booking['createdAt'],
        'updatedAt': booking['updatedAt'],
        'trackingRoute': '/hotel/order/${booking['id']}',
        'items': [
          <String, dynamic>{
            'id': booking['id'],
            'name': booking['roomType'],
            'quantity': booking['nights'],
            'price': _num(booking['subtotal']) ?? 0,
            'total': _num(booking['total']) ?? 0,
            'metadata': {
              'hotelId': booking['hotelId'],
              'checkInAt': booking['checkInAt'],
              'checkOutAt': booking['checkOutAt'],
              'guestCount': booking['guestCount'],
            },
          },
        ],
      },
    for (final laundry in laundries)
      <String, dynamic>{
        'id': laundry['id'],
        'entryType': 'LAUNDRY_ORDER',
        'userId': laundry['userId'],
        'moduleType': 'LAUNDRY',
        'moduleName': _asMap(laundry['service'])?['name'] ?? 'Laundry',
        'status': _mapLaundryStatus(laundry['status']),
        'subtotal': _num(laundry['subtotal']),
        'tax': _num(laundry['tax']),
        'deliveryFee': 0,
        'discount': 0,
        'total': _num(laundry['total']),
        'createdAt': laundry['createdAt'],
        'updatedAt': laundry['updatedAt'],
        'trackingRoute': '/laundry/tracking/${laundry['id']}',
        'items': [
          <String, dynamic>{
            'id': laundry['id'],
            'name': _asMap(laundry['service'])?['name'] ?? 'Laundry',
            'quantity': laundry['itemCount'],
            'price': _num(laundry['subtotal']) ?? 0,
            'total': _num(laundry['total']) ?? 0,
            'metadata': {
              'pickupAt': laundry['pickupAt'],
              'timeSlot': laundry['timeSlot'],
              'itemBreakdown': laundry['itemBreakdown'],
            },
          },
        ],
      },
  ]
    ..sort((a, b) {
      final left = DateTime.tryParse(a['createdAt']?.toString() ?? '')
          ?.millisecondsSinceEpoch ??
          0;
      final right = DateTime.tryParse(b['createdAt']?.toString() ?? '')
          ?.millisecondsSinceEpoch ??
          0;
      return right.compareTo(left);
    });

  return history;
}

String _mapLaundryStatus(dynamic status) => switch (status.toString()) {
  'SCHEDULED' => 'CONFIRMED',
  'PICKED_UP' || 'CLEANING' => 'PROCESSING',
  'OUT_FOR_DELIVERY' => 'IN_PROGRESS',
  'COMPLETED' => 'COMPLETED',
  'CANCELLED' => 'CANCELLED',
  'PENDING' => 'PENDING',
  _ => status.toString(),
};

// ── GET /orders/detail/:orderId ──────────────────────────────────────────────

Map<String, dynamic> _serializeOrderDetail(
  Map<String, dynamic> order, {
  required Map<String, dynamic>? contact,
}) {
  final user = _asMap(order['user']);
  final customerLabel =
      '${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}'.trim();
  final items = (order['items'] as List? ?? const [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  final firstMetadata = items.isEmpty ? null : _enrichItemMetadata(items.first);

  return <String, dynamic>{
    'id': order['id'],
    'userId': order['userId'],
    'moduleType': order['moduleType'],
    'moduleName': _resolveOrderModuleName(order['moduleType'].toString(), items),
    'status': order['status'],
    'subtotal': _num(order['subtotal']),
    'tax': _num(order['tax']),
    'deliveryFee': _num(order['deliveryFee']),
    'discount': _num(order['discount']),
    'total': _num(order['total']),
    'createdAt': order['createdAt'],
    'updatedAt': order['updatedAt'],
    'customerName': customerLabel.isEmpty ? null : customerLabel,
    'customerPhone': user?['phone'],
    'address': _firstMetadataString(firstMetadata, 'address'),
    'deliveryLabel': _firstMetadataString(firstMetadata, 'deliveryLabel'),
    'deliveryEta': _firstMetadataString(firstMetadata, 'deliveryEta'),
    'notes': order['notes'],
    'deliveryAssignee': contact == null
        ? null
        : {'userId': contact['id'], 'name': contact['name'], 'phone': contact['phone']},
    'items': items.map(_serializeOrderItem).toList(),
  };
}

Future<dynamic> _orderDetail(GatewayRequest request) async {
  final orderId = request.requireSegment(1, 'orderId');

  final rows = await SupabaseGateway.table('Order')
      .select(_orderSelect)
      .eq('id', orderId)
      .limit(1);

  if (rows.isEmpty) {
    // Fallback: legacy laundry orders have their own table.
    final laundries = await SupabaseGateway.table('LaundryOrder')
      .select(
        '*,service:LaundryService(id,name),address:Address(id,line1),'
        'user:User!LaundryOrder_userId_fkey(firstName,lastName,phone)',
      )
      .eq('id', orderId)
      .limit(1);
    if (laundries.isEmpty) {
      throw const GatewayError('Order not found.', status: 404);
    }
    return _serializeLaundryDetail(laundries.first);
  }

  final order = rows.first;
  final contact = await _counterparty(_nonEmpty(order['deliveryUserId']));
  return _serializeOrderDetail(order, contact: contact);
}

Map<String, dynamic> _serializeLaundryDetail(Map<String, dynamic> order) {
  final user = _asMap(order['user']);
  final service = _asMap(order['service']);
  final address = _asMap(order['address']);
  final customerLabel =
      '${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}'.trim();
  final pickupAt = order['pickupAt']?.toString();

  return <String, dynamic>{
    'id': order['id'],
    'userId': order['userId'],
    'moduleType': 'LAUNDRY',
    'moduleName': service?['name'] ?? 'Laundry',
    'status': _mapLaundryStatus(order['status']),
    'subtotal': _num(order['subtotal']),
    'tax': _num(order['tax']),
    'deliveryFee': 0,
    'discount': 0,
    'total': _num(order['total']),
    'createdAt': order['createdAt'],
    'updatedAt': order['updatedAt'],
    'customerName': customerLabel.isEmpty ? null : customerLabel,
    'customerPhone': user?['phone'],
    'address': address?['line1'],
    'deliveryLabel': '${order['timeSlot']} • $pickupAt',
    'deliveryEta': null,
    'notes': null,
    'deliveryAssignee': null,
    'items': [
      <String, dynamic>{
        'id': order['id'],
        'productId': null,
        'externalRefId': order['serviceId'],
        'name': service?['name'] ?? 'Laundry',
        'brand': null,
        'quantity': order['itemCount'],
        'price': _num(order['subtotal']),
        'total': _num(order['total']),
        'color': null,
        'size': null,
        'metadata': {
          'serviceId': order['serviceId'],
          'serviceName': service?['name'],
          'itemCount': order['itemCount'],
          'itemBreakdown': order['itemBreakdown'],
          'pickupAt': order['pickupAt'],
          'timeSlot': order['timeSlot'],
          'address': address?['line1'],
          'legacyLaundryOrder': true,
          'legacyLaundryStatus': order['status'],
        },
      },
    ],
  };
}

// ── POST /orders — checkout ──────────────────────────────────────────────────

const Set<String> _orderStatuses = {
  'DRAFT',
  'PENDING',
  'CONFIRMED',
  'PROCESSING',
  'DISPATCHED',
  'IN_PROGRESS',
  'COMPLETED',
  'CANCELLED',
  'REFUNDED',
};

Future<dynamic> _createOrder(GatewayRequest request) async {
  final body = request.body ?? const <String, dynamic>{};

  final userId = _nonEmpty(body['userId']);
  if (userId == null) throw const GatewayError('userId is required.');
  final moduleType = _nonEmpty(body['moduleType'])?.toUpperCase() ?? '';
  if (!_moduleTypes.contains(moduleType)) {
    throw const GatewayError('Invalid moduleType.');
  }
  final status =
      (_nonEmpty(body['status'])?.toUpperCase() ?? 'PENDING');
  if (!_orderStatuses.contains(status)) {
    throw const GatewayError('Invalid status.');
  }

  num requiredNum(String key) {
    final value = _num(body[key]);
    if (value == null) throw GatewayError('$key is required.');
    return value;
  }

  final subtotal = requiredNum('subtotal');
  final tax = requiredNum('tax');
  final total = requiredNum('total');
  final deliveryFee = _num(body['deliveryFee']) ?? 0;
  final discount = _num(body['discount']) ?? 0;
  final notes = _nonEmpty(body['notes']);
  final deferNotifications = body['deferNotifications'] == true;

  final rawItems = body['items'];
  final items = <Map<String, dynamic>>[];
  if (rawItems is List) {
    for (final entry in rawItems) {
      final item = _asMap(entry);
      if (item == null) continue;
      final name = _nonEmpty(item['name']);
      if (name == null) throw const GatewayError('name is required.');
      final price = _num(item['price']);
      if (price == null) throw const GatewayError('price is required.');
      final quantity = _num(item['quantity']);
      if (quantity == null || quantity <= 0 || quantity != quantity.round()) {
        throw const GatewayError('quantity must be a positive integer.');
      }
      final lineTotal = _num(item['total']) ?? price * quantity;
      items.add({
        if (moduleType == 'PHARMACY')
          'medicineId': item['productId']
        else
          'productId': item['productId'],
        'externalRefId': item['id'],
        'name': name,
        'brand': item['brand'],
        'quantity': quantity,
        'unitPrice': price,
        'lineTotal': lineTotal,
        'color': item['color'],
        'size': item['size'],
        if (item['metadata'] is Map) 'metadata': item['metadata'],
      });
    }
  }

  await _requireModule(
    moduleType,
    _moduleName(moduleType),
  );

  final created = await SupabaseGateway.table('Order')
      .insert(<String, dynamic>{
        'userId': userId,
        'moduleType': moduleType,
        'status': status,
        'subtotal': subtotal,
        'tax': tax,
        'deliveryFee': deliveryFee,
        'discount': discount,
        'total': total,
        'notes': ?notes,
        'items': items,
      })
      .select(_orderSelect)
      .single();

  final loadedItems = (created['items'] as List? ?? const [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  final moduleName =
      _resolveOrderModuleName(moduleType, loadedItems);

  if (!deferNotifications) {
    await _notifyOrderCreated(
      userId: userId,
      orderId: created['id'].toString(),
      moduleType: moduleType,
      moduleName: moduleName,
    );
    await _bestEffort(
      () => _fanOutProviders(
        orderId: created['id'].toString(),
        moduleType: moduleType,
        items: loadedItems,
      ),
      'order-fanout',
    );
  }

  return <String, dynamic>{
    'id': created['id'],
    'userId': created['userId'],
    'moduleType': created['moduleType'],
    'status': created['status'],
    'subtotal': _num(created['subtotal']),
    'tax': _num(created['tax']),
    'deliveryFee': _num(created['deliveryFee']),
    'discount': _num(created['discount']),
    'total': _num(created['total']),
    'createdAt': created['createdAt'],
    'updatedAt': created['updatedAt'],
    'items': [
      for (final item in loadedItems)
        <String, dynamic>{
          'id': item['id'],
          'name': item['name'],
          'quantity': item['quantity'],
          'price': _num(item['unitPrice']),
          'total': _num(item['lineTotal']),
          'metadata': _enrichItemMetadata(item),
        },
    ],
  };
}

// ── Hotel bookings ───────────────────────────────────────────────────────────

Map<String, dynamic> _serializeHotelBooking(
  Map<String, dynamic> booking, {
  required String hotelName,
}) {
  final status = booking['status'] == 'CHECKED_OUT'
      ? 'COMPLETED'
      : booking['status'];
  return <String, dynamic>{
    'id': booking['id'],
    'userId': booking['userId'],
    'hotelId': booking['hotelId'],
    'hotelName': hotelName,
    'moduleType': 'HOTEL',
    'status': status,
    'roomType': booking['roomType'],
    'guestName': booking['guestName'],
    'guestEmail': booking['guestEmail'],
    'guestPhone': booking['guestPhone'],
    'specialRequests': booking['specialRequests'],
    'checkInAt': booking['checkInAt'],
    'checkOutAt': booking['checkOutAt'],
    'nights': booking['nights'],
    'guestCount': booking['guestCount'],
    'subtotal': _num(booking['subtotal']),
    'serviceFee': _num(booking['serviceFee']),
    'tax': _num(booking['tax']),
    'total': _num(booking['total']),
    'createdAt': booking['createdAt'],
    'updatedAt': booking['updatedAt'],
    'items': [
      <String, dynamic>{
        'id': booking['id'],
        'name': booking['roomType'],
        'quantity': booking['nights'],
        'price': _num(booking['subtotal']) ?? 0,
        'total': _num(booking['total']) ?? 0,
        'metadata': {
          'hotelId': booking['hotelId'],
          'hotelName': hotelName,
          'checkInAt': booking['checkInAt'],
          'checkOutAt': booking['checkOutAt'],
          'guestCount': booking['guestCount'],
          'nights': booking['nights'],
        },
      },
    ],
  };
}

Future<dynamic> _hotelBookingDetail(GatewayRequest request) async {
  final bookingId = request.requireSegment(1, 'bookingId');
  final rows = await SupabaseGateway.table('HotelBooking')
      .select('*,hotel:Hotel(id,name)')
      .eq('id', bookingId)
      .limit(1);
  if (rows.isEmpty) {
    throw const GatewayError('Hotel booking not found.', status: 404);
  }
  final booking = rows.first;
  return _serializeHotelBooking(
    booking,
    hotelName: _asMap(booking['hotel'])?['name']?.toString() ?? 'Hotel',
  );
}

Future<dynamic> _createHotelBooking(GatewayRequest request) async {
  final body = request.body ?? const <String, dynamic>{};

  String required(String key) {
    final value = _nonEmpty(body[key]);
    if (value == null) throw GatewayError('$key is required.');
    return value;
  }

  final userId = required('userId');
  final hotelId = required('hotelId');
  final roomType = required('roomType');
  final guestName = required('guestName');
  final guestEmail = required('guestEmail');
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(guestEmail)) {
    throw const GatewayError('Invalid email address.');
  }

  final checkIn = DateTime.tryParse(body['checkInAt']?.toString() ?? '');
  final checkOut = DateTime.tryParse(body['checkOutAt']?.toString() ?? '');
  if (checkIn == null || checkOut == null) {
    throw const GatewayError('Invalid check-in or check-out date.');
  }
  if (!checkOut.isAfter(checkIn)) {
    throw const GatewayError('Check-out must be after check-in.');
  }

  int requiredInt(String key) {
    final value = _num(body[key]);
    if (value == null || value <= 0 || value != value.round()) {
      throw GatewayError('$key must be a positive integer.');
    }
    return value.toInt();
  }

  final nights = requiredInt('nights');
  final guestCount = requiredInt('guestCount');
  final subtotal = requiredNumBody(body, 'subtotal');
  final serviceFee = requiredNumBody(body, 'serviceFee');
  final tax = requiredNumBody(body, 'tax');
  final total = requiredNumBody(body, 'total');

  await _requireModule('HOTEL', 'Hotel');

  final hotels = await SupabaseGateway.table('Hotel')
      .select('id,name')
      .eq('id', hotelId)
      .limit(1);
  if (hotels.isEmpty) throw const GatewayError('Hotel not found.', status: 404);
  final hotelName = hotels.first['name']?.toString() ?? 'Hotel';

  final booking = await SupabaseGateway.table('HotelBooking')
      .insert(<String, dynamic>{
        'userId': userId,
        'hotelId': hotelId,
        'status': 'CONFIRMED',
        'roomType': roomType,
        'guestName': guestName,
        'guestEmail': guestEmail.toLowerCase(),
        'guestPhone': _nonEmpty(body['guestPhone']),
        'specialRequests': _nonEmpty(body['specialRequests']),
        'checkInAt': checkIn.toUtc().toIso8601String(),
        'checkOutAt': checkOut.toUtc().toIso8601String(),
        'nights': nights,
        'guestCount': guestCount,
        'subtotal': subtotal,
        'serviceFee': serviceFee,
        'tax': tax,
        'total': total,
      })
      .select('*,hotel:Hotel(id,name)')
      .single();

  await _notifyOrderCreated(
    userId: userId,
    orderId: booking['id'].toString(),
    moduleType: 'HOTEL',
    moduleName: hotelName,
  );

  return _serializeHotelBooking(booking, hotelName: hotelName);
}

num requiredNumBody(Map<String, dynamic> body, String key) {
  final value = _num(body[key]);
  if (value == null) throw GatewayError('$key is required.');
  return value;
}

// ── POST /orders/pharmacy-prescription ──────────────────────────────────────

Future<dynamic> _pharmacyPrescription(GatewayRequest request) async {
  final body = request.body ?? const <String, dynamic>{};

  final userId = _nonEmpty(body['userId']);
  if (userId == null) throw const GatewayError('userId is required.');
  final pharmacyName = _nonEmpty(body['pharmacyName']);
  if (pharmacyName == null || pharmacyName.length < 2) {
    throw const GatewayError('pharmacyName is required.');
  }
  final note = _nonEmpty(body['note']);
  final imageUrl = _nonEmpty(body['prescriptionImageUrl']);
  final address = _nonEmpty(body['address']);
  final latitude = _num(body['latitude']);
  final longitude = _num(body['longitude']);

  await _requireModule('PHARMACY', 'Pharmacy');

  final metadata = <String, dynamic>{
    'sourceBusiness': pharmacyName,
    'selectedPharmacy': pharmacyName,
    'prescriptionRequest': true,
    'prescriptionNote': note ?? '',
    'prescriptionImageUrl': ?imageUrl,
    'address': ?address,
    if (latitude != null && longitude != null)
      'serviceLocation': {'latitude': latitude, 'longitude': longitude},
    'uploadedAt': DateTime.now().toUtc().toIso8601String(),
  };

  final order = await SupabaseGateway.table('Order')
      .insert(<String, dynamic>{
        'userId': userId,
        'moduleType': 'PHARMACY',
        'status': 'PENDING',
        'subtotal': 0,
        'tax': 0,
        'deliveryFee': 0,
        'discount': 0,
        'total': 0,
        'notes': ?note,
        'items': [
          {
            'name': 'Prescription request',
            'brand': pharmacyName,
            'quantity': 1,
            'unitPrice': 0,
            'lineTotal': 0,
            'metadata': metadata,
          },
        ],
      })
      .select(_orderSelect)
      .single();
  final orderId = order['id'].toString();

  await _notifyOrderCreated(
    userId: userId,
    orderId: orderId,
    moduleType: 'PHARMACY',
    moduleName: pharmacyName,
  );

  // Shop queues bound to this pharmacy business name.
  await _bestEffort(
    () => _resolveThenNotifyPharmacy(orderId, pharmacyName),
    'pharmacy-rx/fanout',
  );

  final items = (order['items'] as List? ?? const [])
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  return _serializeOrderDetail(
    {...order, 'items': items},
    contact: null,
  );
}

Future<void> _resolveThenNotifyPharmacy(
  String orderId,
  String pharmacyName,
) async {
  final raw = await SupabaseGateway.rpc(
    'resolve_bound_profile_user_ids',
    params: {
      'p_type': 'SHOP',
      'p_binding_key': 'pharmacyBusinesses',
      'p_targets': [pharmacyName],
      'p_active_module': 'PHARMACY',
    },
  );
  for (final entry in (raw is List ? raw : const [])) {
    final recipient = entry?.toString() ?? '';
    if (recipient.isEmpty) continue;
    await SupabaseGateway.createNotification(
      userId: recipient,
      title: 'New prescription request',
      body: 'A customer uploaded a prescription request for $pharmacyName.',
      module: 'PHARMACY',
      type: 'SYSTEM',
      route: '/pro/shop/queue?module=pharmacy',
      dedupeKey: 'pharmacy-rx:$orderId:$recipient',
      metadata: {
        'orderId': orderId,
        'moduleType': 'PHARMACY',
        'source': 'pharmacy_prescription',
        'pharmacyName': pharmacyName,
        'prescriptionRequest': true,
      },
    );
  }
}

// ── Parcels ──────────────────────────────────────────────────────────────────

const Map<String, num> _parcelFees = {
  'SMALL': 500,
  'MEDIUM': 800,
  'LARGE': 1200,
};

Map<String, dynamic> _serializeParcel(
  Map<String, dynamic> parcel, {
  required Map<String, dynamic>? courier,
}) =>
    <String, dynamic>{
      'id': parcel['id'],
      'userId': parcel['userId'],
      'courierUserId': parcel['courierUserId'],
      'senderName': parcel['senderName'],
      'senderPhone': parcel['senderPhone'],
      'recipientName': parcel['recipientName'],
      'recipientPhone': parcel['recipientPhone'],
      'pickupAddress': parcel['pickupAddress'],
      'dropoffAddress': parcel['dropoffAddress'],
      'packageDescription': parcel['packageDescription'],
      'packageSize': parcel['packageSize'],
      'status': parcel['status'],
      'deliveryFee': _num(parcel['deliveryFee']),
      'currency': parcel['currency'],
      'notes': parcel['notes'],
      'courier': courier == null
          ? null
          : {'name': courier['name'], 'phone': courier['phone']},
      'createdAt': parcel['createdAt'],
      'updatedAt': parcel['updatedAt'],
    };

Future<dynamic> _parcelPricing(GatewayRequest request) async =>
    <String, dynamic>{'currency': 'DJF', 'fees': _parcelFees};

Future<dynamic> _parcelsForUser(GatewayRequest request) async {
  final userId = request.requireSegment(2, 'userId');
  final rows = await SupabaseGateway.table('ParcelDelivery')
      .select('*')
      .eq('userId', userId)
      .order('createdAt', ascending: false);

  final courierIds = <String>{};
  for (final row in rows) {
    final id = _nonEmpty(row['courierUserId']);
    if (id != null) courierIds.add(id);
  }
  final couriers = <String, Map<String, dynamic>?>{};
  for (final id in courierIds) {
    couriers[id] = await _counterparty(id);
  }

  return [
    for (final row in rows)
      _serializeParcel(
        row,
        courier: couriers[_nonEmpty(row['courierUserId'])],
      ),
  ];
}

Future<dynamic> _createParcel(GatewayRequest request) async {
  final body = request.body ?? const <String, dynamic>{};

  String required(String key, {int min = 1, int max = 10000}) {
    final value = body[key]?.toString().trim() ?? '';
    if (value.length < min) throw GatewayError('$key is required.');
    if (value.length > max) {
      throw GatewayError('$key must be at most $max characters.');
    }
    return value;
  }

  final userId = required('userId');
  final packageSize = required('packageSize').toUpperCase();
  final fee = _parcelFees[packageSize];
  if (fee == null) throw const GatewayError('Invalid packageSize.');

  await _requireModule('PARCEL', 'Parcel Delivery');

  final users = await SupabaseGateway.table('User')
      .select('id')
      .eq('id', userId)
      .limit(1);
  if (users.isEmpty) {
    throw const GatewayError('Customer account not found.', status: 404);
  }

  final parcel = await SupabaseGateway.table('ParcelDelivery')
      .insert(<String, dynamic>{
        'userId': userId,
        'senderName': required('senderName', min: 2, max: 120),
        'senderPhone': required('senderPhone', min: 5, max: 40),
        'recipientName': required('recipientName', min: 2, max: 120),
        'recipientPhone': required('recipientPhone', min: 5, max: 40),
        'pickupAddress': required('pickupAddress', min: 5, max: 300),
        'dropoffAddress': required('dropoffAddress', min: 5, max: 300),
        'packageDescription':
            required('packageDescription', min: 2, max: 300),
        'packageSize': packageSize,
        'deliveryFee': fee,
        'notes': _nonEmpty(body['notes']),
      })
      .select('*')
      .single();

  return _serializeParcel(parcel, courier: null);
}

Future<dynamic> _cancelParcel(GatewayRequest request) async {
  final parcelId = request.requireSegment(1, 'parcelId');
  final body = request.body ?? const <String, dynamic>{};
  final userId = _nonEmpty(body['userId']);
  if (userId == null) throw const GatewayError('userId is required.');

  final updated = await SupabaseGateway.table('ParcelDelivery')
      .update({'status': 'CANCELLED'})
      .eq('id', parcelId)
      .eq('userId', userId)
      .eq('status', 'REQUESTED')
      .select('id');

  if (updated.isEmpty) {
    throw const GatewayError(
      'Only unassigned parcel requests can be cancelled.',
      status: 409,
    );
  }
  return <String, dynamic>{'id': parcelId, 'status': 'CANCELLED'};
}

// ── Car rentals ──────────────────────────────────────────────────────────────

Map<String, dynamic> _serializeCar(Map<String, dynamic> product) {
  final metadata =
      product['metadata'] is Map
          ? Map<String, dynamic>.from(product['metadata'])
          : <String, dynamic>{};
  final images = _stringList(product['imageUrlsJson']);
  final tags = _stringList(product['tagsJson']);

  return <String, dynamic>{
    'id': product['id'],
    'name': product['name'],
    'type': _nonEmpty(metadata['type']) ??
        _nonEmpty(product['brand']) ??
        (tags.isNotEmpty ? tags.first : 'Standard'),
    'description': product['description'],
    'pricePerDay': _num(product['price']) ?? 0,
    'unit': product['unit'] ?? 'per day',
    'badge': product['badge'],
    'imageUrl': images.isEmpty ? null : images.first,
    'imageUrls': images,
    'features': _stringList(product['featuresJson']),
    'seats': _num(metadata['seats']) ?? 5,
    'transmission': _nonEmpty(metadata['transmission']) ?? 'Automatic',
    'fuelType': _nonEmpty(metadata['fuelType']) ?? 'Petrol',
    'year': _num(metadata['year']),
    'mileage': _nonEmpty(metadata['mileage']) ?? 'Unlimited',
    'available': product['inStock'] == true,
    'metadata': metadata,
  };
}

Map<String, dynamic> _serializeRentalBooking(Map<String, dynamic> booking) =>
    <String, dynamic>{
      'id': booking['id'],
      'userId': booking['userId'],
      'carId': booking['carId'],
      'carName': booking['carName'],
      'carType': booking['carType'],
      'startDate': booking['startDate'],
      'endDate': booking['endDate'],
      'totalDays': booking['totalDays'],
      'pricePerDay': _num(booking['pricePerDay']),
      'subtotal': _num(booking['subtotal']),
      'tax': _num(booking['tax']),
      'total': _num(booking['total']),
      'status': booking['status'],
      'pickupLocation': booking['pickupLocation'],
      'dropoffLocation': booking['dropoffLocation'],
      'notes': booking['notes'],
      'createdAt': booking['createdAt'],
      'updatedAt': booking['updatedAt'],
    };

Future<List<Map<String, dynamic>>> _rentalProducts() async {
  final rows = await SupabaseGateway.table('Product')
      .select('*')
      .eq('moduleType', 'RIDE')
      .eq('inStock', true)
      .order('price', ascending: true);
  return rows
      .where((row) {
        final metadata = row['metadata'];
        return metadata is Map && metadata['rentalCar'] == true;
      })
      .toList();
}

Future<void> _requireRideZone(String? zoneKey) =>
    _requireModuleZone('RIDE', 'Ride', zoneKey);

Future<dynamic> _rentalCars(GatewayRequest request) async {
  final zoneKey = await SupabaseGateway.resolveZoneKey(
    zone: request.optionalString('zone'),
    latitude: null,
    longitude: null,
  );
  await _requireRideZone(zoneKey);

  final typeFilter = request.optionalString('type');
  final minSeatsRaw = request.optionalString('minSeats');
  final minSeats = minSeatsRaw == null ? null : num.tryParse(minSeatsRaw);

  // Zone filter runs on the raw row (`cityZone` is a Postgres array).
  var rawRows = await _rentalProducts();
  if (zoneKey != null && zoneKey.isNotEmpty) {
    rawRows = rawRows.where((row) => _zoneMatches(row, zoneKey)).toList();
  }

  var cars = rawRows.map(_serializeCar).toList();
  if (typeFilter != null && typeFilter.isNotEmpty) {
    cars = cars.where((car) => car['type'] == typeFilter).toList();
  }
  if (minSeats != null && !minSeats.isNaN) {
    cars = cars.where((car) => (_num(car['seats']) ?? 0) >= minSeats).toList();
  }

  final types = <String>{for (final car in cars) car['type'].toString()};
  return {'items': cars, 'cars': cars, 'types': types.toList()};
}

bool _zoneMatches(Map<String, dynamic> row, String zoneKey) {
  final raw = row['cityZone'];
  if (raw is! List) return true;
  if (raw.isEmpty) return true;
  return raw.map((entry) => entry.toString()).contains(zoneKey);
}

Future<dynamic> _rentalCarDetail(GatewayRequest request) async {
  final carId = request.requireSegment(1, 'carId');
  final zoneKey = await SupabaseGateway.resolveZoneKey(
    zone: request.optionalString('zone'),
    latitude: null,
    longitude: null,
  );
  await _requireRideZone(zoneKey);

  final rows = await SupabaseGateway.table('Product')
      .select('*')
      .eq('id', carId)
      .eq('moduleType', 'RIDE')
      .limit(1);
  final match = rows.where((row) {
    final metadata = row['metadata'];
    return metadata is Map && metadata['rentalCar'] == true;
  });
  if (match.isEmpty) {
    throw const GatewayError('Car not found.', status: 404);
  }
  return _serializeCar(match.first);
}

Future<dynamic> _availability(GatewayRequest request) async {
  final zoneKey = await SupabaseGateway.resolveZoneKey(
    zone: request.optionalString('zone'),
    latitude: null,
    longitude: null,
  );
  await _requireRideZone(zoneKey);

  final carId = request.optionalString('carId');
  final startRaw = request.optionalString('startDate');
  final endRaw = request.optionalString('endDate');
  if (carId == null || startRaw == null || endRaw == null) {
    throw const GatewayError('carId, startDate and endDate are required');
  }

  final start = DateTime.tryParse(startRaw);
  final end = DateTime.tryParse(endRaw);
  if (start == null || end == null || !end.isAfter(start)) {
    throw const GatewayError('End date must be after start date.');
  }

  final cars = await SupabaseGateway.table('Product')
      .select('id')
      .eq('id', carId)
      .eq('moduleType', 'RIDE')
      .eq('inStock', true)
      .limit(1);
  final exists = cars.where((row) {
    final metadata = row['metadata'];
    return metadata is Map && metadata['rentalCar'] == true;
  }).isNotEmpty;
  if (!exists) {
    throw const GatewayError('Car not found or unavailable.', status: 404);
  }

  final available = await SupabaseGateway.rpc(
    'car_rental_available',
    params: {
      'p_car_id': carId,
      'p_start': start.toUtc().toIso8601String(),
      'p_end': end.toUtc().toIso8601String(),
    },
  );
  return {'available': available == true};
}

Future<dynamic> _rentalBookingsForUser(GatewayRequest request) async {
  final userId = request.requireSegment(3, 'userId');
  final rows = await SupabaseGateway.table('CarRentalBooking')
      .select('*')
      .eq('userId', userId)
      .order('createdAt', ascending: false);
  return rows.map(_serializeRentalBooking).toList();
}

Future<dynamic> _createRentalBooking(GatewayRequest request) async {
  final body = request.body ?? const <String, dynamic>{};

  String required(String key, {int min = 1, int max = 10000}) {
    final value = body[key]?.toString().trim() ?? '';
    if (value.length < min) throw GatewayError('$key is required.');
    if (value.length > max) {
      throw GatewayError('$key must be at most $max characters.');
    }
    return value;
  }

  final userId = required('userId');
  final carId = required('carId');
  final pickup = required('pickupLocation', min: 1, max: 200);
  final dropoff = _nonEmpty(body['dropoffLocation']);
  if (dropoff != null && dropoff.length > 200) {
    throw const GatewayError('dropoffLocation must be at most 200 characters.');
  }
  final notes = _nonEmpty(body['notes']);
  if (notes != null && notes.length > 500) {
    throw const GatewayError('notes must be at most 500 characters.');
  }

  await _requireRideZone(_nonEmpty(body['zone']));

  final start = DateTime.tryParse(body['startDate']?.toString() ?? '');
  final end = DateTime.tryParse(body['endDate']?.toString() ?? '');
  if (start == null || end == null) {
    throw const GatewayError('Invalid start or end date.');
  }
  if (!end.isAfter(start)) {
    throw const GatewayError('End date must be after start date.');
  }

  // Atomic: lock + overlap check + booking + accounting order in one RPC
  // (mirrors the backend's $transaction with pg_advisory_xact_lock).
  final booking = await SupabaseGateway.rpc(
    'create_car_rental_booking',
    params: {
      'p_user_id': userId,
      'p_car_id': carId,
      'p_start': start.toUtc().toIso8601String(),
      'p_end': end.toUtc().toIso8601String(),
      'p_pickup': pickup,
      'p_dropoff': dropoff,
      'p_notes': notes,
    },
  );
  final bookingMap = _asMap(booking);
  if (bookingMap == null) {
    throw const GatewayError('Car not found or unavailable.', status: 404);
  }

  await _bestEffort(
    () => SupabaseGateway.notifyAdmins(
      title: 'New car rental booking',
      body: 'A customer booked ${bookingMap['carName']} ('
          '${bookingMap['totalDays']} '
          '${bookingMap['totalDays'] == 1 ? 'day' : 'days'}).',
      module: 'RIDE',
      type: 'ORDER',
      route: '/pro/admin/orders',
      dedupeKey: 'car-rental-created:${bookingMap['id']}',
      metadata: {
        'bookingId': bookingMap['id'],
        'carId': bookingMap['carId'],
        'carName': bookingMap['carName'],
        'userId': bookingMap['userId'],
      },
    ),
    'car-rental-created/admin',
  );

  return _serializeRentalBooking(bookingMap);
}

Future<dynamic> _cancelRentalBooking(GatewayRequest request) async {
  final bookingId = request.requireSegment(2, 'bookingId');
  final body = request.body ?? const <String, dynamic>{};
  final userId = _nonEmpty(body['userId']);
  if (userId == null) throw const GatewayError('userId is required.');

  final result = await SupabaseGateway.rpc(
    'cancel_car_rental_booking',
    params: {'p_booking_id': bookingId, 'p_user_id': userId},
  );
  final bookingMap = _asMap(result);
  if (bookingMap == null) {
    throw const GatewayError('Booking not found.', status: 404);
  }

  await _bestEffort(
    () => SupabaseGateway.notifyAdmins(
      title: 'Car rental cancelled',
      body: 'The booking for ${bookingMap['carName']} was cancelled.',
      module: 'RIDE',
      type: 'ORDER',
      route: '/pro/admin/orders',
      dedupeKey: 'car-rental-cancelled:${bookingMap['id']}',
      metadata: {
        'bookingId': bookingMap['id'],
        'carName': bookingMap['carName'],
        'userId': bookingMap['userId'],
      },
    ),
    'car-rental-cancelled/admin',
  );

  return {
    'success': true,
    'booking': _serializeRentalBooking(bookingMap),
  };
}

Future<dynamic> _appointmentStatus(GatewayRequest request) async {
  final appointmentId = request.requireSegment(1, 'appointmentId');
  final body = request.body ?? const <String, dynamic>{};

  const allowed = {
    'PENDING',
    'APPROVED',
    'REJECTED',
    'COMPLETED',
    'CANCELLED',
    'NO_SHOW',
  };
  final status = body['status']?.toString().toUpperCase() ?? '';
  if (!allowed.contains(status)) {
    throw const GatewayError('Invalid status.');
  }

  final updated = await SupabaseGateway.table('Appointment')
      .update({'status': status})
      .eq('id', appointmentId)
      .select(_appointmentSelect)
      .maybeSingle();
  if (updated == null) {
    throw const GatewayError('Appointment not found.', status: 404);
  }

  if (status == 'CANCELLED' || status == 'REJECTED') {
    final doctor = _asMap(updated['doctor']);
    final userId = updated['userId']?.toString() ?? '';
    await _bestEffort(
      () => SupabaseGateway.notifyAdmins(
        title: status == 'REJECTED'
            ? 'Appointment rejected'
            : 'Appointment cancelled',
        body:
            'An appointment with ${doctor?['name'] ?? 'a doctor'} was moved to ${status.toLowerCase()}.',
        module: 'DOCTOR',
        type: 'APPOINTMENT',
        route: '/pro/admin/appointments',
        dedupeKey: 'appointment-status:$appointmentId:$status',
        metadata: {
          'appointmentId': appointmentId,
          'doctorId': updated['doctorId'],
          'status': status,
          'userId': userId,
          'source': 'user_status_flow',
        },
      ),
      'appointment-status/admin',
    );
  }

  return _serializeAppointment(updated);
}
