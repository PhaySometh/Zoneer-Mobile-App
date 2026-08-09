import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'dart:io' show Platform;

import 'package:zoneer_mobile/presentation/viewmodels/user/user_provider.dart';

class AuthService {
  final SupabaseClient _client;
  bool _googleInitialized = false;

  AuthService(this._client);

  bool get isAuthenticated => _client.auth.currentUser != null;
  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChange => _client.auth.onAuthStateChange;

  String _getWebGoogleRedirectTo() {
    const configuredRedirect = String.fromEnvironment(
      'WEB_GOOGLE_REDIRECT_TO',
      defaultValue: '',
    );
    const debugRedirect = String.fromEnvironment(
      'WEB_GOOGLE_REDIRECT_TO_DEBUG',
      defaultValue: '',
    );
    const releaseRedirect = String.fromEnvironment(
      'WEB_GOOGLE_REDIRECT_TO_RELEASE',
      defaultValue: '',
    );

    if (kDebugMode && debugRedirect.isNotEmpty) return debugRedirect;
    if (!kDebugMode && releaseRedirect.isNotEmpty) return releaseRedirect;
    if (configuredRedirect.isNotEmpty) return configuredRedirect;

    return Uri.base.origin;
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _getWebGoogleRedirectTo(),
      );
    } else {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']!;
      final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '';
      const scopes = ['email', 'profile'];

      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize(
          serverClientId: webClientId,
          clientId: (Platform.isIOS || Platform.isMacOS) && iosClientId.isNotEmpty
              ? iosClientId
              : null,
        );
        _googleInitialized = true;
      }

      final googleUser = await GoogleSignIn.instance.authenticate();

      final authorization =
          await googleUser.authorizationClient.authorizationForScopes(scopes) ??
          await googleUser.authorizationClient.authorizeScopes(scopes);

      final idToken = googleUser.authentication.idToken;
      if (idToken == null) throw AuthException('No ID Token found.');

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authorization.accessToken,
      );
    }
  }

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullname,
  }) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signout() async {
    await _client.auth.signOut();
    if (!kIsWeb) {
      await GoogleSignIn.instance.signOut();
      await GoogleSignIn.instance.disconnect();
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.session?.user != null ||
      Supabase.instance.client.auth.currentUser != null;
});
