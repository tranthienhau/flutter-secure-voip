import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import authRouter from './routes/auth';
import tokenRouter from './routes/token';
import fraudRouter from './routes/fraud';
import { getJWKS, generateKeyPair } from './services/jwks';

const app = express();
const PORT = parseInt(process.env.PORT || '3000', 10);

// Security headers
app.use(helmet({
  hsts: { maxAge: 31536000, includeSubDomains: true },
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
    },
  },
}));

// CORS
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Rate limiting
app.use(rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000', 10),
  max: parseInt(process.env.RATE_LIMIT_MAX || '100', 10),
  standardHeaders: true,
  legacyHeaders: false,
}));

// Body parsing
app.use(express.json({ limit: '10kb' }));

// Routes
app.use('/auth', authRouter);
app.use('/token', tokenRouter);
app.use('/fraud', fraudRouter);

// JWKS well-known endpoint
app.get('/.well-known/jwks.json', (_req, res) => {
  res.json(getJWKS());
});

// Health check
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Initialize JWKS key pair on startup
async function start() {
  await generateKeyPair();
  console.log('JWKS key pair generated');

  app.listen(PORT, () => {
    console.log(`Secure VoIP server running on port ${PORT}`);
    console.log(`JWKS endpoint: http://localhost:${PORT}/.well-known/jwks.json`);
  });
}

start().catch(console.error);

export default app;
