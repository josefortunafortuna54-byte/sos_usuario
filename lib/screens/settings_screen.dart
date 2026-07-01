import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificacoesSom = true;
  bool _notificacoesVibracao = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: const Color(0xFF0D1F3C),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _secao('Notificações', [
            _switchTile('Som de alerta', Icons.volume_up, _notificacoesSom, (v) {
              setState(() => _notificacoesSom = v);
            }),
            _switchTile('Vibração', Icons.vibration, _notificacoesVibracao, (v) {
              setState(() => _notificacoesVibracao = v);
            }),
          ]),
          const SizedBox(height: 16),
          _secao('Conta', [
            _linkTile('Meu Perfil', Icons.person, () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ));
            }),
            _linkTile('Terminar Sessão', Icons.logout, _confirmarLogout,
                corIcon: Colors.red, corTexto: Colors.red),
          ]),
          const SizedBox(height: 16),
          _secao('Sobre', [
            _infoTile('Versão', '1.0.0'),
            _infoTile('App', 'SOS Esquadra — Cidadão'),
          ]),
        ],
      ),
    );
  }

  Widget _secao(String titulo, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(color: Color(0xFF1E90FF), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1F3C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _switchTile(String label, IconData icon, bool valor, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Icon(icon, color: Colors.white54, size: 20),
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: Switch(
        value: valor,
        onChanged: onChanged,
        activeColor: const Color(0xFF1E90FF),
      ),
    );
  }

  Widget _linkTile(String label, IconData icon, VoidCallback onTap, {Color? corIcon, Color? corTexto}) {
    return ListTile(
      leading: Icon(icon, color: corIcon ?? Colors.white54, size: 20),
      title: Text(label, style: TextStyle(color: corTexto ?? Colors.white, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
      onTap: onTap,
    );
  }

  Widget _infoTile(String label, String valor) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
      trailing: Text(valor, style: const TextStyle(color: Colors.white54, fontSize: 13)),
    );
  }

  Future<void> _confirmarLogout() async {
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
}


