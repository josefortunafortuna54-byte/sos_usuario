import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _verificar();
  }

  Future<void> _verificar() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      final perfil = await Supabase.instance.client
          .from('users')
          .select('ativo, role')
          .eq('auth_id', session.user.id)
          .maybeSingle();

      if (!mounted) return;

      if (perfil != null &&
          perfil['ativo'] == true &&
          perfil['role'] == 'user') {
        _irPara(const HomeScreen());
        return;
      }
      await Supabase.instance.client.auth.signOut();
    }

    if (mounted) _irPara(const LoginScreen());
  }

  void _irPara(Widget destino) => Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => destino));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.12),
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: const Icon(Icons.emergency, color: Colors.red, size: 52),
            ),
            const SizedBox(height: 24),
            const Text('SOS ESQUADRA',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3)),
            const SizedBox(height: 8),
            const Text('Segurança ao seu alcance',
                style: TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                  color: Colors.red, strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
