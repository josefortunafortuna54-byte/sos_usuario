import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';

const kSupabaseUrl = 'https://ukyybxwshluqcksqxdpj.supabase.co';
const kSupabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVreXlieHdzaGx1cWNrc3F4ZHBqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY3ODUyMzIsImV4cCI6MjA5MjM2MTIzMn0.bWUK7VTiAU6FvAxRr30zvFd2791kn_JaoypTKlMw8iQ';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Forçar barra de status clara (ícones brancos)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

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
      // TEMA ESCURO FORÇADO
      themeMode: ThemeMode.dark,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      home: const SplashScreen(),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0A1628),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF1E90FF),
        secondary: Color(0xFF1E90FF),
        surface: Color(0xFF0D1F3C),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0A1628),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white70),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: const TextStyle(color: Colors.white38),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1E90FF)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF0D1F3C),
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        side: const BorderSide(color: Colors.white12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E90FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white70),
        bodySmall: TextStyle(color: Colors.white54),
      ),
    );
  }

  ThemeData _lightTheme() => _darkTheme(); // Sempre escuro
}
