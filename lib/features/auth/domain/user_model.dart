class UserModel {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final double? virtualBalance;
  final List<String>? badges;
  final String? role;

  UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    this.virtualBalance,
    this.badges,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      virtualBalance: (json['virtualBalance'] as num?)?.toDouble(),
      badges: (json['badges'] as List?)?.map((e) => e.toString()).toList(),
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'virtualBalance': virtualBalance,
      'badges': badges,
      'role': role,
    };
  }
}
