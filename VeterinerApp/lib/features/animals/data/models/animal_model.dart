class AnimalModel {
  final int id;
  final int ownerId;
  final String name;
  final String species;
  final String? breed;
  final String? gender;
  final DateTime? birthDate;
  final double? weight;
  final String? microchipNo;
  final String? photoUrl;
  final String? notes;
  final DateTime createdAt;

  AnimalModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    this.breed,
    this.gender,
    this.birthDate,
    this.weight,
    this.microchipNo,
    this.photoUrl,
    this.notes,
    required this.createdAt,
  });

  factory AnimalModel.fromJson(Map<String, dynamic> json) {
    return AnimalModel(
      id: json['id'],
      ownerId: json['ownerId'],
      name: json['name'] ?? '',
      species: json['species'] ?? '',
      breed: json['breed'],
      gender: json['gender'],
      birthDate: json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null,
      weight: json['weight']?.toDouble(),
      microchipNo: json['microchipNo'],
      photoUrl: json['photoUrl'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  int get age {
    if (birthDate == null) return 0;
    final today = DateTime.now();
    int age = today.year - birthDate!.year;
    if (today.month < birthDate!.month || (today.month == birthDate!.month && today.day < birthDate!.day)) {
      age--;
    }
    return age < 0 ? 0 : age;
  }
}
