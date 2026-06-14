import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';

const kSupabaseUrl = 'https://ukyybxwshluqcksqxdpj.supabase.co';
const kSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVreXlieHdzaGx1cWNrc3F4ZHBqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3ODUyMzIsImV4cCI6MjA5MjM2MTIzMn0.bWUK7VTiAU6FvAxRr30zvFd2791kn_JaoypTKlMw8iQ';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
  runApp(const SOSUsuarioApp());
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
