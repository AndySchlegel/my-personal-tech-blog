/**
 * posts.test.ts - Tests for the posts API routes
 *
 * Tests validation logic and response formats.
 * The database is MOCKED - no real PostgreSQL needed.
 * jest.mock() replaces the real query function with a fake one
 * that we control in each test.
 */

import request from 'supertest';
import app from '../src/app';
import { query } from '../src/models/database';

// Mock the entire database module
// This replaces the real query() with a jest.fn() we can control
jest.mock('../src/models/database');
const mockQuery = query as jest.MockedFunction<typeof query>;

describe('GET /api/posts', () => {
  // Reset mocks before each test so they don't interfere
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should return an array of posts', async () => {
    // Tell the mock to return some fake posts
    mockQuery.mockResolvedValueOnce({
      rows: [
        {
          id: 1,
          title: 'Test Post',
          slug: 'test-post',
          excerpt: 'A test',
          reading_time_minutes: 3,
          category_name: 'DevOps',
        },
      ],
      command: 'SELECT',
      rowCount: 1,
      oid: 0,
      fields: [],
    });

    const response = await request(app).get('/api/posts');

    expect(response.status).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
    expect(response.body[0].title).toBe('Test Post');
  });

  it('should return empty array when no posts exist', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [],
      command: 'SELECT',
      rowCount: 0,
      oid: 0,
      fields: [],
    });

    const response = await request(app).get('/api/posts');

    expect(response.status).toBe(200);
    expect(response.body).toEqual([]);
  });
});

describe('POST /api/posts', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should return 400 when title is missing', async () => {
    const response = await request(app)
      .post('/api/posts')
      .send({ content: 'Some content', category_id: 1 });

    expect(response.status).toBe(400);
    expect(response.body.error).toContain('required');
  });

  it('should return 400 when content is missing', async () => {
    const response = await request(app)
      .post('/api/posts')
      .send({ title: 'My Post', category_id: 1 });

    expect(response.status).toBe(400);
    expect(response.body.error).toContain('required');
  });

  it('should return 400 when category_id is missing', async () => {
    const response = await request(app)
      .post('/api/posts')
      .send({ title: 'My Post', content: 'Some content' });

    expect(response.status).toBe(400);
    expect(response.body.error).toContain('required');
  });

  it('should create a post with valid data', async () => {
    // Mock: INSERT returns the new post
    mockQuery.mockResolvedValueOnce({
      rows: [
        {
          id: 1,
          title: 'My First Post',
          slug: 'my-first-post',
          content: 'Hello World this is a test post with enough words.',
          status: 'draft',
          reading_time_minutes: 1,
        },
      ],
      command: 'INSERT',
      rowCount: 1,
      oid: 0,
      fields: [],
    });

    const response = await request(app).post('/api/posts').send({
      title: 'My First Post',
      content: 'Hello World this is a test post with enough words.',
      category_id: 1,
    });

    expect(response.status).toBe(201);
    expect(response.body.title).toBe('My First Post');
    expect(response.body.slug).toBe('my-first-post');
  });
});

describe('PUT /api/posts/:id', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should return 400 when no fields are provided', async () => {
    const response = await request(app).put('/api/posts/1').send({});

    expect(response.status).toBe(400);
    expect(response.body.error).toContain('No fields');
  });
});
