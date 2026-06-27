import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/vehicle_service.dart';

class ReportVehicleScreen extends StatefulWidget {
  const ReportVehicleScreen({super.key});

  @override
  State<ReportVehicleScreen> createState() => _ReportVehicleScreenState();
}

class _ReportVehicleScreenState extends State<ReportVehicleScreen> {
  final _marcaCtrl     = TextEditingController();
  final _modeloCtrl    = TextEditingController();
  final _matriculaCtrl = TextEditingController();
  final _corCtrl       = TextEditingController();
  final _localCtrl     = TextEditingController();

  String _tipo    = 'Viatura';
  bool _enviando  = false;
  bool _enviado   = false;
  String _erro    = '';

  @override
  void dispose() {
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _matriculaCtrl.dispose();
    _corCtrl.dispose();
    _localCtrl.dispose();
    super.dispose();
  }

  Future<void> _reportar() async {
    if (_marcaCtrl.text.isEmpty || _modeloCtrl.text.isEmpty ||
        _matriculaCtrl.text.isEmpty || _corCtrl.text.isEmpty ||
        _localCtrl.text.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos.');
      return;
    }
    setState(() { _enviando = true; _erro = ''; });

    try {
      Position? pos;
      try { pos = await Geolocator.getCurrentPosition(); } catch (_) {}

      await VehicleService.reportarRoubo(
        tipo:       _tipo,
        marca:      _marcaCtrl.text.trim(),
        modelo:     _modeloCtrl.text.trim(),
        matricula:  _matriculaCtrl.text.trim(),
        cor:        _corCtrl.text.trim(),
        localFurto: _localCtrl.text.trim(),
        posicao:    pos,
      );

      setState(() => _enviado = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Roubo'),
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'O alerta será enviado imediatamente a todos os agentes.',
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tipo de veículo
              const Text('Tipo de veículo',
                  style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: ['Viatura', 'Motorizada'].map((t) {
                  final sel = _tipo == t;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tipo = t),
                      child: Container(
                        margin: EdgeInsets.only(right: t == 'Viatura' ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: sel ? Colors.orange.withOpacity(0.2) : const Color(0xFF0D1F3C),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel ? Colors.orange : Colors.white12,
                            width: sel ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              t == 'Viatura' ? Icons.directions_car : Icons.two_wheeler,
                              color: sel ? Colors.orange : Colors.white54,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(t, style: TextStyle(
                              color: sel ? Colors.orange : Colors.white54,
                              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                            )),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              _Campo('Marca', _tipo == 'Viatura' ? 'Ex: Toyota' : 'Ex: Honda', _marcaCtrl),
              const SizedBox(height: 12),
              _Campo('Modelo', _tipo == 'Viatura' ? 'Ex: Hilux' : 'Ex: CG 150', _modeloCtrl),
              const SizedBox(height: 12),
              _Campo('Matrícula', 'Ex: LD-42-91-AB', _matriculaCtrl, upper: true),
              const SizedBox(height: 12),
              _Campo('Cor', 'Ex: Branco', _corCtrl),
              const SizedBox(height: 12),
              _Campo('Local do furto', 'Ex: Maianga, junto ao mercado', _localCtrl),
              const SizedBox(height: 24),

              if (_erro.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(_erro, style: const TextStyle(color: Colors.redAccent)),
                ),

              ElevatedButton.icon(
                onPressed: _enviando ? null : _reportar,
                icon: _enviando
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(_enviado ? Icons.check : Icons.send),
                label: Text(_enviado ? 'Alerta enviado!' : _enviando ? 'A enviar...' : 'Enviar Alerta'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _enviado ? Colors.green : Colors.orange[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController ctrl;
  final bool upper;

  const _Campo(this.label, this.hint, this.ctrl, {this.upper = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
            color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          textCapitalization: upper ? TextCapitalization.characters : TextCapitalization.words,
          decoration: InputDecoration(
            hintText: hint,
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
          ),
        ),
      ],
    );
  }
}
