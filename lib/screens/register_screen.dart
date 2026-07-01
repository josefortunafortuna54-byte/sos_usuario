import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomeCtrl      = TextEditingController();
  final _telefoneCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _senhaCtrl     = TextEditingController();
  final _confirmaCtrl  = TextEditingController();

  String _provincia        = 'Luanda';
  DateTime? _dataNascimento;
  bool _loading   = false;
  bool _verSenha  = false;
  String _erro    = '';

  final _provincias = [
    'Bengo', 'Benguela', 'Bié', 'Cabinda', 'Cuando Cubango',
    'Cuanza Norte', 'Cuanza Sul', 'Cunene', 'Huambo', 'Huíla',
    'Luanda', 'Lunda Norte', 'Lunda Sul', 'Malanje', 'Moxico',
    'Namibe', 'Uíge', 'Zaire',
  ];

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telefoneCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      helpText: 'Data de nascimento',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF1E90FF),
            surface: Color(0xFF0D1F3C),
          ),
        ),
        child: child!,
      ),
    );
    if (data != null) setState(() => _dataNascimento = data);
  }

  Future<void> _registar() async {
    final nome     = _nomeCtrl.text.trim();
    final telefone = _telefoneCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final senha    = _senhaCtrl.text;
    final confirma = _confirmaCtrl.text;

    // Validações
    if (nome.isEmpty || telefone.isEmpty || email.isEmpty || senha.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos.');
      return;
    }
    if (_dataNascimento == null) {
      setState(() => _erro = 'Seleccione a data de nascimento.');
      return;
    }
    if (senha != confirma) {
      setState(() => _erro = 'As senhas não coincidem.');
      return;
    }
    if (senha.length < 6) {
      setState(() => _erro = 'A senha deve ter pelo menos 6 caracteres.');
      return;
    }
    if (!telefone.startsWith('+')) {
      setState(() => _erro = 'Telefone deve começar com código do país (ex: +244).');
      return;
    }

    setState(() { _loading = true; _erro = ''; });

    try {
      final authId = await AuthService.registar(
        nome:            nome,
        telefone:        telefone,
        provincia:       _provincia,
        dataNascimento:  '${_dataNascimento!.year}-'
            '${_dataNascimento!.month.toString().padLeft(2, '0')}-'
            '${_dataNascimento!.day.toString().padLeft(2, '0')}',
        email:           email,
        senha:           senha,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(authId: authId, telefone: telefone),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Os seus dados',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Preencha correctamente — os dados serão verificados',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 24),

              // ── Nome ──
              _Label('Nome completo'),
              TextField(
                controller: _nomeCtrl,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Ex: João Manuel Silva',
                  prefixIcon: Icon(Icons.person_outline,
                      color: Colors.white38, size: 20),
                ),
              ),
              const SizedBox(height: 14),

              // ── Telefone ──
              _Label('Número de telefone'),
              TextField(
                controller: _telefoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: '+244 9XX XXX XXX',
                  prefixIcon: Icon(Icons.phone_outlined,
                      color: Colors.white38, size: 20),
                ),
              ),
              const SizedBox(height: 14),

              // ── Província ──
              _Label('Província'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2035),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2A3050)),
                ),
                child: DropdownButton<String>(
                  value: _provincia,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF0D1F3C),
                  underline: const SizedBox(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: _provincias
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _provincia = v!),
                ),
              ),
              const SizedBox(height: 14),

              // ── Data de nascimento ──
              _Label('Data de nascimento'),
              GestureDetector(
                onTap: _escolherData,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2035),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2A3050)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: Colors.white38, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _dataNascimento == null
                            ? 'Seleccionar data'
                            : '${_dataNascimento!.day.toString().padLeft(2,'0')}/'
                              '${_dataNascimento!.month.toString().padLeft(2,'0')}/'
                              '${_dataNascimento!.year}',
                        style: TextStyle(
                          color: _dataNascimento == null
                              ? Colors.white38
                              : Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Email ──
              _Label('Email'),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'email@exemplo.com',
                  prefixIcon: Icon(Icons.email_outlined,
                      color: Colors.white38, size: 20),
                ),
              ),
              const SizedBox(height: 14),

              // ── Senha ──
              _Label('Senha'),
              TextField(
                controller: _senhaCtrl,
                obscureText: !_verSenha,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Mínimo 6 caracteres',
                  prefixIcon: const Icon(Icons.lock_outline,
                      color: Colors.white38, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _verSenha ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white38, size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _verSenha = !_verSenha),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Confirmar senha ──
              _Label('Confirmar senha'),
              TextField(
                controller: _confirmaCtrl,
                obscureText: !_verSenha,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Repita a senha',
                  prefixIcon: Icon(Icons.lock_outline,
                      color: Colors.white38, size: 20),
                ),
              ),

              // ── Erro ──
              if (_erro.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_erro,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Botão registar ──
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _registar,
                  child: _loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : const Text('CRIAR CONTA',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5)),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Após o registo, receberá um SMS com código de confirmação.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String texto;
  const _Label(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(texto,
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      );
}
