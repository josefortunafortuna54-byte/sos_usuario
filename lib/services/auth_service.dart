import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _db = Supabase.instance.client;
  static final _firebaseAuth = fb.FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '140830762340-nnv0umnv9orpksc6b84ev3vj8oni5me5.apps.googleusercontent.com',
  );

  // ── LOGIN COM GOOGLE ─────────────────────────────────────────
  static Future<Map<String, dynamic>> loginComGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Login cancelado.');

      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Erro ao obter tokens do Google.');
      }

      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final firebaseResult = await _firebaseAuth.signInWithCredential(credential);
      if (firebaseResult.user == null) throw Exception('Erro no Firebase Auth.');

      final supabaseResult = await _db.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );
      if (supabaseResult.user == null) throw Exception('Erro ao autenticar no Supabase.');

      return _garantirPerfil(
        supabaseResult.user!,
        nomeFallback: googleUser.displayName ?? googleUser.email.split('@').first,
      );
    } on fb.FirebaseAuthException catch (e) {
      throw Exception('Erro Firebase: ${e.message}');
    }
  }

  // ── REGISTAR — retorna authId (String) ───────────────────────
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

  // ── CONFIRMAR OTP ────────────────────────────────────────────
  static Future<void> confirmarOtp({
    required String authId,
    required String otp,
    String telefone = '',
  }) async {
    // Se tiver telefone, verificar por SMS; caso contrário verificar por email
    if (telefone.isNotEmpty) {
      await _db.auth.verifyOTP(
        phone: telefone,
        token: otp,
        type: OtpType.sms,
      );
    } else {
      await _db.auth.verifyOTP(
        email: authId,
        token: otp,
        type: OtpType.email,
      );
    }
  }

  // ── REENVIAR OTP ─────────────────────────────────────────────
  static Future<void> reenviarOtp(String authId) async {
    // Reenviar por email (fallback seguro)
    await _db.auth.resend(type: OtpType.signup, email: authId);
  }

  // ── PERFIL ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> _garantirPerfil(
    User user, {
    String? nomeFallback,
  }) async {
    final existente = await _db
        .from('users')
        .select()
        .eq('auth_id', user.id)
        .maybeSingle();
    if (existente != null) return existente;

    final novo = {
      'auth_id':         user.id,
      'nome':            nomeFallback ?? 'Utilizador',
      'telefone':        '',
      'provincia':       'Luanda',
      'data_nascimento': '2000-01-01',
      'role':            'user',
      'ativo':           true,
    };
    await _db.from('users').upsert(novo, onConflict: 'auth_id');
    return await _db.from('users').select().eq('auth_id', user.id).maybeSingle() ?? novo;
  }

  static Future<void> logout() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    await _db.auth.signOut();
  }

  static Future<Map<String, dynamic>?> perfil() async {
    final user = _db.auth.currentUser;
    if (user == null) return null;
    return _db.from('users').select().eq('auth_id', user.id).maybeSingle();
  }

  static bool get temSessao => _db.auth.currentSession != null;
}
