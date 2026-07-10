import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/models/clinic_review_model.dart';
import 'star_rating.dart';

/// Puan + yorum girme/düzenleme alt sayfası.
/// Kaydedilirse `true` döner → çağıran ekran listesini yeniler.
///
/// Kullanım:
/// ```dart
/// final saved = await WriteReviewSheet.show(context, clinicId: 1, clinicName: 'X', existing: null);
/// ```
class WriteReviewSheet extends StatefulWidget {
  final int clinicId;
  final String clinicName;
  final ClinicReviewModel? existing;

  const WriteReviewSheet({
    super.key,
    required this.clinicId,
    required this.clinicName,
    this.existing,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int clinicId,
    required String clinicName,
    ClinicReviewModel? existing,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => WriteReviewSheet(
        clinicId: clinicId,
        clinicName: clinicName,
        existing: existing,
      ),
    );
  }

  @override
  State<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<WriteReviewSheet> {
  late int _rating;
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existing?.rating ?? 0;
    _controller = TextEditingController(text: widget.existing?.comment ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir puan seçin.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final comment = _controller.text.trim();
      await DioClient().dio.post(
        '/clinics/${widget.clinicId}/reviews',
        data: {
          'rating': _rating,
          'comment': comment.isEmpty ? null : comment,
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data?['message'] ??
                'Değerlendirme kaydedilemedi.'),
            backgroundColor: context.scheme.error,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Beklenmeyen bir hata oluştu.'),
            backgroundColor: context.scheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing ? 'Değerlendirmeni Düzenle' : 'Kliniği Değerlendir',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(widget.clinicName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  )),
          const SizedBox(height: AppSpacing.xl),

          Center(
            child: StarRating(
              rating: _rating.toDouble(),
              size: 40,
              onChanged: _saving ? null : (v) => setState(() => _rating = v),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          TextField(
            controller: _controller,
            enabled: !_saving,
            maxLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'Yorumunuz (isteğe bağlı)',
              hintText: 'Deneyiminizi diğer hayvan sahipleriyle paylaşın...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: context.scheme.onPrimary),
                    )
                  : Text(isEditing ? 'Güncelle' : 'Gönder'),
            ),
          ),
        ],
      ),
    );
  }
}
