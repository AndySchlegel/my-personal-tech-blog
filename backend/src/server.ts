/**
 * server.ts - Entry point that starts the HTTP server
 *
 * Imports the configured app from app.ts and starts listening on a port.
 * This separation exists so that tests can import the app (from app.ts)
 * without actually starting the server.
 */

import dotenv from 'dotenv';
import app from './app';

// Load environment variables from .env file (only used in local development)
dotenv.config();

// Port: use environment variable or default to 3000
const PORT = process.env.PORT || 3000;

// Start the server
app.listen(PORT, () => {
  console.info(`Server running on port ${PORT}`);
  console.info(`Health check: http://localhost:${PORT}/health`);
});
