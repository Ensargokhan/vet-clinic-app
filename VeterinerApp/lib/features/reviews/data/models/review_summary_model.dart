/// Kliniğin değerlendirme özeti: ortalama puan, adet ve yıldız dağılımı.
class ReviewSummaryModel {
  /// Hiç değerlendirme yoksa null → "Henüz değerlendirilmemiş".
  final double? rating;
  final int reviewCount;

  /// Yıldız (1–5) → o puanı veren yorum sayısı.
  final Map<int, int> distribution;

  ReviewSummaryModel({
    this.rating,
    required this.reviewCount,
    required this.distribution,
  });

  bool get hasReviews => reviewCount > 0;

  factory ReviewSummaryModel.fromJson(Map<String, dynamic> json) {
    final raw = json['distribution'] as Map<String, dynamic>? ?? {};
    final dist = <int, int>{for (var s = 1; s <= 5; s++) s: 0};
    raw.forEach((key, value) {
      final star = int.tryParse(key);
      if (star != null && star >= 1 && star <= 5) {
        dist[star] = (value as num).toInt();
      }
    });

    return ReviewSummaryModel(
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewCount: json['reviewCount'] ?? 0,
      distribution: dist,
    );
  }

  /// Hiç yorum yokken gösterilecek boş özet.
  factory ReviewSummaryModel.empty() => ReviewSummaryModel(
        rating: null,
        reviewCount: 0,
        distribution: {for (var s = 1; s <= 5; s++) s: 0},
      );
}
