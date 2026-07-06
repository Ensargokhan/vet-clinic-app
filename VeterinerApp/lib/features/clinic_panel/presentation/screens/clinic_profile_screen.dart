import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/info_row.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/menu_tile.dart';
import '../../../../shared/widgets/section_header.dart';

const String _imgBase = 'http://10.0.2.2:5295';

class ClinicProfileScreen extends StatefulWidget {
  const ClinicProfileScreen({super.key});

  @override
  State<ClinicProfileScreen> createState() => _ClinicProfileScreenState();
}

class _ClinicProfileScreenState extends State<ClinicProfileScreen> {
  Map<String, dynamic>? _clinicProfile;
  bool _isLoading = true;
  String? _errorMessage;

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
      final response = await dio.get('/clinics/my-clinic');
      if (response.data['success'] == true) {
        setState(() {
          _clinicProfile = response.data['data'];
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

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FcmService().clearToken();
              await FirebaseAuth.instance.signOut();
              if (mounted) context.go('/login');
            },
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabı Kalıcı Olarak Sil'),
        content: const Text(
            'Emin misiniz? Gelecek randevularınız otomatik olarak iptal edilecek ve bu işlem geri alınamaz!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ctx.scheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                final dio = DioClient().dio;
                await dio.delete('/auth/account');
                await FirebaseAuth.instance.signOut();
                if (mounted) context.go('/login');
              } on DioException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.response?.data?['message'] ?? 'Hesap silinemedi'),
                      backgroundColor: context.scheme.error,
                    ),
                  );
                  setState(() => _isLoading = false);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata oluştu: $e'), backgroundColor: context.scheme.error),
                  );
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Kalıcı Olarak Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: ErrorState(message: _errorMessage!, onRetry: _loadProfile),
      );
    }

    final data = _clinicProfile!;
    final name = data['name'] ?? '';
    final city = data['city'] ?? '';
    final district = data['district'] ?? '';
    final address = data['address'] ?? '';
    final phone = data['phone'] ?? '';
    final email = data['email'] ?? '';
    final description = data['description'] ?? 'Açıklama bulunmuyor.';
    final logoUrl = data['logoUrl'];
    final primary = context.scheme.primary;
    final onPrimary = context.scheme.onPrimary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: primary,
            foregroundColor: onPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [primary, primary.withOpacity(0.82)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: context.scheme.surface,
                      backgroundImage:
                          logoUrl != null ? NetworkImage('$_imgBase$logoUrl') : null,
                      child: logoUrl == null
                          ? Icon(Icons.local_hospital, size: 44, color: primary)
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: onPrimary)),
                    Text('$district, $city',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: onPrimary.withOpacity(0.85))),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader('İletişim Bilgileri'),
                  AppCard(
                    child: Column(
                      children: [
                        InfoRow(icon: Icons.phone_outlined, label: 'Telefon', value: phone),
                        InfoRow(icon: Icons.email_outlined, label: 'E-posta', value: email),
                        InfoRow(icon: Icons.location_on_outlined, label: 'Adres', value: address),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SectionHeader('Hakkımızda'),
                  AppCard(
                    child: Text(description,
                        style: Theme.of(context).textTheme.bodyLarge),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        MenuTile(
                          icon: Icons.campaign_outlined,
                          title: 'Duyurular',
                          subtitle: 'Hastalarınıza toplu duyuru gönderin',
                          onTap: () => context.push('/clinic/announcements'),
                        ),
                        const Divider(height: 1),
                        MenuTile(
                          icon: Icons.edit_outlined,
                          title: 'Profili Düzenle',
                          subtitle: 'Bilgilerinizi güncelleyin',
                          onTap: () {
                            context
                                .push('/clinic/profile/edit', extra: _clinicProfile)
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
                          onTap: _logout,
                        ),
                        const Divider(height: 1),
                        MenuTile(
                          icon: Icons.delete_outline,
                          title: 'Hesabımı Sil',
                          subtitle: 'Hesabınızı ve verilerinizi kalıcı olarak silin',
                          iconColor: context.scheme.error,
                          trailing: const SizedBox.shrink(),
                          onTap: _deleteAccount,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
