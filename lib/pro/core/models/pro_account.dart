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

  ProAccount copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    String? avatarUrl,
    bool? isBanned,
    String? banReason,
  }) {
    return ProAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
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
