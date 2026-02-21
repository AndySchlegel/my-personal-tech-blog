/**
 * categories.test.ts - Tests for the categories API routes
 *
 * Tests category listing and creation validation.
 * Database is mocked - no real PostgreSQL needed.
 */

import request from 'supertest';
import app from '../src/app';
import { query } from '../src/models/database';

// Mock the database module
jest.mock('../src/models/database');
const mockQuery = query as jest.MockedFunction<typeof query>;

describe('GET /api/categories', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should return an array of categories', async () => {
    // Mock: return some categories
    mockQuery.mockResolvedValueOnce({
      rows: [
        { id: 1, name: 'DevOps', slug: 'devops', post_count: 3 },
        { id: 2, name: 'Security', slug: 'security', post_count: 1 },
      ],
      command: 'SELECT',
      rowCount: 2,
      oid: 0,
      fields: [],
    });

    const response = await request(app).get('/api/categories');

    expect(response.status).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
    expect(response.body).toHaveLength(2);
    expect(response.body[0].name).toBe('DevOps');
  });
});

describe('POST /api/categories', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should return 400 when name is missing', async () => {
    const response = await request(app)
      .post('/api/categories')
      .send({});

    expect(response.status).toBe(400);
    expect(response.body.error).toContain('required');
  });

  it('should create a category with valid data', async () => {
    // Mock: INSERT returns the new category
    mockQuery.mockResolvedValueOnce({
      rows: [
        {
          id: 1,
          name: 'Homelab',
          slug: 'homelab',
          description: 'Self-hosted stuff',
        },
      ],
      command: 'INSERT',
      rowCount: 1,
      oid: 0,
      fields: [],
    });

    const response = await request(app)
      .post('/api/categories')
      .send({ name: 'Homelab', description: 'Self-hosted stuff' });

    expect(response.status).toBe(201);
    expect(response.body.name).toBe('Homelab');
    expect(response.body.slug).toBe('homelab');
  });
});
