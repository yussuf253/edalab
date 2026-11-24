import 'dart:collection';

class ManagedModule {
  final String id;
  final String name;
  final String moduleType;
  final bool active;
  final int sortOrder;

  const ManagedModule({
    required this.id,
    required this.name,
    required this.moduleType,
    required this.active,
    required this.sortOrder,
  });

  factory ManagedModule.fromJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? '';
    final rawType = json['moduleType']?.toString() ?? '';
    final canonicalId = ModuleAccessService.canonicalModuleId(
      rawId.isNotEmpty ? rawId : rawType,
    );
    final resolvedId = canonicalId.isNotEmpty ? canonicalId : 'unknown';
    return ManagedModule(
      id: resolvedId,
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : ModuleAccessService.defaultModuleName(resolvedId),
      moduleType: rawType.trim().isNotEmpty
          ? rawType.trim().toUpperCase()
          : ModuleAccessService.moduleTypeForId(resolvedId),
      active: json['active'] as bool? ?? true,
      sortOrder:
          (json['sortOrder'] as num?)?.toInt() ??
          ModuleAccessService.defaultSortOrder(resolvedId),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'moduleType': moduleType,
    'active': active,
    'sortOrder': sortOrder,
  };
}

class ModuleAccessService {
  ModuleAccessService._() {
    _applyDefaults();
  }

  static final ModuleAccessService instance = ModuleAccessService._();

  static const List<ManagedModule> _defaultModules = [
    ManagedModule(
      id: 'shopping',
      name: 'Shopping',
      moduleType: 'SHOPPING',
      active: true,
      sortOrder: 1,
    ),
    ManagedModule(
      id: 'food',
      name: 'Food',
      moduleType: 'FOOD',
      active: true,
      sortOrder: 2,
    ),
    ManagedModule(
      id: 'doctor',
      name: 'Doctor',
      moduleType: 'DOCTOR',
      active: true,
      sortOrder: 3,
    ),
    ManagedModule(
      id: 'hotel',
      name: 'Hotel',
      moduleType: 'HOTEL',
      active: true,
      sortOrder: 4,
    ),
    ManagedModule(
      id: 'ride',
      name: 'Ride',
      moduleType: 'RIDE',
      active: true,
      sortOrder: 5,
    ),
    ManagedModule(
      id: 'parcel',
      name: 'Parcel Delivery',
      moduleType: 'PARCEL',
      active: true,
      sortOrder: 6,
    ),
    ManagedModule(
      id: 'pharmacy',
      name: 'Pharmacy',
      moduleType: 'PHARMACY',
      active: true,
      sortOrder: 7,
    ),
    ManagedModule(
      id: 'grocery',
      name: 'Grocery',
      moduleType: 'GROCERY',
      active: true,
      sortOrder: 8,
    ),
    ManagedModule(
      id: 'home-services',
      name: 'Home Services',
      moduleType: 'HOME_SERVICES',
      active: true,
      sortOrder: 9,
    ),
    ManagedModule(
      id: 'laundry',
      name: 'Laundry',
      moduleType: 'LAUNDRY',
      active: true,
      sortOrder: 10,
    ),
  ];

  static const Map<String, String> _pathPrefixToModule = {
    '/shopping': 'shopping',
    '/food': 'food',
    '/doctor': 'doctor',
    '/hotel': 'hotel',
    '/ride': 'ride',
    '/car-rental': 'ride',
    '/parcel': 'parcel',
    '/pharmacy': 'pharmacy',
    '/grocery': 'grocery',
    '/home-services': 'home-services',
    '/laundry': 'laundry',
  };

  Map<String, ManagedModule> _modulesById = {};

  /// Whether a real configuration (persisted or fetched) has been applied.
  ///
  /// The hardcoded defaults alone are *not* a configuration: they mark every
  /// module active, which is exactly the state that must never be presented
  /// while the real answer is still unknown (slow or failed `/modules` call,
  /// fresh install). Consumers read [enabledModuleIds] / [isEnabled], which
  /// fail closed until this turns true.
  bool _hasConfig = false;

  bool get hasConfig => _hasConfig;

  UnmodifiableListView<ManagedModule> get modules {
    final values = _modulesById.values.toList()
      ..sort((left, right) {
        if (left.sortOrder != right.sortOrder) {
          return left.sortOrder.compareTo(right.sortOrder);
        }
        return left.name.compareTo(right.name);
      });
    return UnmodifiableListView(values);
  }

  /// The active module ids — the single source of truth shared by the home
  /// grid, the bottom nav tabs and every module-scoped section.
  ///
  /// Empty while the configuration is unknown, so a pending, timed-out or
  /// failed fetch can never light up modules the admin has switched off.
  Set<String> get enabledModuleIds => _hasConfig
      ? modules
            .where((module) => module.active)
            .map((module) => module.id)
            .toSet()
      : const <String>{};

  /// A module counts as enabled only against a known configuration. While the
  /// configuration is unknown this fails closed instead of advertising every
  /// module as active. Modules the configuration does not list are treated as
  /// disabled, so a partial payload can never widen the visible set.
  bool isEnabled(String moduleIdOrType) {
    final id = canonicalModuleId(moduleIdOrType);
    if (id.isEmpty) return true;
    if (!_hasConfig) return false;
    return _modulesById[id]?.active ?? false;
  }

  String? moduleForPath(String path) {
    for (final entry in _pathPrefixToModule.entries) {
      final prefix = entry.key;
      if (path == prefix || path.startsWith('$prefix/')) {
        return entry.value;
      }
    }
    return null;
  }

  void applyModules(Iterable<ManagedModule> modules) {
    if (modules.isEmpty) {
      // An empty list carries no answer: keep the defaults as placeholders
      // but stay in the unknown state, so nothing is reported active.
      _applyDefaults();
      return;
    }

    // Build the map from the payload alone. Seeding it with the all-active
    // defaults would silently keep every module the payload omits switched
    // on — exactly the "everything shows regardless" case.
    final next = <String, ManagedModule>{};

    for (final incoming in modules) {
      final incomingId = canonicalModuleId(incoming.id);
      if (incomingId.isEmpty) continue;
      next[incomingId] = ManagedModule(
        id: incomingId,
        name: incoming.name.trim().isNotEmpty
            ? incoming.name.trim()
            : defaultModuleName(incomingId),
        moduleType: incoming.moduleType.trim().isNotEmpty
            ? incoming.moduleType.trim().toUpperCase()
            : moduleTypeForId(incomingId),
        active: incoming.active,
        sortOrder: incoming.sortOrder,
      );
    }

    _modulesById = next;
    _hasConfig = true;
  }

  /// Drops everything known about module activation, e.g. when storage holds
  /// no usable configuration. UI keeps its skeleton (or shows nothing) until
  /// a real configuration arrives — never the all-active defaults.
  void resetToUnknown() {
    _modulesById = {};
    _hasConfig = false;
  }

  static String canonicalModuleId(String raw) {
    final normalized = raw
        .trim()
        .toLowerCase()
        .replaceAll('_', '-')
        .replaceAll(' ', '-');
    switch (normalized) {
      case 'shopping':
        return 'shopping';
      case 'food':
        return 'food';
      case 'doctor':
        return 'doctor';
      case 'hotel':
        return 'hotel';
      case 'ride':
        return 'ride';
      case 'parcel':
        return 'parcel';
      case 'pharmacy':
        return 'pharmacy';
      case 'grocery':
        return 'grocery';
      case 'home-services':
      case 'house-help':
      case 'househelp':
        return 'home-services';
      case 'laundry':
        return 'laundry';
      case '':
        return '';
      default:
        return normalized;
    }
  }

  static String moduleTypeForId(String moduleId) {
    switch (canonicalModuleId(moduleId)) {
      case 'shopping':
        return 'SHOPPING';
      case 'food':
        return 'FOOD';
      case 'doctor':
        return 'DOCTOR';
      case 'hotel':
        return 'HOTEL';
      case 'ride':
        return 'RIDE';
      case 'parcel':
        return 'PARCEL';
      case 'pharmacy':
        return 'PHARMACY';
      case 'grocery':
        return 'GROCERY';
      case 'home-services':
        return 'HOME_SERVICES';
      case 'laundry':
        return 'LAUNDRY';
      default:
        return moduleId.toUpperCase().replaceAll('-', '_');
    }
  }

  static String defaultModuleName(String moduleId) {
    final id = canonicalModuleId(moduleId);
    for (final module in _defaultModules) {
      if (module.id == id) {
        return module.name;
      }
    }
    return 'Module';
  }

  static int defaultSortOrder(String moduleId) {
    final id = canonicalModuleId(moduleId);
    for (final module in _defaultModules) {
      if (module.id == id) {
        return module.sortOrder;
      }
    }
    return 999;
  }

  void _applyDefaults() {
    _modulesById = {for (final module in _defaultModules) module.id: module};
    _hasConfig = false;
  }
}
