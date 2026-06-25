import 'vet_model.dart';

class ClinicModel {
  final int id;
  final String name;
  final String? address;
  final String? city;
  final String? district;
  final String? phone;
  final String? email;
  final String? description;
  final String? logoUrl;
  final double? latitude;
  final double? longitude;
  final List<VetModel>? vets;
  final List<String> specialties;
  final double? rating;
  final int reviewCount;

  ClinicModel({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.district,
    this.phone,
    this.email,
    this.description,
    this.logoUrl,
    this.latitude,
    this.longitude,
    this.vets,
    this.specialties = const [],
    this.rating,
    this.reviewCount = 0,
  });

  factory ClinicModel.fromJson(Map<String, dynamic> json) {
    return ClinicModel(
      id: json['id'],
      name: json['name'] ?? '',
      address: json['address'],
      city: json['city'],
      district: json['district'],
      phone: json['phone'],
      email: json['email'],
      description: json['description'],
      logoUrl: json['logoUrl'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      vets: json['vets'] != null
          ? (json['vets'] as List).map((v) => VetModel.fromJson(v)).toList()
          : null,
      specialties: json['specialties'] != null
          ? (json['specialties'] as List).map((e) => e.toString()).toList()
          : const [],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewCount: json['reviewCount'] ?? 0,
    );
  }
}
