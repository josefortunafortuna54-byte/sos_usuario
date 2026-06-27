import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  static final _db = Supabase.instance.client;

  static Future<Position?> getCurrentLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      return null;
    }
  }

  /// Stream em tempo real da localização de um agente
  static Stream<Map<String, dynamic>?> streamAgente(String agentId) {
    return _db
        .from('agent_locations')
        .stream(primaryKey: ['agent_id'])
        .eq('agent_id', agentId)
        .map((lista) => lista.isNotEmpty ? lista.first : null);
  }
}
