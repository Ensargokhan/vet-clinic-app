import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Randevu durumu için TEK kaynak: etiket + ikon + renk.
/// Önceden 3 farklı ekranda kopyalanan/hardcoded olan durum görünümlerini birleştirir.
class AppointmentStatus {
  AppointmentStatus._();

  static String label(String? status) {
    switch (status) {
      case 'pending':
        return 'Bekliyor';
      case 'confirmed':
        return 'Onaylandı';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal Edildi';
      case 'expired':
        return 'Süresi Doldu';
      case 'no_show':
        return 'Gidilmedi';
      default:
        return status ?? 'Bilinmiyor';
    }
  }

  static IconData icon(String? status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'completed':
        return Icons.task_alt;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'expired':
        return Icons.history;
      case 'no_show':
        return Icons.person_off_outlined;
      default:
        return Icons.help_outline;
    }
  }

  /// Duruma göre tema-uyumlu renk (açık/koyu otomatik).
  static Color color(BuildContext context, String? status) {
    final c = context.colors;
    switch (status) {
      case 'pending':
        return c.warning;
      case 'confirmed':
        return c.info;
      case 'completed':
        return c.success;
      case 'cancelled':
        return Theme.of(context).colorScheme.error;
      case 'no_show':
        return c.warning;
      case 'expired':
      default:
        return c.textSecondary;
    }
  }
}
