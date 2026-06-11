import 'package:flutter/material.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {

  String status = "🚨 SOS ENVIADO";
  String eta = "Calculando...";

  @override
  void initState() {
    super.initState();

    // simulação mudança de status
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        status = "🚓 VIATURA A CAMINHO";
        eta = "Tempo estimado: 5 minutos";
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Status Emergência"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Icon(Icons.local_police,
                size: 100, color: Colors.blue),

            const SizedBox(height: 20),

            Text(
              status,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              eta,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancelar SOS"),
            )
          ],
        ),
      ),
    );
  }
}
