import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/ai_urgency.dart';
import '../../data/models/ai_report_model.dart';

/// AI ön raporunu gösteren yeniden kullanılabilir görünüm.
/// [compact] true ise yalnız aciliyet rozeti + belirti özeti (randevu adımı için);
/// false ise ayrıca tam rapor metni (detay ekranları / bottom sheet için).
class AiReportView extends StatelessWidget {
  final AiReportModel report;
  final bool compact;

  const AiReportView({super.key, required this.report, this.compact = false});

  /// Raporu tam ekran modal bottom sheet olarak açar (hekim kartı / owner "Gör" butonu).
  static void showSheet(BuildContext context, AiReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
          child: AiReportView(report: report),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.smart_toy_outlined, color: context.scheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'AI Ön Muayene Raporu',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            _UrgencyBadge(level: report.urgencyLevel),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Belirti Özeti', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(report.symptomsSummary,
            style: Theme.of(context).textTheme.bodyMedium),
        if (!compact) ...[
          const SizedBox(height: AppSpacing.lg),
          Divider(color: context.colors.outline),
          const SizedBox(height: AppSpacing.sm),
          Text('Detaylı Rapor', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(report.reportContent,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}

/// Aciliyet rozeti (pill) — [AiUrgency] ile tema-uyumlu.
class _UrgencyBadge extends StatelessWidget {
  final String level;
  const _UrgencyBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = AiUrgency.color(context, level);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AiUrgency.icon(level), size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            AiUrgency.label(level),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
