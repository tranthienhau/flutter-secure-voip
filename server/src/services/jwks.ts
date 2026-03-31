import * as jose from 'jose';

interface KeyEntry {
  privateKey: jose.KeyLike;
  publicJWK: jose.JWK;
  kid: string;
  createdAt: number;
}

const KEY_ROTATION_INTERVAL_MS = 24 * 60 * 60 * 1000; // 24 hours
const keys: KeyEntry[] = [];

export async function generateKeyPair(): Promise<KeyEntry> {
  const { publicKey, privateKey } = await jose.generateKeyPair('RS256');
  const kid = `key-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  const publicJWK = await jose.exportJWK(publicKey);
  publicJWK.kid = kid;
  publicJWK.use = 'sig';
  publicJWK.alg = 'RS256';

  const entry: KeyEntry = {
    privateKey,
    publicJWK,
    kid,
    createdAt: Date.now(),
  };

  keys.unshift(entry);

  // Keep only 2 most recent keys (current + previous for rotation grace period)
  while (keys.length > 2) {
    keys.pop();
  }

  return entry;
}

export async function getCurrentKey(): Promise<KeyEntry> {
  if (keys.length === 0 || Date.now() - keys[0].createdAt > KEY_ROTATION_INTERVAL_MS) {
    return generateKeyPair();
  }
  return keys[0];
}

export function getJWKS(): { keys: jose.JWK[] } {
  return { keys: keys.map((k) => k.publicJWK) };
}

export async function signJWT(payload: jose.JWTPayload): Promise<string> {
  const key = await getCurrentKey();
  return new jose.SignJWT(payload)
    .setProtectedHeader({ alg: 'RS256', kid: key.kid })
    .setIssuedAt()
    .setIssuer(process.env.JWT_ISSUER || 'https://secure-voip.example.com')
    .setAudience(process.env.JWT_AUDIENCE || 'flutter-secure-voip')
    .setExpirationTime('15m')
    .sign(key.privateKey);
}

export async function verifyJWT(token: string): Promise<jose.JWTPayload> {
  const JWKS = jose.createLocalJWKSet({ keys: keys.map((k) => k.publicJWK) });
  const { payload } = await jose.jwtVerify(token, JWKS, {
    issuer: process.env.JWT_ISSUER || 'https://secure-voip.example.com',
    audience: process.env.JWT_AUDIENCE || 'flutter-secure-voip',
  });
  return payload;
}
