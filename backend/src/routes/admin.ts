/**
 * admin.ts - Admin dashboard API routes
 *
 * Provides aggregated statistics for the admin dashboard:
 *   GET /api/admin/stats - Post counts, comment counts, views, recent activity
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
