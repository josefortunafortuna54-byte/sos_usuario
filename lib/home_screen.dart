import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/location_service.dart';
import '../services/socket_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  bool _isSending = false;
  final LocationService _locationService = LocationService();
  final SocketService _socketService = SocketService();

  Future<void> sendSOS() async {

    Future<void> sendSOS() async {
  setState(() => _isSending = true);

  final location = await _locationService.getCurrentLocation();

  if (location == null) {
    setState(() => _isSending = false);
    _showMessage("❌ Não foi possível obter GPS", Colors.red);
    return;
  }

  // 🔥 Enviar localização via Socket em tempo real
  _socketService.sendLiveLocation(
    location.latitude!,
    location.longitude!,
  );

  final url = Uri.parse("https://sos-server.onrender.com/alerts");

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": "José Fortuna",
        "phone": "952625660",
        "latitude": location.latitude,
        "longitude": location.longitude,
        "message": "Emergência!"
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      _showMessage("🚨 SOS enviado com sucesso!", Colors.green);
    } else {
      _showMessage("❌ Erro do servidor", Colors.red);
    }

  } catch (e) {
    _showMessage("❌ Falha de conexão", Colors.red);
  }

  setState(() => _isSending = false);
}

  void _showMessage(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: color,
      ),
    );
  }
  
  @override
void dispose() {
  _socketService.socket.dispose();
  super.dispose();
}
  @override
  void initState() {
    super.initState();
    _socketService.connect();
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A2F),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("SOS ESQUADRA"),
        centerTitle: true,
      ),
      body: Center(
        child: _isSending
            ? const CircularProgressIndicator(color: Colors.red)
            : ElevatedButton(
                onPressed: sendSOS,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 25,
                  ),
                ),
                child: const Text(
                  "🚨 ENVIAR SOS",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              
              ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapScreen()),
    );
  },
  child: const Text("Ver Mapa"),
),
      ),
    );
  }
}
