import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Kullanıcının rolünü öğrenmek için backend'den profilini çek
      final dio = DioClient().dio;
      final response = await dio.get('/auth/me');
      
      if (mounted) {
        if (response.data['success'] == true) {
          // Giriş başarılı → FCM token'ını backend'e kaydet
          FcmService().registerToken();
          final role = response.data['data']['role'];
          if (role == 'clinic_admin') {
            context.go('/clinic-home');
          } else if (role == 'vet') {
            context.go('/vet-home');
          } else {
            context.go('/home');
          }
        } else {
          // Fallback
          context.go('/home');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Bir hata oluştu (${e.code})';
      if (e.code == 'user-not-found' || e.code == 'invalid-email') message = 'Kullanıcı bulunamadı';
      if (e.code == 'wrong-password') message = 'Hatalı şifre';
      if (e.code == 'invalid-credential') message = 'E-posta veya şifre hatalı';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } on DioException catch (e) {
      String message = 'Sunucu hatası: Kullanıcı profili çekilemedi.';
      if (e.response?.statusCode == 404) {
        message = 'Kullanıcı veritabanında bulunamadı. Lütfen yeniden kayıt olun.';
        // Optional: Firebase'den de çıkış yapalım çünkü DB'de yok
        await FirebaseAuth.instance.signOut();
      } else if (e.response?.statusCode == 403) {
        message = e.response?.data?['message'] ?? 'Hesabınız sistem yöneticisi veya klinik tarafından pasife alınmıştır.';
        await FirebaseAuth.instance.signOut();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bilinmeyen bir hata oluştu: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.pets, size: 64, color: context.scheme.primary),
                  const SizedBox(height: 24),
                  Text(
                    'Tekrar Hoş Geldiniz! 👋',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PatiLife hesabınıza giriş yapın.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-posta Adresi',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Şifremi unuttum akışı
                      },
                      child: const Text('Şifremi Unuttum'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading 
                        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: context.scheme.onPrimary, strokeWidth: 2))
                        : const Text('Giriş Yap'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Hesabınız yok mu?', style: Theme.of(context).textTheme.bodyMedium),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: const Text('Kayıt Ol', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.push('/register-clinic'),
                    icon: const Icon(Icons.business_center_outlined, size: 20),
                    label: const Text('Kurumsal Kayıt (Klinikler İçin)'),
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.info,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
