class LabTestModel {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final String? fullDescription;
  final double price;
  final double? originalPrice;
  final String? preparationInstructions;
  final String? sampleType;
  final String? durationLabel;
  final String? imageUrl;
  final bool active;
  final int sortOrder;

  LabTestModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    this.fullDescription,
    required this.price,
    this.originalPrice,
    this.preparationInstructions,
    this.sampleType,
    this.durationLabel,
    this.imageUrl,
    required this.active,
    required this.sortOrder,
  });

  factory LabTestModel.fromApi(Map<String, dynamic> json) {
    return LabTestModel(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      fullDescription: json['fullDescription'] as String?,
      price: (json['price'] as num).toDouble(),
      originalPrice: json['originalPrice'] != null
          ? (json['originalPrice'] as num).toDouble()
          : null,
      preparationInstructions: json['preparationInstructions'] as String?,
      sampleType: json['sampleType'] as String?,
      durationLabel: json['durationLabel'] as String?,
      imageUrl: json['imageUrl'] as String?,
      active: json['active'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  double get discountPercent {
    if (originalPrice == null || originalPrice! <= price) return 0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }
}
