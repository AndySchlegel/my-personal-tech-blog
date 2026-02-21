/**
 * database.ts - PostgreSQL connection setup
 *
 * Creates a connection pool to the database. A "pool" means we reuse
 * connections instead of opening a new one for every request (much faster).
 *
 * Uses the DATABASE_URL environment variable which looks like:
 * postgresql://user:password@host:5432/dbname
 */

import { Pool } from 'pg';

// Create the connection pool
// In production (EKS), DATABASE_URL comes from a Kubernetes Secret
// In local development, it comes from .env
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,

  // Max 10 connections in the pool (db.t3.micro has limited connections)
  max: 10,

  // Close idle connections after 30 seconds
  idleTimeoutMillis: 30000,

  // Fail fast if DB is unreachable (don't wait forever)
  connectionTimeoutMillis: 5000,
});

// Log connection errors (but don't crash the server)
pool.on('error', (err: Error) => {
  console.error('Database pool error:', err.message);
});

/**
 * Execute a SQL query against the database.
 *
 * Usage:
 *   const result = await query('SELECT * FROM posts WHERE id = $1', [1]);
 *   const posts = result.rows;
 *
 * The $1, $2 syntax prevents SQL injection (never concatenate user input!)
 */
export const query = (text: string, params?: unknown[]) => {
  return pool.query(text, params);
};

// Export the pool directly for cases that need transactions
export { pool };
