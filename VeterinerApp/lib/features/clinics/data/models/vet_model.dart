class VetModel {
  final int id;
  final int? clinicId;
  final String fullName;
  final String? title;
  final String? specialty;
  final String? bio;
  final String? profilePhoto;

  VetModel({
    required this.id,
    this.clinicId,
    required this.fullName,
    this.title,
    this.specialty,
    this.bio,
    this.profilePhoto,
  });

  factory VetModel.fromJson(Map<String, dynamic> json) {
    return VetModel(
      id: json['id'],
      clinicId: json['clinicId'],
      fullName: json['fullName'] ?? '',
      title: json['title'],
      specialty: json['specialty'],
      bio: json['bio'],
      profilePhoto: json['profilePhoto'],
    );
  }
}
