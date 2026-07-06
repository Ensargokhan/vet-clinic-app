class ConversationModel {
  final int id;
  final String peerName;
  final String? peerTitle;
  final String? lastMessagePreview;
  final DateTime lastMessageAt;
  final int unreadCount;

  ConversationModel({
    required this.id,
    required this.peerName,
    this.peerTitle,
    this.lastMessagePreview,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      peerName: json['peerName'] ?? '',
      peerTitle: json['peerTitle'],
      lastMessagePreview: json['lastMessagePreview'],
      lastMessageAt: DateTime.parse(json['lastMessageAt']),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  /// Ünvan varsa "Dr. Ahmet" gibi birleşik ad döner.
  String get displayName =>
      (peerTitle != null && peerTitle!.isNotEmpty) ? '$peerTitle $peerName' : peerName;
}
