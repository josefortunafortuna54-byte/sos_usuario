import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../services/auth_service.dart';
import '../services/sos_service.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

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

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.92,
      upperBound: 1.05,
    );

    _pulseAnim = CurvedAnimation(
      parent: _pulseCtrl, curve: Curves.easeInOut);

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
      if (_eventos.length > 8) _eventos.removeLast();
    });
  }

  Future<void> _enviarSos() async {
    if (_enviando) return;

    // Vibração de confirmação
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 200, 100, 200]);
    }

    setState(() {
      _enviando   = true;
      _enviado    = false;
      _statusMsg  = 'A obter localização...';
    });
    _log('Início do envio SOS (${_tipoSelecionado.toUpperCase()}).');

    try {
      if (_usuario == null) throw Exception('Utilizador não encontrado.');
      final userId = _usuario!['id'] ?? _usuario!['auth_id'];
      if (userId == null) {
        throw Exception('Perfil incompleto. Termine sessão e entre novamente.');
      }
      _log('Utilizador OK: $userId');

      setState(() => _statusMsg = 'A enviar SOS...');
      _log('A enviar dados para Supabase...');

      await SosService.enviarSos(
        userId: userId,
        tipo: _tipoSelecionado,
        descricao: _descricaoCtrl.text.trim().isEmpty
            ? null
            : _descricaoCtrl.text.trim(),
      ).timeout(const Duration(seconds: 20));

      // Vibração de sucesso
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 100, 50, 100, 50, 300]);
      }

      setState(() {
        _enviado   = true;
        _statusMsg = '✓ SOS enviado! Aguarde a polícia.';
      });
      _log('SOS enviado com sucesso.');

      // Resetar após 5 segundos
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _enviado = false;
          _statusMsg = '';
          _descricaoCtrl.clear();
        });
      }

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
        title: const Text('Terminar sessão',
            style: TextStyle(color: Colors.white)),
        content: const Text('Tem a certeza?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white38)),
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
    _pulseCtrl.dispose();
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
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white38)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: Colors.white54),
            tooltip: 'Mapa',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white54),
            tooltip: 'Histórico',
            onPressed: () {
              if (_usuario == null) return;
              final userId = _usuario!['id'] ?? _usuario!['auth_id'];
              if (userId == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      HistoryScreen(userId: userId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Banner info ──────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1F3C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Color(0xFF1E90FF), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Prima o botão SOS em caso de emergência. A sua localização será enviada automaticamente.',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),

            // ── Botão SOS ────────────────────────────────────────
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
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
                                color: selecionado
                                    ? Colors.white
                                    : Colors.white70,
                                fontSize: 12,
                              ),
                              selectedColor: const Color(0xFF1E90FF),
                              backgroundColor: const Color(0xFF0D1F3C),
                              side: BorderSide(
                                color: selecionado
                                    ? Colors.transparent
                                    : Colors.white12,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _descricaoCtrl,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Descrição opcional da ocorrência...',
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Anel exterior animado
                      child: GestureDetector(
                        onTap: _enviando ? null : _enviarSos,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Anel exterior
                            Container(
                              width: 260,
                              height: 260,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (_enviado
                                        ? Colors.green
                                        : Colors.red)
                                    .withOpacity(0.08),
                                border: Border.all(
                                  color: (_enviado
                                          ? Colors.green
                                          : Colors.red)
                                      .withOpacity(0.25),
                                  width: 2,
                                ),
                              ),
                            ),
                            // Botão principal
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _enviado
                                    ? Colors.green
                                    : Colors.red,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_enviado
                                            ? Colors.green
                                            : Colors.red)
                                        .withOpacity(0.5),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _enviando
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3)
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _enviado
                                                ? Icons.check_circle
                                                : Icons.emergency,
                                            color: Colors.white,
                                            size: 52,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _enviado ? 'ENVIADO' : 'SOS',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 28,
                                              fontWeight:
                                                  FontWeight.bold,
                                              letterSpacing: 4,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // ── Mensagem de status ──
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _statusMsg.isNotEmpty
                          ? Container(
                              key: ValueKey(_statusMsg),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: _enviado
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _enviado
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.white12,
                                ),
                              ),
                              child: Text(
                                _statusMsg,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _enviado
                                      ? Colors.green
                                      : Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : const Text(
                              'Prima em caso de emergência',
                              key: ValueKey('idle'),
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 14),
                            ),
                    ),
                    if (_eventos.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        height: 98,
                        child: ListView.builder(
                          itemCount: _eventos.length,
                          itemBuilder: (_, i) => Text(
                            _eventos[i],
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Rodapé ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: GestureDetector(
                onTap: () {
                  if (_usuario == null) return;
                  final userId = _usuario!['id'] ?? _usuario!['auth_id'];
                  if (userId == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          HistoryScreen(userId: userId),
                    ),
                  );
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
                      Text('Ver histórico de ocorrências',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 13)),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right,
                          color: Colors.white24, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
