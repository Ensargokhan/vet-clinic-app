class AppointmentModel {
  final int id;
  final int animalId;
  final int vetId;
  final String? reason;
  final DateTime appointmentDate;
  final String status;
  final String? notes;

  // Extra display fields
  final String? animalName;
  final String? vetName;

  AppointmentModel({
    required this.id,
    required this.animalId,
    required this.vetId,
    this.reason,
    required this.appointmentDate,
    required this.status,
    this.notes,
    this.animalName,
    this.vetName,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      animalId: json['animalId'],
      vetId: json['vetId'],
      reason: json['reason'],
      appointmentDate: DateTime.parse(json['appointmentDate']),
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      animalName: json['animalName'], // Eager loading ile backend'den gelebilir
      vetName: json['vetName'],
    );
  }
}
