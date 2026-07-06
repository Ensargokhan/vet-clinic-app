class AnnouncementModel {
  final int id;
  final int clinicId;
  final String title;
  final String body;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.clinicId,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'],
      clinicId: json['clinicId'],
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
