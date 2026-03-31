# flutter-secure-voip

Zero-trust, banking-grade VoIP security demo built with **Flutter + WebRTC + SIP** and a **Node.js/Express** backend.

Demonstrates 5 production security patterns for secure real-time communication:

## Security Features

### 1. Certificate Pinning + TLS 1.3
- SHA-256 cert pinning via `badCertificateCallback` (Dio + HttpClient)
- TLS 1.3 minimum enforced, zero `allowBadCertificate` overrides
- Dashboard card shows real-time pinning status

### 2. OAuth 2.0 PKCE + MFA
- Full Authorization Code Flow with PKCE (S256 challenge)
- Server-side JWKS key rotation (`.well-known/jwks.json`)
- TOTP-based MFA second factor
- Tokens stored in-memory only (never SharedPreferences/SQLite)

### 3. Anti-Fraud Engine (RTT vs GPS)
- Collects RTT/jitter from WebRTC `getStats()` + GPS from `geolocator`
- Haversine distance calculation, expected RTT estimation
- Detects: GPS spoofing, VPN/proxy routing, jitter anomalies
- Fraud score 0-100 with animated gauge + factor breakdown chart

### 4. Secure WebRTC + SIP Headers
- WSS-only SIP transport (no WS fallback)
- Custom SIP headers: `X-Session-ID`, `X-Geo-Region`, `P-Asserted-Identity`
- DTLS-SRTP mandatory, ICE restricted to TLS STUN/TURN
- Call screen security overlay: TLS version, SRTP cipher, ICE state

### 5. Data Ephemerality
- GPS/PII processed in-memory only, auto-cleared after use
- No SQLite, no SharedPreferences, no file writes for sensitive data
- Ephemeral Dart `Map` token storage, cleared on app restart

## Architecture

```
flutter-secure-voip/
  server/                         # Node.js/Express/TypeScript
    src/
      routes/auth.ts              # OAuth 2.0 PKCE + MFA
      routes/token.ts             # JWT token exchange
      routes/fraud.ts             # Fraud scoring endpoint
      services/jwks.ts            # JWKS key generation & rotation
      services/pkce.ts            # PKCE verifier/challenge
      services/fraud-engine.ts    # RTT vs GPS heuristic engine
      middleware/auth.ts          # JWT validation
      __tests__/                  # Jest tests (19 passing)
  app/                            # Flutter
    lib/
      core/services/              # Cert pinning, ephemeral token storage
      data/models/                # Auth state, fraud score, call stats, SIP metadata
      data/repositories/          # Auth (PKCE), WebRTC, Fraud
      presentation/
        screens/login/            # OAuth PKCE + MFA flow
        screens/dashboard/        # 6 security status cards
        screens/call/             # WebRTC call + security overlay
        screens/fraud/            # Fraud gauge + breakdown chart
        widgets/                  # SecurityGauge, CertStatusBadge, TlsIndicator
```

## Screen Flow

```
Login (PKCE + MFA) --> Dashboard (6 security cards) --> Call Screen (security overlay)
                                                    --> Fraud Score (gauge + breakdown)
```

## Tech Stack

**Flutter**: flutter_webrtc, sip_ua, flutter_riverpod, dio (cert pinning), geolocator, fl_chart, jose

**Node.js**: express, helmet, jose, otplib (TOTP MFA), express-rate-limit, jest

## Getting Started

### Server
```bash
cd server
npm install
npm test        # 19 tests passing
npm run dev     # starts on port 3000
```

### Flutter App
```bash
cd app
flutter pub get
flutter run
```

## Verification Checklist

- [x] `npm test` - fraud engine + PKCE tests pass (19/19)
- [x] `npm run dev` - server starts on port 3000
- [x] No `allowBadCertificate` anywhere in codebase
- [x] No SharedPreferences/SQLite for sensitive data
- [x] WSS-only SIP transport (no WS fallback)
- [x] DTLS-SRTP mandatory in WebRTC config
- [x] Tokens stored in ephemeral Dart Map only
