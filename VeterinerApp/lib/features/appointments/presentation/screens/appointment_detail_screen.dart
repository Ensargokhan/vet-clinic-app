import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Randevuyu İptal Et'),
        content: const Text('Bu randevuyu iptal etmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('İptal Et', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final dio = DioClient().dio;
      await dio.put('/appointments/${widget.appointmentId}/cancel');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Randevu iptal edildi.'), backgroundColor: Colors.green),
        );
        _fetchAppointment(); // Refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İptal işlemi başarısız.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Randevu Detayı', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_appointment == null) return const SizedBox.shrink();

    final appt = _appointment!;
    final date = DateTime.parse(appt['appointmentDate']);
    final status = appt['status'] ?? 'pending';
    final isPending = status == 'pending';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _statusGradient(status),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(_statusIcon(status), color: Colors.white, size: 48),
                const SizedBox(height: 12),
                Text(
                  _statusText(status),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(date),
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Info Cards
          _buildInfoCard(
            icon: Icons.pets,
            title: 'Hasta',
            value: appt['animalName'] ?? 'Bilinmiyor',
          ),
          _buildInfoCard(
            icon: Icons.person,
            title: 'Veteriner Hekim',
            value: appt['vetName'] ?? 'Bilinmiyor',
          ),
          _buildInfoCard(
            icon: Icons.access_time,
            title: 'Süre',
            value: '${appt['durationMinutes'] ?? 30} dakika',
          ),
          if (appt['reason'] != null && appt['reason'].toString().isNotEmpty)
            _buildInfoCard(
              icon: Icons.description,
              title: 'Sebep',
              value: appt['reason'],
            ),
          if (appt['notes'] != null && appt['notes'].toString().isNotEmpty)
            _buildInfoCard(
              icon: Icons.note,
              title: 'Notlar',
              value: appt['notes'],
            ),

          const SizedBox(height: 32),

          // Cancel Button
          if (isPending)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cancelAppointment,
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                label: const Text('Randevuyu İptal Et', style: TextStyle(color: Colors.red, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String value}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _statusGradient(String status) {
    switch (status) {
      case 'completed': return [Colors.green.shade400, Colors.green.shade700];
      case 'cancelled': return [Colors.red.shade400, Colors.red.shade700];
      default: return [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)];
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed': return Icons.check_circle;
      case 'cancelled': return Icons.cancel;
      default: return Icons.schedule;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'completed': return 'Tamamlandı';
      case 'cancelled': return 'İptal Edildi';
      default: return 'Beklemede';
    }
  }
}
