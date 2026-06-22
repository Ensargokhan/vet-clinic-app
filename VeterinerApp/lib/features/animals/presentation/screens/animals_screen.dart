import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/animal_model.dart';

class AnimalsScreen extends StatefulWidget {
  const AnimalsScreen({super.key});

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  List<AnimalModel> _animals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAnimals();
  }

  Future<void> _fetchAnimals() async {
    try {
      final dio = DioClient().dio;
      // Normalde sadece kullanıcının kendi hayvanlarını getiren uç olmalı.
      // API'mizde `GET /api/animals/my-animals` vb uçlar varsa kullanılabilir.
      // Şu an için get(/animals) çalışır. Backend auth control yapacaktır.
      final response = await dio.get('/animals');
      
      if (response.data['success']) {
        final List<dynamic> data = response.data['data'];
        setState(() {
          _animals = data.map((e) => AnimalModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Hayvanlarınız yüklenemedi. Oturumu kontrol edin.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hayvanlarım', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/animals/add').then((_) => _fetchAnimals()), // Dönüşte yenile
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Yeni Ekle', style: TextStyle(color: Colors.white)),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));

    if (_animals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.pets, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Henüz bir hayvan eklemediniz.', style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _animals.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final animal = _animals[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              context.push('/animals/${animal.id}').then((_) => _fetchAnimals());
            },
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.backgroundColor,
                child: Icon(Icons.pets, color: AppTheme.primaryColor, size: 30),
              ),
              title: Text(animal.name, style: Theme.of(context).textTheme.titleLarge),
              subtitle: Text('${animal.species} • ${animal.breed ?? 'Irk Belirtilmemiş'} • ${animal.birthDate == null ? 'Yaş Bilinmiyor' : '${animal.age} Yaş'}'),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}
