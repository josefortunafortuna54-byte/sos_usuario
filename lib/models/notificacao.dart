class Notificacao {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final bool read;
  final String createdAt;

  Notificacao({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.type = 'info',
    this.data,
    this.read = false,
    required this.createdAt,
  });

  factory Notificacao.fromMap(Map<String, dynamic> map) {
    return Notificacao(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? 'info',
      data: map['data'] as Map<String, dynamic>?,
      read: map['read'] as bool? ?? false,
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
