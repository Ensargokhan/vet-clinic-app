import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';

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
        List<Map<String, dynamic>> loadedSchedules = [];
        for (int i = 0; i < 7; i++) {
          final existing = data.firstWhere((s) => s['dayOfWeek'] == i, orElse: () => null);
          if (existing != null) {
            loadedSchedules.add({
              'dayOfWeek': i,
              'startTime': existing['startTime'],
              'endTime': existing['endTime'],
              'slotDuration': existing['slotDuration'] ?? 30,
              'isActive': existing['isActive'] ?? true,
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
          SnackBar(
            content: const Text('Program başarıyla kaydedildi.'),
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
    );

    if (picked != null) {
      setState(() {
        final formattedTime =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
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
      appBar: AppBar(
        title: const Text('Programım'),
        actions: [
          if (!_isLoading && _errorMessage == null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _isSaving
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : TextButton.icon(
                      onPressed: _saveSchedule,
                      icon: const Icon(Icons.save),
                      label: const Text('Kaydet'),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _errorMessage != null
              ? ErrorState(message: _errorMessage!, onRetry: _loadSchedule)
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: 7,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    int dayIndex = index + 1;
                    if (dayIndex == 7) dayIndex = 0;

                    final schedule = _schedules.firstWhere((s) => s['dayOfWeek'] == dayIndex);
                    final isActive = schedule['isActive'] ?? false;
                    final startStr = schedule['startTime'].toString().substring(0, 5);
                    final endStr = schedule['endTime'].toString().substring(0, 5);

                    return AppCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_days[dayIndex],
                                  style: Theme.of(context).textTheme.titleMedium),
                              Switch(
                                value: isActive,
                                onChanged: (val) => setState(() => schedule['isActive'] = val),
                              ),
                            ],
                          ),
                          if (isActive) ...[
                            const Divider(),
                            Row(
                              children: [
                                Expanded(
                                  child: _timeBox('Başlangıç', startStr,
                                      () => _selectTime(context, dayIndex, true)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                                  child: Icon(Icons.arrow_forward, color: context.colors.textSecondary),
                                ),
                                Expanded(
                                  child: _timeBox('Bitiş', endStr,
                                      () => _selectTime(context, dayIndex, false)),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Text('Randevu Süresi:',
                                    style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(width: AppSpacing.lg),
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
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _timeBox(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.surfaceAlt,
          borderRadius: AppRadius.smAll,
        ),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
