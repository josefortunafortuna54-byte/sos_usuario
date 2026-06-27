import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  static final _db = Supabase.instance.client;

  static Stream<List<Map<String, dynamic>>> streamMensagens(
      String occurrenceId) {
    return _db
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('occurrence_id', occurrenceId)
        .order('created_at', ascending: true);
  }

  static Future<void> enviar({
    required String occurrenceId,
    required String content,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Não autenticado');
    await _db.from('messages').insert({
      'occurrence_id': occurrenceId,
      'sender_id': user.id,
      'sender_role': 'user',
      'content': content,
    });
  }

  static Future<void> marcarLidas(String occurrenceId) async {
    final user = _db.auth.currentUser;
    if (user == null) return;
    await _db
        .from('messages')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('occurrence_id', occurrenceId)
        .neq('sender_id', user.id)
        .isFilter('read_at', null);
  }
}
