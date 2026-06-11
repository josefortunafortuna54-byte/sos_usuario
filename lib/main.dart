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
      title: 'SOS Esquadra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0F1E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1E90FF),
          secondary: Colors.red,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0F1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A2035),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2A3050)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2A3050)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFF1E90FF), width: 1.5),
          ),
          hintStyle: const TextStyle(color: Colors.white38),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E90FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
