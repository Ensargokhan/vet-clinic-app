import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/info_row.dart';

const String _imgBase = 'http://10.0.2.2:5295';

class CreateAppointmentScreen extends StatefulWidget {
  final int vetId;
  final int clinicId;
  const CreateAppointmentScreen({super.key, required this.vetId, required this.clinicId});

  @override
  State<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  late final PageController _pageController;
  int _currentStep = 0;

  // Step 1: Vet Selection
  int? _selectedVetId;
  Map<String, dynamic>? _selectedVetInfo;
  List<dynamic> _clinicVets = [];
  bool _isLoadingVets = false;

  // Step 2: Date & Time Selection
  DateTime? _selectedDate;
  String? _selectedTime;
  List<dynamic> _availableSlots = [];
  bool _isLoadingSlots = false;

  // Step 3: Animal & Reason
  int? _selectedAnimalId;
  Map<String, dynamic>? _selectedAnimalInfo;
  List<dynamic> _myAnimals = [];
  bool _isLoadingAnimals = false;
  final _reasonController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    int initialPage = widget.vetId != 0 ? 1 : 0;
    _pageController = PageController(initialPage: initialPage);
    _currentStep = initialPage;

    if (widget.clinicId != 0) {
      _fetchClinicVets();
    }

    if (widget.vetId != 0) {
      _selectedVetId = widget.vetId;
      var nextDate = DateTime.now().add(const Duration(days: 1));
      while (nextDate.weekday == DateTime.saturday || nextDate.weekday == DateTime.sunday) {
        nextDate = nextDate.add(const Duration(days: 1));
      }
      _selectedDate = nextDate;
      _fetchSlots(_selectedDate!);
    }
    _fetchMyAnimals();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchClinicVets() async {
    if (widget.clinicId == 0) return;
    setState(() => _isLoadingVets = true);
    try {
      final dio = DioClient().dio;
      final response = await dio.get('/clinics/${widget.clinicId}');
      if (response.data['success']) {
        setState(() {
          _clinicVets = response.data['data']['vets'] ?? [];
          if (_selectedVetId != null && _selectedVetInfo == null) {
            final matches = _clinicVets.where((v) => v['id'] == _selectedVetId);
            if (matches.isNotEmpty) {
              _selectedVetInfo = matches.first;
            }
          }
        });
      }
    } catch (e) {
      // handle error
    } finally {
      setState(() => _isLoadingVets = false);
    }
  }

  Future<void> _fetchMyAnimals() async {
    setState(() => _isLoadingAnimals = true);
    try {
      final dio = DioClient().dio;
      final response = await dio.get('/animals');
      if (response.data['success']) {
        setState(() {
          _myAnimals = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      // handle error
    } finally {
      setState(() => _isLoadingAnimals = false);
    }
  }

  Future<void> _fetchSlots(DateTime date) async {
    if (_selectedVetId == null) return;
    setState(() => _isLoadingSlots = true);
    try {
      final dio = DioClient().dio;
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final response = await dio.get('/vets/$_selectedVetId/available-slots?date=$dateStr');
      if (response.data['success']) {
        setState(() {
          _availableSlots = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      // handle error
    } finally {
      setState(() => _isLoadingSlots = false);
    }
  }

  Future<void> _submitAppointment() async {
    if (_selectedVetId == null || _selectedDate == null || _selectedTime == null || _selectedAnimalId == null) return;
    setState(() => _isSubmitting = true);

    try {
      final dio = DioClient().dio;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final appointmentDate = '${dateStr}T$_selectedTime:00Z';

      await dio.post('/appointments', data: {
        'animalId': _selectedAnimalId,
        'vetId': _selectedVetId,
        'reason': _reasonController.text,
        'appointmentDate': appointmentDate,
      });

      if (mounted) {
        _showSuccessModal();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Randevu alınamadı.'), backgroundColor: context.scheme.error),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: dialogContext.colors.success, size: 72),
            const SizedBox(height: AppSpacing.lg),
            Text('Başarılı!', style: Theme.of(dialogContext).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            const Text('Randevunuz başarıyla oluşturuldu.', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.go('/appointments');
                },
                child: const Text('Randevularıma Git'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.go('/home');
                },
                child: const Text('Ana Sayfaya Dön'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  Widget _stepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildStepIndicator() {
    final primary = context.scheme.primary;
    final inactive = context.colors.outline;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final isActive = _currentStep == index;
          final isCompleted = _currentStep > index;
          final on = isActive || isCompleted;
          return Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: on ? primary : inactive,
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(Icons.check, color: context.scheme.onPrimary, size: 16)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive ? context.scheme.onPrimary : context.colors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              if (index < 3)
                Container(width: 40, height: 2, color: isCompleted ? primary : inactive),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildVetSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('Hekim Seçimi', 'Randevu almak istediğiniz hekimi seçin.'),
          if (_isLoadingVets)
            const Center(child: CircularProgressIndicator())
          else if (_clinicVets.isEmpty)
            const Center(child: Text('Klinikte kayıtlı hekim bulunamadı.'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _clinicVets.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final vet = _clinicVets[index];
                final isSelected = _selectedVetId == vet['id'];
                final photo = vet['profilePhoto'];
                return _selectableTile(
                  selected: isSelected,
                  onTap: () => setState(() {
                    _selectedVetId = vet['id'];
                    _selectedVetInfo = vet;
                  }),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: context.scheme.primary.withValues(alpha: 0.12),
                        backgroundImage: photo != null ? NetworkImage('$_imgBase$photo') : null,
                        child: photo == null
                            ? Icon(Icons.person, color: context.scheme.primary)
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vet['fullName'] ?? '',
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(vet['specialty'] ?? vet['title'] ?? '',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: context.scheme.primary),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDateSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('Tarih & Saat', 'Uygun olduğunuz tarih ve saati seçin.'),
          InkWell(
            borderRadius: AppRadius.lgAll,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                  _selectedTime = null;
                });
                _fetchSlots(date);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                border: Border.all(color: context.scheme.primary),
                borderRadius: AppRadius.lgAll,
                color: context.scheme.primary.withValues(alpha: 0.06),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, color: context.scheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    _selectedDate == null
                        ? 'Tarih Seçmek İçin Dokunun'
                        : DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate!),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: context.scheme.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_selectedDate != null) ...[
            Text('Müsait Saatler', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            if (_isLoadingSlots)
              const Center(child: CircularProgressIndicator())
            else if (_availableSlots.isEmpty)
              Text('Bu tarihte uygun randevu bulunmuyor.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: context.scheme.error))
            else
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: _availableSlots.map((slot) {
                  final time = slot['time'].toString().substring(0, 5);
                  final isAvailable = slot['isAvailable'] as bool;
                  final isSelected = _selectedTime == time;
                  final primary = context.scheme.primary;
                  return InkWell(
                    onTap: isAvailable ? () => setState(() => _selectedTime = time) : null,
                    borderRadius: AppRadius.smAll,
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary
                            : (isAvailable ? context.scheme.surface : context.colors.surfaceAlt),
                        border: Border.all(
                          color: isSelected
                              ? primary
                              : (isAvailable ? primary.withValues(alpha: 0.3) : context.colors.outline),
                        ),
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Center(
                        child: Text(
                          time,
                          style: TextStyle(
                            color: isSelected
                                ? context.scheme.onPrimary
                                : (isAvailable
                                    ? context.scheme.onSurface
                                    : context.colors.textSecondary),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimalSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('Hasta Detayı', 'Hangi evcil hayvanınız için randevu alıyorsunuz?'),
          if (_isLoadingAnimals)
            const Center(child: CircularProgressIndicator())
          else if (_myAnimals.isEmpty)
            Center(
              child: Column(
                children: [
                  const Text('Kayıtlı hayvanınız bulunmuyor.'),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => context.push('/animals/add'),
                    child: const Text('Yeni Hayvan Ekle'),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _myAnimals.length,
                itemBuilder: (context, index) {
                  final animal = _myAnimals[index];
                  final isSelected = _selectedAnimalId == animal['id'];
                  final primary = context.scheme.primary;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedAnimalId = animal['id'];
                      _selectedAnimalInfo = animal;
                    }),
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: isSelected ? primary.withValues(alpha: 0.08) : context.scheme.surface,
                        borderRadius: AppRadius.lgAll,
                        border: Border.all(
                          color: isSelected ? primary : context.colors.outline,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: primary.withValues(alpha: 0.12),
                            backgroundImage: animal['photoUrl'] != null
                                ? NetworkImage(animal['photoUrl'])
                                : null,
                            child: animal['photoUrl'] == null
                                ? Icon(Icons.pets, size: 32, color: primary)
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            animal['name'] ?? '',
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(animal['species'] ?? '',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          Text('Randevu Sebebi', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Örn: Karma aşısı yapılacak, halsizlik şikayeti var...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStep() {
    final vetName = _selectedVetInfo != null ? _selectedVetInfo!['fullName'] : 'Hekim ID: $_selectedVetId';
    final animalName = _selectedAnimalInfo != null ? _selectedAnimalInfo!['name'] : 'Hayvan ID: $_selectedAnimalId';
    final dateStr = _selectedDate != null ? DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate!) : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('Randevu Özeti', 'Lütfen bilgileri kontrol edip onaylayın.'),
          AppCard(
            child: Column(
              children: [
                InfoRow(icon: Icons.medical_services_outlined, label: 'Hekim', value: vetName),
                InfoRow(icon: Icons.calendar_today_outlined, label: 'Tarih', value: dateStr),
                InfoRow(icon: Icons.access_time, label: 'Saat', value: _selectedTime ?? ''),
                InfoRow(icon: Icons.pets, label: 'Hasta', value: animalName),
                if (_reasonController.text.isNotEmpty)
                  InfoRow(icon: Icons.notes_outlined, label: 'Neden', value: _reasonController.text),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAppointment,
              child: _isSubmitting
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: context.scheme.onPrimary),
                    )
                  : const Text('Randevuyu Onayla'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectableTile({
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? context.scheme.primary.withValues(alpha: 0.08)
                : context.scheme.surface,
            border: Border.all(
              color: selected ? context.scheme.primary : context.colors.outline,
              width: selected ? 2 : 1,
            ),
            borderRadius: AppRadius.lgAll,
          ),
          child: child,
        ),
      ),
    );
  }

  bool _canGoNext() {
    if (_currentStep == 0 && _selectedVetId == null) return false;
    if (_currentStep == 1 && (_selectedDate == null || _selectedTime == null)) return false;
    if (_currentStep == 2 && _selectedAnimalId == null) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Randevu Al')),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildVetSelectionStep(),
                _buildDateSelectionStep(),
                _buildAnimalSelectionStep(),
                _buildSummaryStep(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                TextButton.icon(
                  onPressed: _prevStep,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Geri'),
                )
              else
                const SizedBox(width: 80),
              if (_currentStep < 3)
                ElevatedButton(
                  onPressed: _canGoNext() ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Devam Et'),
                      SizedBox(width: AppSpacing.sm),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
