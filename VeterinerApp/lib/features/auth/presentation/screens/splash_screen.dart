import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    
    _controller.forward().then((_) {
      _checkAuthAndNavigate();
    });
  }

  void _checkAuthAndNavigate() async {
    // Biraz bekleme hissi
    await Future.delayed(const Duration(milliseconds: 500));
    
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      if (user != null) {
        try {
          final dio = DioClient().dio;
          final response = await dio.get('/auth/me');
          if (mounted) {
            if (response.data['success'] == true) {
              final role = response.data['data']['role'];
              if (role == 'clinic_admin') {
                context.go('/clinic-home');
                return;
              } else if (role == 'vet') {
                context.go('/vet-home');
                return;
              }
            }
          }
        } on DioException catch (e) {
          if (e.response?.statusCode == 404 || e.response?.statusCode == 401) {
            // Kullanıcı DB'de silinmiş veya pasif edilmiş
            await FirebaseAuth.instance.signOut();
            if (mounted) context.go('/login');
            return;
          }
        } catch (e) {
          // Diğer ağ hatalarında da login'e atmak güvenli olabilir
          await FirebaseAuth.instance.signOut();
          if (mounted) context.go('/login');
          return;
        }
        
        if (mounted) context.go('/home'); // Sadece rolü 'owner' olanlar buraya düşer
      } else {
        if (mounted) context.go('/login'); // Oturum yoksa login ekranına
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo placeholder (İleride SVG eklenebilir)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Icon(
                  Icons.pets,
                  size: 80,
                  color: context.scheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'PatiLife',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 40,
                      letterSpacing: 1.5,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dijital Veteriner Asistanınız',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
