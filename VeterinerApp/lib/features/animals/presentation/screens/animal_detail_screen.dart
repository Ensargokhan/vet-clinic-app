import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';

class AnimalDetailScreen extends StatefulWidget {
  final int animalId;
  const AnimalDetailScreen({super.key, required this.animalId});

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  Map<String, dynamic>? _animal;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAnimal();
  }

  Future<void> _fetchAnimal() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final dio = DioClient().dio;
      final response = await dio.get('/animals/${widget.animalId}');
      if (response.data['success']) {
        setState(() {
          _animal = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Hayvan detayları yüklenemedi.';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAnimal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hayvanı Sil', style: TextStyle(color: Colors.red)),
        content: const Text('Bu hayvan profilini silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final dio = DioClient().dio;
      await dio.delete('/animals/${widget.animalId}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hayvan başarıyla silindi.'), backgroundColor: Colors.green),
        );
        context.go('/animals'); // Hayvanlar listesine dön
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silme işlemi başarısız oldu.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _calculateAge(String? birthDateStr) {
    if (birthDateStr == null) return 'Bilinmiyor';
    try {
      final birthDate = DateTime.parse(birthDateStr);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      if (age == 0) {
        int months = today.month - birthDate.month;
        if (months < 0) months += 12;
        return '$months Aylık';
      }
      return '$age Yaşında';
    } catch (e) {
      return 'Geçersiz Tarih';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Hayvan Detayı', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_animal != null)
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
              onPressed: () async {
                await context.push('/animals/${widget.animalId}/edit');
                _fetchAnimal(); // Dönüşte yenile
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_animal == null) return const SizedBox.shrink();

    final a = _animal!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: const Icon(Icons.pets, size: 50, color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              a['name'] ?? 'Bilinmiyor',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                a['species'] ?? 'Bilinmiyor',
                style: const TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Info Cards
          _buildInfoRow('Irk', a['breed'] ?? 'Belirtilmemiş', Icons.merge_type),
          _buildInfoRow(
            'Cinsiyet', 
            a['gender'] == 'male' ? 'Erkek' : a['gender'] == 'female' ? 'Dişi' : 'Bilinmiyor', 
            Icons.male
          ),
          _buildInfoRow('Yaş', _calculateAge(a['birthDate']), Icons.cake),
          _buildInfoRow(
            'Kilo', 
            a['weight'] != null ? '${a['weight']} kg' : 'Belirtilmemiş', 
            Icons.scale
          ),
          _buildInfoRow('Çip No', a['microchipNo'] ?? 'Yok', Icons.memory),
          
          if (a['notes'] != null && a['notes'].toString().isNotEmpty)
            _buildInfoRow('Notlar', a['notes'], Icons.note),

          const SizedBox(height: 48),

          // Delete Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _deleteAnimal,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Profili Sil', style: TextStyle(color: Colors.red, fontSize: 16)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
