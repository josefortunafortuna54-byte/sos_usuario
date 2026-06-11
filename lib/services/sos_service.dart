import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SosService {
  static final _db = Supabase.instance.client;

  /// Envia SOS — compatível com home_screen.dart original
  static Future<Map<String, dynamic>> enviarSos({
    required dynamic userId,
    required String tipo,
    String? descricao,
  }) async {
    // Obter localização
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
    } catch (_) {}

    final res = await _db.from('occurrences').insert({
      'user_id':   userId.toString(),
      'tipo':      tipo,
      'status':    'Pendente',
      'latitude':  posicao?.latitude,
      'longitude': posicao?.longitude,
      if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
    }).select().single();

    return res;
  }

  /// Histórico — compatível com history_screen.dart (userId como Object)
  static Future<List<Map<String, dynamic>>> historico(Object userId) async {
    final res = await _db
        .from('occurrences')
        .select()
        .eq('user_id', userId.toString())
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  /// Cancelar ocorrência activa
  static Future<void> cancelarSOS(String occurrenceId) async {
    await _db
        .from('occurrences')
        .update({'status': 'Finalizado'})
        .eq('id', occurrenceId);
  }

  /// Ocorrência activa do utilizador
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
