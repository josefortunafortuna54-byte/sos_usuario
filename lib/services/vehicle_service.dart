import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleService {
  static final _db = Supabase.instance.client;

  static Future<void> reportarRoubo({
    required String marca,
    required String modelo,
    required String matricula,
    required String cor,
    required String localFurto,
    Position? posicao,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Utilizador não autenticado');

    await _db.from('stolen_vehicles').insert({
      'user_id':     user.id,
      'marca':       marca,
      'modelo':      modelo,
      'matricula':   matricula.toUpperCase(),
      'cor':         cor,
      'local_furto': localFurto,
      'latitude':    posicao?.latitude,
      'longitude':   posicao?.longitude,
      'status':      'Procurado',
    });
  }

  static Future<List<Map<String, dynamic>>> minhasViaturas() async {
    final user = _db.auth.currentUser;
    if (user == null) return [];

    final res = await _db
        .from('stolen_vehicles')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }
}
