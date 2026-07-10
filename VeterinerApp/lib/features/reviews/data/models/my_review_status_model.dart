import 'clinic_review_model.dart';

/// Kullanıcının bir klinikteki değerlendirme durumu — arayüzün butonu
/// ("Değerlendir" / "Değerlendirmeni Düzenle" / gizli) tek çağrıyla belirlemesi için.
class MyReviewStatusModel {
  final bool canReview;
  final bool hasCompletedAppointment;
  final ClinicReviewModel? review;

  MyReviewStatusModel({
    required this.canReview,
    required this.hasCompletedAppointment,
    this.review,
  });

  bool get hasReviewed => review != null;

  factory MyReviewStatusModel.fromJson(Map<String, dynamic> json) {
    return MyReviewStatusModel(
      canReview: json['canReview'] ?? false,
      hasCompletedAppointment: json['hasCompletedAppointment'] ?? false,
      review: json['review'] != null
          ? ClinicReviewModel.fromJson(json['review'])
          : null,
    );
  }

  factory MyReviewStatusModel.none() =>
      MyReviewStatusModel(canReview: false, hasCompletedAppointment: false);
}
