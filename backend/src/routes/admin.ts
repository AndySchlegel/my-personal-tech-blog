/**
 * admin.ts - Admin dashboard API routes
 *
 * Provides endpoints for the admin dashboard:
 *   GET /api/admin/stats        - Post counts, comment counts, views, recent activity
 *   GET /api/admin/posts        - List all posts (any status) for management
 *   GET /api/admin/posts/:id    - Get single post with full content for editing
 *   GET /api/admin/comments     - List all comments (any status) for moderation
 *
 * All routes are protected by requireAuth middleware.
 */

import { Router, Request, Response } from 'express';
import { query } from '../models/database';
import { requireAuth } from '../middleware/auth';

export const adminRouter = Router();

// All admin routes require authentication
adminRouter.use(requireAuth);

/**
 * GET /api/admin/stats - Dashboard overview statistics
 *
 * Returns aggregated counts and recent activity for the admin dashboard.
 * Runs multiple queries in parallel for better performance.
 */
adminRouter.get('/stats', async (_req: Request, res: Response) => {
  try {
    // Run all stat queries in parallel
    const [postStats, commentStats, viewStats, recentPosts, recentComments] = await Promise.all([
      // Post counts by status
      query(`
        SELECT
          COUNT(*)::int AS total,
          COUNT(*) FILTER (WHERE status = 'published')::int AS published,
          COUNT(*) FILTER (WHERE status = 'draft')::int AS drafts
        FROM posts
      `),

      // Comment counts by status
      query(`
        SELECT
          COUNT(*)::int AS total,
          COUNT(*) FILTER (WHERE status = 'pending')::int AS pending,
          COUNT(*) FILTER (WHERE status = 'approved')::int AS approved,
          COUNT(*) FILTER (WHERE status = 'flagged')::int AS flagged
        FROM comments
      `),

      // Total views across all posts
      query(`SELECT COALESCE(SUM(view_count), 0)::int AS total FROM posts`),

      // Last 5 posts (any status)
      query(`
        SELECT title, status, published_at, created_at
        FROM posts
        ORDER BY created_at DESC
        LIMIT 5
      `),

      // Last 5 comments (any status)
      query(`
        SELECT c.author_name, c.content, c.status, c.created_at, p.title AS post_title
        FROM comments c
        LEFT JOIN posts p ON c.post_id = p.id
        ORDER BY c.created_at DESC
        LIMIT 5
      `),
    ]);

    res.json({
      posts: postStats.rows[0],
      comments: commentStats.rows[0],
      views: viewStats.rows[0],
      recentPosts: recentPosts.rows,
      recentComments: recentComments.rows,
    });
  } catch (err) {
    console.error('Error fetching admin stats:', err);
    res.status(500).json({ error: 'Failed to fetch admin stats' });
  }
});

/**
 * GET /api/admin/posts - List all posts for admin management
 *
 * Returns all posts regardless of status (published, draft, archived),
 * sorted by created_at descending. Includes category info and view counts.
 */
adminRouter.get('/posts', async (_req: Request, res: Response) => {
  try {
    const result = await query(`
      SELECT
        p.id, p.title, p.slug, p.status, p.featured,
        p.reading_time_minutes, p.view_count,
        c.name AS category_name, c.slug AS category_slug,
        p.published_at, p.created_at, p.updated_at
      FROM posts p
      LEFT JOIN categories c ON p.category_id = c.id
      ORDER BY p.created_at DESC
    `);

    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching admin posts:', err);
    res.status(500).json({ error: 'Failed to fetch posts' });
  }
});

/**
 * GET /api/admin/posts/:id - Get a single post with full content for editing
 *
 * Returns the complete post including Markdown content, category info, and tags.
 * Does NOT increment view count (admin views don't count).
 */
adminRouter.get('/posts/:id', async (req: Request, res: Response) => {
  try {
    const postResult = await query(
      `
      SELECT
        p.*,
        c.name AS category_name, c.slug AS category_slug
      FROM posts p
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.id = $1
    `,
      [req.params.id]
    );

    if (postResult.rows.length === 0) {
      res.status(404).json({ error: 'Post not found' });
      return;
    }

    const post = postResult.rows[0];

    // Fetch tags for this post
    const tagsResult = await query(
      `
      SELECT t.name, t.slug
      FROM tags t
      JOIN post_tags pt ON t.id = pt.tag_id
      WHERE pt.post_id = $1
    `,
      [post.id]
    );

    res.json({ ...post, tags: tagsResult.rows });
  } catch (err) {
    console.error('Error fetching admin post:', err);
    res.status(500).json({ error: 'Failed to fetch post' });
  }
});

/**
 * GET /api/admin/comments - List all comments for moderation
 *
 * Returns all comments regardless of status, with the post title.
 * Supports optional ?status= filter (pending, approved, flagged, deleted).
 * Sorted by newest first.
 */
adminRouter.get('/comments', async (req: Request, res: Response) => {
  try {
    const { status } = req.query;
    const conditions: string[] = [];
    const values: unknown[] = [];
    let paramIndex = 1;

    // Optional status filter
    if (status && typeof status === 'string') {
      const validStatuses = ['pending', 'approved', 'flagged', 'deleted'];
      if (validStatuses.includes(status)) {
        conditions.push(`c.status = $${paramIndex++}`);
        values.push(status);
      }
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';

    const result = await query(
      `
      SELECT
        c.id, c.author_name, c.content, c.status, c.created_at,
        p.title AS post_title, p.id AS post_id
      FROM comments c
      LEFT JOIN posts p ON c.post_id = p.id
      ${whereClause}
      ORDER BY c.created_at DESC
    `,
      values
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching admin comments:', err);
    res.status(500).json({ error: 'Failed to fetch comments' });
  }
});
