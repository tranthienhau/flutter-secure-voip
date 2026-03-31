import { Request, Response, NextFunction } from 'express';
import { verifyJWT } from '../services/jwks';

export interface AuthenticatedRequest extends Request {
  userId?: string;
  jwtPayload?: Record<string, unknown>;
}

export async function authMiddleware(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing or invalid Authorization header' });
    return;
  }

  const token = authHeader.slice(7);
  try {
    const payload = await verifyJWT(token);
    req.userId = payload.sub;
    req.jwtPayload = payload as Record<string, unknown>;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}
