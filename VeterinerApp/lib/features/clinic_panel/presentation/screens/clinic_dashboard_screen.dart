import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/notification_bell.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/stat_card.dart';

class ClinicDashboardScreen extends StatefulWidget {
  const ClinicDashboardScreen({super.key});

  @override
  State<ClinicDashboardScreen> createState() => _ClinicDashboardScreenState();
}

class _ClinicDashboardScreenState extends State<ClinicDashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

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
      final response = await dio.get('/clinics/my-clinic/dashboard');
      if (response.data['success'] == true) {
        setState(() {
          _dashboardData = response.data['data'];
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['message'] ?? 'Veriler yüklenemedi';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Bir hata oluştu.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingIndicator();
    if (_errorMessage != null) {
      return ErrorState(message: _errorMessage!, onRetry: _loadDashboard);
    }

    final data = _dashboardData!;
    final adminName = data['adminName'] ?? '';
    final clinicName = data['clinicName'] ?? '';
    final todayCount = data['todayAppointmentCount'] ?? 0;
    final pendingCount = data['pendingAppointmentCount'] ?? 0;
    final vetCount = data['activeVetCount'] ?? 0;
    final upcoming = data['upcomingAppointments'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: context.scheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(adminName, clinicName),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                        icon: Icons.calendar_today_outlined,
                        value: todayCount.toString(),
                        label: 'Bugün'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: StatCard(
                        icon: Icons.pending_actions,
                        value: pendingCount.toString(),
                        label: 'Bekleyen',
                        accent: context.colors.warning),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: StatCard(
                        icon: Icons.group,
                        value: vetCount.toString(),
                        label: 'Hekimler',
                        accent: context.colors.info),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader('Yaklaşan Randevular'),
                  const SizedBox(height: AppSpacing.sm),
                  if (upcoming.isEmpty)
                    const EmptyState(
                      icon: Icons.event_available_outlined,
                      message: 'Yaklaşan randevu bulunmuyor.',
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: upcoming.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) => _upcomingItem(upcoming[index]),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String adminName, String clinicName) {
    final primary = context.scheme.primary;
    final onPrimary = context.scheme.onPrimary;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primary.withOpacity(0.82)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl + 12),
          bottomRight: Radius.circular(AppRadius.xl + 12),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Merhaba, $adminName',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: onPrimary)),
                  ),
                  NotificationBell(color: onPrimary),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.local_hospital, color: onPrimary.withOpacity(0.85), size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Text(clinicName,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: onPrimary.withOpacity(0.9))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _upcomingItem(dynamic appt) {
    final date = DateTime.tryParse(appt['appointmentDate'] ?? '')?.toLocal();
    final timeStr = date != null
        ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : '';
    final primary = context.scheme.primary;

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: AppRadius.mdAll,
            ),
            child: Text(timeStr,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: primary)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appt['animalName'] ?? '',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text('Hekim: ${appt['vetName']}',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
