import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';

const kSupabaseUrl = 'https://ukyybxwshluqcksqxdpj.supabase.co';
const kSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVreXlieHdzaGx1cWNrc3F4ZHBqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3ODUyMzIsImV4cCI6MjA5MjM2MTIzMn0.bWUK7VTiAU6FvAxRr30zvFd2791kn_JaoypTKlMw8iQ';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Capturar TODOS os erros e mostrar na tela
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.red[900],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Text(
              'ERRO:\n\n${details.exceptionAsString()}\n\n${details.stack}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  };

  try {
    await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
  } catch (e, st) {
    runApp(_ErrorApp(error: 'Supabase init falhou:\n$e\n\n$st'));
    return;
  }

  runApp(const SOSUsuarioApp());
}

class _ErrorApp extends StatelessWidget {
  final String error;
  const _ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red[900],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Text(error, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
        ),
      ),
    );
  }
}

class SOSUsuarioApp extends StatelessWidget {
  const SOSUsuarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOS Usuário',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
