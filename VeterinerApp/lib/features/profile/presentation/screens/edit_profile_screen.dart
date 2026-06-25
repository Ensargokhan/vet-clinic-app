import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/loading_indicator.dart';

const String _imgBase = 'http://10.0.2.2:5295';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _email = '';
  String? _profilePhotoUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    try {
      final dio = DioClient().dio;
      final response = await dio.get('/auth/me');

      if (response.data['success'] == true) {
        final data = response.data['data'];
        setState(() {
          _nameController.text = data['fullName'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _email = data['email'] ?? '';
          _profilePhotoUrl = data['profilePhoto'];
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil yüklenemedi: ${e.message}'),
            backgroundColor: context.scheme.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final dio = DioClient().dio;
      await dio.put('/auth/profile', data: {
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil başarıyla güncellendi!'),
            backgroundColor: context.colors.success,
          ),
        );
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme hatası: ${e.response?.data?['message'] ?? e.message}'),
            backgroundColor: context.scheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handlePhotoUpload() async {
    final file = await ImageUploadService.pickImage(context);
    if (file == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final newPhotoUrl = await ImageUploadService.uploadProfilePhoto(file, '/auth/profile-photo');
      if (newPhotoUrl != null && mounted) {
        setState(() {
          _profilePhotoUrl = newPhotoUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profil fotoğrafı başarıyla güncellendi!'),
            backgroundColor: context.colors.success,
          ),
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
    final primary = context.scheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Profili Düzenle'), centerTitle: true),
      body: _isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: _profilePhotoUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        '$_imgBase$_profilePhotoUrl',
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            _initials(primary),
                                      ),
                                    )
                                  : _initials(primary),
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
                                  color: primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: context.scheme.surface, width: 2),
                                ),
                                child: _isUploadingPhoto
                                    ? Padding(
                                        padding: const EdgeInsets.all(AppSpacing.sm),
                                        child: CircularProgressIndicator(
                                            color: context.scheme.onPrimary, strokeWidth: 2),
                                      )
                                    : Icon(Icons.camera_alt,
                                        color: context.scheme.onPrimary, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    _sectionLabel('Ad Soyad'),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        hintText: 'Adınız ve soyadınız',
                      ),
                      validator: (v) => Validators.required(v, alan: 'Ad soyad'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    _sectionLabel('E-posta'),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceAlt,
                        borderRadius: AppRadius.mdAll,
                        border: Border.all(color: context.colors.outline),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.email_outlined,
                              color: context.colors.textSecondary, size: 22),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(_email,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: context.colors.textSecondary)),
                          ),
                          Icon(Icons.lock_outline,
                              color: context.colors.textSecondary, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('E-posta adresi güvenlik nedeniyle değiştirilemez',
                        style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: AppSpacing.xl),

                    _sectionLabel('Telefon Numarası'),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      validator: Validators.phoneOptional,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '05XX XXX XX XX',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      child: _isSaving
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: context.scheme.onPrimary, strokeWidth: 2),
                            )
                          : const Text('Değişiklikleri Kaydet'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _initials(Color color) {
    return Text(
      _getInitials(_nameController.text),
      style: Theme.of(context)
          .textTheme
          .displayLarge
          ?.copyWith(color: color, fontSize: 34),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: Theme.of(context).textTheme.labelLarge);
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2 && parts.first.isNotEmpty && parts.last.isNotEmpty) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }
}
