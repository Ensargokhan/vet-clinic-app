import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../data/models/vaccine_model.dart';

/// Hekim/klinik için aşı yönetim ekranı: bir hayvanın aşılarını listeler, ekleme/düzenleme/silme sağlar.
/// Randevu ekranından açılır (yetki randevu-linkiyle backend'de doğrulanır).
class AnimalVaccinesScreen extends StatefulWidget {
  final int animalId;
  final String? animalName;

  const AnimalVaccinesScreen({super.key, required this.animalId, this.animalName});

  @override
  State<AnimalVaccinesScreen> createState() => _AnimalVaccinesScreenState();
}

class _AnimalVaccinesScreenState extends State<AnimalVaccinesScreen> {
  List<VaccineModel> _vaccines = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVaccines();
  }

  Future<void> _fetchVaccines() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response =
          await DioClient().dio.get('/vaccines/animal/${widget.animalId}');
      if (response.data['success'] == true && mounted) {
        final List<dynamic> data = response.data['data'] ?? [];
        setState(() {
          _vaccines = data.map((e) => VaccineModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Aşılar yüklenemedi.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openForm({VaccineModel? vaccine}) async {
    final result = await context.push<bool>('/vaccines/add', extra: {
      'animalId': widget.animalId,
      'animalName': widget.animalName,
      'vaccine': vaccine,
    });
    if (result == true) _fetchVaccines();
  }

  Future<void> _deleteVaccine(VaccineModel v) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aşıyı Sil'),
        content: Text('"${v.vaccineName}" aşı kaydını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
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
      await DioClient().dio.delete('/vaccines/${v.id}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Aşı silindi.'),
            backgroundColor: context.colors.success,
          ),
        );
        _fetchVaccines();
      }
    } catch (_) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.animalName != null ? '${widget.animalName} — Aşılar' : 'Aşılar'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Aşı Ekle'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingIndicator();
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _fetchVaccines);
    }
    if (_vaccines.isEmpty) {
      return const EmptyState(
        icon: Icons.vaccines_outlined,
        message: 'Henüz aşı kaydı yok.',
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchVaccines,
      color: context.scheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _vaccines.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) => _vaccineCard(_vaccines[i]),
      ),
    );
  }

  Widget _vaccineCard(VaccineModel v) {
    final administered = DateFormat('dd.MM.yyyy').format(v.administeredDate);
    return AppCard(
      child: Column(
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
          if (v.batchNumber != null && v.batchNumber!.isNotEmpty)
            Text('Parti No: ${v.batchNumber}',
                style: Theme.of(context).textTheme.labelSmall),
          if (v.notes != null && v.notes!.isNotEmpty)
            Text('Not: ${v.notes}',
                style: Theme.of(context).textTheme.bodyMedium),
          const Divider(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _openForm(vaccine: v),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Düzenle'),
              ),
              const SizedBox(width: AppSpacing.sm),
              TextButton.icon(
                onPressed: () => _deleteVaccine(v),
                icon: Icon(Icons.delete_outline, size: 18, color: context.scheme.error),
                label: Text('Sil', style: TextStyle(color: context.scheme.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
