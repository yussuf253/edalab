class LaundryService {
  final String id;
  final String name; // e.g., 'Wash & Fold', 'Dry Cleaning', 'Ironing'
  final String description;
  final double price;
  final String unit; // e.g., 'per bag', 'per item'
  final String iconUrl;

  LaundryService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.unit,
    required this.iconUrl,
  });
}

class LaundryModel {
  static List<LaundryService> sampleServices = [
    LaundryService(
      id: 'l1',
      name: 'Wash & Fold',
      description: 'Standard washing and folding for regular clothes.',
      price: 25.0,
      unit: 'per bag',
      iconUrl: 'wash',
    ),
    LaundryService(
      id: 'l2',
      name: 'Dry Cleaning',
      description: 'Professional dry cleaning for delicate fabrics.',
      price: 15.0,
      unit: 'per item',
      iconUrl: 'dry',
    ),
    LaundryService(
      id: 'l3',
      name: 'Ironing Only',
      description: 'Professional pressing and ironing service.',
      price: 5.0,
      unit: 'per item',
      iconUrl: 'iron',
    ),
  ];
}
