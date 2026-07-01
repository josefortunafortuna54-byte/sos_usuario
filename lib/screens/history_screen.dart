import 'package:flutter/material.dart';
import '../services/sos_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _ocorrencias = [];
  bool _loading = true;

  final _corStatus = {
    'Pendente':   Colors.red,
    'Despachado': Colors.blue,
    'A caminho':  Colors.orange,
    'No local':   Colors.purple,
    'Finalizado': Colors.green,
  };

  final _iconStatus = {
    'Pendente':   Icons.hourglass_empty,
    'Despachado': Icons.local_police,
    'A caminho':  Icons.directions_car,
    'No local':   Icons.location_on,
    'Finalizado': Icons.check_circle,
  };

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final dados = await SosService.historico();
      if (mounted) setState(() => _ocorrencias = dados);
    } catch (e) {
      if (mounted) setState(() => _ocorrencias = []);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatarData(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.parse(iso).toLocal();
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  String? _formatarCoordenadas(Map<String, dynamic> oc) {
    final lat = (oc['latitude'] as num?)?.toDouble();
    final lng = (oc['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return 'Lat: ${lat.toStringAsFixed(4)}  Lng: ${lng.toStringAsFixed(4)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregar,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFF1E90FF)))
          : _ocorrencias.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history,
                          color: Colors.white12, size: 64),
                      const SizedBox(height: 16),
                      const Text('Sem ocorrências registadas.',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 15)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _ocorrencias.length,
                    itemBuilder: (_, i) {
                      final oc = _ocorrencias[i];
                      final status =
                          oc['status'] as String? ?? 'Pendente';
                      final cor = _corStatus[status] ?? Colors.grey;
                      final icone =
                          _iconStatus[status] ?? Icons.emergency;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1B2A),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: cor.withValues(alpha: 0.3)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cor.withValues(alpha: 0.12),
                              border: Border.all(
                                  color: cor.withValues(alpha: 0.4)),
                            ),
                            child: Icon(icone, color: cor, size: 20),
                          ),
                          title: Text(
                            oc['tipo'] as String? ?? 'Emergência',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                _formatarData(
                                    oc['created_at'] as String?),
                                style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11),
                              ),
                              if (_formatarCoordenadas(oc) != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _formatarCoordenadas(oc)!,
                                  style: const TextStyle(
                                      color: Colors.white24,
                                      fontSize: 10),
                                ),
                              ],
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: cor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: cor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                  color: cor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
