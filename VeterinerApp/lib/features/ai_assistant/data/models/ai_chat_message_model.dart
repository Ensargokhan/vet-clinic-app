/// AI ön muayene sohbetindeki tek mesaj. Rol 'user' (hasta sahibi) veya 'assistant' (AI).
class AiChatMessageModel {
  final int id;
  final String role;
  final String content;
  final DateTime createdAt;

  AiChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get isAssistant => role == 'assistant';

  factory AiChatMessageModel.fromJson(Map<String, dynamic> json) {
    return AiChatMessageModel(
      id: json['id'] ?? 0,
      role: json['role'] ?? 'assistant',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
