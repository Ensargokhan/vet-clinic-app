import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Yıldız gösterimi için TEK kaynak.
/// [onChanged] verilirse dokunmatik girdi modunda çalışır (puan seçme),
/// verilmezse salt-okunur gösterim yapar (yarım yıldız desteği ile).
class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final ValueChanged<int>? onChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 16,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = context.colors.warning;
    final inactive = context.colors.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final star = index + 1;
        final icon = _iconFor(star);
        final isActive = rating >= star - 0.5;

        final child = Icon(
          icon,
          size: size,
          color: isActive ? color : inactive,
        );

        if (onChanged == null) return child;

        return InkResponse(
          onTap: () => onChanged!(star),
          radius: size,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: child,
          ),
        );
      }),
    );
  }

  IconData _iconFor(int star) {
    // Girdi modunda yarım yıldız yok; salt-okunur modda ortalama için var.
    if (rating >= star) return Icons.star;
    if (onChanged == null && rating >= star - 0.5) return Icons.star_half;
    return Icons.star_border;
  }
}
