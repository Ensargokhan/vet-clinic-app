import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';

class ClinicRegisterScreen extends StatefulWidget {
  const ClinicRegisterScreen({super.key});

  @override
  State<ClinicRegisterScreen> createState() => _ClinicRegisterScreenState();
}

class _ClinicRegisterScreenState extends State<ClinicRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Adım 1: Yönetici Bilgileri
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Adım 2: Klinik Bilgileri
  final _clinicNameController = TextEditingController();
  final _clinicPhoneController = TextEditingController();
  String? _selectedCity;
  String? _selectedDistrict;
  
  List<dynamic> _citiesData = [];
  List<String> _cities = [];
  List<String> _districts = [];

  final _clinicAddressController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  int _currentStep = 0;

  int _trCompare(String a, String b) {
    String replaceTr(String text) {
      return text.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase()
        .replaceAll('ç', 'c~')
        .replaceAll('ğ', 'g~')
        .replaceAll('ı', 'h~')
        .replaceAll('ö', 'o~')
        .replaceAll('ş', 's~')
        .replaceAll('ü', 'u~');
    }
    return replaceTr(a).compareTo(replaceTr(b));
  }

  @override
  void initState() {
    super.initState();
    _loadCitiesData();
  }

  Future<void> _loadCitiesData() async {
    try {
      final String response = await rootBundle.loadString('assets/data/turkey_cities.json');
      final data = await json.decode(response);
      setState(() {
        _citiesData = data['data'];
        _cities = _citiesData.map<String>((city) => city['name'].toString()).toList();
        _cities.sort(_trCompare);
      });
    } catch (e) {
      debugPrint("Error loading cities: $e");
    }
  }

  void _onCityChanged(String? val) {
    setState(() {
      _selectedCity = val;
      _selectedDistrict = null;
      if (val != null) {
        final cityObj = _citiesData.firstWhere((element) => element['name'] == val, orElse: () => null);
        if (cityObj != null && cityObj['districts'] != null) {
          _districts = (cityObj['districts'] as List).map<String>((d) => d['name'].toString()).toList();
          _districts.sort(_trCompare);
        } else {
          _districts = [];
        }
      } else {
        _districts = [];
      }
    });
  }

  @override
  void dispose() {
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPhoneController.dispose();
    _passwordController.dispose();
    _clinicNameController.dispose();
    _clinicPhoneController.dispose();
    _clinicAddressController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Firebase Authentication ile kullanıcı oluştur
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _adminEmailController.text.trim(),
        password: _passwordController.text,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Firebase kullanıcısı oluşturulamadı');

      // Token'ı al (Interceptor bu token'ı kullanacak)
      await user.getIdToken(true);

      // 2. Backend'e klinik ve yönetici bilgilerini gönder
      final dio = DioClient().dio;
      final response = await dio.post('/auth/register-clinic', data: {
        'adminFullName': _adminNameController.text.trim(),
        'adminEmail': _adminEmailController.text.trim(),
        'adminPhone': _adminPhoneController.text.trim(),
        'clinicName': _clinicNameController.text.trim(),
        'clinicPhone': _clinicPhoneController.text.trim(),
        'clinicCity': _selectedCity ?? '',
        'clinicDistrict': _selectedDistrict ?? '',
        'clinicAddress': _clinicAddressController.text.trim(),
      });

      if (response.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Klinik başarıyla kaydedildi! Giriş yapabilirsiniz.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Güvenli çıkış ve logine yönlendirme
          await FirebaseAuth.instance.signOut();
          context.go('/login');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Bir hata oluştu: ${e.message}';
      if (e.code == 'email-already-in-use') message = 'Bu e-posta zaten kullanımda';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } on DioException catch (e) {
      // Backend'de hata olursa, oluşturulan Firebase kullanıcısını temizle
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (_) {
        await FirebaseAuth.instance.signOut();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt sırasında hata: ${e.response?.data?['message'] ?? e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            elevation: 0,
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : (_currentStep == 1 ? _handleRegister : details.onStepContinue),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _currentStep == 1 ? 'Kliniği Kaydet' : 'Devam Et',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    if (_currentStep > 0) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : details.onStepCancel,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: AppTheme.primaryColor,
                            side: const BorderSide(color: AppTheme.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Geri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            onStepContinue: () {
              if (_currentStep == 0) {
                // Sadece 1. adımın alanlarını doğrula
                if (_adminNameController.text.isEmpty || 
                    _adminEmailController.text.isEmpty || 
                    _passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen gerekli alanları doldurun'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                setState(() => _currentStep += 1);
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep -= 1);
              }
            },
            steps: [
              Step(
                title: const Text('Yönetici'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kurumsal Kayıt 🏢',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Önce kliniği yönetecek yetkilinin bilgilerini girelim.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _adminNameController,
                      label: 'Yönetici Ad Soyad',
                      icon: Icons.person_outline,
                      validator: (v) => v?.isEmpty == true ? 'Zorunlu alan' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _adminEmailController,
                      label: 'Kurumsal E-posta',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => v?.contains('@') == true ? null : 'Geçerli bir e-posta girin',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _adminPhoneController,
                      label: 'Yönetici Telefonu',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Şifre',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) => v != null && v.length >= 6 ? null : 'En az 6 karakter',
                    ),
                  ],
                ),
              ),
              Step(
                title: const Text('Klinik'),
                isActive: _currentStep >= 1,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Klinik Bilgileri',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _clinicNameController,
                      label: 'Klinik Adı',
                      icon: Icons.local_hospital_outlined,
                      validator: (v) => v?.isEmpty == true ? 'Zorunlu alan' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _clinicPhoneController,
                      label: 'Klinik İletişim Numarası',
                      icon: Icons.support_agent_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'İl',
                              prefixIcon: const Icon(Icons.location_city_outlined, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppTheme.primaryColor),
                              ),
                            ),
                            isExpanded: true,
                            value: _selectedCity,
                            items: _cities.map((city) {
                              return DropdownMenuItem(
                                value: city,
                                child: Text(city, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: _onCityChanged,
                            validator: (v) => v == null ? 'Zorunlu' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'İlçe',
                              prefixIcon: const Icon(Icons.map_outlined, color: Colors.grey),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppTheme.primaryColor),
                              ),
                            ),
                            isExpanded: true,
                            value: _selectedDistrict,
                            items: _districts.map((district) {
                              return DropdownMenuItem(
                                value: district,
                                child: Text(district, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedDistrict = val;
                              });
                            },
                            validator: (v) => v == null ? 'Zorunlu' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _clinicAddressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Açık Adres',
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 40.0),
                          child: Icon(Icons.location_on_outlined, color: Colors.grey),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.primaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
      ),
    );
  }
}
