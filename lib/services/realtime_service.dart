import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeService {
  static final _db = Supabase.instance.client;

  /// Stream da ocorrência mais recente do utilizador autenticado
  static Stream<Map<String, dynamic>?> streamMinhaOcorrencia() {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _db
        .from('occurrences')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((lista) => lista.isNotEmpty ? lista.first : null);
  }

  /// Stream de todas as ocorrências do utilizador (histórico)
  static Stream<List<Map<String, dynamic>>> streamHistorico() {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) return const Stream.empty();

    return _db
        .from('occurrences')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  /// Localização actual do agente atribuído à ocorrência
  static Future<Map<String, dynamic>?> localizacaoAgente(
      String agentId) async {
    try {
      return await _db
          .from('agent_locations')
          .select()
          .eq('agent_id', agentId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }
}
