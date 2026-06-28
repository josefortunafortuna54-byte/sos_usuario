import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../services/auth_service.dart';
import '../services/sos_service.dart';
import 'history_screen.dart';
import 'report_vehicle_screen.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _usuario;
  bool _enviando = false;
  String _statusMsg = '';
  bool _enviado = false;
  final List<String> _eventos = [];
  String _tipoSelecionado = 'Emergência';
  final TextEditingController _descricaoCtrl = TextEditingController();

  static const List<String> _sugestoesOcorrencia = [
    'Emergência',
    'Assalto',
    'Acidente',
    'Violência',
    'Incêndio',
    'Pessoa suspeita',
  ];

  @override
  void initState() {
    super.initState();
    _carregarUsuario();
  }

  Future<void> _carregarUsuario() async {
    _log('A carregar perfil...');
    try {
      final p = await AuthService.perfil().timeout(const Duration(seconds: 12));
      if (mounted) setState(() => _usuario = p);
      _log(p == null ? 'Perfil não encontrado.' : 'Perfil carregado com sucesso.');
    } catch (e) {
      _log('Erro ao carregar perfil: $e');
    }
  }

  void _log(String msg) {
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final linha = '[$hh:$mm:$ss] $msg';
    if (!mounted) return;
    setState(() {
      _eventos.insert(0, linha);
      if (_eventos.length > 6) _eventos.removeLast();
    });
  }

  Future<void> _enviarSos() async {
    if (_enviando) return;

    if (_usuario == null) {
      _log('Erro: Utilizador não encontrado.');
      return;
    }

    setState(() {
      _enviando  = true;
      _enviado   = false;
      _statusMsg = 'A obter localização...';
    });
    _log('Início do envio SOS (${_tipoSelecionado.toUpperCase()}).');

    try {
      await SosService.enviarSos(
        tipo: _tipoSelecionado,
        descricao: _descricaoCtrl.text.trim().isEmpty
            ? null
            : _descricaoCtrl.text.trim(),
      ).timeout(const Duration(seconds: 20));

      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 300]);
      }

      setState(() {
        _enviado   = true;
        _statusMsg = '✓ SOS enviado! Aguarde a polícia.';
      });
      _log('SOS enviado com sucesso.');

      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _enviado = false;
          _statusMsg = '';
          _descricaoCtrl.clear();
        });
      }
    } on TimeoutException {
      setState(() {
        _statusMsg = 'O servidor demorou muito a responder. Verifique a sua ligação.';
      });
      _log('Timeout ao enviar SOS.');
      await Future.delayed(const Duration(seconds: 4));
      if (mounted) setState(() => _statusMsg = '');
    } catch (e) {
      setState(() {
        _statusMsg = e.toString().replaceAll('Exception: ', '');
      });
      _log('Falha no envio SOS: $e');
      await Future.delayed(const Duration(seconds: 4));
      if (mounted) setState(() => _statusMsg = '');
    } finally {
      if (mounted) setState(() => _enviando = false);
      _log('Fluxo SOS finalizado.');
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D1F3C),
        title: const Text('Terminar sessão', style: TextStyle(color: Colors.white)),
        content: const Text('Tem a certeza?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nome = _usuario?['nome'] as String? ?? '';
    final primeiroNome = nome.split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SOS ESQUADRA',
                style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 2,
                    color: Color(0xFF1E90FF),
                    fontWeight: FontWeight.bold)),
            if (primeiroNome.isNotEmpty)
              Text('Olá, $primeiroNome',
                  style: const TextStyle(fontSize: 11, color: Colors.white38)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white54),
            tooltip: 'Notificações',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined, color: Colors.white54),
            tooltip: 'Mapa',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white54),
            tooltip: 'Histórico',
            onPressed: () {
              if (_usuario == null) return;
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.directions_car, color: Colors.orange),
            tooltip: 'Reportar Roubo',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportVehicleScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Banner info ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1F3C),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF1E90FF), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Prima o botão SOS em caso de emergência. A sua localização será enviada automaticamente.',
                        style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Tipo de ocorrência (grid) ─────────────────────────
              const Text('Tipo de ocorrência',
                  style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sugestoesOcorrencia.map((tipo) {
                  final selecionado = _tipoSelecionado == tipo;
                  return ChoiceChip(
                    label: Text(tipo),
                    selected: selecionado,
                    onSelected: (_) {
                      setState(() => _tipoSelecionado = tipo);
                      _log('Tipo selecionado: $tipo');
                    },
                    labelStyle: TextStyle(
                      color: selecionado ? Colors.white : Colors.white70,
                      fontSize: 12,
                    ),
                    selectedColor: const Color(0xFF1E90FF),
                    backgroundColor: const Color(0xFF0D1F3C),
                    side: BorderSide(
                      color: selecionado ? Colors.transparent : Colors.white12,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 14),

              // ── Descrição opcional ────────────────────────────────
              TextField(
                controller: _descricaoCtrl,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Descrição opcional da ocorrência...',
                  filled: true,
                  fillColor: const Color(0xFF0D1F3C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Botão SOS ──────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _enviando ? null : _enviarSos,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _enviado ? Colors.green : Colors.red,
                      boxShadow: [
                        BoxShadow(
                          color: (_enviado ? Colors.green : Colors.red).withOpacity(0.4),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _enviando
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _enviado ? Icons.check_circle : Icons.emergency,
                                  color: Colors.white,
                                  size: 44,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _enviado ? 'ENVIADO' : 'SOS',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Mensagem de status ─────────────────────────────────
              if (_statusMsg.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _enviado ? Colors.green.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _enviado ? Colors.green.withOpacity(0.3) : Colors.white12,
                    ),
                  ),
                  child: Text(
                    _statusMsg,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _enviado ? Colors.green : Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                const Center(
                  child: Text(
                    'Prima em caso de emergência',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),

              const SizedBox(height: 16),

              // ── Histórico de eventos (debug) ───────────────────────
              if (_eventos.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  constraints: const BoxConstraints(maxHeight: 110),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _eventos.length,
                    itemBuilder: (_, i) => Text(
                      _eventos[i],
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // ── Rodapé — histórico ─────────────────────────────────
              GestureDetector(
                onTap: () {
                  if (_usuario == null) return;
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1F3C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, color: Colors.white38, size: 18),
                      SizedBox(width: 8),
                      Text('Ver histórico de ocorrências', style: TextStyle(color: Colors.white38, fontSize: 13)),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
