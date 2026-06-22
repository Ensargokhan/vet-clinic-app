import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import 'package:dio/dio.dart';

class VetProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;

  const VetProfileEditScreen({super.key, this.profileData});

  @override
  State<VetProfileEditScreen> createState() => _VetProfileEditScreenState();
}

class _VetProfileEditScreenState extends State<VetProfileEditScreen> {
  bool _isLoading = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profili Düzenle', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Telefon', prefixIcon: Icon(Icons.phone)),
                      keyboardType: TextInputType.phone,
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
    );
  }
}
