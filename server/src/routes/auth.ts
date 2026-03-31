import { Router, Request, Response } from 'express';
import { randomBytes } from 'crypto';
import { authenticator } from 'otplib';
import { storeAuthCode } from '../services/pkce';
import { getJWKS } from '../services/jwks';

const router = Router();

// In-memory user store (demo purposes)
const users = new Map<string, { password: string; totpSecret: string }>();
users.set('demo', {
  password: 'secure123',
  totpSecret: process.env.TOTP_SECRET || 'JBSWY3DPEHPK3PXP',
});

// Pending MFA sessions
const pendingMfa = new Map<string, { userId: string; codeChallenge: string; expiresAt: number }>();

/**
 * POST /auth/authorize
 * Step 1: Validate credentials + PKCE challenge, return MFA session
 */
router.post('/authorize', (req: Request, res: Response) => {
  const { username, password, code_challenge, code_challenge_method } = req.body;

  if (!username || !password || !code_challenge) {
    res.status(400).json({ error: 'Missing required fields' });
    return;
  }

  if (code_challenge_method && code_challenge_method !== 'S256') {
    res.status(400).json({ error: 'Only S256 challenge method supported' });
    return;
  }

  const user = users.get(username);
  if (!user || user.password !== password) {
    res.status(401).json({ error: 'Invalid credentials' });
    return;
  }

  // Issue MFA session token
  const mfaSessionId = randomBytes(32).toString('hex');
  pendingMfa.set(mfaSessionId, {
    userId: username,
    codeChallenge: code_challenge,
    expiresAt: Date.now() + 5 * 60 * 1000,
  });

  res.json({
    mfa_required: true,
    mfa_session: mfaSessionId,
    mfa_method: 'totp',
  });
});

/**
 * POST /auth/mfa-verify
 * Step 2: Verify TOTP code, issue authorization code
 */
router.post('/mfa-verify', (req: Request, res: Response) => {
  const { mfa_session, totp_code } = req.body;

  if (!mfa_session || !totp_code) {
    res.status(400).json({ error: 'Missing mfa_session or totp_code' });
    return;
  }

  const session = pendingMfa.get(mfa_session);
  if (!session || Date.now() > session.expiresAt) {
    pendingMfa.delete(mfa_session);
    res.status(401).json({ error: 'Invalid or expired MFA session' });
    return;
  }

  const user = users.get(session.userId);
  if (!user) {
    res.status(401).json({ error: 'User not found' });
    return;
  }

  const isValid = authenticator.check(totp_code, user.totpSecret);
  if (!isValid) {
    res.status(401).json({ error: 'Invalid TOTP code' });
    return;
  }

  // MFA verified - issue authorization code
  pendingMfa.delete(mfa_session);
  const authCode = randomBytes(32).toString('hex');
  storeAuthCode(authCode, session.codeChallenge, session.userId, true);

  res.json({
    code: authCode,
    state: 'mfa_verified',
  });
});

/**
 * GET /.well-known/jwks.json
 * Public JWKS endpoint for token verification
 */
router.get('/jwks.json', (_req: Request, res: Response) => {
  res.json(getJWKS());
});

// Cleanup expired MFA sessions
setInterval(() => {
  const now = Date.now();
  for (const [key, value] of pendingMfa.entries()) {
    if (now > value.expiresAt) {
      pendingMfa.delete(key);
    }
  }
}, 60_000);

export default router;
