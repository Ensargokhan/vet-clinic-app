import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/info_row.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/menu_tile.dart';
import '../../../../shared/widgets/stat_card.dart';

const String _imgBase = 'http://10.0.2.2:5295';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _userStats;
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
      final responses = await Future.wait([
        dio.get('/auth/me'),
        dio.get('/auth/stats'),
      ]);

      final profileResponse = responses[0];
      final statsResponse = responses[1];

      if (profileResponse.data['success'] == true) {
        setState(() {
          _userProfile = profileResponse.data['data'];
          if (statsResponse.data['success'] == true) {
            _userStats = statsResponse.data['data'];
          }
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['message'] ?? 'Profil yüklenemedi';
        _isLoading = false;
      });
    }
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Vazgeç')),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) context.go('/login');
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabımı Sil'),
        content: const Text(
            'Hesabınızı silmek istediğinize emin misiniz?\n\nBu işlem kalıcıdır. Hayvan profilleriniz pasife alınacak ve gelecekteki randevularınız iptal edilecektir.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ctx.scheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Evet, Hesabımı Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final dio = DioClient().dio;
        await dio.delete('/auth/account');
        await FirebaseAuth.instance.signOut();
        if (mounted) context.go('/login');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Hesap silme işlemi başarısız oldu. Lütfen tekrar deneyin.'),
              backgroundColor: context.scheme.error,
            ),
          );
        }
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.pets, color: ctx.scheme.primary, size: 28),
            const SizedBox(width: AppSpacing.sm),
            const Text('PatiLife'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Versiyon: 1.0.0'),
            const SizedBox(height: AppSpacing.sm),
            const Text('Dijital Veteriner Asistanınız'),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'PatiLife, sevimli dostlarınızın sağlık takibini kolaylaştırmak için tasarlanmış bir uygulamadır.',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Tamam')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        color: context.scheme.primary,
        child: _isLoading
            ? const LoadingIndicator()
            : _errorMessage != null
                ? _buildErrorView()
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildStatsCards(),
                        const SizedBox(height: AppSpacing.xl),
                        _buildMenuSection(),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: context.colors.textSecondary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _errorMessage ?? 'Bir hata oluştu',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış Yap'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final name = _userProfile?['fullName'] ?? 'Kullanıcı';
    final email = _userProfile?['email'] ?? '';
    final role = _userProfile?['role'] ?? 'owner';
    final profilePhoto = _userProfile?['profilePhoto'];
    final roleText = role == 'owner'
        ? 'Hayvan Sahibi'
        : role == 'vet'
            ? 'Veteriner'
            : 'Yönetici';
    final primary = context.scheme.primary;
    final onPrimary = context.scheme.onPrimary;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primary.withOpacity(0.82)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xl + 12),
          bottomRight: Radius.circular(AppRadius.xl + 12),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Profilim',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: onPrimary),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: context.scheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: profilePhoto != null
                      ? ClipOval(
                          child: Image.network(
                            '$_imgBase$profilePhoto',
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _initialsText(name, primary),
                          ),
                        )
                      : _initialsText(name, primary),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: onPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                email,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: onPrimary.withOpacity(0.85)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: onPrimary.withOpacity(0.2),
                  borderRadius: AppRadius.pillAll,
                ),
                child: Text(
                  roleText,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: onPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _initialsText(String name, Color color) {
    return Text(
      _getInitials(name),
      style: Theme.of(context)
          .textTheme
          .displayLarge
          ?.copyWith(color: color, fontSize: 30),
    );
  }

  Widget _buildStatsCards() {
    final animals = _userStats?['totalAnimals']?.toString() ?? '—';
    final appointments = _userStats?['totalAppointments']?.toString() ?? '—';
    final rating = _userStats?['rating']?.toString() ?? '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
                icon: Icons.pets, value: animals, label: 'Hayvanlarım'),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: StatCard(
                icon: Icons.calendar_today_outlined,
                value: appointments,
                label: 'Randevularım',
                accent: context.colors.info),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: StatCard(
                icon: Icons.star,
                value: rating,
                label: 'Puanım',
                accent: context.colors.warning),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Açık tema';
      case ThemeMode.dark:
        return 'Koyu tema';
      case ThemeMode.system:
        return 'Sistem ayarına göre';
    }
  }

  void _showThemeSheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        final current = ref.read(themeModeProvider);
        Widget option(ThemeMode mode, IconData icon) {
          return ListTile(
            leading: Icon(icon),
            title: Text(_themeModeLabel(mode)),
            trailing: current == mode
                ? Icon(Icons.check, color: sheetContext.scheme.primary)
                : null,
            onTap: () {
              ref.read(themeModeProvider.notifier).setMode(mode);
              Navigator.pop(sheetContext);
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text('Görünüm', style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              option(ThemeMode.system, Icons.brightness_auto_outlined),
              option(ThemeMode.light, Icons.light_mode_outlined),
              option(ThemeMode.dark, Icons.dark_mode_outlined),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            MenuTile(
              icon: Icons.person_outline,
              title: 'Kişisel Bilgiler',
              subtitle: 'Ad, e-posta, telefon bilgileriniz',
              onTap: _showPersonalInfoSheet,
            ),
            const Divider(height: 1),
            MenuTile(
              icon: Icons.edit_outlined,
              title: 'Profili Düzenle',
              subtitle: 'Bilgilerinizi güncelleyin',
              onTap: () async {
                await context.push('/profile/edit');
                _loadProfile();
              },
            ),
            const Divider(height: 1),
            MenuTile(
              icon: Icons.brightness_6_outlined,
              title: 'Görünüm',
              subtitle: _themeModeLabel(ref.watch(themeModeProvider)),
              onTap: _showThemeSheet,
            ),
            const Divider(height: 1),
            MenuTile(
              icon: Icons.info_outline,
              title: 'Hakkında',
              subtitle: 'Uygulama bilgileri ve versiyon',
              onTap: _showAboutDialog,
            ),
            const Divider(height: 1),
            MenuTile(
              icon: Icons.logout,
              title: 'Çıkış Yap',
              subtitle: 'Hesabınızdan güvenli çıkış yapın',
              iconColor: context.colors.textSecondary,
              trailing: const SizedBox.shrink(),
              onTap: _handleLogout,
            ),
            const Divider(height: 1),
            MenuTile(
              icon: Icons.delete_outline,
              title: 'Hesabımı Sil',
              subtitle: 'Hesabınızı ve verilerinizi kalıcı olarak silin',
              iconColor: context.scheme.error,
              trailing: const SizedBox.shrink(),
              onTap: _handleDeleteAccount,
            ),
          ],
        ),
      ),
    );
  }

  void _showPersonalInfoSheet() {
    final name = _userProfile?['fullName'] ?? 'Bilinmiyor';
    final email = _userProfile?['email'] ?? 'Bilinmiyor';
    final phone = _userProfile?['phone'] ?? 'Belirtilmemiş';
    final role = _userProfile?['role'] ?? 'owner';
    final roleText = role == 'owner'
        ? 'Hayvan Sahibi'
        : role == 'vet'
            ? 'Veteriner'
            : 'Yönetici';

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: sheetContext.colors.outline,
                  borderRadius: AppRadius.pillAll,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Kişisel Bilgiler',
                style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            InfoRow(icon: Icons.person_outline, label: 'Ad Soyad', value: name),
            InfoRow(icon: Icons.email_outlined, label: 'E-posta', value: email),
            InfoRow(icon: Icons.phone_outlined, label: 'Telefon', value: phone),
            InfoRow(icon: Icons.badge_outlined, label: 'Hesap Türü', value: roleText),
          ],
        ),
      ),
    );
  }
}
