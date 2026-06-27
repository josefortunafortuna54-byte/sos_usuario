import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String authId;
  final String telefone;

  const OtpScreen({
    super.key,
    required this.authId,
    required this.telefone,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _ctls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _foci =
      List.generate(6, (_) => FocusNode());

  bool _loading      = false;
  bool _reenviar     = false;
  String _erro       = '';
  int _countdown     = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _iniciarContagem();
  }

  void _iniciarContagem() {
    _timer?.cancel();
    if (mounted) setState(() { _countdown = 60; _reenviar = false; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_countdown == 0) {
        t.cancel();
        setState(() => _reenviar = true);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  String get _otp => _ctls.map((c) => c.text).join();

  Future<void> _confirmar() async {
    if (_otp.length < 6) {
      setState(() => _erro = 'Introduza os 6 dígitos do código.');
      return;
    }
    setState(() { _loading = true; _erro = ''; });
    try {
      await AuthService.confirmarOtp(authId: widget.authId, otp: _otp);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString().replaceAll('Exception: ', ''));
      // Limpar campos em caso de erro
      for (final c in _ctls) c.clear();
      _foci[0].requestFocus();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reenviarOtp() async {
    setState(() { _loading = true; _erro = ''; });
    try {
      await AuthService.reenviarOtp(widget.authId);
      if (!mounted) return;
      _iniciarContagem();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Novo código enviado por SMS.'),
            backgroundColor: Colors.green,
          ),
        );
    } catch (e) {
      setState(() => _erro = 'Erro ao reenviar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctls) c.dispose();
    for (final f in _foci) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmação'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Ícone ──
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E90FF).withOpacity(0.1),
                  border: Border.all(
                      color: const Color(0xFF1E90FF), width: 2),
                ),
                child: const Icon(Icons.sms_outlined,
                    color: Color(0xFF1E90FF), size: 38),
              ),
              const SizedBox(height: 24),

              const Text('Verifique o seu telemóvel',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              Text(
                'Enviámos um código de 6 dígitos para\n${widget.telefone}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 36),

              // ── Campos OTP ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (i) => _OtpBox(
                  controller: _ctls[i],
                  focusNode: _foci[i],
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 5) {
                      _foci[i + 1].requestFocus();
                    } else if (v.isEmpty && i > 0) {
                      _foci[i - 1].requestFocus();
                    }
                    if (_otp.length == 6) _confirmar();
                  },
                )),
              ),

              // ── Erro ──
              if (_erro.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(_erro,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 28),

              // ── Confirmar ──
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _confirmar,
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('CONFIRMAR',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5)),
                ),
              ),

              const SizedBox(height: 20),

              // ── Reenviar ──
              if (_reenviar)
                TextButton(
                  onPressed: _loading ? null : _reenviarOtp,
                  child: const Text('Reenviar código',
                      style: TextStyle(
                          color: Color(0xFF1E90FF),
                          fontWeight: FontWeight.bold)),
                )
              else
                Text(
                  'Reenviar código em $_countdown s',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 13),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 44, height: 54,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: const Color(0xFF1A2035),
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF2A3050)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF1E90FF), width: 2),
            ),
          ),
          onChanged: onChanged,
        ),
      );
}
