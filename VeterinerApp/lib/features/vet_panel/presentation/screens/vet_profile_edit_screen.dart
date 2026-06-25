import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import 'package:dio/dio.dart';

class VetProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const VetProfileEditScreen({super.key, this.profileData});

  @override
  State<VetProfileEditScreen> createState() => _VetProfileEditScreenState();
}

class _VetProfileEditScreenState extends State<VetProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String? _profilePhotoUrl;

  final List<String> _titles = [
    'Veteriner Hekim',
    'Uzman Veteriner Hekim',
    'Dr. Veteriner Hekim',
  ];

  // Uzmanlık listesi backend'den (tek kaynak) yüklenir
  List<String> _specialties = [];

  late String _selectedTitle;
  String? _selectedSpecialty;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();

    final profile = widget.profileData;

    final fetchedTitle = profile?['title'] ?? '';
    _selectedTitle = _titles.contains(fetchedTitle) ? fetchedTitle : 'Veteriner Hekim';

    final fetchedSpec = (profile?['specialty'] ?? '').toString();
    _selectedSpecialty = fetchedSpec.isNotEmpty ? fetchedSpec : null;

    _profilePhotoUrl = profile?['profilePhoto'];
    _bioController = TextEditingController(text: profile?['bio'] ?? '');
    _phoneController = TextEditingController(text: profile?['phone'] ?? '');

    _loadSpecialties();
  }

  Future<void> _loadSpecialties() async {
    try {
      final dio = DioClient().dio;
      final response = await dio.get('/specialties');
      if (response.data['success'] == true && mounted) {
        final list = List<String>.from(response.data['data']);
        // Mevcut kayıtlı uzmanlık kanonik listede yoksa, dropdown patlamasın diye
        // listeye geçici olarak eklenir (hekim isterse kanonik birini seçer).
        if (_selectedSpecialty != null && _selectedSpecialty!.isNotEmpty && !list.contains(_selectedSpecialty)) {
          list.insert(0, _selectedSpecialty!);
        }
        setState(() => _specialties = list);
      }
    } catch (e) {
      debugPrint('Uzmanlık listesi yüklenemedi: $e');
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final dio = DioClient().dio;
      await dio.put('/vets/my-profile', data: {
        'title': _selectedTitle,
        'specialty': _selectedSpecialty,
        'bio': _bioController.text,
        'phone': _phoneController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Profil başarıyla güncellendi.'), backgroundColor: context.colors.success),
        );
        context.pop(true); // Return true to indicate success
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?['message'] ?? 'Hata oluştu'), backgroundColor: context.scheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePhotoUpload() async {
    final file = await ImageUploadService.pickImage(context);
    if (file == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final newPhotoUrl = await ImageUploadService.uploadProfilePhoto(file, '/vets/profile-photo');
      if (newPhotoUrl != null && mounted) {
        setState(() {
          _profilePhotoUrl = newPhotoUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Profil fotoğrafı başarıyla güncellendi!'), backgroundColor: context.colors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Fotoğraf yüklenemedi.'), backgroundColor: context.scheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profili Düzenle')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: context.scheme.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _profilePhotoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                'http://10.0.2.2:5295${_profilePhotoUrl}',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 48, color: context.scheme.primary),
                              ),
                            )
                          : Icon(Icons.person, size: 48, color: context.scheme.primary),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingPhoto ? null : _handlePhotoUpload,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: context.scheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.scheme.surface, width: 2),
                        ),
                        child: _isUploadingPhoto
                            ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(color: context.scheme.onPrimary, strokeWidth: 2),
                              )
                            : Icon(Icons.camera_alt, color: context.scheme.onPrimary, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Unvan', prefixIcon: Icon(Icons.badge)),
                      isExpanded: true,
                      value: _selectedTitle,
                      items: _titles.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTitle = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Uzmanlık', prefixIcon: Icon(Icons.medical_services)),
                      isExpanded: true,
                      // Liste API'den gelene kadar değer items içinde olmayabilir; o ana dek null göster
                      value: _specialties.contains(_selectedSpecialty) ? _selectedSpecialty : null,
                      hint: const Text('Uzmanlık seçin'),
                      items: _specialties.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSpecialty = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Telefon', prefixIcon: Icon(Icons.phone)),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      validator: Validators.phoneOptional,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Hakkında', prefixIcon: Icon(Icons.info)),
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: context.scheme.onPrimary))
                        : const Text('Değişiklikleri Kaydet'),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}
