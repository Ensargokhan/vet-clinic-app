import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/info_row.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/menu_tile.dart';
import '../../../../shared/widgets/section_header.dart';

const String _imgBase = 'http://10.0.2.2:5295';

class VetProfileScreen extends StatefulWidget {
  const VetProfileScreen({super.key});

  @override
  State<VetProfileScreen> createState() => _VetProfileScreenState();
}

class _VetProfileScreenState extends State<VetProfileScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = DioClient().dio;
      final response = await dio.get('/vets/my-profile');
      if (response.data['success'] == true) {
        setState(() {
          _profile = response.data['data'];
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['message'] ?? 'Profil yüklenemedi';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Beklenmeyen bir hata oluştu.';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await FcmService().clearToken();
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go('/login');
  }

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);
    try {
      final dio = DioClient().dio;
      await dio.delete('/auth/account');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Hesabınız başarıyla silindi.'),
            backgroundColor: context.colors.success,
          ),
        );
      }
      await FirebaseAuth.instance.signOut();
      if (mounted) context.go('/login');
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data?['message'] ?? 'Hata oluştu'),
            backgroundColor: context.scheme.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Beklenmeyen hata: $e'), backgroundColor: context.scheme.error),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text(
            'Hesabınızı silmek kalıcı bir işlemdir. Profil bilgileriniz silinecek ve aktif olan tüm randevularınız otomatik olarak iptal edilecektir. Bu işlemi onaylıyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ctx.scheme.error),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAccount();
            },
            child: const Text('Evet, Hesabımı Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: _isLoading
          ? const LoadingIndicator()
          : _errorMessage != null
              ? ErrorState(message: _errorMessage!, onRetry: _loadProfile)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: context.scheme.primary.withOpacity(0.12),
                          backgroundImage: _profile?['profilePhoto'] != null
                              ? NetworkImage('$_imgBase${_profile?['profilePhoto']}')
                              : null,
                          child: _profile?['profilePhoto'] == null
                              ? Icon(Icons.person, size: 48, color: context.scheme.primary)
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(_profile?['fullName'] ?? '',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: AppSpacing.xl),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader('Profil Bilgileri'),
                            const Divider(),
                            InfoRow(
                                icon: Icons.badge_outlined,
                                label: 'Unvan',
                                value: _profile?['title'] ?? 'Belirtilmemiş'),
                            InfoRow(
                                icon: Icons.medical_services_outlined,
                                label: 'Uzmanlık',
                                value: _profile?['specialty'] ?? 'Belirtilmemiş'),
                            InfoRow(
                                icon: Icons.phone_outlined,
                                label: 'Telefon',
                                value: _profile?['phone'] ?? 'Belirtilmemiş'),
                            InfoRow(
                                icon: Icons.info_outline,
                                label: 'Hakkında',
                                value: _profile?['bio'] ?? 'Açıklama bulunmuyor.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            MenuTile(
                              icon: Icons.edit_outlined,
                              title: 'Profili Düzenle',
                              subtitle: 'Bilgilerinizi güncelleyin',
                              onTap: () {
                                context
                                    .push('/vet/profile/edit', extra: _profile)
                                    .then((_) => _loadProfile());
                              },
                            ),
                            const Divider(height: 1),
                            MenuTile(
                              icon: Icons.logout,
                              title: 'Çıkış Yap',
                              subtitle: 'Hesabınızdan güvenli çıkış yapın',
                              iconColor: context.colors.textSecondary,
                              trailing: const SizedBox.shrink(),
                              onTap: _confirmLogout,
                            ),
                            const Divider(height: 1),
                            MenuTile(
                              icon: Icons.delete_outline,
                              title: 'Hesabımı Sil',
                              subtitle: 'Hesabınızı ve verilerinizi kalıcı olarak silin',
                              iconColor: context.scheme.error,
                              trailing: const SizedBox.shrink(),
                              onTap: _confirmDelete,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
    );
  }
}
