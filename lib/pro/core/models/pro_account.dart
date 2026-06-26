class ProAccount {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String? avatarUrl;
  final bool isBanned;
  final String? banReason;

  const ProAccount({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    this.avatarUrl,
    this.isBanned = false,
    this.banReason,
  });

  factory ProAccount.fromJson(Map<String, dynamic> json) {
    return ProAccount(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      isBanned: json['banned'] as bool? ?? false,
      banReason: json['banReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'banned': isBanned,
      'banReason': banReason,
    };
  }
}
