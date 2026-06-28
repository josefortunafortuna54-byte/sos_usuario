import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SosService {
  static final _db = Supabase.instance.client;

  static Future<Map<String, dynamic>> enviarSos({
    required String tipo,
    String? descricao,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw Exception('Sessão expirada. Faça login novamente.');
    }

    Position? posicao;
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        posicao = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
      }
    } catch (e) {
      throw Exception('Erro ao obter localização: $e');
    }

    final res = await _db.from('occurrences').insert({
      'user_id': user.id,
      'tipo': tipo,
      'status': 'Pendente',
      'latitude': posicao?.latitude,
      'longitude': posicao?.longitude,
      if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
    }).select().single();

    return res;
  }

  static Future<List<Map<String, dynamic>>> historico() async {
    final user = _db.auth.currentUser;
    if (user == null) return [];

    final res = await _db
        .from('occurrences')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  static Future<void> cancelarSOS(String occurrenceId) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Sessão expirada.');

    final res = await _db
        .from('occurrences')
        .update({'status': 'Finalizado'})
        .eq('id', occurrenceId)
        .eq('user_id', user.id);

    if (res == null || (res is List && res.isEmpty)) {
      throw Exception('Não foi possível cancelar a ocorrência.');
    }
  }

  static Future<Map<String, dynamic>?> ocorrenciaActiva() async {
    final user = _db.auth.currentUser;
    if (user == null) return null;

    return await _db
        .from('occurrences')
        .select()
        .eq('user_id', user.id)
        .neq('status', 'Finalizado')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
  }
}
