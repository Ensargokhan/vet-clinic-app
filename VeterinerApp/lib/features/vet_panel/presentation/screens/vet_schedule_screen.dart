import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import 'package:dio/dio.dart';

class VetScheduleScreen extends StatefulWidget {
  const VetScheduleScreen({super.key});

  @override
  State<VetScheduleScreen> createState() => _VetScheduleScreenState();
}

class _VetScheduleScreenState extends State<VetScheduleScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSaving = false;

  final List<String> _days = ['Pazar', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'];
  
  // Each schedule item is a map: { dayOfWeek: 0..6, startTime: '09:00', endTime: '17:00', slotDuration: 30, isActive: true }
  List<Map<String, dynamic>> _schedules = [];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = DioClient().dio;
      final response = await dio.get('/vets/my-schedule');

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data'] ?? [];
        
        // Initialize default schedules for all 7 days
        List<Map<String, dynamic>> loadedSchedules = [];
        for (int i = 0; i < 7; i++) {
          final existing = data.firstWhere((s) => s['dayOfWeek'] == i, orElse: () => null);
          if (existing != null) {
            loadedSchedules.add({
              'dayOfWeek': i,
              'startTime': existing['startTime'],
              'endTime': existing['endTime'],
              'slotDuration': existing['slotDuration'] ?? 30,
              'isActive': existing['isActive'] ?? true, // we might need to rely on start/end logic if isActive not strictly given
            });
          } else {
            loadedSchedules.add({
              'dayOfWeek': i,
              'startTime': '09:00:00',
              'endTime': '17:00:00',
              'slotDuration': 30,
              'isActive': false,
            });
          }
        }
        
        setState(() {
          _schedules = loadedSchedules;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['message'] ?? 'Program yüklenemedi';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Beklenmeyen bir hata oluştu.';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);
    try {
      final dio = DioClient().dio;
      await dio.put('/vets/my-schedule', data: _schedules);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Program başarıyla kaydedildi.'), backgroundColor: Colors.green),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?['message'] ?? 'Hata oluştu'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectTime(BuildContext context, int dayIndex, bool isStart) async {
    final timeStr = isStart ? _schedules[dayIndex]['startTime'] : _schedules[dayIndex]['endTime'];
    final parts = timeStr.toString().split(':');
    final currentHour = int.parse(parts[0]);
    final currentMin = int.parse(parts[1]);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMin),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
        if (isStart) {
          _schedules[dayIndex]['startTime'] = formattedTime;
        } else {
          _schedules[dayIndex]['endTime'] = formattedTime;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Programım', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isLoading && _errorMessage == null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _isSaving
                  ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
                  : TextButton.icon(
                      onPressed: _saveSchedule,
                      icon: const Icon(Icons.save, color: AppTheme.primaryColor),
                      label: const Text('Kaydet', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    // Monday is index 1 in the list of days but we might want to display Monday first
                    // Let's just map 0-6 properly (0=Sunday ... 6=Saturday)
                    // Visual order: Monday(1) to Sunday(0)
                    int dayIndex = index + 1;
                    if (dayIndex == 7) dayIndex = 0; // Sunday at the end

                    final schedule = _schedules.firstWhere((s) => s['dayOfWeek'] == dayIndex);
                    final isActive = schedule['isActive'] ?? false;
                    
                    String startStr = schedule['startTime'].toString().substring(0, 5); // 09:00
                    String endStr = schedule['endTime'].toString().substring(0, 5);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _days[dayIndex],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Switch(
                                  value: isActive,
                                  activeColor: AppTheme.primaryColor,
                                  onChanged: (val) {
                                    setState(() {
                                      schedule['isActive'] = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (isActive) ...[
                              const Divider(),
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _selectTime(context, dayIndex, true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text('Başlangıç', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                            const SizedBox(height: 4),
                                            Text(startStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Icon(Icons.arrow_forward, color: Colors.grey),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _selectTime(context, dayIndex, false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          children: [
                                            const Text('Bitiş', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                            const SizedBox(height: 4),
                                            Text(endStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Text('Randevu Süresi:', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButton<int>(
                                      value: schedule['slotDuration'],
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(value: 15, child: Text('15 Dakika')),
                                        DropdownMenuItem(value: 20, child: Text('20 Dakika')),
                                        DropdownMenuItem(value: 30, child: Text('30 Dakika')),
                                        DropdownMenuItem(value: 45, child: Text('45 Dakika')),
                                        DropdownMenuItem(value: 60, child: Text('60 Dakika')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() => schedule['slotDuration'] = val);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
