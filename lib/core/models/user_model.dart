class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? avatarUrl;
  final List<AddressModel> addresses;
  final DateTime? dateOfBirth;
  final int points;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.addresses = const [],
    this.dateOfBirth,
    this.points = 0,
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? avatarUrl,
    List<AddressModel>? addresses,
    DateTime? dateOfBirth,
    int? points,
  }) {
    return UserModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      addresses: addresses ?? this.addresses,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      points: points ?? this.points,
    );
  }
}

class AddressModel {
  final String id;
  final String label;
  final String address;
  final String? city;
  final String? quartier;
  final String? zipCode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.label,
    required this.address,
    this.city,
    this.quartier,
    this.zipCode,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });
}
