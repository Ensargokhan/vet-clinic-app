/// Bir kliniğe yazılmış tek değerlendirme (puan + isteğe bağlı yorum).
class ClinicReviewModel {
  final int id;
  final int userId;
  final String userName;
  final int rating; // 1–5
  final String? comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Yorum, oturum açan kullanıcıya mı ait? (düzenle/sil menüsü için)
  final bool isMine;

  ClinicReviewModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.updatedAt,
    required this.isMine,
  });

  bool get isEdited => updatedAt != null;

  factory ClinicReviewModel.fromJson(Map<String, dynamic> json) {
    return ClinicReviewModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isMine: json['isMine'] ?? false,
    );
  }
}
