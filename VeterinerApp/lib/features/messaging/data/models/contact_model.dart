class ContactModel {
  final int userId;
  final String name;
  final String? title;

  ContactModel({
    required this.userId,
    required this.name,
    this.title,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      userId: json['userId'],
      name: json['name'] ?? '',
      title: json['title'],
    );
  }

  String get displayName =>
      (title != null && title!.isNotEmpty) ? '$title $name' : name;
}
