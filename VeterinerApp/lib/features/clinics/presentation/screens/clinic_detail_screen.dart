import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/clinic_model.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchClinicDetails();
  }

  Future<void> _fetchClinicDetails() async {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)));
    }

    if (_error != null || _clinic == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Bulunamadı', style: const TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_clinic!.name, style: const TextStyle(color: Colors.white, shadows: [Shadow(color: Colors.black45, blurRadius: 4)])),
              background: Container(
                color: AppTheme.primaryColor,
                child: const Center(child: Icon(Icons.local_hospital, size: 80, color: Colors.white24)),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(Icons.location_on, _clinic!.address ?? 'Adres belirtilmemiş'),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.phone, _clinic!.phone ?? 'Telefon belirtilmemiş'),
                  const SizedBox(height: 24),
                  Text('Hakkında', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(_clinic!.description ?? 'Açıklama yok.', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 32),
                  Text('Veteriner Hekimlerimiz', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (_clinic!.vets != null)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final vet = _clinic!.vets![index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.backgroundColor,
                          child: Icon(Icons.person, color: AppTheme.primaryColor),
                        ),
                        title: Text(vet.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(vet.title ?? vet.specialty ?? 'Veteriner Hekim'),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            textStyle: const TextStyle(fontSize: 14),
                          ),
                          onPressed: () {
                            // Randevu ekranına yönlendirme
                            context.push('/appointments/create?vetId=${vet.id}&clinicId=${_clinic!.id}');
                          },
                          child: const Text('Randevu Al'),
                        ),
                      ),
                    ),
                  );
                },
                childCount: _clinic!.vets!.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
      ],
    );
  }
}
