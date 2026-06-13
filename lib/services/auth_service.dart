import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _db = Supabase.instance.client;
  static final _firebaseAuth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // ── LOGIN COM GOOGLE via Firebase ────────────────────────────
  static Future<Map<String, dynamic>> loginComGoogle() async {
    try {
      // 1. Abrir selector de conta Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Login cancelado.');

      // 2. Obter tokens Google
      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Erro ao obter tokens do Google.');
      }

      // 3. Autenticar no Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final firebaseResult = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = firebaseResult.user;
      if (firebaseUser == null) throw Exception('Erro no Firebase Auth.');

      // 4. Obter token Firebase para o Supabase
      final firebaseToken = await firebaseUser.getIdToken();

      // 5. Autenticar no Supabase com token Firebase
      final supabaseResult = await _db.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken!,
      );

      if (supabaseResult.user == null) {
        throw Exception('Erro ao autenticar no Supabase.');
      }

      // 6. Garantir perfil na tabela users
      return _garantirPerfil(
        supabaseResult.user!,
        nomeFallback: googleUser.displayName ?? googleUser.email.split('@').first,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception('Erro Firebase: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  // ── GARANTIR PERFIL NO SUPABASE ──────────────────────────────
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
    final perfilFinal = await _db
        .from('users')
        .select()
        .eq('auth_id', authId)
        .maybeSingle();
    return perfilFinal ?? novoPerfil;
  }

  // ── LOGOUT ───────────────────────────────────────────────────
  static Future<void> logout() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    await _db.auth.signOut();
  }

  // ── PERFIL ACTUAL ────────────────────────────────────────────
  static Future<Map<String, dynamic>?> perfil() async {
    final user = _db.auth.currentUser;
    if (user == null) return null;
    return _db.from('users').select().eq('auth_id', user.id).maybeSingle();
  }

  // ── SESSÃO ACTIVA ─────────────────────────────────────────────
  static bool get temSessao => _db.auth.currentSession != null;
}
