import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {

  Future<void> sendSOS() async {

    final url = Uri.parse("http://192.168.95.153:3000/sos");

    await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": "Usuário Teste",
        "phone": "999999999",
        "location": "Teste Localização",
        "message": "Emergência!"
      }),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🚨 SOS enviado")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SOS Emergência")),
      body: Center(
        child: ElevatedButton(
          onPressed: sendSOS,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          ),
          child: const Text("🚨 ENVIAR SOS"),
        ),
      ),
    );
  }
}
