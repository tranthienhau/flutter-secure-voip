import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' show sha256;

import '../../core/constants/api_config.dart';
import '../../core/services/secure_http_client.dart';
import '../../core/services/token_storage.dart';
import '../models/auth_state.dart';

/// Handles OAuth 2.0 PKCE authentication flow with MFA.
class AuthRepository {
  final SecureHttpClient _httpClient;
  final TokenStorage _tokenStorage;

  // Ephemeral PKCE state - never persisted
  String? _codeVerifier;

  AuthRepository(this._httpClient, this._tokenStorage);

  /// Generate cryptographically secure PKCE code verifier
  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '').substring(0, 128);
  }

  /// Generate S256 code challenge from verifier
  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Step 1: Initiate PKCE auth flow - returns MFA session
  Future<AuthState> authorize(String username, String password) async {
    _codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(_codeVerifier!);

    try {
      final response = await _httpClient.post(
        ApiConfig.authorizePath,
        data: {
          'username': username,
          'password': password,
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data['mfa_required'] == true) {
        return AuthState(
          status: AuthStatus.awaitingMfa,
          mfaSession: data['mfa_session'] as String,
        );
      }

      return const AuthState(
        status: AuthStatus.error,
        errorMessage: 'Unexpected auth response',
      );
    } catch (e) {
      return AuthState(
        status: AuthStatus.error,
        errorMessage: 'Authorization failed: $e',
      );
    }
  }

  /// Step 2: Verify MFA TOTP code
  Future<AuthState> verifyMfa(String mfaSession, String totpCode) async {
    try {
      final response = await _httpClient.post(
        ApiConfig.mfaVerifyPath,
        data: {
          'mfa_session': mfaSession,
          'totp_code': totpCode,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final authCode = data['code'] as String;

      // Step 3: Exchange auth code + PKCE verifier for tokens
      return _exchangeToken(authCode);
    } catch (e) {
      return AuthState(
        status: AuthStatus.error,
        errorMessage: 'MFA verification failed: $e',
      );
    }
  }

  /// Step 3: Exchange authorization code for access token
  Future<AuthState> _exchangeToken(String authCode) async {
    if (_codeVerifier == null) {
      return const AuthState(
        status: AuthStatus.error,
        errorMessage: 'PKCE verifier missing - restart auth flow',
      );
    }

    try {
      final response = await _httpClient.post(
        ApiConfig.tokenPath,
        data: {
          'grant_type': 'authorization_code',
          'code': authCode,
          'code_verifier': _codeVerifier,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final accessToken = data['access_token'] as String;
      final expiresIn = data['expires_in'] as int;

      // Store tokens in memory only
      _tokenStorage.setAccessToken(
        accessToken,
        expiry: Duration(seconds: expiresIn),
      );

      if (data['refresh_token'] != null) {
        _tokenStorage.setRefreshToken(data['refresh_token'] as String);
      }

      // Clear PKCE state immediately after use
      _codeVerifier = null;

      return AuthState(
        status: AuthStatus.authenticated,
        accessToken: accessToken,
        tokenExpiry: DateTime.now().add(Duration(seconds: expiresIn)),
      );
    } catch (e) {
      _codeVerifier = null;
      return AuthState(
        status: AuthStatus.error,
        errorMessage: 'Token exchange failed: $e',
      );
    }
  }

  /// Logout - clear all ephemeral state
  void logout() {
    _tokenStorage.clearAll();
    _codeVerifier = null;
  }
}
