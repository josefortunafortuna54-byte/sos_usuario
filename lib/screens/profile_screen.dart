import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/ocorrencia.dart';
import '../services/auth_service.dart';
import '../services/sos_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  int _totalOcorrencias = 0;
  bool _loading = true;
  bool _saving = false;

  final _nomeCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _provinciaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final perfil = await AuthService.perfil();
      final historico = await SosService.historico();
      if (!mounted) return;
      if (perfil != null) {
        _user = AppUser.fromMap(perfil);
        _nomeCtrl.text = _user!.nome;
        _telefoneCtrl.text = _user!.telefone;
        _provinciaCtrl.text = _user!.provincia;
      }
      _totalOcorrencias = historico.length;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _salvar() async {
    if (_user == null) return;
    setState(() => _saving = true);
    try {
      await AuthService.actualizarPerfil(
        nome: _nomeCtrl.text.trim(),
        telefone: _telefoneCtrl.text.trim(),
        provincia: _provinciaCtrl.text.trim(),
      );
      if (!mounted) return;
      _user = _user!.copyWith(
        nome: _nomeCtrl.text.trim(),
        telefone: _telefoneCtrl.text.trim(),
        provincia: _provinciaCtrl.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telefoneCtrl.dispose();
    _provinciaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: const Color(0xFF0D1F3C),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildStats(),
                  const SizedBox(height: 24),
                  _buildForm(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    final iniciais = _user?.nome.isNotEmpty == true
        ? _user!.nome.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: const Color(0xFF1E90FF),
          child: Text(iniciais, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 12),
        Text(_user?.nome ?? 'Utilizador', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
        Text(_user?.telefone.isNotEmpty == true ? _user!.telefone : 'Sem telefone',
            style: const TextStyle(color: Colors.white38, fontSize: 14)),
      ],
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F3C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          _statItem(Icons.emergency, 'Ocorrências', _totalOcorrencias.toString()),
          const SizedBox(width: 24),
          _statItem(Icons.check_circle, 'Activas', _ocorrenciasActivas.toString()),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1E90FF), size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  int get _ocorrenciasActivas => _totalOcorrencias; // simplificado

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F3C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Editar Perfil', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          _campo('Nome', _nomeCtrl),
          const SizedBox(height: 12),
          _campo('Telefone', _telefoneCtrl),
          const SizedBox(height: 12),
          _campo('Província', _provinciaCtrl),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _salvar,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E90FF),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF0A0E27),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white12),
        ),
      ),
    );
  }
}
