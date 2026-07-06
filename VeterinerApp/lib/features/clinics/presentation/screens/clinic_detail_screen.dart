import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_state.dart';
import '../../../../shared/widgets/info_row.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../announcements/data/models/announcement_model.dart';
import '../../data/models/clinic_model.dart';

const String _imgBase = 'http://10.0.2.2:5295';

class ClinicDetailScreen extends StatefulWidget {
  final int clinicId;
  const ClinicDetailScreen({super.key, required this.clinicId});

  @override
  State<ClinicDetailScreen> createState() => _ClinicDetailScreenState();
}

class _ClinicDetailScreenState extends State<ClinicDetailScreen> {
  ClinicModel? _clinic;
  bool _isLoading = true;
  String? _error;

  List<AnnouncementModel> _announcements = [];

  @override
  void initState() {
    super.initState();
    _fetchClinicDetails();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final response =
          await DioClient().dio.get('/clinics/${widget.clinicId}/announcements');
      if (response.data['success'] == true && mounted) {
        final List<dynamic> data = response.data['data'] ?? [];
        setState(() {
          _announcements =
              data.map((e) => AnnouncementModel.fromJson(e)).toList();
        });
      }
    } catch (_) {
      // duyuru yüklenemezse sessiz geç (bölüm gizli kalır)
    }
  }

  Future<void> _fetchClinicDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = DioClient().dio;
      final response = await dio.get('/clinics/${widget.clinicId}');
      if (response.data['success']) {
        setState(() {
          _clinic = ClinicModel.fromJson(response.data['data']);
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _error = 'Bağlantı hatası: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Bir hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildAnnouncements() {
    if (_announcements.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        Text('Duyurular', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        for (final a in _announcements) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.campaign_outlined,
                        size: 18, color: context.scheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(a.title,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(a.body, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(DateFormat('dd.MM.yyyy').format(a.createdAt),
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingIndicator());
    }

    if (_error != null || _clinic == null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorState(message: _error ?? 'Bulunamadı', onRetry: _fetchClinicDetails),
      );
    }

    final clinic = _clinic!;
    final primary = context.scheme.primary;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: primary,
            foregroundColor: context.scheme.onPrimary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                clinic.name,
                style: TextStyle(color: context.scheme.onPrimary),
              ),
              background: Container(
                color: primary,
                child: Icon(Icons.local_hospital,
                    size: 80, color: context.scheme.onPrimary.withOpacity(0.25)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    child: Column(
                      children: [
                        InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Adres',
                          value: clinic.address ?? 'Adres belirtilmemiş',
                        ),
                        InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Telefon',
                          value: clinic.phone ?? 'Telefon belirtilmemiş',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Hakkında', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(clinic.description ?? 'Açıklama yok.',
                      style: Theme.of(context).textTheme.bodyLarge),
                  _buildAnnouncements(),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Veteriner Hekimlerimiz',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
          if (clinic.vets != null)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final vet = clinic.vets![index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
                    child: AppCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: primary.withOpacity(0.12),
                            backgroundImage: vet.profilePhoto != null
                                ? NetworkImage('$_imgBase${vet.profilePhoto}')
                                : null,
                            child: vet.profilePhoto == null
                                ? Icon(Icons.person, color: primary)
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(vet.fullName,
                                    style: Theme.of(context).textTheme.titleMedium),
                                Text(vet.title ?? vet.specialty ?? 'Veteriner Hekim',
                                    style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                            ),
                            onPressed: () => context.push(
                                '/appointments/create?vetId=${vet.id}&clinicId=${clinic.id}'),
                            child: const Text('Randevu Al'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: clinic.vets!.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }
}
