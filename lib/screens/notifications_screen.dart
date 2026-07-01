import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações', style: TextStyle(fontSize: 14)),
        backgroundColor: const Color(0xFF0D1F3C),
        actions: [
          TextButton(
            onPressed: () async {
              await NotificationService.marcarTodasLidas();
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todas marcadas como lidas')));
            },
            child: const Text('Ler tudo', style: TextStyle(color: Color(0xFF1E90FF), fontSize: 12)),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: NotificationService.streamNotificacoes(),
        builder: (context, snap) {
          final nots = snap.data ?? [];
          if (nots.isEmpty) {
            return const Center(child: Text('Sem notificações.', style: TextStyle(color: Colors.white38)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: nots.length,
            itemBuilder: (_, i) => _NotificacaoCard(not: nots[i], onTap: () => NotificationService.marcarLida(nots[i]['id'])),
          );
        },
      ),
    );
  }
}

class _NotificacaoCard extends StatelessWidget {
  final Map<String, dynamic> not;
  final VoidCallback onTap;
  const _NotificacaoCard({required this.not, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lida = not['read'] == true;
    final time = not['created_at'] as String? ?? '';
    final hora = time.length >= 16 ? time.substring(11, 16) : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: lida ? const Color(0xFF0A1628) : const Color(0xFF0D1F3C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: lida ? Colors.white12 : const Color(0xFF1E90FF).withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8, height: 8, margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: lida ? Colors.transparent : const Color(0xFF1E90FF), shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(not['title'] ?? '', style: TextStyle(color: lida ? Colors.white54 : Colors.white, fontWeight: lida ? FontWeight.normal : FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(not['body'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(hora, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
