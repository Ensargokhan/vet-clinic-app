import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
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
          title: const Text('Randevularım', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
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
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));

    final upcomingAppointments = _appointments.where((a) => a.status == 'pending' || a.status == 'confirmed').toList();
    upcomingAppointments.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

    final pastAppointments = _appointments.where((a) => a.status != 'pending' && a.status != 'confirmed').toList();
    pastAppointments.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

    return TabBarView(
      children: [
        _buildList(upcomingAppointments, 'Yaklaşan randevunuz bulunmuyor.'),
        _buildList(pastAppointments, 'Geçmiş randevunuz bulunmuyor.'),
      ],
    );
  }

  Widget _buildList(List<AppointmentModel> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final appt = list[index];
        final date = DateFormat('dd MMM yyyy, HH:mm').format(appt.appointmentDate);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/appointments/${appt.id}'),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: appt.status == 'cancelled' || appt.status == 'expired' || appt.status == 'no_show'
                    ? Colors.red.withOpacity(0.1) 
                    : AppTheme.primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.calendar_today,
                  color: appt.status == 'cancelled' || appt.status == 'expired' || appt.status == 'no_show' 
                      ? Colors.red 
                      : AppTheme.primaryColor,
                ),
              ),
              title: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (appt.animalName != null) Text('🐾 ${appt.animalName}'),
                  if (appt.vetName != null) Text('👨‍⚕️ ${appt.vetName}'),
                  if (appt.reason != null && appt.reason!.isNotEmpty) Text('📋 ${appt.reason}'),
                ],
              ),
              trailing: _buildStatusChip(appt.status),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    switch (status) {
      case 'confirmed':
        color = Colors.blue;
        text = 'Onaylandı';
        break;
      case 'completed':
        color = Colors.green;
        text = 'Tamamlandı';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'İptal Edildi';
        break;
      case 'expired':
        color = Colors.grey;
        text = 'Süresi Doldu';
        break;
      case 'no_show':
        color = Colors.orange.shade700;
        text = 'Gidilmedi';
        break;
      default:
        color = Colors.orange;
        text = 'Bekliyor';
    }
    return Chip(
      label: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
    );
  }
}
