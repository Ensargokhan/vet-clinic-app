import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/image_upload_service.dart';
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

  final List<String> _specialties = [
    'Genel Veteriner Hekim (Uzmanlık Yok)',
    'Veteriner Cerrahi',
    'Veteriner İç Hastalıkları (Dahiliye)',
    'Veteriner Dermatoloji',
    'Veteriner Onkoloji',
    'Veteriner Diş Hekimliği',
    'Veteriner Acil Tıp ve Yoğun Bakım',
    'Veteriner Göz Hastalıkları',
    'Egzotik Hayvan Hekimliği',
  ];

  late String _selectedTitle;
  late String _selectedSpecialty;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    
    final profile = widget.profileData;
    
    final fetchedTitle = profile?['title'] ?? '';
    _selectedTitle = _titles.contains(fetchedTitle) ? fetchedTitle : 'Veteriner Hekim';

    final fetchedSpec = profile?['specialty'] ?? '';
    _selectedSpecialty = _specialties.contains(fetchedSpec) ? fetchedSpec : 'Genel Veteriner Hekim (Uzmanlık Yok)';

    _profilePhotoUrl = profile?['profilePhoto'];
    _bioController = TextEditingController(text: profile?['bio'] ?? '');
    _phoneController = TextEditingController(text: profile?['phone'] ?? '');
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
          const SnackBar(content: Text('Profil başarıyla güncellendi.'), backgroundColor: Colors.green),
        );
        context.pop(true); // Return true to indicate success
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?['message'] ?? 'Hata oluştu'), backgroundColor: Colors.red),
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
          const SnackBar(content: Text('Profil fotoğrafı başarıyla güncellendi!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoğraf yüklenemedi.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profili Düzenle', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
                      color: AppTheme.primaryColor.withOpacity(0.1),
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
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50, color: AppTheme.primaryColor),
                              ),
                            )
                          : const Icon(Icons.person, size: 50, color: AppTheme.primaryColor),
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
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: _isUploadingPhoto
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
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
                      value: _selectedSpecialty,
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
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
