import { Router, Request, Response } from 'express';
import { consumeAuthCode } from '../services/pkce';
import { signJWT } from '../services/jwks';

const router = Router();

/**
 * POST /token
 * Exchange authorization code + PKCE verifier for JWT access token
 */
router.post('/', async (req: Request, res: Response) => {
  const { grant_type, code, code_verifier } = req.body;

  if (grant_type !== 'authorization_code') {
    res.status(400).json({ error: 'Unsupported grant_type. Use authorization_code' });
    return;
  }

  if (!code || !code_verifier) {
    res.status(400).json({ error: 'Missing code or code_verifier' });
    return;
  }

  const result = consumeAuthCode(code, code_verifier);
  if (!result) {
    res.status(401).json({ error: 'Invalid authorization code or PKCE verifier' });
    return;
  }

  const accessToken = await signJWT({
    sub: result.userId,
    mfa_verified: result.mfaVerified,
    scope: 'voip:call voip:stats',
  });

  // Short-lived refresh token (in production, use opaque tokens with server-side storage)
  const refreshToken = await signJWT({
    sub: result.userId,
    type: 'refresh',
  });

  res.json({
    access_token: accessToken,
    token_type: 'Bearer',
    expires_in: 900, // 15 minutes
    refresh_token: refreshToken,
    scope: 'voip:call voip:stats',
  });
});

export default router;
