/// Custom SIP headers for zero-trust call identification.
class SipMetadata {
  /// Unique session identifier for call tracing
  final String sessionId;

  /// Geo-region derived from GPS
  final String geoRegion;

  /// P-Asserted-Identity (PAI) - authenticated caller identity
  final String pAssertedIdentity;

  /// Whether WSS (secure WebSocket) is used
  final bool isWss;

  const SipMetadata({
    required this.sessionId,
    required this.geoRegion,
    required this.pAssertedIdentity,
    this.isWss = true,
  });

  /// Generate custom SIP headers for INVITE request
  Map<String, String> toSipHeaders() {
    return {
      'X-Session-ID': sessionId,
      'X-Geo-Region': geoRegion,
      'P-Asserted-Identity': '<sip:$pAssertedIdentity>',
    };
  }
}
