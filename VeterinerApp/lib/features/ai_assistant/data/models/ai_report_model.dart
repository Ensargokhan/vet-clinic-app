/// AI ön muayene sohbetinin sonunda üretilen yapılandırılmış ön rapor (anamnez).
class AiReportModel {
  final int id;
  final int animalId;
  final int? appointmentId;
  final String reportContent;
  final String symptomsSummary;
  final String urgencyLevel; // low, medium, high, emergency
  final DateTime createdAt;

  AiReportModel({
    required this.id,
    required this.animalId,
    required this.appointmentId,
    required this.reportContent,
    required this.symptomsSummary,
    required this.urgencyLevel,
    required this.createdAt,
  });

  factory AiReportModel.fromJson(Map<String, dynamic> json) {
    return AiReportModel(
      id: json['id'] ?? 0,
      animalId: json['animalId'] ?? 0,
      appointmentId: json['appointmentId'],
      reportContent: json['reportContent'] ?? '',
      symptomsSummary: json['symptomsSummary'] ?? '',
      urgencyLevel: json['urgencyLevel'] ?? 'low',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
