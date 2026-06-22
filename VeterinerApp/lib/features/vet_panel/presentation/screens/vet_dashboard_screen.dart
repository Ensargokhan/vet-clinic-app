import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import 'package:dio/dio.dart';

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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointment(Map<String, dynamic> apt) {
    final date = DateTime.parse(apt['appointmentDate']);
    final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    
    Color statusColor;
    String statusText;
    switch (apt['status']) {
      case 'confirmed':
        statusColor = Colors.blue;
        statusText = 'Onaylandı';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Tamamlandı';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'İptal';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Bekliyor';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pets, color: AppTheme.primaryColor, size: 20),
            ],
          ),
        ),
        title: Text(
          apt['animalName'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sahibi: ${apt['ownerName']}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(timeStr, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  color: AppTheme.primaryColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Section
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 30,
                              backgroundColor: AppTheme.primaryColor,
                              child: Icon(Icons.person, color: Colors.white, size: 30),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hoş Geldiniz,',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                  ),
                                  Text(
                                    _dashboardData?['fullName'] ?? 'Hekim',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  if (_dashboardData?['clinicName'] != null)
                                    Text(
                                      _dashboardData!['clinicName'],
                                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Stats Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Bugün',
                                _dashboardData?['todayAppointmentCount']?.toString() ?? '0',
                                Icons.today,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                'Bekleyen',
                                _dashboardData?['pendingAppointmentCount']?.toString() ?? '0',
                                Icons.pending_actions,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStatCard(
                          'Toplam Randevu',
                          _dashboardData?['totalAppointmentCount']?.toString() ?? '0',
                          Icons.calendar_month,
                          AppTheme.primaryColor,
                        ),
                        
                        const SizedBox(height: 32),
                        const Text(
                          'Yaklaşan Randevular',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Upcoming Appointments
                        if (_dashboardData?['upcomingAppointments'] != null)
                          ...(_dashboardData!['upcomingAppointments'] as List)
                              .map((apt) => _buildUpcomingAppointment(apt as Map<String, dynamic>))
                              .toList()
                        else
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text('Yaklaşan randevu bulunmuyor.'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
