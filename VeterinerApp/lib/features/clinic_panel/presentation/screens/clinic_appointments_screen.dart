import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/status_badge.dart';

class ClinicAppointmentsScreen extends StatefulWidget {
  const ClinicAppointmentsScreen({super.key});

  @override
  State<ClinicAppointmentsScreen> createState() => _ClinicAppointmentsScreenState();
}

class _ClinicAppointmentsScreenState extends State<ClinicAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = DioClient().dio;
      final response = await dio.get('/clinics/my-clinic/appointments');
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

  List<dynamic> _getFilteredAppointments(String type) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _appointments.where((appt) {
      final apptDate = DateTime.tryParse(appt['appointmentDate'] ?? '')?.toLocal();
      if (apptDate == null) return false;
      final apptDay = DateTime(apptDate.year, apptDate.month, apptDate.day);

      if (type == 'today') {
        return apptDay.isAtSameMomentAs(today) && appt['status'] != 'cancelled';
      } else if (type == 'upcoming') {
        return apptDay.isAfter(today) &&
            (appt['status'] == 'pending' || appt['status'] == 'confirmed');
      } else {
        return apptDay.isBefore(today) ||
            appt['status'] == 'cancelled' ||
            appt['status'] == 'completed' ||
            appt['status'] == 'no_show';
      }
    }).toList();
  }

  Future<void> _updateStatus(int appointmentId, String newStatus, String? notes) async {
    try {
      final dio = DioClient().dio;
      await dio.put('/clinics/my-clinic/appointments/$appointmentId/status', data: {
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
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data?['message'] ?? 'Hata oluştu'),
            backgroundColor: context.scheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Beklenmeyen hata: $e'), backgroundColor: context.scheme.error),
        );
      }
    }
  }

  void _showStatusDialog(Map<String, dynamic> appt) {
    final notesCtrl = TextEditingController(text: appt['notes'] ?? '');
    final String currentStatus = appt['status'] ?? 'pending';

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
                _statusButton(sheetContext, 'Onayla', sheetContext.colors.info, () {
                  Navigator.pop(sheetContext);
                  _updateStatus(appt['id'], 'confirmed', notesCtrl.text);
                }),
                const SizedBox(height: AppSpacing.sm),
                _statusButton(sheetContext, 'Reddet', sheetContext.scheme.error, () {
                  Navigator.pop(sheetContext);
                  _updateStatus(appt['id'], 'cancelled', notesCtrl.text);
                }),
              ] else if (currentStatus == 'confirmed') ...[
                _statusButton(sheetContext, 'Tamamlandı', sheetContext.colors.success, () {
                  Navigator.pop(sheetContext);
                  _updateStatus(appt['id'], 'completed', notesCtrl.text);
                }),
                const SizedBox(height: AppSpacing.sm),
                _statusButton(sheetContext, 'İptal Et', sheetContext.scheme.error, () {
                  Navigator.pop(sheetContext);
                  _updateStatus(appt['id'], 'cancelled', notesCtrl.text);
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

  Widget _statusButton(BuildContext ctx, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(backgroundColor: color),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }

  Widget _buildAppointmentList(String type) {
    if (_isLoading) return const LoadingIndicator();
    if (_errorMessage != null) {
      return ErrorState(message: _errorMessage!, onRetry: _loadAppointments);
    }

    final filteredList = _getFilteredAppointments(type);
    if (filteredList.isEmpty) {
      return const EmptyState(
        icon: Icons.event_busy_outlined,
        message: 'Bu kategoride randevu bulunmuyor.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: context.scheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: filteredList.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => _appointmentCard(filteredList[index]),
      ),
    );
  }

  Widget _appointmentCard(Map<String, dynamic> appt) {
    final date = DateTime.tryParse(appt['appointmentDate'] ?? '')?.toLocal();
    final timeStr = date != null ? DateFormat('HH:mm').format(date) : '';
    final dateStr = date != null ? DateFormat('dd MMM', 'tr_TR').format(date) : '';
    final primary = context.scheme.primary;
    final canEdit = appt['status'] != 'completed' && appt['status'] != 'cancelled';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.pets, color: primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(appt['animalName'] ?? '',
                          style: Theme.of(context).textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              StatusBadge(appt['status']),
              if (canEdit)
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: primary, size: 20),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showStatusDialog(appt),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _metaRow(Icons.person_outline, 'Sahibi: ${appt['ownerName']}'),
          const SizedBox(height: AppSpacing.sm),
          _metaRow(Icons.medical_services_outlined, 'Hekim: ${appt['vetName']}'),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.colors.surfaceAlt,
              borderRadius: AppRadius.mdAll,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _iconText(Icons.calendar_today_outlined, dateStr),
                _iconText(Icons.access_time, timeStr),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.colors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.scheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(text, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Klinik Randevuları'),
        bottom: TabBar(
          controller: _tabController,
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentList('today'),
          _buildAppointmentList('upcoming'),
          _buildAppointmentList('past'),
        ],
      ),
    );
  }
}
