class AppointmentModel {
  final int id;
  final int animalId;
  final int vetId;
  final int clinicId;
  final String? reason;
  final DateTime appointmentDate;
  final String status;
  final String? notes;
  final String? cancellationReason;

  // Extra display fields
  final String? animalName;
  final String? vetName;
  final String? clinicName;

  AppointmentModel({
    required this.id,
    required this.animalId,
    required this.vetId,
    this.clinicId = 0,
    this.reason,
    required this.appointmentDate,
    required this.status,
    this.notes,
    this.cancellationReason,
    this.animalName,
    this.vetName,
    this.clinicName,
  });

  /// Tamamlanmış randevu → kullanıcı bu kliniği değerlendirebilir.
  bool get canReviewClinic => status == 'completed' && clinicId != 0;

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      animalId: json['animalId'],
      vetId: json['vetId'],
      clinicId: json['clinicId'] ?? 0,
      reason: json['reason'],
      appointmentDate: DateTime.parse(json['appointmentDate']),
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      cancellationReason: json['cancellationReason'],
      animalName: json['animalName'], // Eager loading ile backend'den gelebilir
      vetName: json['vetName'],
      clinicName: json['clinicName'],
    );
  }
}
