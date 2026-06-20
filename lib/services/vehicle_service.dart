import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleService {
  static final _db = Supabase.instance.client;

  static Future<void> reportarRoubo({
    required String tipo,
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
      'user_id':     user.id, // auth.uid() directamente
      'tipo':        tipo,
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
}
