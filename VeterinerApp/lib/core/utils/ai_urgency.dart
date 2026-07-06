import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// AI ön raporunun aciliyet seviyesi için TEK kaynak: etiket + ikon + renk.
/// `appointment_status.dart` deseniyle aynı yapıda (tema-uyumlu açık/koyu).
class AiUrgency {
  AiUrgency._();

  static String label(String? level) {
    switch (level) {
      case 'low':
        return 'Düşük';
      case 'medium':
        return 'Orta';
      case 'high':
        return 'Yüksek';
      case 'emergency':
        return 'ACİL';
      default:
        return level ?? 'Bilinmiyor';
    }
  }

  static IconData icon(String? level) {
    switch (level) {
      case 'low':
        return Icons.info_outline;
      case 'medium':
        return Icons.warning_amber_outlined;
      case 'high':
        return Icons.priority_high;
      case 'emergency':
        return Icons.emergency_outlined;
      default:
        return Icons.help_outline;
    }
  }

  /// Seviyeye göre tema-uyumlu renk.
  static Color color(BuildContext context, String? level) {
    final c = context.colors;
    switch (level) {
      case 'low':
        return c.info;
      case 'medium':
        return c.warning;
      case 'high':
      case 'emergency':
        return Theme.of(context).colorScheme.error;
      default:
        return c.textSecondary;
    }
  }
}
