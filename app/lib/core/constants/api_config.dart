class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://secure-voip.example.com';
  static const String authorizePath = '/auth/authorize';
  static const String mfaVerifyPath = '/auth/mfa-verify';
  static const String tokenPath = '/token';
  static const String fraudScorePath = '/fraud/score';
  static const String jwksPath = '/.well-known/jwks.json';
  static const String healthPath = '/health';

  // SIP/WebRTC
  static const String sipWssUrl = 'wss://sip.secure-voip.example.com';
  static const String stunUrl = 'stun:stun.secure-voip.example.com:5349';
  static const String turnUrl = 'turns:turn.secure-voip.example.com:5349';
  static const String turnUsername = 'voip-client';
  static const String turnCredential = 'ephemeral-credential';
}
