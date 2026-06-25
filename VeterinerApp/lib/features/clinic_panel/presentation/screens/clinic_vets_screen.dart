import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import 'package:dio/dio.dart';

class ClinicVetsScreen extends StatefulWidget {
  const ClinicVetsScreen({super.key});

  @override
  State<ClinicVetsScreen> createState() => _ClinicVetsScreenState();
}

class _ClinicVetsScreenState extends State<ClinicVetsScreen> {
  List<dynamic> _vets = [];
  List<String> _specialties = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVets();
    _loadSpecialties();
  }

  Future<void> _loadSpecialties() async {
    try {
      final dio = DioClient().dio;
      final response = await dio.get('/specialties');
      if (response.data['success'] == true && mounted) {
        setState(() {
          _specialties = List<String>.from(response.data['data']);
        });
      }
    } catch (e) {
      debugPrint('Uzmanlık listesi yüklenemedi: $e');
    }
  }

  Future<void> _loadVets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = DioClient().dio;
      final response = await dio.get('/clinics/my-clinic');

      if (response.data['success'] == true) {
        setState(() {
          _vets = response.data['data']['vets'] ?? [];
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['message'] ?? 'Hekimler yüklenemedi';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Beklenmeyen bir hata oluştu.';
        _isLoading = false;
      });
    }
  }

  void _showAddVetDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    
    String selectedTitle = 'Veteriner Hekim';
    final List<String> specialties = _specialties;
    String? selectedSpecialty = specialties.isNotEmpty ? specialties.first : null;

    final List<String> titles = [
      'Veteriner Hekim',
      'Uzman Veteriner Hekim',
      'Dr. Veteriner Hekim',
    ];

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
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yeni Hekim Ekle',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Ad Soyad', prefixIcon: Icon(Icons.person)),
                  validator: (v) => Validators.required(v, alan: 'Ad soyad'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-posta', prefixIcon: Icon(Icons.email)),
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Geçici Şifre', prefixIcon: Icon(Icons.lock)),
                  validator: Validators.password,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: const InputDecoration(labelText: 'Telefon', prefixIcon: Icon(Icons.phone)),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Unvan', isDense: true),
                        isExpanded: true,
                        value: selectedTitle,
                        items: titles.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedTitle = val!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Uzmanlık', isDense: true),
                        isExpanded: true,
                        value: selectedSpecialty,
                        items: specialties.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedSpecialty = val!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context);
                        await _addVet(
                          nameCtrl.text,
                          emailCtrl.text,
                          passwordCtrl.text,
                          phoneCtrl.text,
                          selectedTitle,
                          selectedSpecialty ?? '',
                        );
                      }
                    },
                    child: const Text('Hekimi Kaydet'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    ),
  ),
);
  }

  Future<void> _addVet(String name, String email, String pass, String phone, String title, String spec) async {
    setState(() => _isLoading = true);
    try {
      final dio = DioClient().dio;
      await dio.post('/clinics/my-clinic/vets', data: {
        'fullName': name,
        'email': email,
        'password': pass,
        'phone': phone,
        'title': title,
        'specialty': spec,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Hekim başarıyla eklendi!'), backgroundColor: context.colors.success),
        );
        _loadVets();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?['message'] ?? 'Hata oluştu'), backgroundColor: context.scheme.error),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showVetDetails(Map<String, dynamic> vet) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: context.scheme.primary.withOpacity(0.12),
                  backgroundImage: vet['profilePhoto'] != null
                      ? NetworkImage('http://10.0.2.2:5295${vet['profilePhoto']}')
                      : null,
                  child: vet['profilePhoto'] == null
                      ? Text(_getInitials(vet['fullName'] ?? ''),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: context.scheme.primary))
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(vet['fullName'] ?? '', style: Theme.of(context).textTheme.titleLarge),
                if (vet['title'] != null)
                  Text(vet['title'],
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: context.scheme.primary)),
                if (vet['specialty'] != null)
                  Text(vet['specialty'], style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.scheme.error,
                      side: BorderSide(color: context.scheme.error),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hekimi Klinikden Sil'),
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDeleteVet(vet['id'], vet['fullName']);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteVet(int vetId, String vetName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emin misiniz?'),
        content: Text('$vetName isimli hekimi kliniğinizden silmek (pasife almak) istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.scheme.error),
            onPressed: () {
              Navigator.pop(context);
              _deleteVet(vetId);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVet(int vetId) async {
    setState(() => _isLoading = true);
    try {
      final dio = DioClient().dio;
      await dio.delete('/clinics/my-clinic/vets/$vetId');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Hekim başarıyla silindi!'), backgroundColor: context.colors.success),
        );
        _loadVets();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?['message'] ?? 'Silme işlemi başarısız oldu'), backgroundColor: context.scheme.error),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hekimlerim')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVetDialog,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Hekim'),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _errorMessage != null
              ? ErrorState(message: _errorMessage!, onRetry: _loadVets)
              : _vets.isEmpty
                  ? const EmptyState(
                      icon: Icons.group_outlined,
                      message: 'Henüz kayıtlı hekim bulunmuyor.')
                  : RefreshIndicator(
                      onRefresh: _loadVets,
                      color: context.scheme.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: _vets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final vet = _vets[index];
                          final name = vet['fullName'] ?? '';
                          final title = vet['title'] ?? '';
                          final spec = vet['specialty'] ?? '';
                          final primary = context.scheme.primary;

                          return AppCard(
                            onTap: () => _showVetDetails(vet),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: primary.withOpacity(0.12),
                                  backgroundImage: vet['profilePhoto'] != null
                                      ? NetworkImage('http://10.0.2.2:5295${vet['profilePhoto']}')
                                      : null,
                                  child: vet['profilePhoto'] == null
                                      ? Text(_getInitials(name),
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: primary))
                                      : null,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: Theme.of(context).textTheme.titleMedium),
                                      if (title.isNotEmpty)
                                        Text(title,
                                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: primary)),
                                      if (spec.isNotEmpty)
                                        Text(spec, style: Theme.of(context).textTheme.bodyMedium),
                                    ],
                                  ),
                                ),
                                Icon(Icons.more_vert, color: context.colors.textSecondary),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
