/**
 * auth.ts - Authentication middleware for admin routes
 *
 * Two modes of operation:
 *   1. Production: Validates Cognito JWTs using aws-jwt-verify
 *   2. Dev mode: Bypasses auth when COGNITO_USER_POOL_ID is not set
 *
 * Usage: Add requireAuth to any route that needs admin access.
 *   router.post('/', requireAuth, (req, res) => { ... });
 */

import { Response, NextFunction } from 'express';
import { CognitoJwtVerifier } from 'aws-jwt-verify';
import { AuthenticatedRequest, TokenPayload } from '../models/types';

// Track whether we've logged the dev mode warning
let devModeWarningLogged = false;

// Cognito environment variables (set in production via K8s secrets)
const userPoolId = process.env.COGNITO_USER_POOL_ID;
const clientId = process.env.COGNITO_CLIENT_ID;

// Create the JWT verifier only when Cognito is configured
const verifier =
  userPoolId && clientId
    ? CognitoJwtVerifier.create({
        userPoolId,
        clientId,
        tokenUse: 'access',
      })
    : null;

/**
 * Middleware that requires a valid Cognito JWT token.
 * In dev mode (no COGNITO_USER_POOL_ID), all requests pass through
 * with a mock admin user attached.
 */
export const requireAuth = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  // --- Dev mode bypass ---
  if (!verifier) {
    if (!devModeWarningLogged) {
      console.warn('Auth disabled -- dev mode (COGNITO_USER_POOL_ID not set)');
      devModeWarningLogged = true;
    }

    // Attach a mock admin user so route handlers can use req.user
    req.user = {
      sub: 'dev-admin-000',
      email: 'admin@localhost',
      'cognito:groups': ['admin'],
    };

    next();
    return;
  }

  // --- Production mode: validate JWT ---
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    res.status(401).json({ error: 'Authorization header is required' });
    return;
  }

  // Expect format: "Bearer <token>"
  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    res.status(401).json({ error: 'Authorization header must be: Bearer <token>' });
    return;
  }

  const token = parts[1];

  try {
    // Verify the JWT signature, expiration, and claims
    const payload = await verifier.verify(token);

    // Attach decoded token to the request
    req.user = {
      sub: payload.sub,
      email: (payload as Record<string, unknown>).email as string,
      'cognito:groups': (payload as Record<string, unknown>)['cognito:groups'] as
        | string[]
        | undefined,
    } satisfies TokenPayload;

    next();
  } catch (err) {
    console.error('JWT verification failed:', (err as Error).message);
    res.status(403).json({ error: 'Invalid or expired token' });
  }
};
