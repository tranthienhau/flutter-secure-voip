/// Pinned certificate SHA-256 hashes for TLS certificate pinning.
/// These must match the server's leaf or intermediate certificate.
class SecurityConfig {
  SecurityConfig._();

  /// SHA-256 fingerprints of pinned certificates (hex-encoded)
  static const List<String> pinnedCertHashes = [
    // Primary certificate
    'A1:B2:C3:D4:E5:F6:78:90:AB:CD:EF:12:34:56:78:9A:BC:DE:F0:12:34:56:78:9A:BC:DE:F0:12:34:56:78:9A',
    // Backup certificate (for rotation)
    'F0:E1:D2:C3:B4:A5:96:87:78:69:5A:4B:3C:2D:1E:0F:F0:E1:D2:C3:B4:A5:96:87:78:69:5A:4B:3C:2D:1E',
  ];

  /// Minimum TLS version (1.3)
  static const String minTlsVersion = '1.3';

  /// Token expiry in seconds
  static const int accessTokenExpiry = 900; // 15 minutes

  /// Maximum PKCE verifier length
  static const int pkceVerifierLength = 128;

  /// Fraud score thresholds
  static const int fraudScoreLow = 25;
  static const int fraudScoreMedium = 50;
  static const int fraudScoreHigh = 75;
}
