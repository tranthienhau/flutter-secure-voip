import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/secure_http_client.dart';
import '../../core/services/token_storage.dart';
import '../../data/models/auth_state.dart';
import '../../data/models/call_stats.dart';
import '../../data/models/fraud_score.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/fraud_repository.dart';
import '../../data/repositories/webrtc_repository.dart';

// --- Core Services ---

final secureHttpClientProvider = Provider<SecureHttpClient>((ref) {
  return SecureHttpClient();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

// --- Repositories ---

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(secureHttpClientProvider),
    ref.read(tokenStorageProvider),
  );
});

final webRtcRepositoryProvider = Provider<WebRtcRepository>((ref) {
  return WebRtcRepository();
});

final fraudRepositoryProvider = Provider<FraudRepository>((ref) {
  return FraudRepository(
    ref.read(secureHttpClientProvider),
    ref.read(tokenStorageProvider),
  );
});

// --- State Notifiers ---

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;

  AuthNotifier(this._authRepo) : super(const AuthState());

  Future<void> authorize(String username, String password) async {
    final result = await _authRepo.authorize(username, password);
    state = result;
  }

  Future<void> verifyMfa(String totpCode) async {
    if (state.mfaSession == null) return;
    final result = await _authRepo.verifyMfa(state.mfaSession!, totpCode);
    state = result;
  }

  void logout() {
    _authRepo.logout();
    state = const AuthState();
  }
}

// --- Call Stats ---

final callStatsProvider = StateNotifierProvider<CallStatsNotifier, CallStats?>((ref) {
  return CallStatsNotifier(ref.read(webRtcRepositoryProvider));
});

class CallStatsNotifier extends StateNotifier<CallStats?> {
  final WebRtcRepository _webRtcRepo;

  CallStatsNotifier(this._webRtcRepo) : super(null);

  Future<void> refreshStats() async {
    state = await _webRtcRepo.getCallStats();
  }
}

// --- Fraud Score ---

final fraudScoreProvider = StateNotifierProvider<FraudScoreNotifier, AsyncValue<FraudScore?>>((ref) {
  return FraudScoreNotifier(ref.read(fraudRepositoryProvider));
});

class FraudScoreNotifier extends StateNotifier<AsyncValue<FraudScore?>> {
  final FraudRepository _fraudRepo;

  FraudScoreNotifier(this._fraudRepo) : super(const AsyncValue.data(null));

  Future<void> computeScore({
    required double measuredRttMs,
    required double jitterMs,
    required double callerLat,
    required double callerLon,
    required double calleeLat,
    required double calleeLon,
  }) async {
    state = const AsyncValue.loading();
    try {
      final score = await _fraudRepo.computeFraudScore(
        measuredRttMs: measuredRttMs,
        jitterMs: jitterMs,
        callerLat: callerLat,
        callerLon: callerLon,
        calleeLat: calleeLat,
        calleeLon: calleeLon,
      );
      state = AsyncValue.data(score);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// --- Security Status ---

class SecurityStatus {
  final bool certPinningActive;
  final bool tlsEnforced;
  final bool mfaVerified;
  final bool ephemeralStorage;
  final bool wssOnly;
  final bool dtlsSrtp;

  const SecurityStatus({
    this.certPinningActive = true,
    this.tlsEnforced = true,
    this.mfaVerified = false,
    this.ephemeralStorage = true,
    this.wssOnly = true,
    this.dtlsSrtp = true,
  });

  int get activeCount => [
        certPinningActive,
        tlsEnforced,
        mfaVerified,
        ephemeralStorage,
        wssOnly,
        dtlsSrtp,
      ].where((b) => b).length;
}

final securityStatusProvider = StateProvider<SecurityStatus>((ref) {
  final auth = ref.watch(authStateProvider);
  return SecurityStatus(
    mfaVerified: auth.status == AuthStatus.authenticated,
  );
});
