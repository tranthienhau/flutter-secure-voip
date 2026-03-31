import { createHash, randomBytes } from 'crypto';

export function generateCodeVerifier(): string {
  return randomBytes(32)
    .toString('base64url')
    .replace(/[^a-zA-Z0-9\-._~]/g, '')
    .slice(0, 128);
}

export function generateCodeChallenge(verifier: string): string {
  return createHash('sha256').update(verifier).digest('base64url');
}

export function verifyCodeChallenge(
  verifier: string,
  challenge: string,
  method: 'S256' | 'plain' = 'S256'
): boolean {
  if (method === 'plain') {
    return verifier === challenge;
  }
  const computed = generateCodeChallenge(verifier);
  return computed === challenge;
}

// In-memory authorization code store (ephemeral)
interface AuthCode {
  code: string;
  codeChallenge: string;
  challengeMethod: 'S256';
  userId: string;
  expiresAt: number;
  mfaVerified: boolean;
}

const authCodes = new Map<string, AuthCode>();

export function storeAuthCode(
  code: string,
  codeChallenge: string,
  userId: string,
  mfaVerified: boolean
): void {
  authCodes.set(code, {
    code,
    codeChallenge,
    challengeMethod: 'S256',
    userId,
    expiresAt: Date.now() + 5 * 60 * 1000, // 5 minutes
    mfaVerified,
  });
}

export function consumeAuthCode(
  code: string,
  codeVerifier: string
): { userId: string; mfaVerified: boolean } | null {
  const entry = authCodes.get(code);
  if (!entry) return null;

  // Always delete after use (single-use)
  authCodes.delete(code);

  if (Date.now() > entry.expiresAt) return null;

  if (!verifyCodeChallenge(codeVerifier, entry.codeChallenge, entry.challengeMethod)) {
    return null;
  }

  return { userId: entry.userId, mfaVerified: entry.mfaVerified };
}

// Cleanup expired codes periodically
setInterval(() => {
  const now = Date.now();
  for (const [key, value] of authCodes.entries()) {
    if (now > value.expiresAt) {
      authCodes.delete(key);
    }
  }
}, 60_000);
