import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _db = Supabase.instance.client;

  static const _androidRedirect = 'io.supabase.flutter://login-callback/';

  // ── LOGIN COM GOOGLE via OAuth browser ───────────────────────
  static Future<Map<String, dynamic>> loginComGoogle() async {
    final redirectTo = kIsWeb ? '${Uri.base.origin}/' : _androidRedirect;

    bool launched;
    try {
      launched = await _db.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        authScreenLaunchMode:
            kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    }

    if (!launched) {
      throw Exception('Não foi possível abrir o login Google.');
    }

    final session = await _aguardaSessao();
    final user = session?.user;
    if (user == null) {
      throw Exception(
        'Login não concluído. Verifique a ligação à internet e tente novamente.',
      );
    }

    return _garantirPerfil(user);
  }

  static Future<Session?> _aguardaSessao() async {
    final atual = _db.auth.currentSession;
    if (atual != null) return atual;

    try {
      return await _db.auth.onAuthStateChange
          .map((estado) => estado.session)
          .firstWhere((sessao) => sessao != null)
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      return null;
    }
  }

  // ── PERFIL ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> _garantirPerfil(User user) async {
    final existente = await _db
        .from('users')
        .select()
        .eq('auth_id', user.id)
        .maybeSingle();
    if (existente != null) return existente;

    final nome = user.userMetadata?['full_name'] ??
        user.userMetadata?['name'] ??
        user.email?.split('@').first ??
        'Utilizador';

    final novo = {
      'auth_id':         user.id,
      'nome':            nome,
      'telefone':        '',
      'provincia':       'Luanda',
      'data_nascimento': '2000-01-01',
      'role':            'user',
      'ativo':           true,
    };
    await _db.from('users').upsert(novo, onConflict: 'auth_id');
    return await _db.from('users').select().eq('auth_id', user.id).maybeSingle() ?? novo;
  }

  // ── REGISTAR (email/senha) ────────────────────────────────────
  static Future<String> registar({
    required String nome,
    required String email,
    required String senha,
    String telefone = '',
    String provincia = 'Luanda',
    String dataNascimento = '2000-01-01',
  }) async {
    final res = await _db.auth.signUp(email: email, password: senha);
    if (res.user == null) throw Exception('Erro ao registar.');

    final authId = res.user!.id;
    await _db.from('users').upsert({
      'auth_id':          authId,
      'nome':             nome,
      'telefone':         telefone,
      'provincia':        provincia,
      'data_nascimento':  dataNascimento,
      'role':             'user',
      'ativo':            true,
    }, onConflict: 'auth_id');

    return authId;
  }

  static Future<void> confirmarOtp({
    required String authId,
    required String otp,
    String telefone = '',
  }) async {
    if (telefone.isNotEmpty) {
      await _db.auth.verifyOTP(phone: telefone, token: otp, type: OtpType.sms);
    } else {
      await _db.auth.verifyOTP(email: authId, token: otp, type: OtpType.email);
    }
  }

  static Future<void> reenviarOtp(String authId) async {
    await _db.auth.resend(type: OtpType.signup, email: authId);
  }

  static Future<void> logout() async {
    await _db.auth.signOut();
  }

  static Future<Map<String, dynamic>?> perfil() async {
    final user = _db.auth.currentUser;
    if (user == null) return null;
    return _db.from('users').select().eq('auth_id', user.id).maybeSingle();
  }

  static Future<void> actualizarPerfil({
    required String nome,
    required String telefone,
    required String provincia,
  }) async {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Não autenticado');
    await _db.from('users').update({
      'nome': nome,
      'telefone': telefone,
      'provincia': provincia,
    }).eq('auth_id', user.id);
  }

  static bool get temSessao => _db.auth.currentSession != null;
}
