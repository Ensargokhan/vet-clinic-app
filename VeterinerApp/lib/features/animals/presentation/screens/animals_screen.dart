import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = DioClient().dio;
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
      appBar: AppBar(title: const Text('Hayvanlarım')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/animals/add').then((_) => _fetchAnimals()),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Ekle'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingIndicator();
    if (_error != null) return ErrorState(message: _error!, onRetry: _fetchAnimals);

    if (_animals.isEmpty) {
      return const EmptyState(
        icon: Icons.pets,
        message: 'Henüz bir hayvan eklemediniz.',
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAnimals,
      color: context.scheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _animals.length,
        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => _animalCard(_animals[index]),
      ),
    );
  }

  Widget _animalCard(AnimalModel animal) {
    final primary = context.scheme.primary;
    final age = animal.birthDate == null ? 'Yaş Bilinmiyor' : '${animal.age} Yaş';
    return AppCard(
      onTap: () => context.push('/animals/${animal.id}').then((_) => _fetchAnimals()),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: AppRadius.mdAll,
            ),
            child: Icon(Icons.pets, color: primary, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(animal.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${animal.species} • ${animal.breed ?? 'Irk Belirtilmemiş'} • $age',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.colors.textSecondary),
        ],
      ),
    );
  }
}
