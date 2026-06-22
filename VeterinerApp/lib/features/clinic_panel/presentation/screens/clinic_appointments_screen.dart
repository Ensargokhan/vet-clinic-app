import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

class ClinicAppointmentsScreen extends StatefulWidget {
  const ClinicAppointmentsScreen({super.key});

  @override
  State<ClinicAppointmentsScreen> createState() => _ClinicAppointmentsScreenState();
}

class _ClinicAppointmentsScreenState extends State<ClinicAppointmentsScreen> with SingleTickerProviderStateMixin {
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
        return apptDay.isAfter(today) && (appt['status'] == 'pending' || appt['status'] == 'confirmed');
      } else { // past
        return apptDay.isBefore(today) || appt['status'] == 'cancelled' || appt['status'] == 'completed' || appt['status'] == 'no_show';
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
          const SnackBar(content: Text('Randevu durumu güncellendi'), backgroundColor: Colors.green),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?['message'] ?? 'Hata oluştu'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Beklenmeyen hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showStatusDialog(Map<String, dynamic> appt) {
    final notesCtrl = TextEditingController(text: appt['notes'] ?? '');
    String currentStatus = appt['status'] ?? 'pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Randevu Durumunu Güncelle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (currentStatus == 'pending') ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateStatus(appt['id'], 'confirmed', notesCtrl.text);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Center(child: Text('Onayla', style: TextStyle(color: Colors.white))),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateStatus(appt['id'], 'cancelled', notesCtrl.text);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Center(child: Text('Reddet', style: TextStyle(color: Colors.white))),
                ),
              ] else if (currentStatus == 'confirmed') ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateStatus(appt['id'], 'completed', notesCtrl.text);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Center(child: Text('Tamamlandı', style: TextStyle(color: Colors.white))),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateStatus(appt['id'], 'cancelled', notesCtrl.text);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Center(child: Text('İptal Et', style: TextStyle(color: Colors.white))),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Not Ekle (İsteğe Bağlı)'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentList(String type) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            TextButton(onPressed: _loadAppointments, child: const Text('Tekrar Dene')),
          ],
        ),
      );
    }

    final filteredList = _getFilteredAppointments(type);

    if (filteredList.isEmpty) {
      return const Center(child: Text('Bu kategoride randevu bulunmuyor.', style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredList.length,
        itemBuilder: (context, index) {
          final appt = filteredList[index];
          final date = DateTime.tryParse(appt['appointmentDate'] ?? '')?.toLocal();
          final timeStr = date != null ? DateFormat('HH:mm').format(date) : '';
          final dateStr = date != null ? DateFormat('dd MMM', 'tr_TR').format(date) : '';
          
          Color statusColor;
          String statusText;
          switch (appt['status']) {
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
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            shadowColor: Colors.black12,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.pets, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            appt['animalName'] ?? '',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (appt['status'] != 'completed' && appt['status'] != 'cancelled')
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showStatusDialog(appt),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text('Sahibi: ${appt['ownerName']}', style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.medical_services_outlined, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text('Hekim: ${appt['vetName']}', style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Klinik Randevuları', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
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
