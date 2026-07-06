import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../announcements/data/models/announcement_model.dart';

/// Klinik yöneticisinin duyuru yönetimi: listeleme, yayınlama, silme.
/// Yayınlanan duyuru, klinikte randevusu olan sahiplere bildirim olarak gider.
class ClinicAnnouncementsScreen extends StatefulWidget {
  const ClinicAnnouncementsScreen({super.key});

  @override
  State<ClinicAnnouncementsScreen> createState() => _ClinicAnnouncementsScreenState();
}

class _ClinicAnnouncementsScreenState extends State<ClinicAnnouncementsScreen> {
  List<AnnouncementModel> _announcements = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await DioClient().dio.get('/clinics/my-clinic/announcements');
      if (res.data['success'] == true && mounted) {
        final List<dynamic> data = res.data['data'] ?? [];
        setState(() {
          _announcements = data.map((e) => AnnouncementModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Duyurular yüklenemedi.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createAnnouncement() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final published = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              top: AppSpacing.xl,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Yeni Duyuru',
                        style: Theme.of(ctx).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      controller: titleCtrl,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'Başlık',
                        prefixIcon: Icon(Icons.campaign_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Başlık zorunludur.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: bodyCtrl,
                      maxLength: 1000,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'İçerik',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'İçerik zorunludur.'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() => saving = true);
                                try {
                                  await DioClient().dio.post(
                                    '/clinics/my-clinic/announcements',
                                    data: {
                                      'title': titleCtrl.text.trim(),
                                      'body': bodyCtrl.text.trim(),
                                    },
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx, true);
                                } on DioException catch (e) {
                                  setSheetState(() => saving = false);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      SnackBar(
                                        content: Text(e.response?.data?['message'] ??
                                            'Duyuru yayınlanamadı.'),
                                        backgroundColor: ctx.scheme.error,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: saving
                            ? SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: ctx.scheme.onPrimary),
                              )
                            : const Icon(Icons.send),
                        label: const Text('Yayınla'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (published == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Duyuru yayınlandı, sahiplere bildirim gönderildi.'),
          backgroundColor: context.colors.success,
        ),
      );
      _load();
    }
  }

  Future<void> _delete(AnnouncementModel a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duyuruyu Sil'),
        content: Text('"${a.title}" duyurusunu silmek istiyor musunuz?'),
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
      await DioClient().dio.delete('/clinics/my-clinic/announcements/${a.id}');
      if (mounted) _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Duyuru silinemedi.'),
            backgroundColor: context.scheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duyurular')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAnnouncement,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Duyuru'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingIndicator();
    if (_error != null) {
      return ErrorState(message: _error!, onRetry: _load);
    }
    if (_announcements.isEmpty) {
      return const EmptyState(
        icon: Icons.campaign_outlined,
        message: 'Henüz duyuru yok.\n"Yeni Duyuru" ile paylaşın.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: context.scheme.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _announcements.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) => _announcementCard(_announcements[i]),
      ),
    );
  }

  Widget _announcementCard(AnnouncementModel a) {
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(a.createdAt);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign_outlined, size: 18, color: context.scheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(a.title,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: context.scheme.error, size: 20),
                visualDensity: VisualDensity.compact,
                onPressed: () => _delete(a),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(a.body, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(dateStr, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
