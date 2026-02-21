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
import { healthRouter } from './routes/health';

// Create the Express application
const app = express();

// --- Middleware ---
// Middleware = functions that run BEFORE your route handlers.
// Think of them as "guards" that process every incoming request.

// Helmet: sets various HTTP headers for security
// Example: prevents clickjacking, hides "X-Powered-By: Express" header
app.use(helmet());

// CORS: controls which websites can call our API
// In production, we'll restrict this to our frontend domain only
app.use(
  cors({
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
  })
);

// Parse JSON request bodies (needed for POST/PUT requests)
app.use(express.json());

// --- Routes ---

// Health check route - used by Kubernetes to verify the server is alive
app.use('/health', healthRouter);

export default app;
