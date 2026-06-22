import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';

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

  // Final Step: Loading for submission
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
      // Start with next available weekday
      var nextDate = DateTime.now().add(const Duration(days: 1));
      while (nextDate.weekday == DateTime.saturday || nextDate.weekday == DateTime.sunday) {
        nextDate = nextDate.add(const Duration(days: 1));
      }
      _selectedDate = nextDate;
      _fetchSlots(_selectedDate!);
    }
    _fetchMyAnimals();
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
      final appointmentDate = '${dateStr}T$_selectedTime:00Z'; // Timezone adjustments might be needed based on DB config

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Randevu alınamadı.'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 16),
            const Text('Başarılı!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Randevunuz başarıyla oluşturuldu.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.go('/home'); // Go to main screen
                },
                child: const Text('Randevularıma Git'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  context.go('/home'); // Go to main screen
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

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          bool isActive = _currentStep == index;
          bool isCompleted = _currentStep > index;
          return Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted || isActive ? AppTheme.primaryColor : Colors.grey.shade300,
                  boxShadow: isActive ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.4), blurRadius: 8)] : null,
                ),
                child: Center(
                  child: isCompleted 
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text('${index + 1}', style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold)),
                ),
              ),
              if (index < 3)
                Container(
                  width: 40,
                  height: 2,
                  color: isCompleted ? AppTheme.primaryColor : Colors.grey.shade300,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildVetSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hekim Seçimi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Randevu almak istediğiniz hekimi seçin.', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          if (_isLoadingVets)
            const Center(child: CircularProgressIndicator())
          else if (_clinicVets.isEmpty)
            const Center(child: Text('Klinikte kayıtlı hekim bulunamadı.'))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _clinicVets.length,
              itemBuilder: (context, index) {
                final vet = _clinicVets[index];
                bool isSelected = _selectedVetId == vet['id'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedVetId = vet['id'];
                      _selectedVetInfo = vet;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
                      border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200, width: isSelected ? 2 : 1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
                        child: Icon(Icons.person, color: isSelected ? Colors.white : Colors.grey.shade600),
                      ),
                      title: Text(vet['fullName'] ?? '', style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text(vet['specialty'] ?? vet['title'] ?? ''),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : null,
                    ),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tarih & Saat', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Uygun olduğunuz tarih ve saati seçin.', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
                    ),
                    child: child!,
                  );
                },
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor),
                borderRadius: BorderRadius.circular(16),
                color: AppTheme.primaryColor.withOpacity(0.05),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                  const SizedBox(width: 16),
                  Text(
                    _selectedDate == null ? 'Tarih Seçmek İçin Dokunun' : DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate!),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          if (_selectedDate != null) ...[
            const Text('Müsait Saatler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (_isLoadingSlots)
              const Center(child: CircularProgressIndicator())
            else if (_availableSlots.isEmpty)
              Center(child: Text('Bu tarihte uygun randevu bulunmuyor.', style: TextStyle(color: Colors.red.shade400)))
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _availableSlots.map((slot) {
                  final time = slot['time'].toString().substring(0, 5);
                  final isAvailable = slot['isAvailable'] as bool;
                  final isSelected = _selectedTime == time;
                  
                  return InkWell(
                    onTap: isAvailable ? () {
                      setState(() => _selectedTime = time);
                    } : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryColor 
                            : (isAvailable ? Colors.white : Colors.grey.shade200),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : (isAvailable ? AppTheme.primaryColor.withOpacity(0.3) : Colors.grey.shade300),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          time,
                          style: TextStyle(
                            color: isSelected ? Colors.white : (isAvailable ? AppTheme.textPrimary : Colors.grey.shade400),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hasta Detayı', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Hangi evcil hayvanınız için randevu alıyorsunuz?', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          
          if (_isLoadingAnimals)
            const Center(child: CircularProgressIndicator())
          else if (_myAnimals.isEmpty)
            Center(
              child: Column(
                children: [
                  const Text('Kayıtlı hayvanınız bulunmuyor.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.push('/animals/add'),
                    child: const Text('Yeni Hayvan Ekle'),
                  )
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
                  bool isSelected = _selectedAnimalId == animal['id'];
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAnimalId = animal['id'];
                        _selectedAnimalInfo = animal;
                      });
                    },
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200),
                        boxShadow: [
                          if (isSelected) BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
                            backgroundImage: animal['photoUrl'] != null ? NetworkImage(animal['photoUrl']) : null,
                            child: animal['photoUrl'] == null 
                                ? Icon(Icons.pets, size: 40, color: isSelected ? Colors.white : AppTheme.primaryColor)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            animal['name'] ?? '',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            animal['species'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white.withOpacity(0.8) : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
          const SizedBox(height: 40),
          const Text('Randevu Sebebi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Örn: Karma aşısı yapılacak, halsizlik şikayeti var...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStep() {
    String vetName = _selectedVetInfo != null ? _selectedVetInfo!['fullName'] : 'Hekim ID: $_selectedVetId';
    String animalName = _selectedAnimalInfo != null ? _selectedAnimalInfo!['name'] : 'Hayvan ID: $_selectedAnimalId';
    String dateStr = _selectedDate != null ? DateFormat('dd MMMM yyyy', 'tr_TR').format(_selectedDate!) : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Randevu Özeti', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Lütfen bilgileri kontrol edip onaylayın.', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                _buildSummaryRow(Icons.person, 'Hekim', vetName),
                const Divider(height: 32),
                _buildSummaryRow(Icons.calendar_today, 'Tarih', dateStr),
                const Divider(height: 32),
                _buildSummaryRow(Icons.access_time, 'Saat', _selectedTime ?? ''),
                const Divider(height: 32),
                _buildSummaryRow(Icons.pets, 'Hasta', animalName),
                if (_reasonController.text.isNotEmpty) ...[
                  const Divider(height: 32),
                  _buildSummaryRow(Icons.notes, 'Neden', _reasonController.text),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Randevuyu Onayla', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ],
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Randevu Al', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable manual swipe
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
          padding: const EdgeInsets.all(24.0),
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
                const SizedBox(width: 80), // placeholder
                
              if (_currentStep < 3)
                ElevatedButton(
                  onPressed: _canGoNext() ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Devam Et'),
                      SizedBox(width: 8),
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
