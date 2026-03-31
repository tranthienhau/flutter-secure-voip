enum AuthStatus {
  unauthenticated,
  awaitingMfa,
  authenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? mfaSession;
  final String? accessToken;
  final String? userId;
  final String? errorMessage;
  final DateTime? tokenExpiry;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.mfaSession,
    this.accessToken,
    this.userId,
    this.errorMessage,
    this.tokenExpiry,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? mfaSession,
    String? accessToken,
    String? userId,
    String? errorMessage,
    DateTime? tokenExpiry,
  }) {
    return AuthState(
      status: status ?? this.status,
      mfaSession: mfaSession ?? this.mfaSession,
      accessToken: accessToken ?? this.accessToken,
      userId: userId ?? this.userId,
      errorMessage: errorMessage ?? this.errorMessage,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
    );
  }
}
