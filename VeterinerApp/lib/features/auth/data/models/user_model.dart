class UserModel {
  final int id;
  final String firebaseUid;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String? profilePhoto;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.firebaseUid,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.profilePhoto,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      firebaseUid: json['firebaseUid'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'owner',
      profilePhoto: json['profilePhoto'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'profilePhoto': profilePhoto,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
