import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class SosButton extends StatefulWidget {
  final VoidCallback onActivated;

  const SosButton({super.key, required this.onActivated});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> {
  final AudioPlayer _player = AudioPlayer();
  bool _loading = false;

  Future<void> _activate() async {
    setState(() => _loading = true);

    await WakelockPlus.enable();

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 200);
    }

    await _player.play(AssetSource('sounds/confirm.mp3'));

    await Future.delayed(const Duration(milliseconds: 600));

    widget.onActivated();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _activate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _loading ? Colors.red.shade900 : Colors.red,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.6),
              blurRadius: 30,
              spreadRadius: 10,
            )
          ],
        ),
        child: Center(
          child: _loading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Icon(Icons.warning, size: 60, color: Colors.white),
        ),
      ),
    );
  }
}
