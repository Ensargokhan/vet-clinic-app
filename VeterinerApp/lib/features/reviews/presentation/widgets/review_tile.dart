import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/models/clinic_review_model.dart';
import 'star_rating.dart';

/// Tek bir değerlendirme kartı. Yorum kullanıcıya aitse düzenle/sil menüsü gösterir.
class ReviewTile extends StatelessWidget {
  final ClinicReviewModel review;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReviewTile({
    super.key,
    required this.review,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy', 'tr_TR').format(review.createdAt);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _initialAvatar(context),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.isMine ? '${review.userName} (Siz)' : review.userName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        StarRating(rating: review.rating.toDouble(), size: 14),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          review.isEdited ? '$dateStr · düzenlendi' : dateStr,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (review.isMine && (onEdit != null || onDelete != null))
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert,
                      size: 20, color: context.colors.textSecondary),
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    if (onEdit != null)
                      const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                    if (onDelete != null)
                      const PopupMenuItem(value: 'delete', child: Text('Sil')),
                  ],
                ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(review.comment!,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _initialAvatar(BuildContext context) {
    final initial =
        review.userName.trim().isEmpty ? '?' : review.userName.trim()[0].toUpperCase();
    final primary = context.scheme.primary;

    return CircleAvatar(
      radius: 20,
      backgroundColor: primary.withValues(alpha: 0.12),
      child: Text(
        initial,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(color: primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}
