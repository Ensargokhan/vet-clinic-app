import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../data/models/clinic_review_model.dart';
import '../../data/models/my_review_status_model.dart';
import '../../data/models/review_summary_model.dart';
import '../widgets/rating_summary.dart';
import '../widgets/review_tile.dart';
import '../widgets/write_review_sheet.dart';

/// Bir kliniğin tüm değerlendirmeleri: özet + sayfalı liste + kendi yorumunu yaz/düzenle/sil.
class ClinicReviewsScreen extends StatefulWidget {
  final int clinicId;
  final String? clinicName;

  const ClinicReviewsScreen({super.key, required this.clinicId, this.clinicName});

  @override
  State<ClinicReviewsScreen> createState() => _ClinicReviewsScreenState();
}

class _ClinicReviewsScreenState extends State<ClinicReviewsScreen> {
  ReviewSummaryModel _summary = ReviewSummaryModel.empty();
  MyReviewStatusModel _myStatus = MyReviewStatusModel.none();
  final List<ClinicReviewModel> _reviews = [];

  int _page = 1;
  bool _hasNext = false;
  bool _isLoading = true;
  bool _loadingMore = false;
  String? _error;

  static const _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await Future.wait([_fetchSummary(), _fetchMyStatus(), _fetchPage(1, reset: true)]);
      if (mounted) setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Değerlendirmeler yüklenemedi.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchSummary() async {
    final res = await DioClient().dio.get('/clinics/${widget.clinicId}/reviews/summary');
    if (res.data['success'] == true && mounted) {
      setState(() => _summary = ReviewSummaryModel.fromJson(res.data['data']));
    }
  }

  Future<void> _fetchMyStatus() async {
    try {
      final res = await DioClient().dio.get('/clinics/${widget.clinicId}/reviews/me');
      if (res.data['success'] == true && mounted) {
        setState(() => _myStatus = MyReviewStatusModel.fromJson(res.data['data']));
      }
    } catch (_) {
      // hekim/klinik rolü veya hata → buton gizli kalır
    }
  }

  Future<void> _fetchPage(int page, {bool reset = false}) async {
    final res = await DioClient().dio.get(
      '/clinics/${widget.clinicId}/reviews',
      queryParameters: {'page': page, 'pageSize': _pageSize},
    );
    if (res.data['success'] == true && mounted) {
      final data = res.data['data'];
      final List<dynamic> items = data['items'] ?? [];
      setState(() {
        if (reset) _reviews.clear();
        _reviews.addAll(items.map((e) => ClinicReviewModel.fromJson(e)));
        _page = data['page'] ?? page;
        _hasNext = data['hasNext'] ?? false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      await _fetchPage(_page + 1);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daha fazla yorum yüklenemedi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _writeOrEdit() async {
    final saved = await WriteReviewSheet.show(
      context,
      clinicId: widget.clinicId,
      clinicName: widget.clinicName ?? 'Klinik',
      existing: _myStatus.review,
    );
    if (saved == true) _loadAll();
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Değerlendirmeyi Sil'),
        content: const Text('Değerlendirmenizi silmek istediğinize emin misiniz?'),
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
      await DioClient().dio.delete('/clinics/${widget.clinicId}/reviews/me');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Değerlendirmeniz silindi.'),
            backgroundColor: context.colors.success,
          ),
        );
        _loadAll();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data?['message'] ?? 'Silinemedi.'),
            backgroundColor: context.scheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.clinicName ?? 'Değerlendirmeler')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const LoadingIndicator();
    if (_error != null) return ErrorState(message: _error!, onRetry: _loadAll);

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: context.scheme.primary,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          AppCard(child: RatingSummary(summary: _summary)),
          if (_myStatus.canReview) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _writeOrEdit,
                icon: Icon(_myStatus.hasReviewed ? Icons.edit_outlined : Icons.rate_review_outlined),
                label: Text(_myStatus.hasReviewed
                    ? 'Değerlendirmeni Düzenle'
                    : 'Kliniği Değerlendir'),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (_reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxl),
              child: EmptyState(
                icon: Icons.rate_review_outlined,
                message: 'Bu klinik için henüz değerlendirme yapılmamış.',
              ),
            )
          else ...[
            for (final r in _reviews) ...[
              ReviewTile(
                review: r,
                onEdit: r.isMine ? _writeOrEdit : null,
                onDelete: r.isMine ? _delete : null,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (_hasNext)
              Center(
                child: TextButton(
                  onPressed: _loadingMore ? null : _loadMore,
                  child: _loadingMore
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Daha fazla yükle'),
                ),
              ),
          ],
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
