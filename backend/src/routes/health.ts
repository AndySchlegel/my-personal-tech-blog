/**
 * health.ts - Health check route
 *
 * Used by Kubernetes (liveness + readiness probes) to check if the server
 * is running and ready to accept requests. Returns a simple JSON response.
 *
 * GET /health -> { status: "ok", timestamp: "..." }
 */

import { Router, Request, Response } from 'express';

export const healthRouter = Router();

// Basic health check - returns 200 if the server is running
healthRouter.get('/', (_req: Request, res: Response) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});
