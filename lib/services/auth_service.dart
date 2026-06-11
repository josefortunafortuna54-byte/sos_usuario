import 'dart:async';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _db = Supabase.instance.client;

  /// Client ID OAuth tipo **«Aplicação Web»** na Google Cloud (Credenciais).
  ///
  /// **NÃO** coloque aqui o ID do cliente **Android** (o que mostra pacote +
  /// SHA-1 na consola) — esse é outro cliente. Usar o ID Android aqui causa
  /// [sign_in_failed] erro **10**.
  ///
  /// Crie «+ Criar credenciais → ID cliente OAuth → Aplicação Web», copie o
  /// ID e use esse valor aqui e em Supabase → Auth → Google → Client ID.
  static const _googleWebClientId =
      '149671969987-trb0jl8vevursdeplt5pfs4jn22h1qa6.apps.googleusercontent.com';

  static const _androidRedirect = 'io.supabase.flutter://login-callback/';

  static final GoogleSignIn _googleSignInMobile = GoogleSignIn(
    serverClientId: _googleWebClientId,
    scopes: const ['email', 'profile'],
  );

  static bool get _nativeGoogleSignIn {
    if (kIsWeb) return false;
    final t = defaultTargetPlatform;
    return t == TargetPlatform.android || t == TargetPlatform.iOS;
  }

  // ── LOGIN COM GOOGLE ─────────────────────────────────────────
  static Future<Map<String, dynamic>> loginComGoogle() async {
    if (_nativeGoogleSignIn) {
      return _loginGoogleNativo();
    }
    return _loginGoogleOAuth();
  }

  /// Android/iOS: conta Google nativa → id token → Supabase (sem redirect URL).
  static Future<Map<String, dynamic>> _loginGoogleNativo() async {
    try {
      final googleUser = await _googleSignInMobile.signIn();
      if (googleUser == null) throw Exception('Login cancelado.');

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Erro ao obter tokens do Google.');
      }

      final res = await _db.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (res.user == null) {
        throw Exception('Erro ao autenticar no Supabase.');
      }

      return _garantirPerfil(
        res.user!,
        nomeFallback:
            googleUser.displayName ?? googleUser.email.split('@').first,
      );
    } on AuthException catch (e) {
      throw _traduzErroAuth(e);
    } on PlatformException catch (e) {
      final msg = e.message ?? '';

      // ConnectionResult.NETWORK_ERROR (7) nos Play Services.
      if (e.code == 'network_error' || msg.contains(': 7:')) {
        throw Exception(
          'Sem ligação aos servidores Google. Confirme dados móveis ou Wi‑Fi, '
          'desligue VPN/firewall restritivo, active data e hora automáticas e '
          'actualize o Google Play Services. Tente noutra rede.',
        );
      }

      final isGoogleConfigError = e.code == 'sign_in_failed' &&
          (msg.contains('10'));

      if (isGoogleConfigError) {
        throw Exception(
          'Erro de configuração Google (10). Mantenha na consola um cliente '
          'Android com o package actual e SHA-1; no código use o Client ID de '
          'uma credencial OAuth tipo «Aplicação Web» (não o ID do cliente Android).',
        );
      }
      rethrow;
    }
  }

  /// Web / desktop: OAuth no browser + deep link / site URL.
  static Future<Map<String, dynamic>> _loginGoogleOAuth() async {
    final redirectTo = kIsWeb ? '${Uri.base.origin}/' : _androidRedirect;

    bool launched;
    try {
      launched = await _db.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
      );
    } on AuthException catch (e) {
      throw _traduzErroAuth(e);
    }
    if (!launched) {
      throw Exception('Não foi possível abrir o login Google.');
    }

    final session = await _aguardaSessao();
    final user = session?.user;
    if (user == null) {
      throw Exception(
        'Login não concluído. No Supabase → Authentication → URL Configuration, '
        'adicione o redirect: $redirectTo',
      );
    }

    return _garantirPerfil(user);
  }

  static Future<Map<String, dynamic>> _garantirPerfil(
    User user, {
    String? nomeFallback,
  }) async {
    final perfilExistente = await _db
        .from('users')
        .select()
        .eq('auth_id', user.id)
        .maybeSingle();

    if (perfilExistente != null) {
      if (perfilExistente['role'] != 'user') {
        await _db.auth.signOut();
        throw Exception('Acesso não autorizado nesta aplicação.');
      }
      return perfilExistente;
    }

    final nome = nomeFallback ??
        user.userMetadata?['full_name'] ??
        user.userMetadata?['name'] ??
        user.email?.split('@').first ??
        'Utilizador';

    final novoPerfil = {
      'auth_id': user.id,
      'nome': nome,
      'telefone': '',
      'provincia': 'Luanda',
      'data_nascimento': '2000-01-01',
      'role': 'user',
      'ativo': true,
    };

    try {
      await _db.from('users').upsert(novoPerfil, onConflict: 'auth_id');
      final perfilFinal = await _db
          .from('users')
          .select()
          .eq('auth_id', user.id)
          .maybeSingle();
      return perfilFinal ?? novoPerfil;
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        final perfil = await _db
            .from('users')
            .select()
            .eq('auth_id', user.id)
            .maybeSingle();
        if (perfil != null) return perfil;
      }
      throw Exception('Erro ao garantir perfil do utilizador: ${e.message}');
    }
  }

  // ── LOGOUT ───────────────────────────────────────────────────
  static Future<void> logout() async {
    if (_nativeGoogleSignIn) {
      await _googleSignInMobile.signOut();
    }
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

  static Exception _traduzErroAuth(AuthException erro) {
    final msg = erro.message.toLowerCase();
    final erroCriacaoAuth = msg.contains('database error saving new user') ||
        msg.contains('unexpected_failure');

    if (erroCriacaoAuth) {
      return Exception(
        'O Supabase Auth não conseguiu criar o utilizador. '
        'Normalmente isso é trigger/função SQL na criação de utilizador. '
        'No painel Supabase, reveja triggers em auth.users e corrija colunas '
        'NOT NULL/constraints da tabela public.users.',
      );
    }

    return Exception(erro.message);
  }
}
