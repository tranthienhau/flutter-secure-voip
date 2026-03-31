import { Router, Response } from 'express';
import { computeFraudScore, FraudInput } from '../services/fraud-engine';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';

const router = Router();

/**
 * POST /fraud/score
 * Compute fraud score from WebRTC stats and GPS coordinates
 * Requires authentication
 */
router.post('/score', authMiddleware, (req: AuthenticatedRequest, res: Response) => {
  const { measuredRttMs, jitterMs, callerLat, callerLon, calleeLat, calleeLon } = req.body;

  if (
    typeof measuredRttMs !== 'number' ||
    typeof jitterMs !== 'number' ||
    typeof callerLat !== 'number' ||
    typeof callerLon !== 'number' ||
    typeof calleeLat !== 'number' ||
    typeof calleeLon !== 'number'
  ) {
    res.status(400).json({ error: 'All fields must be numbers: measuredRttMs, jitterMs, callerLat, callerLon, calleeLat, calleeLon' });
    return;
  }

  if (callerLat < -90 || callerLat > 90 || calleeLat < -90 || calleeLat > 90) {
    res.status(400).json({ error: 'Latitude must be between -90 and 90' });
    return;
  }

  if (callerLon < -180 || callerLon > 180 || calleeLon < -180 || calleeLon > 180) {
    res.status(400).json({ error: 'Longitude must be between -180 and 180' });
    return;
  }

  const input: FraudInput = {
    measuredRttMs,
    jitterMs,
    callerLat,
    callerLon,
    calleeLat,
    calleeLon,
  };

  const result = computeFraudScore(input);

  // Ephemeral: input data is not stored, only the score is returned
  res.json({
    score: result.score,
    factors: result.factors,
    flags: result.flags,
    timestamp: new Date().toISOString(),
    userId: req.userId,
  });
});

export default router;
