/**
 * health.test.ts - Tests for the health check endpoint
 *
 * Verifies that GET /health returns the expected response.
 * This is our first test - more will be added as we build the API.
 */

import request from 'supertest';
// Import app (not server!) so the test doesn't start an HTTP server
import app from '../src/app';

describe('GET /health', () => {
  // Test 1: Should return HTTP 200 (success)
  it('should return 200 with status ok', async () => {
    const response = await request(app).get('/health');

    expect(response.status).toBe(200);
    expect(response.body.status).toBe('ok');
  });

  // Test 2: Should include a timestamp in ISO format
  it('should include a valid timestamp', async () => {
    const response = await request(app).get('/health');

    expect(response.body.timestamp).toBeDefined();
    // Check that the timestamp is a valid date
    const date = new Date(response.body.timestamp);
    expect(date.getTime()).not.toBeNaN();
  });

  // Test 3: Should include uptime (how long the server has been running)
  it('should include uptime as a number', async () => {
    const response = await request(app).get('/health');

    expect(response.body.uptime).toBeDefined();
    expect(typeof response.body.uptime).toBe('number');
  });
});
