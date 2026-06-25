import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/appointment_status.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/appointment_model.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final dio = DioClient().dio;
      final response = await dio.get('/appointments'); // Kullanıcının randevuları
      if (response.data['success']) {
        final List<dynamic> data = response.data['data'];
        setState(() {
          _appointments = data.map((e) => AppointmentModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Randevularım'),
          bottom: TabBar(
            labelColor: context.scheme.primary,
            unselectedLabelColor: context.colors.textSecondary,
            indicatorColor: context.scheme.primary,
            tabs: const [
              Tab(text: 'Yaklaşanlar'),
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

    final upcoming = _appointments
        .where((a) => a.status == 'pending' || a.status == 'confirmed')
        .toList()
      ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

    final past = _appointments
        .where((a) => a.status != 'pending' && a.status != 'confirmed')
        .toList()
      ..sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

    return TabBarView(
      children: [
        _buildList(upcoming, 'Yaklaşan randevunuz bulunmuyor.'),
        _buildList(past, 'Geçmiş randevunuz bulunmuyor.'),
      ],
    );
  }

  Widget _buildList(List<AppointmentModel> list, String emptyMessage) {
    if (list.isEmpty) {
      return EmptyState(icon: Icons.event_busy_outlined, message: emptyMessage);
    }

    return RefreshIndicator(
      onRefresh: _fetchAppointments,
      color: context.scheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => _appointmentCard(list[index]),
      ),
    );
  }

  Widget _appointmentCard(AppointmentModel appt) {
    final date = DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(appt.appointmentDate);
    final statusColor = AppointmentStatus.color(context, appt.status);

    return AppCard(
      onTap: () => context.push('/appointments/${appt.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(Icons.calendar_today_outlined, color: statusColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                if (appt.animalName != null)
                  _metaRow(Icons.pets, appt.animalName!),
                if (appt.vetName != null)
                  _metaRow(Icons.medical_services_outlined, appt.vetName!),
                if (appt.reason != null && appt.reason!.isNotEmpty)
                  _metaRow(Icons.notes_outlined, appt.reason!),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusBadge(appt.status),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: context.colors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
