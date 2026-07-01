class Mensagem {
  final String id;
  final String occurrenceId;
  final String senderId;
  final String senderRole;
  final String content;
  final String createdAt;
  final String? readAt;

  Mensagem({
    required this.id,
    required this.occurrenceId,
    required this.senderId,
    required this.senderRole,
    required this.content,
    required this.createdAt,
    this.readAt,
  });

  factory Mensagem.fromMap(Map<String, dynamic> map) {
    return Mensagem(
      id: map['id'] as String? ?? '',
      occurrenceId: map['occurrence_id'] as String? ?? '',
      senderId: map['sender_id'] as String? ?? '',
      senderRole: map['sender_role'] as String? ?? '',
      content: map['content'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      readAt: map['read_at'] as String?,
    );
  }

  bool get foiLida => readAt != null;

  bool get souEu => senderRole == 'user';
}
