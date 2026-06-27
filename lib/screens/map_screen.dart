import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/realtime_service.dart';
import '../services/location_service.dart';
import 'chat_screen.dart';
import 'media_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapCtrl = MapController();
  StreamSubscription? _occStream;
  StreamSubscription<Map<String, dynamic>?>? _agentStream;

  LatLng _posicaoInicial = const LatLng(-8.8390, 13.2894);
  LatLng? _ocorrenciaPos;
  LatLng? _agentePos;
  String _statusOcorrencia = 'A carregar...';
  String? _agentId;
  String _tipoOcorrencia = 'SOS';
  String? _occurrenceId;

  @override
  void initState() {
    super.initState();
    _obterLocalizacaoActual();
    _subscreverOcorrencia();
  }

  @override
  void dispose() {
    _occStream?.cancel();
    _agentStream?.cancel();
    super.dispose();
  }

  Future<void> _obterLocalizacaoActual() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _posicaoInicial = LatLng(pos.latitude, pos.longitude));
      _mapCtrl.move(_posicaoInicial, 15);
    } catch (_) {}
  }

  void _subscreverOcorrencia() {
    _occStream = RealtimeService.streamMinhaOcorrencia().listen((ocorrencia) {
      if (!mounted) return;
      if (ocorrencia == null) {
        setState(() {
          _statusOcorrencia = 'Sem ocorrência activa';
          _ocorrenciaPos = null;
        });
        return;
      }

      final status = ocorrencia['status'] ?? 'Pendente';
      setState(() {
        _statusOcorrencia = status;
        _tipoOcorrencia = ocorrencia['tipo'] ?? 'SOS';
      });

      setState(() => _occurrenceId = ocorrencia['id'] as String?);

      if (ocorrencia['latitude'] != null && ocorrencia['longitude'] != null) {
        final pos = LatLng(
          (ocorrencia['latitude'] as num).toDouble(),
          (ocorrencia['longitude'] as num).toDouble(),
        );
        setState(() => _ocorrenciaPos = pos);
      }

      final novoAgentId = ocorrencia['agent_id'] as String?;
      if (novoAgentId != null && novoAgentId != _agentId) {
        _agentId = novoAgentId;
        _subscreverAgente(novoAgentId);
      } else if (novoAgentId == null) {
        _agentStream?.cancel();
        setState(() => _agentePos = null);
      }
    });
  }

  void _subscreverAgente(String agentId) {
    _agentStream?.cancel();
    _agentStream = LocationService.streamAgente(agentId).listen((loc) {
      if (!mounted) return;
      if (loc == null) return;
      final pos = LatLng(
        (loc['latitude'] as num).toDouble(),
        (loc['longitude'] as num).toDouble(),
      );
      setState(() => _agentePos = pos);
    });
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

    if (_ocorrenciaPos != null) {
      markers.add(
        Marker(
          point: _ocorrenciaPos!,
          width: 44,
          height: 44,
          child: const Icon(Icons.location_pin, color: Colors.red, size: 44),
        ),
      );
    }

    if (_agentePos != null) {
      markers.add(
        Marker(
          point: _agentePos!,
          width: 44,
          height: 44,
          child: const Icon(Icons.local_police, color: Colors.blue, size: 38),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('O meu SOS'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapCtrl,
            options: MapOptions(
              initialCenter: _posicaoInicial,
              initialZoom: 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sos_usuario',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _corStatus(_statusOcorrencia),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: Colors.white, size: 12),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$_tipoOcorrencia — Estado: $_statusOcorrencia',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _LegendaItem(icone: Icons.location_pin, cor: Colors.red, label: 'O meu SOS'),
                  SizedBox(height: 4),
                  _LegendaItem(icone: Icons.local_police, cor: Colors.blue, label: 'Agente'),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_occurrenceId != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FloatingActionButton.small(
                      backgroundColor: const Color(0xFF1E90FF),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(occurrenceId: _occurrenceId!, occurrenceTitle: '$_tipoOcorrencia — $_statusOcorrencia'))),
                      child: const Icon(Icons.chat, color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: FloatingActionButton.small(
                      backgroundColor: Colors.green,
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MediaScreen(occurrenceId: _occurrenceId!))),
                      child: const Icon(Icons.photo_camera, color: Colors.white),
                    ),
                  ),
                ],
                FloatingActionButton(
                  backgroundColor: Colors.red[700],
                  onPressed: _obterLocalizacaoActual,
                  child: const Icon(Icons.my_location, color: Colors.white),
                ),
              ],
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
  final IconData icone;
  final Color cor;
  final String label;
  const _LegendaItem({required this.icone, required this.cor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, color: cor, size: 18),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
