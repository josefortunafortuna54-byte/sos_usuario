import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide OAuthProvider;
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient, Supabase, PostgrestException;

class AuthService {
  static final _db = Supabase.instance.client;
  static final _firebaseAuth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  static Future<Map<String, dynamic>> loginComGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Login cancelado.');

      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Erro ao obter tokens do Google.');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final firebaseResult = await _firebaseAuth.signInWithCredential(credential);
      if (firebaseResult.user == null) throw Exception('Erro no Firebase Auth.');

      final supabaseResult = await _db.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );

      if (supabaseResult.user == null) throw Exception('Erro ao autenticar no Supabase.');

      return _garantirPerfil(
        supabaseResult.user!,
        nomeFallback: googleUser.displayName ?? googleUser.email.split('@').first,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception('Erro Firebase: ${e.message}');
    }
  }

  static Future<Map<String, dynamic>> _garantirPerfil(
    dynamic user, {
    String? nomeFallback,
  }) async {
    final authId = user.id as String;
    final perfilExistente = await _db
        .from('users')
        .select()
        .eq('auth_id', authId)
        .maybeSingle();

    if (perfilExistente != null) return perfilExistente;

    final nome = nomeFallback ?? 'Utilizador';
    final novoPerfil = {
      'auth_id': authId,
      'nome': nome,
      'telefone': '',
      'provincia': 'Luanda',
      'data_nascimento': '2000-01-01',
      'role': 'user',
      'ativo': true,
    };

    await _db.from('users').upsert(novoPerfil, onConflict: 'auth_id');
    return await _db.from('users').select().eq('auth_id', authId).maybeSingle() ?? novoPerfil;
  }

  static Future<void> confirmarOtp({required String telefone, required String otp}) async {
    await _db.auth.verifyOTP(phone: telefone, token: otp, type: OtpType.sms);
  }

  static Future<void> reenviarOtp({required String telefone}) async {
    await _db.auth.signInWithOtp(phone: telefone);
  }

  static Future<void> registar({
    required String nome,
    required String email,
    required String password,
  }) async {
    final res = await _db.auth.signUp(email: email, password: password);
    if (res.user == null) throw Exception('Erro ao registar.');
    await _db.from('users').upsert({
      'auth_id': res.user!.id,
      'nome': nome,
      'telefone': '',
      'provincia': 'Luanda',
      'data_nascimento': '2000-01-01',
      'role': 'user',
      'ativo': true,
    }, onConflict: 'auth_id');
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
