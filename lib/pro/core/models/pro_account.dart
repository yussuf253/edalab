class ProAccount {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String? avatarUrl;

  const ProAccount({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    this.avatarUrl,
  });

  factory ProAccount.fromJson(Map<String, dynamic> json) {
    return ProAccount(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'avatarUrl': avatarUrl,
    };
  }
}
