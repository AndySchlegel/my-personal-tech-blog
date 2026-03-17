/**
 * app.ts - Express application setup
 *
 * Creates and configures the Express app with middleware and routes.
 * This file is separate from server.ts so that tests can import the app
 * WITHOUT starting the actual HTTP server.
 */

import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { healthRouter } from './routes/health';
import { postsRouter } from './routes/posts';
import { commentsRouter } from './routes/comments';
import { categoriesRouter } from './routes/categories';
import { adminRouter } from './routes/admin';

// Create the Express application
const app = express();

// --- Middleware ---
// Middleware = functions that run BEFORE your route handlers.
// Think of them as "guards" that process every incoming request.

// Helmet: sets various HTTP headers for security
// Example: prevents clickjacking, hides "X-Powered-By: Express" header
app.use(helmet());

// CORS: controls which websites can call our API
// In production, restrict to our frontend domain only.
// Fail closed: if CORS_ORIGIN is not set in production, deny cross-origin
// requests instead of allowing all origins with '*'.
const defaultOrigin =
  process.env.NODE_ENV === 'production' ? 'https://techblog.aws.his4irness23.de' : '*';
app.use(
  cors({
    origin: process.env.CORS_ORIGIN || defaultOrigin,
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
  })
);

// Parse JSON request bodies (needed for POST/PUT requests)
// Limit body size to prevent DoS via oversized payloads.
// Public endpoints (comments) accept untrusted input, so a
// reasonable limit protects against memory exhaustion attacks.
app.use(express.json({ limit: '100kb' }));

// --- Rate Limiting ---
// Protects public endpoints from abuse (spam, cost inflation on AWS ML services).
// Uses IP-based limiting. Separate limiters for different risk levels.

// Comment submissions: max 5 per 15 minutes per IP
const commentLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: { error: 'Too many comments. Please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// Like actions: max 20 per 15 minutes per IP
const likeLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: { error: 'Too many like requests. Please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// --- Routes ---

// Health check - used by Kubernetes to verify the server is alive
app.use('/health', healthRouter);

// Blog API routes
app.use('/api/posts', postsRouter);
app.use('/api/categories', categoriesRouter);

// Comment routes are mounted at /api (because they use /posts/:postId/comments)
// Rate limit comment POST submissions to prevent spam and Comprehend cost inflation
app.use('/api/posts/:postId/comments', commentLimiter);
app.use('/api', commentsRouter);

// Rate limit like endpoint to prevent artificial like inflation
app.use('/api/posts/:id/like', likeLimiter);

// Admin dashboard routes (protected by auth middleware)
app.use('/api/admin', adminRouter);

export default app;
