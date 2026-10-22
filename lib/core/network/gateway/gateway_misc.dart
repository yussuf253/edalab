import 'dart:math' as math;

import '../supabase_gateway.dart';
import 'gateway_router.dart';

/// `/modules`, `/promotions`, `/version/*`, `/health`, `/realtime/*`.
///
/// These are the boot-time reads (`ModuleProvider`, promotions on the home
/// feed, the update check) plus the one write that runs unauthenticated.
void register() {
  GatewayRouter.get('/health', _health);
  GatewayRouter.get('/modules/zones/resolve', _resolveZone);
  GatewayRouter.get('/modules/zones', _listZones);
  GatewayRouter.get('/modules/zones/:zoneKey/modules', _zoneModules);
  GatewayRouter.get('/modules/enabled', _modulesEnabled);
  GatewayRouter.get('/modules', _modules);
  GatewayRouter.get('/promotions', _promotions);
  GatewayRouter.get('/version/check', _versionCheck);
  GatewayRouter.post('/version/report-action', _reportAction);
  GatewayRouter.post('/realtime/subscribe', _realtimeNoop);
  GatewayRouter.post('/realtime/unsubscribe', _realtimeNoop);
}

// ── Managed module catalogue (mirrors utils/module-settings.ts) ─────────────

class _ManagedModule {
  final String moduleType;
  final String id;
  final String name;
  final int sortOrder;

  const _ManagedModule(this.moduleType, this.id, this.name, this.sortOrder);
}

const List<_ManagedModule> _managed = [
  _ManagedModule('SHOPPING', 'shopping', 'Shopping', 1),
  _ManagedModule('FOOD', 'food', 'Food', 2),
  _ManagedModule('DOCTOR', 'doctor', 'Doctor', 3),
  _ManagedModule('HOTEL', 'hotel', 'Hotel', 4),
  _ManagedModule('RIDE', 'ride', 'Ride', 5),
  _ManagedModule('PARCEL', 'parcel', 'Parcel Delivery', 6),
  _ManagedModule('PHARMACY', 'pharmacy', 'Pharmacy', 7),
  _ManagedModule('GROCERY', 'grocery', 'Grocery', 8),
  _ManagedModule('HOME_SERVICES', 'home-services', 'Home Services', 9),
  _ManagedModule('LAUNDRY', 'laundry', 'Laundry', 10),
];

List<Map<String, dynamic>> _defaultModules() => _managed
    .map(
      (definition) => <String, dynamic>{
        'id': definition.id,
        'moduleType': definition.moduleType,
        'name': definition.name,
        'active': true,
        'sortOrder': definition.sortOrder,
      },
    )
    .toList();

Future<List<Map<String, dynamic>>> _listManagedModules() async {
  final types = _managed.map((entry) => entry.moduleType).toList();
  final records = await SupabaseGateway.table('AppModule')
      .select('moduleType,slug,name,active,sortOrder')
      .inFilter('moduleType', types);

  final byType = <String, Map<String, dynamic>>{
    for (final row in records) row['moduleType'].toString(): row,
  };

  final modules = _managed.map((definition) {
    final record = byType[definition.moduleType];
    return <String, dynamic>{
      'id': record?['slug'] ?? definition.id,
      'moduleType': definition.moduleType,
      'name': record?['name'] ?? definition.name,
      'active': record?['active'] ?? true,
      'sortOrder': record?['sortOrder'] ?? definition.sortOrder,
    };
  }).toList();

  modules.sort((left, right) {
    final byOrder =
        (left['sortOrder'] as int).compareTo(right['sortOrder'] as int);
    if (byOrder != 0) return byOrder;
    return left['name'].toString().compareTo(right['name'].toString());
  });
  return modules;
}

Future<Map<String, dynamic>?> _findZoneByKey(String rawKey) async {
  final normalized = rawKey
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s-]+'), '_');
  if (normalized.isEmpty) return null;

  var rows = await SupabaseGateway.table('ServiceZone')
      .select('*')
      .eq('zoneKey', normalized)
      .limit(1);
  if (rows.isEmpty) {
    rows = await SupabaseGateway.table('ServiceZone')
        .select('*')
        .eq('id', rawKey.trim())
        .limit(1);
  }
  if (rows.isEmpty) return null;
  return rows.first;
}

Map<String, dynamic> _zoneSummary(Map<String, dynamic> zone) =>
    <String, dynamic>{
      'id': zone['id'],
      'zoneKey': zone['zoneKey'],
      'name': zone['name'],
      'nameEn': zone['nameEn'],
      'nameFr': zone['nameFr'],
      'nameAr': zone['nameAr'],
      'centerLatitude': zone['centerLatitude'],
      'centerLongitude': zone['centerLongitude'],
      'radiusKm': zone['radiusKm'],
      'active': zone['active'],
      'sortOrder': zone['sortOrder'],
    };

Future<List<Map<String, dynamic>>> _listModulesForZone(String zoneId) async {
  final global = await SupabaseGateway.table('AppModule').select('*');
  final zoneRows = await SupabaseGateway.table('ZoneModuleConfig')
      .select('moduleType,active')
      .eq('zoneId', zoneId);

  final globalByType = <String, Map<String, dynamic>>{
    for (final row in global) row['moduleType'].toString(): row,
  };
  final zoneByType = <String, Map<String, dynamic>>{
    for (final row in zoneRows) row['moduleType'].toString(): row,
  };

  final modules = _managed.map((definition) {
    final globalRecord = globalByType[definition.moduleType];
    final zoneRecord = zoneByType[definition.moduleType];
    return <String, dynamic>{
      'id': definition.id,
      'moduleType': definition.moduleType,
      'name': globalRecord?['name'] ?? definition.name,
      'active':
          (globalRecord?['active'] ?? true) && (zoneRecord?['active'] ?? true),
      'sortOrder': definition.sortOrder,
    };
  }).toList();

  modules.sort(
    (left, right) =>
        (left['sortOrder'] as int).compareTo(right['sortOrder'] as int),
  );
  return modules;
}

// ── Handlers ────────────────────────────────────────────────────────────────

Future<dynamic> _health(GatewayRequest request) async =>
    <String, dynamic>{'status': 'ok', 'message': 'EdaLab API is running'};

Future<dynamic> _modules(GatewayRequest request) async {
  final zoneKey = request.optionalString('zone');
  try {
    if (zoneKey != null) {
      final zone = await _findZoneByKey(zoneKey);
      if (zone != null) {
        return await _listModulesForZone(zone['id'].toString());
      }
    }
    return await _listManagedModules();
  } catch (_) {
    // The backend kept the app usable mid-migration; do the same.
    return _defaultModules();
  }
}

Future<dynamic> _listZones(GatewayRequest request) async {
  final activeOnly = request.optionalString('activeOnly') == 'true';
  try {
    var rows = await SupabaseGateway.table('ServiceZone').select('*');
    if (activeOnly) {
      rows = rows.where((row) => row['active'] == true).toList();
    }

    final zones = rows.map(_zoneSummary).toList()
      ..sort((left, right) {
        final byOrder =
            (left['sortOrder'] as int).compareTo(right['sortOrder'] as int);
        if (byOrder != 0) return byOrder;
        return left['name'].toString().compareTo(right['name'].toString());
      });
    return zones;
  } catch (_) {
    return <Map<String, dynamic>>[];
  }
}

Future<dynamic> _resolveZone(GatewayRequest request) async {
  final latitude = double.tryParse(request.optionalString('latitude') ?? '');
  final longitude = double.tryParse(request.optionalString('longitude') ?? '');
  if (latitude == null || longitude == null) {
    throw const GatewayError('latitude and longitude are required numbers.');
  }

  try {
    final rows = await SupabaseGateway.table('ServiceZone')
        .select('*')
        .eq('active', true);
    for (final zone in rows) {
      final distance = _haversineKm(
        latitude,
        longitude,
        (zone['centerLatitude'] as num).toDouble(),
        (zone['centerLongitude'] as num).toDouble(),
      );
      if (distance <= (zone['radiusKm'] as num).toDouble()) {
        return <String, dynamic>{'zone': _zoneSummary(zone)};
      }
    }
    return <String, dynamic>{'zone': null};
  } catch (_) {
    return <String, dynamic>{'zone': null};
  }
}

Future<dynamic> _zoneModules(GatewayRequest request) async {
  final zone = await _findZoneByKey(request.requireSegment(2, 'zoneKey'));
  if (zone == null) {
    throw const GatewayError('Service zone not found.', status: 404);
  }
  try {
    return await _listModulesForZone(zone['id'].toString());
  } catch (_) {
    return _defaultModules();
  }
}

Future<dynamic> _modulesEnabled(GatewayRequest request) async {
  final zoneKey = request.optionalString('zone');
  if (zoneKey == null) {
    final rows = await SupabaseGateway.table('AppModule')
        .select('active')
        .eq('moduleType', 'SHOPPING')
        .limit(1);
    final active = rows.isNotEmpty ? rows.first['active'] == true : true;
    return <String, dynamic>{
      'moduleType': request.param('moduleType'),
      'enabled': active,
      'zone': null,
    };
  }

  final zone = await _findZoneByKey(zoneKey);
  if (zone == null) {
    throw const GatewayError('Service zone not found.', status: 404);
  }
  return <String, dynamic>{
    'zone': {'id': zone['id'], 'zoneKey': zone['zoneKey']},
    'modules': await _listModulesForZone(zone['id'].toString()),
  };
}

Future<dynamic> _promotions(GatewayRequest request) async {
  final rows = await SupabaseGateway.table('Promotion')
      .select(
        'id,moduleType,title,description,code,discountType,discountValue,'
        'startsAt,endsAt,priority,metadata',
      )
      .eq('active', true)
      .order('priority', ascending: false)
      .order('createdAt', ascending: false);

  final serialized = rows.map((map) {
    final rawMetadata = map['metadata'];
    final metadata = rawMetadata is Map
        ? Map<String, dynamic>.from(rawMetadata)
        : <String, dynamic>{};
    return <String, dynamic>{
      'id': map['id'],
      'moduleType': map['moduleType'],
      'title': map['title'],
      'description': map['description'],
      'code': map['code'],
      'discountType': map['discountType'],
      'discountValue': map['discountValue'],
      'startsAt': map['startsAt'],
      'endsAt': map['endsAt'],
      'priority': map['priority'],
      'kind': metadata['kind'] ?? 'coupon',
      'metadata': metadata,
    };
  }).toList();

  return <String, dynamic>{
    'specialOffers':
        serialized.where((item) => item['kind'] == 'special').toList(),
    'flashSales': serialized.where((item) => item['kind'] == 'flash').toList(),
    'coupons': serialized.where((item) => item['kind'] == 'coupon').toList(),
  };
}

Future<dynamic> _versionCheck(GatewayRequest request) async {
  final platform = request.optionalString('platform');

  var query = SupabaseGateway.table('AppVersion')
      .select(
        'currentVersion,minRequiredVersion,latestVersion,releaseNotes,'
        'isForceUpdateRequired,isSkippableUpdate,downloadUrl,storeUrl,'
        'releasedAt,isActive,platform',
      )
      .eq('isActive', true);
  if (platform != null && platform.isNotEmpty) {
    query = query.or('platform.eq.both,platform.eq.$platform');
  }

  final rows = await query.order('latestVersion', ascending: false).limit(1);
  if (rows.isEmpty) {
    throw const GatewayError('No version information available', status: 404);
  }

  final version = rows.first;
  return <String, dynamic>{
    'currentVersion': version['currentVersion'],
    'minRequiredVersion': version['minRequiredVersion'],
    'latestVersion': version['latestVersion'],
    'releaseNotes': version['releaseNotes'],
    'isForceUpdateRequired': version['isForceUpdateRequired'],
    'isSkippableUpdate': version['isSkippableUpdate'],
    'downloadUrl': version['downloadUrl'] ?? '',
    'storeUrl': version['storeUrl'],
    'releasedAt': version['releasedAt'],
    'isActive': version['isActive'],
  };
}

Future<dynamic> _reportAction(GatewayRequest request) async {
  final body = request.body ?? const <String, dynamic>{};
  final action = body['action']?.toString() ?? '';
  const valid = ['skipped', 'updated', 'forced_update', 'update_confirmed'];
  if (!valid.contains(action)) throw const GatewayError('Invalid action');

  await SupabaseGateway.table('UpdateActionLog').insert({
    'action': action,
    'currentVersion': body['currentVersion'],
    'platform': body['platform'],
    'userId': body['userId'] ?? await SupabaseGateway.currentCuid(),
    'timestamp': body['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
  });

  return <String, dynamic>{
    'success': true,
    'message': 'Action recorded successfully',
  };
}

/// Supabase Realtime replaces the SSE stream entirely, so subscribing is a
/// no-op at the transport level — `RealtimeService` opens a channel itself.
Future<dynamic> _realtimeNoop(GatewayRequest request) async =>
    <String, dynamic>{'success': true};

double _haversineKm(
  double startLatitude,
  double startLongitude,
  double endLatitude,
  double endLongitude,
) {
  const earthRadiusKm = 6371.0;
  double toRadians(double value) => value * math.pi / 180;

  final startLat = toRadians(startLatitude);
  final endLat = toRadians(endLatitude);
  final dLat = toRadians(endLatitude - startLatitude);
  final dLon = toRadians(endLongitude - startLongitude);

  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(startLat) *
          math.cos(endLat) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}
