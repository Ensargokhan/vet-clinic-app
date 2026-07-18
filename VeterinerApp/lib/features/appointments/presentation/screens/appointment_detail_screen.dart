import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/appointment_status.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/info_row.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../reviews/presentation/widgets/write_review_sheet.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final int appointmentId;
  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailScreen> createState() => _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  Map<String, dynamic>? _appointment;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAppointment();
  }

  Future<void> _fetchAppointment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = DioClient().dio;
      final response = await dio.get('/appointments/${widget.appointmentId}');
      if (response.data['success']) {
        setState(() {
          _appointment = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Randevu detayları yüklenemedi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelAppointment() async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Randevuyu İptal Et'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bu randevuyu iptal etmek istediğinize emin misiniz?'),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: reasonController,
              maxLength: 500,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'İptal gerekçesi (isteğe bağlı)',
                hintText: 'Örn: Programım değişti',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ctx.scheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final reason = reasonController.text.trim();

    try {
      final dio = DioClient().dio;
      await dio.put(
        '/appointments/${widget.appointmentId}/cancel',
        data: {'reason': reason.isEmpty ? null : reason},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Randevu iptal edildi.'),
            backgroundColor: context.colors.success,
          ),
        );
        _fetchAppointment();
      }
    } catch (e) {
      if (mounted) {
        // Backend mesajını göster (örn. "2 saatten az kaldığı için iptal edilemez")
        String message = 'İptal işlemi başarısız.';
        if (e is DioException) {
          final backendMessage = e.response?.data?['message'];
          if (backendMessage is String && backendMessage.isNotEmpty) {
            message = backendMessage;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: context.scheme.error,
          ),
        );
      }
    }
  }

  Future<void> _reviewClinic(int clinicId, String clinicName) async {
    final saved = await WriteReviewSheet.show(
      context,
      clinicId: clinicId,
      clinicName: clinicName,
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Değerlendirmeniz için teşekkürler!'),
          backgroundColor: context.colors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Randevu Detayı')),
      body: _isLoading
          ? const LoadingIndicator()
          : _error != null
              ? ErrorState(message: _error!, onRetry: _fetchAppointment)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_appointment == null) return const SizedBox.shrink();

    final appt = _appointment!;
    final date = DateTime.parse(appt['appointmentDate']);
    final status = appt['status']?.toString() ?? 'pending';
    // Sahip, bekleyen veya onaylanmış randevuyu iptal edebilir; randevuya 2 saatten
    // az kaldıysa iptal kapanır (backend nihai hakem, UI kolaylık sağlar).
    final isCancellableStatus = status == 'pending' || status == 'confirmed';
    final withinCutoff =
        date.difference(DateTime.now()) <= const Duration(hours: 2);
    final canCancel = isCancellableStatus && !withinCutoff;
    final statusColor = AppointmentStatus.color(context, status);

    // Tamamlanan randevudan sonra klinik değerlendirilebilir
    final clinicId = appt['clinicId'] as int?;
    final canReview = status == 'completed' && clinicId != null && clinicId != 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Durum başlığı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.lgAll,
            ),
            child: Column(
              children: [
                Icon(AppointmentStatus.icon(status), color: statusColor, size: 48),
                const SizedBox(height: AppSpacing.md),
                Text(
                  AppointmentStatus.label(status),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(color: statusColor),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(date),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          AppCard(
            child: Column(
              children: [
                InfoRow(
                  icon: Icons.pets,
                  label: 'Hasta',
                  value: appt['animalName']?.toString() ?? 'Bilinmiyor',
                ),
                InfoRow(
                  icon: Icons.medical_services_outlined,
                  label: 'Veteriner Hekim',
                  value: appt['vetName']?.toString() ?? 'Bilinmiyor',
                ),
                InfoRow(
                  icon: Icons.access_time,
                  label: 'Süre',
                  value: '${appt['durationMinutes'] ?? 30} dakika',
                ),
                if (appt['reason'] != null && appt['reason'].toString().isNotEmpty)
                  InfoRow(
                    icon: Icons.description_outlined,
                    label: 'Sebep',
                    value: appt['reason'].toString(),
                  ),
                if (appt['notes'] != null && appt['notes'].toString().isNotEmpty)
                  InfoRow(
                    icon: Icons.notes_outlined,
                    label: 'Notlar',
                    value: appt['notes'].toString(),
                  ),
                if (appt['cancellationReason'] != null &&
                    appt['cancellationReason'].toString().isNotEmpty)
                  InfoRow(
                    icon: Icons.cancel_outlined,
                    label: 'İptal Gerekçesi',
                    value: appt['cancellationReason'].toString(),
                  ),
              ],
            ),
          ),

          if (canReview) ...[
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _reviewClinic(
                  clinicId,
                  appt['clinicName']?.toString() ?? 'Klinik',
                ),
                icon: const Icon(Icons.rate_review_outlined),
                label: const Text('Kliniği Değerlendir'),
              ),
            ),
          ],

          if (canCancel) ...[
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cancelAppointment,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Randevuyu İptal Et'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.scheme.error,
                  side: BorderSide(color: context.scheme.error),
                ),
              ),
            ),
          ] else if (isCancellableStatus && withinCutoff) ...[
            // Butonu sessizce gizlemek yerine nedenini açıkla
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Icon(Icons.info_outline,
                    size: 18, color: context.colors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Randevuya 2 saatten az kaldığı için iptal edilemez. '
                    'Lütfen kliniği arayınız.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: context.colors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
