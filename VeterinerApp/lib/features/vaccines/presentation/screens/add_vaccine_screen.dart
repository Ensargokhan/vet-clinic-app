import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/vaccine_model.dart';

/// Hekimin bir hayvana aşı eklemesi/düzenlemesi için form. `animalId` zorunlu; randevu/aşı
/// ekranından geçilir. `vaccine` doluysa düzenleme modu (PUT), boşsa ekleme modu (POST).
class AddVaccineScreen extends StatefulWidget {
  final int animalId;
  final String? animalName;
  final VaccineModel? vaccine;

  const AddVaccineScreen({
    super.key,
    required this.animalId,
    this.animalName,
    this.vaccine,
  });

  @override
  State<AddVaccineScreen> createState() => _AddVaccineScreenState();
}

class _AddVaccineScreenState extends State<AddVaccineScreen> {
  static const String _otherOption = 'Diğer';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  List<String> _vaccineNames = [];
  String? _selectedName;
  bool _isOther = false;

  DateTime _administeredDate = DateTime.now();
  DateTime? _nextDueDate;
  bool _isSaving = false;

  bool get _isEdit => widget.vaccine != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vaccine;
    if (v != null) {
      _administeredDate = v.administeredDate;
      _nextDueDate = v.nextDueDate;
      _notesController.text = v.notes ?? '';
    }
    _loadVaccineNames();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadVaccineNames() async {
    try {
      final response = await DioClient().dio.get('/vaccinenames');
      if (response.data['success'] == true && mounted) {
        final list = List<String>.from(response.data['data'] ?? []);
        setState(() {
          _vaccineNames = list;
          _applyInitialName(list);
        });
      }
    } catch (_) {
      // Liste yüklenemezse dropdown boş kalır; "Diğer" ile yine de aşı girilebilir.
      if (mounted) setState(() => _applyInitialName(_vaccineNames));
    }
  }

  /// Düzenleme modunda mevcut aşı adını dropdown'a veya "Diğer" serbest metnine yerleştir.
  void _applyInitialName(List<String> list) {
    final initial = widget.vaccine?.vaccineName;
    if (initial == null || initial.isEmpty) return;
    if (list.contains(initial)) {
      _selectedName = initial;
      _isOther = false;
    } else {
      _selectedName = _otherOption;
      _isOther = true;
      _nameController.text = initial;
    }
  }

  Future<void> _pickDate({required bool isAdministered}) async {
    final now = DateTime.now();
    final initial = isAdministered ? _administeredDate : (_nextDueDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        if (isAdministered) {
          _administeredDate = picked;
        } else {
          _nextDueDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final vaccineName = _isOther ? _nameController.text.trim() : _selectedName;

    setState(() => _isSaving = true);
    try {
      final data = {
        'animalId': widget.vaccine?.animalId ?? widget.animalId,
        'vaccineName': vaccineName,
        'administeredDate': DateFormat('yyyy-MM-dd').format(_administeredDate),
        'nextDueDate': _nextDueDate != null
            ? DateFormat('yyyy-MM-dd').format(_nextDueDate!)
            : null,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      };

      if (_isEdit) {
        await DioClient().dio.put('/vaccines/${widget.vaccine!.id}', data: data);
      } else {
        await DioClient().dio.post('/vaccines', data: data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Aşı güncellendi.' : 'Aşı başarıyla eklendi.'),
            backgroundColor: context.colors.success,
          ),
        );
        context.pop(true);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data?['message'] ?? 'Aşı kaydedilemedi.'),
            backgroundColor: context.scheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Aşı Düzenle' : 'Aşı Ekle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (widget.animalName != null) ...[
              Text('Hasta: ${widget.animalName}',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.lg),
            ],
            DropdownButtonFormField<String>(
              value: _selectedName,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Aşı Adı',
                prefixIcon: Icon(Icons.vaccines_outlined),
              ),
              hint: const Text('Aşı seçin'),
              items: [
                ..._vaccineNames.map((n) => DropdownMenuItem(
                      value: n,
                      child: Text(n, overflow: TextOverflow.ellipsis),
                    )),
                const DropdownMenuItem(value: _otherOption, child: Text(_otherOption)),
              ],
              validator: (v) => v == null ? 'Aşı seçiniz.' : null,
              onChanged: (val) {
                setState(() {
                  _selectedName = val;
                  _isOther = val == _otherOption;
                });
              },
            ),
            if (_isOther) ...[
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Aşı Adı (Diğer)',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                validator: (v) => (_isOther && (v == null || v.trim().isEmpty))
                    ? 'Aşı adı zorunludur.'
                    : null,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _dateField(
              label: 'Yapılış Tarihi',
              value: _administeredDate,
              onTap: () => _pickDate(isAdministered: true),
            ),
            const SizedBox(height: AppSpacing.lg),
            _dateField(
              label: 'Sonraki Aşı Tarihi (opsiyonel)',
              value: _nextDueDate,
              onTap: () => _pickDate(isAdministered: false),
              onClear: _nextDueDate != null
                  ? () => setState(() => _nextDueDate = null)
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Not (opsiyonel)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              ),
              child: _isSaving
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: context.scheme.onPrimary))
                  : Text(_isEdit ? 'Değişiklikleri Kaydet' : 'Aşıyı Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: onClear != null
              ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
              : null,
        ),
        child: Text(
          value != null ? DateFormat('dd.MM.yyyy').format(value) : 'Seçilmedi',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
