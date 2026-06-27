import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class MediaService {
  static final _db = Supabase.instance.client;

  static Future<String> upload({
    required String occurrenceId,
    required File file,
    required bool isVideo,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Não autenticado');

    final ext = isVideo ? 'mp4' : 'jpg';
    final path = '$occurrenceId/${user.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _db.storage.from('occurrence_media').upload(path, file);

    final url = _db.storage.from('occurrence_media').getPublicUrl(path);

    await _db.from('occurrence_media').insert({
      'occurrence_id': occurrenceId,
      'user_id': user.id,
      'type': isVideo ? 'video' : 'image',
      'url': url,
    });

    return url;
  }

  static Future<List<Map<String, dynamic>>> listar(String occurrenceId) async {
    final res = await _db
        .from('occurrence_media')
        .select()
        .eq('occurrence_id', occurrenceId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }
}
