import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/realtime_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _db = Supabase.instance.client;

  GoogleMapController? _mapCtrl;
  Set<Marker> _markers = {};
  StreamSubscription? _occStream;
  Timer? _agentTimer;

  LatLng _posicaoInicial = const LatLng(-8.8390, 13.2894); // Luanda
  String _statusOcorrencia = 'A carregar...';
  String? _agentId;

  @override
  void initState() {
    super.initState();
    _obterLocalizacaoActual();
    _subscreverOcorrencia();
  }

  @override
  void dispose() {
    _occStream?.cancel();
    _agentTimer?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
  }

  // ── Localização actual do utilizador ─────────────────────
  Future<void> _obterLocalizacaoActual() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _posicaoInicial = LatLng(pos.latitude, pos.longitude));
      _mapCtrl?.animateCamera(
        CameraUpdate.newLatLngZoom(_posicaoInicial, 15),
      );
    } catch (_) {}
  }

  // ── Stream da ocorrência do utilizador ───────────────────
  void _subscreverOcorrencia() {
    _occStream = RealtimeService.streamMinhaOcorrencia().listen((ocorrencia) {
      if (!mounted) return;
      if (ocorrencia == null) {
        setState(() {
          _statusOcorrencia = 'Sem ocorrência activa';
          _markers.removeWhere((m) => m.markerId.value.startsWith('occ_'));
        });
        return;
      }

      final status = ocorrencia['status'] ?? 'Pendente';
      setState(() => _statusOcorrencia = status);

      // Marcador do SOS
      if (ocorrencia['latitude'] != null && ocorrencia['longitude'] != null) {
        final pos = LatLng(
          (ocorrencia['latitude'] as num).toDouble(),
          (ocorrencia['longitude'] as num).toDouble(),
        );
        final marker = Marker(
          markerId: MarkerId('occ_${ocorrencia['id']}'),
          position: pos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: ocorrencia['tipo'] ?? 'SOS',
            snippet: 'Estado: $status',
          ),
        );
        setState(() {
          _markers.removeWhere((m) => m.markerId.value.startsWith('occ_'));
          _markers.add(marker);
        });
      }

      // Se há agente, rastrear localização
      final novoAgentId = ocorrencia['agent_id'] as String?;
      if (novoAgentId != null && novoAgentId != _agentId) {
        _agentId = novoAgentId;
        _iniciarRastreioAgente(novoAgentId);
      } else if (novoAgentId == null) {
        _agentTimer?.cancel();
        setState(() => _markers.removeWhere(
            (m) => m.markerId.value == 'agent'));
      }
    });
  }

  // ── Rastrear posição do agente (actualiza a cada 5s) ─────
  void _iniciarRastreioAgente(String agentId) {
    _agentTimer?.cancel();
    _actualizarAgente(agentId); // imediato
    _agentTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _actualizarAgente(agentId);
    });
  }

  Future<void> _actualizarAgente(String agentId) async {
    final loc = await RealtimeService.localizacaoAgente(agentId);
    if (loc == null || !mounted) return;

    final pos = LatLng(
      (loc['latitude'] as num).toDouble(),
      (loc['longitude'] as num).toDouble(),
    );
    final marker = Marker(
      markerId: const MarkerId('agent'),
      position: pos,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(
        title: 'Agente',
        snippet: 'A caminho',
      ),
    );
    if (mounted) {
      setState(() {
        _markers.removeWhere((m) => m.markerId.value == 'agent');
        _markers.add(marker);
      });
    }
  }

  // ── UI ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('O meu SOS'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _posicaoInicial,
              zoom: 14,
            ),
            markers: _markers,
            onMapCreated: (c) => _mapCtrl = c,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          // Barra de status da ocorrência
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _corStatus(_statusOcorrencia),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: Colors.white, size: 12),
                  const SizedBox(width: 8),
                  Text(
                    'Estado: $_statusOcorrencia',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          // Legenda
          Positioned(
            bottom: 24,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _LegendaItem(cor: Colors.red, label: 'O meu SOS'),
                  SizedBox(height: 4),
                  _LegendaItem(cor: Colors.blue, label: 'Agente'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'Pendente':   return Colors.orange;
      case 'Despachado': return Colors.blue;
      case 'A caminho':  return Colors.indigo;
      case 'No local':   return Colors.green;
      case 'Finalizado': return Colors.grey;
      default:           return Colors.red;
    }
  }
}

class _LegendaItem extends StatelessWidget {
  final Color cor;
  final String label;
  const _LegendaItem({required this.cor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_pin, color: cor, size: 18),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
