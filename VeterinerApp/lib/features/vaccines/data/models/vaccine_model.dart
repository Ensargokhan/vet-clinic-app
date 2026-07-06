class VaccineModel {
  final int id;
  final int animalId;
  final int? vetId;
  final String? vetName;
  final String vaccineName;
  final DateTime administeredDate;
  final DateTime? nextDueDate;
  final String? batchNumber;
  final String? notes;

  VaccineModel({
    required this.id,
    required this.animalId,
    this.vetId,
    this.vetName,
    required this.vaccineName,
    required this.administeredDate,
    this.nextDueDate,
    this.batchNumber,
    this.notes,
  });

  factory VaccineModel.fromJson(Map<String, dynamic> json) {
    return VaccineModel(
      id: json['id'],
      animalId: json['animalId'],
      vetId: json['vetId'],
      vetName: json['vetName'],
      vaccineName: json['vaccineName'] ?? '',
      administeredDate: DateTime.parse(json['administeredDate']),
      nextDueDate: json['nextDueDate'] != null
          ? DateTime.parse(json['nextDueDate'])
          : null,
      batchNumber: json['batchNumber'],
      notes: json['notes'],
    );
  }

  /// Sonraki aşı tarihi bugünden itibaren 3 gün içinde mi (yaklaşıyor)?
  bool get isDueSoon {
    if (nextDueDate == null) return false;
    final now = DateTime.now();
    final diff = nextDueDate!.difference(DateTime(now.year, now.month, now.day)).inDays;
    return diff >= 0 && diff <= 3;
  }
}
