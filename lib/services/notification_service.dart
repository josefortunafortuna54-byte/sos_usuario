import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final _db = Supabase.instance.client;

  static Stream<List<Map<String, dynamic>>> streamNotificacoes() {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();
    return _db
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  static Future<List<Map<String, dynamic>>> listar() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return [];
    final res = await _db
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<void> marcarLida(String id) async {
    await _db.from('notifications').update({'read': true}).eq('id', id);
  }

  static Future<void> marcarTodasLidas() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    await _db.from('notifications').update({'read': true}).eq('user_id', userId).isFilter('read', false);
  }

  static Future<int> naoLidas() async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return 0;
    final res = await _db
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .isFilter('read', false);
    return res.length;
  }

  static Future<void> registarTokenPush(String token, String platform, String role) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return;
    await _db.from('push_tokens').upsert({
      'user_id': userId,
      'token': token,
      'platform': platform,
      'role': role,
    }, onConflict: 'token');
  }
}
