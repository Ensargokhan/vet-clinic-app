import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/review_summary_model.dart';
import 'star_rating.dart';

/// Kliniğin değerlendirme özeti: büyük ortalama + yıldızlar + adet.
/// [compact] true ise yıldız dağılımı çubukları gizlenir (klinik detay sayfası için).
class RatingSummary extends StatelessWidget {
  final ReviewSummaryModel summary;
  final bool compact;

  const RatingSummary({super.key, required this.summary, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (!summary.hasReviews) {
      return Text(
        'Henüz değerlendirilmemiş.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
      );
    }

    final rating = summary.rating ?? 0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            StarRating(rating: rating, size: 16),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${summary.reviewCount} değerlendirme',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        if (!compact) ...[
          const SizedBox(width: AppSpacing.xl),
          Expanded(child: _distribution(context)),
        ],
      ],
    );
  }

  Widget _distribution(BuildContext context) {
    final total = summary.reviewCount;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 5; star >= 1; star--)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 12,
                  child: Text('$star',
                      style: Theme.of(context).textTheme.labelSmall),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: ClipRRect(
                    borderRadius: AppRadius.pillAll,
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : (summary.distribution[star] ?? 0) / total,
                      minHeight: 6,
                      backgroundColor: context.colors.surfaceAlt,
                      valueColor:
                          AlwaysStoppedAnimation(context.colors.warning),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                SizedBox(
                  width: 20,
                  child: Text(
                    '${summary.distribution[star] ?? 0}',
                    style: Theme.of(context).textTheme.labelSmall,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
