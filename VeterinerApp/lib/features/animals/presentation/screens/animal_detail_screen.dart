import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/info_row.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../vaccines/data/models/vaccine_model.dart';

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

  List<VaccineModel> _vaccines = [];
  bool _vaccinesLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnimal();
    _fetchVaccines();
  }

  Future<void> _fetchVaccines() async {
    setState(() => _vaccinesLoading = true);
    try {
      final response =
          await DioClient().dio.get('/vaccines/animal/${widget.animalId}');
      if (response.data['success'] == true && mounted) {
        final List<dynamic> data = response.data['data'] ?? [];
        setState(() {
          _vaccines = data.map((e) => VaccineModel.fromJson(e)).toList();
          _vaccinesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _vaccinesLoading = false);
    }
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
        title: const Text('Hayvanı Sil'),
        content: const Text(
            'Bu hayvan profilini silmek istediğinize emin misiniz? Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ctx.scheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
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
          SnackBar(
            content: const Text('Hayvan başarıyla silindi.'),
            backgroundColor: context.colors.success,
          ),
        );
        context.go('/animals');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Silme işlemi başarısız oldu.'),
            backgroundColor: context.scheme.error,
          ),
        );
      }
    }
  }

  Widget _buildVaccineSection() {
    if (_vaccinesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_vaccines.isEmpty) {
      return const EmptyState(
        icon: Icons.vaccines_outlined,
        message: 'Henüz aşı kaydı yok.',
      );
    }
    return AppCard(
      child: Column(
        children: [
          for (int i = 0; i < _vaccines.length; i++) ...[
            if (i > 0) const Divider(),
            _vaccineTile(_vaccines[i]),
          ],
        ],
      ),
    );
  }

  Widget _vaccineTile(VaccineModel v) {
    final administered = DateFormat('dd.MM.yyyy').format(v.administeredDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.vaccines_outlined, size: 18, color: context.scheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(v.vaccineName,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            if (v.isDueSoon)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.warning.withOpacity(0.15),
                  borderRadius: AppRadius.pillAll,
                ),
                child: Text('Yaklaşıyor',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.colors.warning,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('Yapılış: $administered',
            style: Theme.of(context).textTheme.bodyMedium),
        if (v.nextDueDate != null)
          Text('Sonraki: ${DateFormat('dd.MM.yyyy').format(v.nextDueDate!)}',
              style: Theme.of(context).textTheme.bodyMedium),
        if (v.vetName != null && v.vetName!.isNotEmpty)
          Text('Uygulayan: ${v.vetName}',
              style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  String _calculateAge(String? birthDateStr) {
    if (birthDateStr == null) return 'Bilinmiyor';
    try {
      final birthDate = DateTime.parse(birthDateStr);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
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
      appBar: AppBar(
        title: const Text('Hayvan Detayı'),
        actions: [
          if (_animal != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await context.push('/animals/${widget.animalId}/edit');
                _fetchAnimal();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _error != null
              ? ErrorState(message: _error!, onRetry: _fetchAnimal)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_animal == null) return const SizedBox.shrink();
    final a = _animal!;
    final primary = context.scheme.primary;
    final accent = context.colors.info;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: primary.withValues(alpha: 0.12),
              child: Icon(Icons.pets, size: 48, color: primary),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              a['name'] ?? 'Bilinmiyor',
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: AppRadius.pillAll,
              ),
              child: Text(
                a['species'] ?? 'Bilinmiyor',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: accent, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              children: [
                InfoRow(
                    icon: Icons.merge_type,
                    label: 'Irk',
                    value: a['breed'] ?? 'Belirtilmemiş'),
                InfoRow(
                  icon: Icons.transgender,
                  label: 'Cinsiyet',
                  value: a['gender'] == 'male'
                      ? 'Erkek'
                      : a['gender'] == 'female'
                          ? 'Dişi'
                          : 'Bilinmiyor',
                ),
                InfoRow(
                    icon: Icons.cake_outlined,
                    label: 'Yaş',
                    value: _calculateAge(a['birthDate'])),
                InfoRow(
                  icon: Icons.scale_outlined,
                  label: 'Kilo',
                  value: a['weight'] != null ? '${a['weight']} kg' : 'Belirtilmemiş',
                ),
                InfoRow(
                    icon: Icons.memory,
                    label: 'Çip No',
                    value: a['microchipNo'] ?? 'Yok'),
                if (a['notes'] != null && a['notes'].toString().isNotEmpty)
                  InfoRow(
                      icon: Icons.notes_outlined,
                      label: 'Notlar',
                      value: a['notes'].toString()),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader('Aşı Geçmişi'),
          const SizedBox(height: AppSpacing.sm),
          _buildVaccineSection(),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _deleteAnimal,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Profili Sil'),
              style: OutlinedButton.styleFrom(
                foregroundColor: context.scheme.error,
                side: BorderSide(color: context.scheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
