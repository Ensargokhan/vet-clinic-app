class MessageModel {
  final int id;
  final int conversationId;
  final int senderUserId;
  final String body;
  final bool isMine;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.body,
    required this.isMine,
    required this.isRead,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      conversationId: json['conversationId'],
      senderUserId: json['senderUserId'],
      body: json['body'] ?? '',
      isMine: json['isMine'] ?? false,
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
