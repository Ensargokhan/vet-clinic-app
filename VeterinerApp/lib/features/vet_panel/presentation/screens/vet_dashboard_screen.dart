import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/status_badge.dart';

const String _imgBase = 'http://10.0.2.2:5295';

class VetDashboardScreen extends StatefulWidget {
  const VetDashboardScreen({super.key});

  @override
  State<VetDashboardScreen> createState() => _VetDashboardScreenState();
}

class _VetDashboardScreenState extends State<VetDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = DioClient().dio;
      final response = await dio.get('/vets/my-dashboard');
      if (response.data['success'] == true) {
        setState(() {
          _dashboardData = response.data['data'];
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['message'] ?? 'Dashboard yüklenemedi';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Beklenmeyen bir hata oluştu.';
        _isLoading = false;
      });
    }
  }

  Widget _buildUpcomingAppointment(Map<String, dynamic> apt) {
    final date = DateTime.parse(apt['appointmentDate']);
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final primary = context.scheme.primary;

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(Icons.pets, color: primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(apt['animalName'] ?? '',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text('Sahibi: ${apt['ownerName']}',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: context.colors.textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(timeStr, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ],
            ),
          ),
          StatusBadge(apt['status']),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: _isLoading
          ? const LoadingIndicator()
          : _errorMessage != null
              ? ErrorState(message: _errorMessage!, onRetry: _loadDashboard)
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  color: context.scheme.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _welcome(),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                icon: Icons.today,
                                value: _dashboardData?['todayAppointmentCount']?.toString() ?? '0',
                                label: 'Bugün',
                                accent: context.colors.info,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: StatCard(
                                icon: Icons.pending_actions,
                                value: _dashboardData?['pendingAppointmentCount']?.toString() ?? '0',
                                label: 'Bekleyen',
                                accent: context.colors.warning,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        StatCard(
                          icon: Icons.calendar_month,
                          value: _dashboardData?['totalAppointmentCount']?.toString() ?? '0',
                          label: 'Toplam Randevu',
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const SectionHeader('Yaklaşan Randevular'),
                        const SizedBox(height: AppSpacing.sm),
                        if (_dashboardData?['upcomingAppointments'] != null &&
                            (_dashboardData!['upcomingAppointments'] as List).isNotEmpty)
                          ...List.generate(
                            (_dashboardData!['upcomingAppointments'] as List).length,
                            (i) {
                              final list = _dashboardData!['upcomingAppointments'] as List;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: _buildUpcomingAppointment(
                                    list[i] as Map<String, dynamic>),
                              );
                            },
                          )
                        else
                          const EmptyState(
                            icon: Icons.event_available_outlined,
                            message: 'Yaklaşan randevu bulunmuyor.',
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _welcome() {
    final primary = context.scheme.primary;
    final photo = _dashboardData?['profilePhoto'];
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: primary.withOpacity(0.12),
          backgroundImage: photo != null ? NetworkImage('$_imgBase$photo') : null,
          child: photo == null ? Icon(Icons.person, color: primary, size: 30) : null,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hoş Geldiniz,', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                _dashboardData?['fullName'] ?? 'Hekim',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: primary),
              ),
              if (_dashboardData?['clinicName'] != null)
                Text(_dashboardData!['clinicName'],
                    style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
