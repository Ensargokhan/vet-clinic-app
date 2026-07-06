import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Network fotoğraf + fallback ikonlu yuvarlak avatar.
/// [imageUrl] tam URL olmalıdır (göreli yolsa çağıran taraf baseUrl ekler).
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final double radius;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.fallbackIcon = Icons.person,
    this.radius = 28,
  });

  @override
  Widget build(BuildContext context) {
    final primary = context.scheme.primary;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: primary.withValues(alpha: 0.12),
      backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
      child: hasImage
          ? null
          : Icon(fallbackIcon, color: primary, size: radius * 0.9),
    );
  }
}
