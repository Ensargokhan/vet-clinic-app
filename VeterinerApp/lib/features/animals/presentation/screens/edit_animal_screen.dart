import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/loading_indicator.dart';

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
          SnackBar(
            content: const Text('Hayvan detayları yüklenemedi.'),
            backgroundColor: context.scheme.error,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Hayvan başarıyla güncellendi!'),
            backgroundColor: context.colors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: context.scheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profili Düzenle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Adı',
                icon: Icons.pets,
                validator: (v) => Validators.required(v, alan: 'Ad'),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField(
                controller: _speciesController,
                label: 'Türü (Kedi, Köpek vb.)',
                icon: Icons.category_outlined,
                validator: (v) => Validators.required(v, alan: 'Tür'),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField(
                controller: _breedController,
                label: 'Irkı (Opsiyonel)',
                icon: Icons.merge_type,
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Cinsiyet (Opsiyonel)',
                  prefixIcon: Icon(Icons.transgender),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Erkek')),
                  DropdownMenuItem(value: 'female', child: Text('Dişi')),
                  DropdownMenuItem(value: 'unknown', child: Text('Bilinmiyor')),
                ],
                onChanged: (val) => setState(() => _selectedGender = val),
              ),
              const SizedBox(height: AppSpacing.lg),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Doğum Tarihi (Opsiyonel)',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  child: Text(
                    _birthDate == null ? 'Seçiniz' : DateFormat('dd.MM.yyyy').format(_birthDate!),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _birthDate == null
                              ? context.colors.textSecondary
                              : context.scheme.onSurface,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField(
                controller: _weightController,
                label: 'Kilo (Opsiyonel)',
                icon: Icons.scale_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  child: _isSaving
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: context.scheme.onPrimary),
                        )
                      : const Text('Değişiklikleri Kaydet'),
                ),
              ),
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
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: validator,
    );
  }
}
