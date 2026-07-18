import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../ai_assistant/data/models/ai_report_model.dart';
import '../../../ai_assistant/presentation/widgets/ai_report_view.dart';

class VetAppointmentsScreen extends StatefulWidget {
  const VetAppointmentsScreen({super.key});

  @override
  State<VetAppointmentsScreen> createState() => _VetAppointmentsScreenState();
}

class _VetAppointmentsScreenState extends State<VetAppointmentsScreen> {
  List<dynamic> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = DioClient().dio;
      final response = await dio.get('/vets/my-appointments');
      if (response.data['success'] == true) {
        setState(() {
          _appointments = response.data['data'] ?? [];
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['message'] ?? 'Randevular yüklenemedi';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Beklenmeyen bir hata oluştu.';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(int appointmentId, String newStatus, String? notes) async {
    try {
      final dio = DioClient().dio;
      await dio.put('/vets/my-appointments/$appointmentId/status', data: {
        'status': newStatus,
        'notes': notes,
      });
      _loadAppointments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Randevu durumu güncellendi'),
            backgroundColor: context.colors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Backend mesajını göster (örn. eşzamanlı güncelleme uyarısı)
        String message = 'Hata oluştu';
        if (e is DioException) {
          final backendMessage = e.response?.data?['message'];
          if (backendMessage is String && backendMessage.isNotEmpty) {
            message = backendMessage;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: context.scheme.error),
        );
      }
    }
  }

  void _showStatusDialog(Map<String, dynamic> apt) {
    final notesCtrl = TextEditingController(text: apt['notes'] ?? '');
    final String currentStatus = apt['status'] ?? 'pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Randevu Durumunu Güncelle',
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              if (currentStatus == 'pending') ...[
                _btn(sheetContext, 'Onayla', sheetContext.colors.info, () {
                  Navigator.pop(sheetContext);
                  _updateStatus(apt['id'], 'confirmed', notesCtrl.text);
                }),
                const SizedBox(height: AppSpacing.sm),
                _btn(sheetContext, 'Reddet', sheetContext.scheme.error, () {
                  Navigator.pop(sheetContext);
                  _updateStatus(apt['id'], 'cancelled', notesCtrl.text);
                }),
              ] else if (currentStatus == 'confirmed') ...[
                _btn(sheetContext, 'Tamamlandı', sheetContext.colors.success, () {
                  Navigator.pop(sheetContext);
                  _updateStatus(apt['id'], 'completed', notesCtrl.text);
                }),
                const SizedBox(height: AppSpacing.sm),
                _btn(sheetContext, 'Gelmedi', sheetContext.colors.warning, () {
                  Navigator.pop(sheetContext);
                  _updateStatus(apt['id'], 'no_show', notesCtrl.text);
                }),
                const SizedBox(height: AppSpacing.sm),
                _btn(sheetContext, 'İptal Et', sheetContext.scheme.error, () {
                  Navigator.pop(sheetContext);
                  _updateStatus(apt['id'], 'cancelled', notesCtrl.text);
                }),
              ],
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Not Ekle (İsteğe Bağlı)'),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  // Randevuya bağlı AI ön raporu tembel getir → bottom sheet; yoksa bilgi ver.
  Future<void> _showAiReport(int appointmentId) async {
    try {
      final res = await DioClient()
          .dio
          .get('/ai/reports/by-appointment/$appointmentId');
      if (res.data['success'] == true && mounted) {
        AiReportView.showSheet(context, AiReportModel.fromJson(res.data['data']));
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.statusCode == 404
          ? 'Bu randevuya bağlı ön rapor yok.'
          : (e.response?.data?['message'] ?? 'Ön rapor getirilemedi.');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Beklenmeyen bir hata oluştu.')),
        );
      }
    }
  }

  Widget _btn(BuildContext ctx, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(backgroundColor: color),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Randevularım'),
          bottom: TabBar(
            labelColor: context.scheme.primary,
            unselectedLabelColor: context.colors.textSecondary,
            indicatorColor: context.scheme.primary,
            tabs: const [
              Tab(text: 'Bugün'),
              Tab(text: 'Yaklaşan'),
              Tab(text: 'Geçmiş'),
            ],
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingIndicator();
    if (_errorMessage != null) {
      return ErrorState(message: _errorMessage!, onRetry: _loadAppointments);
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    final todayAppointments = _appointments.where((apt) {
      final aptDate = DateTime.parse(apt['appointmentDate']);
      return aptDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
          aptDate.isBefore(tomorrowStart);
    }).toList()
      ..sort((a, b) =>
          DateTime.parse(a['appointmentDate']).compareTo(DateTime.parse(b['appointmentDate'])));

    final upcomingAppointments = _appointments.where((apt) {
      final aptDate = DateTime.parse(apt['appointmentDate']);
      final status = apt['status'];
      return aptDate.isAfter(tomorrowStart.subtract(const Duration(seconds: 1))) &&
          (status == 'pending' || status == 'confirmed');
    }).toList()
      ..sort((a, b) =>
          DateTime.parse(a['appointmentDate']).compareTo(DateTime.parse(b['appointmentDate'])));

    final pastAppointments = _appointments.where((apt) {
      final aptDate = DateTime.parse(apt['appointmentDate']);
      final status = apt['status'];
      final isPastDate = aptDate.isBefore(todayStart);
      final isTerminalStatus = status == 'completed' ||
          status == 'cancelled' ||
          status == 'expired' ||
          status == 'no_show';
      return isPastDate || isTerminalStatus;
    }).toList()
      ..sort((a, b) =>
          DateTime.parse(b['appointmentDate']).compareTo(DateTime.parse(a['appointmentDate'])));

    return TabBarView(
      children: [
        _buildList(todayAppointments, 'Bugün için randevunuz bulunmuyor.'),
        _buildList(upcomingAppointments, 'Yaklaşan randevunuz bulunmuyor.'),
        _buildList(pastAppointments, 'Geçmiş randevunuz bulunmuyor.'),
      ],
    );
  }

  Widget _buildList(List<dynamic> list, String emptyMessage) {
    if (list.isEmpty) {
      return EmptyState(icon: Icons.event_busy_outlined, message: emptyMessage);
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: context.scheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => _card(list[index]),
      ),
    );
  }

  Widget _card(Map<String, dynamic> apt) {
    final date = DateTime.parse(apt['appointmentDate']);
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final canEdit = apt['status'] == 'pending' || apt['status'] == 'confirmed';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(apt['animalName'] ?? '',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              StatusBadge(apt['status']),
              if (canEdit)
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: context.scheme.primary, size: 20),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showStatusDialog(apt),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _metaRow(Icons.person_outline, apt['ownerName'] ?? ''),
          const SizedBox(height: AppSpacing.xs),
          _metaRow(Icons.calendar_today_outlined, '$dateStr - $timeStr'),
          if (apt['reason'] != null && apt['reason'].toString().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Neden: ${apt['reason']}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontStyle: FontStyle.italic)),
          ],
          // Hasta sahibi iptal ettiyse gerekçesini hekime göster
          if (apt['status'] == 'cancelled' &&
              apt['cancellationReason'] != null &&
              apt['cancellationReason'].toString().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _metaRow(Icons.cancel_outlined,
                'İptal gerekçesi: ${apt['cancellationReason']}'),
          ],
          if (apt['status'] == 'confirmed' || apt['status'] == 'completed') ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showAiReport(apt['id']),
                  icon: const Icon(Icons.smart_toy_outlined, size: 18),
                  label: const Text('AI Ön Rapor'),
                ),
                TextButton.icon(
                  onPressed: () => context.push(
                    '/animals/${apt['animalId']}/vaccines',
                    extra: {'animalName': apt['animalName']},
                  ),
                  icon: const Icon(Icons.vaccines_outlined, size: 18),
                  label: const Text('Aşılar'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.colors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}
