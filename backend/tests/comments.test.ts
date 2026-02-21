/**
 * comments.test.ts - Tests for the comments API routes
 *
 * Tests comment creation validation and moderation.
 * Database is mocked - no real PostgreSQL needed.
 */

import request from 'supertest';
import app from '../src/app';
import { query } from '../src/models/database';

// Mock the database module
jest.mock('../src/models/database');
const mockQuery = query as jest.MockedFunction<typeof query>;

describe('POST /api/posts/:postId/comments', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should return 400 when author_name is missing', async () => {
    const response = await request(app)
      .post('/api/posts/1/comments')
      .send({ content: 'Nice post!' });

    expect(response.status).toBe(400);
    expect(response.body.error).toContain('required');
  });

  it('should return 400 when content is missing', async () => {
    const response = await request(app)
      .post('/api/posts/1/comments')
      .send({ author_name: 'Reader' });

    expect(response.status).toBe(400);
    expect(response.body.error).toContain('required');
  });

  it('should return 404 when post does not exist', async () => {
    // Mock: post check returns empty (post not found)
    mockQuery.mockResolvedValueOnce({
      rows: [],
      command: 'SELECT',
      rowCount: 0,
      oid: 0,
      fields: [],
    });

    const response = await request(app)
      .post('/api/posts/999/comments')
      .send({ author_name: 'Reader', content: 'Great post!' });

    expect(response.status).toBe(404);
    expect(response.body.error).toContain('Post not found');
  });

  it('should create a comment with valid data', async () => {
    // Mock 1: post exists check
    mockQuery.mockResolvedValueOnce({
      rows: [{ id: 1 }],
      command: 'SELECT',
      rowCount: 1,
      oid: 0,
      fields: [],
    });

    // Mock 2: INSERT comment
    mockQuery.mockResolvedValueOnce({
      rows: [
        {
          id: 1,
          author_name: 'Reader',
          content: 'Great article!',
          status: 'pending',
          created_at: '2026-02-21T10:00:00Z',
        },
      ],
      command: 'INSERT',
      rowCount: 1,
      oid: 0,
      fields: [],
    });

    const response = await request(app)
      .post('/api/posts/1/comments')
      .send({ author_name: 'Reader', content: 'Great article!' });

    expect(response.status).toBe(201);
    expect(response.body.author_name).toBe('Reader');
    // New comments always start as pending (needs moderation)
    expect(response.body.status).toBe('pending');
  });
});

describe('PUT /api/comments/:id/status', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should return 400 for invalid status', async () => {
    const response = await request(app)
      .put('/api/comments/1/status')
      .send({ status: 'invalid' });

    expect(response.status).toBe(400);
    expect(response.body.error).toContain('Status must be one of');
  });

  it('should return 400 when status is missing', async () => {
    const response = await request(app)
      .put('/api/comments/1/status')
      .send({});

    expect(response.status).toBe(400);
  });
});
