import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';

class EditAnimalScreen extends StatefulWidget {
  final int animalId;
  const EditAnimalScreen({super.key, required this.animalId});

  @override
  State<EditAnimalScreen> createState() => _EditAnimalScreenState();
}

class _EditAnimalScreenState extends State<EditAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  
  DateTime? _birthDate;
  String? _selectedGender;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchAnimal();
  }

  Future<void> _fetchAnimal() async {
    try {
      final dio = DioClient().dio;
      final response = await dio.get('/animals/${widget.animalId}');
      if (response.data['success']) {
        final a = response.data['data'];
        setState(() {
          _nameController.text = a['name'] ?? '';
          _speciesController.text = a['species'] ?? '';
          _breedController.text = a['breed'] ?? '';
          if (a['weight'] != null) _weightController.text = a['weight'].toString();
          
          if (a['birthDate'] != null) {
            _birthDate = DateTime.parse(a['birthDate']);
          }
          
          if (['male', 'female', 'unknown'].contains(a['gender'])) {
            _selectedGender = a['gender'];
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hayvan detayları yüklenemedi.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    try {
      final dio = DioClient().dio;
      
      await dio.put('/animals/${widget.animalId}', data: {
        'name': _nameController.text.trim(),
        'species': _speciesController.text.trim(),
        'breed': _breedController.text.trim().isEmpty ? null : _breedController.text.trim(),
        'gender': _selectedGender,
        'birthDate': _birthDate != null ? DateFormat('yyyy-MM-dd').format(_birthDate!) : null,
        'weight': double.tryParse(_weightController.text.trim()),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hayvan başarıyla güncellendi!'), backgroundColor: Colors.green));
        context.pop(); // Geri dön
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profili Düzenle', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Adı',
                icon: Icons.pets,
                validator: (v) => v!.isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _speciesController,
                label: 'Türü (Kedi, Köpek vb.)',
                icon: Icons.category,
                validator: (v) => v!.isEmpty ? 'Gerekli' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _breedController,
                label: 'Irkı (Opsiyonel)',
                icon: Icons.merge_type,
              ),
              const SizedBox(height: 16),
              
              // Gender Dropdown
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: 'Cinsiyet (Opsiyonel)',
                  prefixIcon: const Icon(Icons.male),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Erkek')),
                  DropdownMenuItem(value: 'female', child: Text('Dişi')),
                  DropdownMenuItem(value: 'unknown', child: Text('Bilinmiyor')),
                ],
                onChanged: (val) {
                  setState(() => _selectedGender = val);
                },
              ),
              const SizedBox(height: 16),

              // BirthDate Picker
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Doğum Tarihi (Opsiyonel)',
                    prefixIcon: const Icon(Icons.calendar_month),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  child: Text(
                    _birthDate == null ? 'Seçiniz' : DateFormat('dd.MM.yyyy').format(_birthDate!),
                    style: TextStyle(color: _birthDate == null ? Colors.grey.shade600 : Colors.black87, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Weight
              _buildTextField(
                controller: _weightController,
                label: 'Kilo (Opsiyonel)',
                icon: Icons.scale,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text('Değişiklikleri Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }
}
