import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import 'package:dio/dio.dart';

class VetAppointmentsScreen extends StatefulWidget {
  const VetAppointmentsScreen({super.key});

  @override
  State<VetAppointmentsScreen> createState() => _VetAppointmentsScreenState();
}

class _VetAppointmentsScreenState extends State<VetAppointmentsScreen> {
  List<dynamic> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'Tümü';
  final List<String> _filters = ['Tümü', 'Bugün', 'Geçmiş', 'Bekleyen', 'Onaylanmış', 'Tamamlanmış'];

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
          const SnackBar(content: Text('Randevu durumu güncellendi'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hata oluştu'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showStatusDialog(Map<String, dynamic> apt) {
    final notesCtrl = TextEditingController(text: apt['notes'] ?? '');
    String currentStatus = apt['status'] ?? 'pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
                    _updateStatus(apt['id'], 'confirmed', notesCtrl.text);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Center(child: Text('Onayla (Confirmed)', style: TextStyle(color: Colors.white))),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateStatus(apt['id'], 'cancelled', notesCtrl.text);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Center(child: Text('Reddet (Cancelled)', style: TextStyle(color: Colors.white))),
                ),
              ] else if (currentStatus == 'confirmed') ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateStatus(apt['id'], 'completed', notesCtrl.text);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Center(child: Text('Tamamlandı', style: TextStyle(color: Colors.white))),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateStatus(apt['id'], 'no_show', notesCtrl.text);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700),
                  child: const Center(child: Text('Gelmedi', style: TextStyle(color: Colors.white))),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateStatus(apt['id'], 'cancelled', notesCtrl.text);
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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Randevularım', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
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
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    if (_errorMessage != null) return Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)));

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    // Bugün
    final todayAppointments = _appointments.where((apt) {
      final aptDate = DateTime.parse(apt['appointmentDate']);
      return aptDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) && aptDate.isBefore(tomorrowStart);
    }).toList();
    todayAppointments.sort((a, b) => DateTime.parse(a['appointmentDate']).compareTo(DateTime.parse(b['appointmentDate'])));

    // Yaklaşan (Yarın ve sonrası, pending/confirmed)
    final upcomingAppointments = _appointments.where((apt) {
      final aptDate = DateTime.parse(apt['appointmentDate']);
      final status = apt['status'];
      return aptDate.isAfter(tomorrowStart.subtract(const Duration(seconds: 1))) && (status == 'pending' || status == 'confirmed');
    }).toList();
    upcomingAppointments.sort((a, b) => DateTime.parse(a['appointmentDate']).compareTo(DateTime.parse(b['appointmentDate'])));

    // Geçmiş (Dünde kalanlar VEYA durumu completed/cancelled/expired/no_show olanlar)
    final pastAppointments = _appointments.where((apt) {
      final aptDate = DateTime.parse(apt['appointmentDate']);
      final status = apt['status'];
      final isPastDate = aptDate.isBefore(todayStart);
      final isTerminalStatus = status == 'completed' || status == 'cancelled' || status == 'expired' || status == 'no_show';
      return isPastDate || isTerminalStatus;
    }).toList();
    pastAppointments.sort((a, b) => DateTime.parse(b['appointmentDate']).compareTo(DateTime.parse(a['appointmentDate'])));

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
      return Center(child: Text(emptyMessage));
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final apt = list[index];
          final date = DateTime.parse(apt['appointmentDate']);
          final dateStr = '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
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
            case 'expired':
              statusColor = Colors.grey;
              statusText = 'Süresi Doldu';
              break;
            case 'no_show':
              statusColor = Colors.orange.shade700;
              statusText = 'Gelmedi';
              break;
            default:
              statusColor = Colors.orange;
              statusText = 'Bekliyor';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(apt['animalName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(apt['ownerName'] ?? '', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('$dateStr - $timeStr', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                  if (apt['reason'] != null && apt['reason'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Neden: ${apt['reason']}', style: const TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
              trailing: (apt['status'] == 'pending' || apt['status'] == 'confirmed')
                  ? IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
                      onPressed: () => _showStatusDialog(apt),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
