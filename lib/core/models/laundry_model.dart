class LaundryServiceItemConfig {
  final String id;
  final String label;
  final double price;
  final String category;
  final String spec;

  bool get isGroup => category == 'group';
  bool get isUnit => !isGroup;

  LaundryServiceItemConfig({
    required this.id,
    required this.label,
    required this.price,
    required this.category,
    required this.spec,
  });

  factory LaundryServiceItemConfig.fromApi(Map<String, dynamic> json) {
    final rawId = json['id']?.toString().trim() ?? '';
    final label = json['label']?.toString().trim() ?? '';
    final generatedId = label
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final normalizedId = rawId.isNotEmpty ? rawId : generatedId;
    final rawCategory = json['category']?.toString().trim().toLowerCase() ?? '';
    final inferredCategory =
        normalizedId.contains('wash_fold_') ||
            label.toLowerCase().contains('wash & fold')
        ? 'group'
        : 'unit';
    final category = rawCategory == 'group' || rawCategory == 'unit'
        ? rawCategory
        : inferredCategory;
    final spec = json['spec']?.toString().trim() ?? '';
    return LaundryServiceItemConfig(
      id: normalizedId,
      label: label,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      category: category,
      spec: category == 'group' ? spec : '',
    );
  }
}

class LaundryBookingConfig {
  final List<LaundryServiceItemConfig> itemCatalog;
  final List<String> pickupSlots;
  final int turnaroundHours;
  final int minNoticeHours;
  final int maxAdvanceDays;
  final double taxRatePercent;
  final double deliveryFee;

  LaundryBookingConfig({
    required this.itemCatalog,
    required this.pickupSlots,
    required this.turnaroundHours,
    required this.minNoticeHours,
    required this.maxAdvanceDays,
    required this.taxRatePercent,
    required this.deliveryFee,
  });

  factory LaundryBookingConfig.fromApi(
    Map<String, dynamic>? json, {
    required double fallbackPrice,
  }) {
    final washAndFoldBasePrice = fallbackPrice > 0 ? fallbackPrice : 6000.0;
    final defaultConfig = LaundryBookingConfig(
      itemCatalog: [
        LaundryServiceItemConfig(
          id: 'shirts',
          label: 'Shirt',
          price: 700,
          category: 'unit',
          spec: '',
        ),
        LaundryServiceItemConfig(
          id: 't_shirt',
          label: 'T-Shirt',
          price: 500,
          category: 'unit',
          spec: '',
        ),
        LaundryServiceItemConfig(
          id: 'polo',
          label: 'Polo',
          price: 500,
          category: 'unit',
          spec: '',
        ),
        LaundryServiceItemConfig(
          id: 'trouser',
          label: 'Trouser',
          price: 800,
          category: 'unit',
          spec: '',
        ),
        LaundryServiceItemConfig(
          id: 'blazer',
          label: 'Blazer',
          price: 1500,
          category: 'unit',
          spec: '',
        ),
        LaundryServiceItemConfig(
          id: 'suit_2_pieces',
          label: 'Suit 2 pieces',
          price: 2000,
          category: 'unit',
          spec: '',
        ),
        LaundryServiceItemConfig(
          id: 'suit_3_pieces',
          label: 'Suit 3 pieces',
          price: 2700,
          category: 'unit',
          spec: '',
        ),
        LaundryServiceItemConfig(
          id: 'jacket',
          label: 'Jacket',
          price: 1500,
          category: 'unit',
          spec: '',
        ),
        LaundryServiceItemConfig(
          id: 'dress',
          label: 'Dress',
          price: 1200,
          category: 'unit',
          spec: '',
        ),
        LaundryServiceItemConfig(
          id: 'wash_fold_10_20',
          label: 'Wash & Fold 10-20 pieces',
          price: washAndFoldBasePrice,
          category: 'group',
          spec: '10 to 20 pieces',
        ),
        LaundryServiceItemConfig(
          id: 'wash_fold_21_30',
          label: 'Wash & Fold 21-30 pieces',
          price: 12000,
          category: 'group',
          spec: '21 to 30 pieces',
        ),
        LaundryServiceItemConfig(
          id: 'wash_fold_31_40',
          label: 'Wash & Fold 31-40 pieces',
          price: 14500,
          category: 'group',
          spec: '31 to 40 pieces',
        ),
      ],
      pickupSlots: const [
        '08:00 - 10:00',
        '10:00 - 12:00',
        '14:00 - 16:00',
        '16:00 - 18:00',
      ],
      turnaroundHours: 26,
      minNoticeHours: 0,
      maxAdvanceDays: 5,
      taxRatePercent: 8,
      deliveryFee: 0,
    );
    if (json == null) {
      return defaultConfig;
    }

    final itemCatalog = (json['itemCatalog'] as List<dynamic>? ?? const [])
        .map(
          (entry) => LaundryServiceItemConfig.fromApi(
            Map<String, dynamic>.from(entry as Map),
          ),
        )
        .where((entry) => entry.id.isNotEmpty && entry.label.isNotEmpty)
        .toList(growable: false);
    final hasItemCatalogField = json.containsKey('itemCatalog');
    final pickupSlots = (json['pickupSlots'] as List<dynamic>? ?? const [])
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);

    final turnaroundHours = (json['turnaroundHours'] as num?)?.toInt() ?? -1;
    final minNoticeHours = (json['minNoticeHours'] as num?)?.toInt() ?? -1;
    final maxAdvanceDays = (json['maxAdvanceDays'] as num?)?.toInt() ?? -1;
    final taxRatePercent = (json['taxRatePercent'] as num?)?.toDouble() ?? -1;
    final deliveryFee = (json['deliveryFee'] as num?)?.toDouble() ?? -1;

    return LaundryBookingConfig(
      itemCatalog: hasItemCatalogField
          ? itemCatalog
          : defaultConfig.itemCatalog,
      pickupSlots: pickupSlots.isNotEmpty
          ? pickupSlots
          : defaultConfig.pickupSlots,
      turnaroundHours: turnaroundHours >= 1 && turnaroundHours <= 168
          ? turnaroundHours
          : defaultConfig.turnaroundHours,
      minNoticeHours: minNoticeHours >= 0 && minNoticeHours <= 72
          ? minNoticeHours
          : defaultConfig.minNoticeHours,
      maxAdvanceDays: maxAdvanceDays >= 1 && maxAdvanceDays <= 30
          ? maxAdvanceDays
          : defaultConfig.maxAdvanceDays,
      taxRatePercent: taxRatePercent >= 0 && taxRatePercent <= 40
          ? taxRatePercent
          : defaultConfig.taxRatePercent,
      deliveryFee: deliveryFee >= 0 && deliveryFee <= 100000
          ? deliveryFee
          : defaultConfig.deliveryFee,
    );
  }
}

class LaundryService {
  final String id;
  final String name; // e.g., 'Wash & Fold', 'Dry Cleaning', 'Ironing'
  final String profileName;
  final String description;
  final double price;
  final String unit; // e.g., 'per bag', 'per item'
  final String iconUrl;
  final LaundryBookingConfig bookingConfig;

  LaundryService({
    required this.id,
    required this.name,
    required this.profileName,
    required this.description,
    required this.price,
    required this.unit,
    required this.iconUrl,
    required this.bookingConfig,
  });

  factory LaundryService.fromApi(Map<String, dynamic> json) {
    final price = (json['price'] as num?)?.toDouble() ?? 0;
    return LaundryService(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Laundry Service',
      profileName: json['profileName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: price,
      unit: json['unit']?.toString() ?? '',
      iconUrl: json['iconUrl']?.toString() ?? '',
      bookingConfig: LaundryBookingConfig.fromApi(
        json['bookingConfig'] is Map
            ? Map<String, dynamic>.from(json['bookingConfig'] as Map)
            : null,
        fallbackPrice: price,
      ),
    );
  }
}

class LaundryModel {
  static List<LaundryService> sampleServices = [
    LaundryService(
      id: 'l1',
      name: 'Wash & Fold',
      profileName: 'Laundry King Djibouti',
      description: 'Laundry service inspired by Djibouti market tariffs.',
      price: 6000.0,
      unit: 'per order',
      iconUrl: 'wash',
      bookingConfig: LaundryBookingConfig.fromApi(null, fallbackPrice: 6000),
    ),
  ];
}
