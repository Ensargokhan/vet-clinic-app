import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/clinic_model.dart';

class ClinicsScreen extends StatefulWidget {
  const ClinicsScreen({super.key});

  @override
  State<ClinicsScreen> createState() => _ClinicsScreenState();
}

class _ClinicsScreenState extends State<ClinicsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<ClinicModel> _clinics = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  int _currentPage = 1;
  int _pageSize = 15;
  bool _hasNext = true;

  String? _searchQuery;
  String? _selectedCity;

  List<String> _cities = [];

  int _trCompare(String a, String b) {
    String replaceTr(String text) {
      return text.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase()
        .replaceAll('ç', 'c~')
        .replaceAll('ğ', 'g~')
        .replaceAll('ı', 'h~')
        .replaceAll('ö', 'o~')
        .replaceAll('ş', 's~')
        .replaceAll('ü', 'u~');
    }
    return replaceTr(a).compareTo(replaceTr(b));
  }

  @override
  void initState() {
    super.initState();
    _loadCitiesData();
    _fetchClinics(refresh: true);
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadCitiesData() async {
    try {
      final String response = await rootBundle.loadString('assets/data/turkey_cities.json');
      final data = await json.decode(response);
      setState(() {
        final List<dynamic> citiesData = data['data'];
        _cities = citiesData.map<String>((city) => city['name'].toString()).toList();
        _cities.sort(_trCompare);
      });
    } catch (e) {
      debugPrint("Error loading cities: $e");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && !_isLoadingMore && _hasNext) {
        _fetchClinics();
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchQuery != query) {
        setState(() {
          _searchQuery = query.isEmpty ? null : query;
        });
        _fetchClinics(refresh: true);
      }
    });
  }

  Future<void> _fetchClinics({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final dio = DioClient().dio;
      final queryParams = {
        'page': _currentPage,
        'pageSize': _pageSize,
        if (_searchQuery != null) 'search': _searchQuery,
        if (_selectedCity != null) 'city': _selectedCity,
      };

      final response = await dio.get('/clinics', queryParameters: queryParams);
      
      if (response.data['success']) {
        final data = response.data['data'];
        final List<dynamic> items = data['items'];
        final newClinics = items.map((e) => ClinicModel.fromJson(e)).toList();

        setState(() {
          if (refresh) {
            _clinics = newClinics;
          } else {
            _clinics.addAll(newClinics);
          }
          _hasNext = data['hasNext'] ?? false;
          if (_hasNext) _currentPage++;
          
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        if (refresh) _error = 'Klinikler yüklenemedi: ${e.message}';
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        if (refresh) _error = 'Bilinmeyen bir hata oluştu.';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filtrele', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Şehir Seçin',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCity,
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Tümü'),
                      ),
                      ..._cities.map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(city),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setModalState(() {
                        _selectedCity = val;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCity = null;
                            });
                            Navigator.pop(context);
                            _fetchClinics(refresh: true);
                          },
                          child: const Text('Temizle'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _fetchClinics(refresh: true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Uygula'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anlaşmalı Klinikler', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list, color: AppTheme.primaryColor),
                if (_selectedCity != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Klinik adı ile ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery != null && _searchQuery!.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            TextButton(
              onPressed: () => _fetchClinics(refresh: true), 
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_clinics.isEmpty) {
      return const Center(
        child: Text(
          'Aradığınız kritere uygun klinik bulunamadı.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchClinics(refresh: true),
      color: AppTheme.primaryColor,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _clinics.length + (_hasNext ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == _clinics.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
            );
          }

          final clinic = _clinics[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push('/clinics/${clinic.id}'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: clinic.logoUrl != null && clinic.logoUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(clinic.logoUrl!, fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_hospital, color: AppTheme.primaryColor, size: 32),
                              ),
                            )
                          : const Icon(Icons.local_hospital, color: AppTheme.primaryColor, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clinic.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${clinic.district ?? ""}${clinic.district != null && clinic.city != null ? ", " : ""}${clinic.city ?? ""}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
