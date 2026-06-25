import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/validators.dart';
import 'package:dio/dio.dart';

class ClinicVetsScreen extends StatefulWidget {
  const ClinicVetsScreen({super.key});

  @override
  State<ClinicVetsScreen> createState() => _ClinicVetsScreenState();
}

class _ClinicVetsScreenState extends State<ClinicVetsScreen> {
  List<dynamic> _vets = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVets();
  }

  Future<void> _loadVets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = DioClient().dio;
      final response = await dio.get('/clinics/my-clinic');

      if (response.data['success'] == true) {
        setState(() {
          _vets = response.data['data']['vets'] ?? [];
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?['message'] ?? 'Hekimler yüklenemedi';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Beklenmeyen bir hata oluştu.';
        _isLoading = false;
      });
    }
  }

  void _showAddVetDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    
    String selectedTitle = 'Veteriner Hekim';
    String selectedSpecialty = 'Genel Veteriner Hekim (Uzmanlık Yok)';

    final List<String> titles = [
      'Veteriner Hekim',
      'Uzman Veteriner Hekim',
      'Dr. Veteriner Hekim',
    ];

    final List<String> specialties = [
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yeni Hekim Ekle',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Ad Soyad', prefixIcon: Icon(Icons.person)),
                  validator: (v) => Validators.required(v, alan: 'Ad soyad'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-posta', prefixIcon: Icon(Icons.email)),
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Geçici Şifre', prefixIcon: Icon(Icons.lock)),
                  validator: Validators.password,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
                  decoration: const InputDecoration(labelText: 'Telefon', prefixIcon: Icon(Icons.phone)),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Unvan', isDense: true),
                        isExpanded: true,
                        value: selectedTitle,
                        items: titles.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedTitle = val!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Uzmanlık', isDense: true),
                        isExpanded: true,
                        value: selectedSpecialty,
                        items: specialties.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedSpecialty = val!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(context);
                        await _addVet(
                          nameCtrl.text,
                          emailCtrl.text,
                          passwordCtrl.text,
                          phoneCtrl.text,
                          selectedTitle,
                          selectedSpecialty,
                        );
                      }
                    },
                    child: const Text('Hekimi Kaydet'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    ),
  ),
);
  }

  Future<void> _addVet(String name, String email, String pass, String phone, String title, String spec) async {
    setState(() => _isLoading = true);
    try {
      final dio = DioClient().dio;
      await dio.post('/clinics/my-clinic/vets', data: {
        'fullName': name,
        'email': email,
        'password': pass,
        'phone': phone,
        'title': title,
        'specialty': spec,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hekim başarıyla eklendi!'), backgroundColor: Colors.green),
        );
        _loadVets();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?['message'] ?? 'Hata oluştu'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showVetDetails(Map<String, dynamic> vet) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  backgroundImage: vet['profilePhoto'] != null
                      ? NetworkImage('http://10.0.2.2:5295${vet['profilePhoto']}')
                      : null,
                  child: vet['profilePhoto'] == null
                      ? Text(_getInitials(vet['fullName'] ?? ''), style: const TextStyle(fontSize: 24, color: AppTheme.primaryColor, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(height: 16),
                Text(vet['fullName'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                if (vet['title'] != null) Text(vet['title'], style: const TextStyle(fontSize: 16, color: AppTheme.primaryColor)),
                if (vet['specialty'] != null) Text(vet['specialty'], style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hekimi Klinikden Sil'),
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                      _confirmDeleteVet(vet['id'], vet['fullName']);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteVet(int vetId, String vetName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emin misiniz?'),
        content: Text('$vetName isimli hekimi kliniğinizden silmek (pasife almak) istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteVet(vetId);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteVet(int vetId) async {
    setState(() => _isLoading = true);
    try {
      final dio = DioClient().dio;
      await dio.delete('/clinics/my-clinic/vets/$vetId');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hekim başarıyla silindi!'), backgroundColor: Colors.green),
        );
        _loadVets();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.response?.data?['message'] ?? 'Silme işlemi başarısız oldu'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Hekimlerim', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddVetDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Yeni Hekim', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : _vets.isEmpty
                  ? const Center(child: Text('Henüz kayıtlı hekim bulunmuyor.'))
                  : RefreshIndicator(
                      onRefresh: _loadVets,
                      color: AppTheme.primaryColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _vets.length,
                        itemBuilder: (context, index) {
                          final vet = _vets[index];
                          final name = vet['fullName'] ?? '';
                          final title = vet['title'] ?? '';
                          final spec = vet['specialty'] ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showVetDetails(vet),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                  backgroundImage: vet['profilePhoto'] != null
                                      ? NetworkImage('http://10.0.2.2:5295${vet['profilePhoto']}')
                                      : null,
                                  child: vet['profilePhoto'] == null
                                      ? Text(_getInitials(name), style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold))
                                      : null,
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (title.isNotEmpty) Text(title, style: TextStyle(color: AppTheme.primaryColor)),
                                    if (spec.isNotEmpty) Text(spec),
                                  ],
                                ),
                                trailing: const Icon(Icons.more_vert, color: Colors.grey),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
