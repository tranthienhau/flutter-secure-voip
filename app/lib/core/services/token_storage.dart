/// Ephemeral in-memory token storage.
/// NEVER persists to SharedPreferences, SQLite, or filesystem.
/// Tokens are lost on app restart by design (zero-trust principle).
class TokenStorage {
  // Private in-memory store - no persistence
  final Map<String, String> _store = {};

  // Timestamp tracking for auto-expiry
  final Map<String, DateTime> _expiry = {};

  /// Store access token with expiry
  void setAccessToken(String token, {Duration expiry = const Duration(minutes: 15)}) {
    _store['access_token'] = token;
    _expiry['access_token'] = DateTime.now().add(expiry);
  }

  /// Store refresh token
  void setRefreshToken(String token, {Duration expiry = const Duration(hours: 1)}) {
    _store['refresh_token'] = token;
    _expiry['refresh_token'] = DateTime.now().add(expiry);
  }

  /// Get access token (returns null if expired)
  String? get accessToken {
    final token = _store['access_token'];
    if (token == null) return null;
    if (_isExpired('access_token')) {
      _store.remove('access_token');
      _expiry.remove('access_token');
      return null;
    }
    return token;
  }

  /// Get refresh token (returns null if expired)
  String? get refreshToken {
    final token = _store['refresh_token'];
    if (token == null) return null;
    if (_isExpired('refresh_token')) {
      _store.remove('refresh_token');
      _expiry.remove('refresh_token');
      return null;
    }
    return token;
  }

  /// Check if a token is expired
  bool _isExpired(String key) {
    final exp = _expiry[key];
    if (exp == null) return true;
    return DateTime.now().isAfter(exp);
  }

  /// Clear all tokens (logout)
  void clearAll() {
    _store.clear();
    _expiry.clear();
  }

  /// Check if user has valid tokens
  bool get isAuthenticated => accessToken != null;
}
