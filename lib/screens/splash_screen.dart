import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    _verificar();
  }

  Future<void> _verificar() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      final perfil = await Supabase.instance.client
          .from('users')
          .select('ativo, role')
          .eq('auth_id', session.user.id)
          .maybeSingle();

      if (!mounted) return;

      if (perfil != null && perfil['role'] == 'user') {
        _irPara(const HomeScreen());
        return;
      }
      await Supabase.instance.client.auth.signOut();
    }

    if (mounted) _irPara(const LoginScreen());
  }

  void _irPara(Widget w) => Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => w));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 28),
                const Text('SOS ESQUADRA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4)),
                const SizedBox(height: 8),
                const Text('Segurança ao seu alcance',
                    style: TextStyle(color: Colors.white38, fontSize: 13)),
                const SizedBox(height: 60),
                const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.red, strokeWidth: 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
