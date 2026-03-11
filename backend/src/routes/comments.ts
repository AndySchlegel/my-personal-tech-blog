/**
 * comments.ts - Comment API routes
 *
 * Handles comments on blog posts:
 *   GET    /posts/:postId/comments  - List approved comments for a post
 *   POST   /posts/:postId/comments  - Submit a new comment (public)
 *   PUT    /comments/:id/status     - Moderate a comment (admin only, later)
 */

import { Router, Request, Response } from 'express';
import { query } from '../models/database';
import { CreateCommentRequest } from '../models/types';
import { requireAuth } from '../middleware/auth';
import { notifyNewComment } from '../services/telegram';
import { analyzeSentiment } from '../services/comprehend';

export const commentsRouter = Router();

/**
 * GET /posts/:postId/comments - List all approved comments for a post
 *
 * Only returns approved comments (not pending, flagged, or deleted).
 * Sorted by oldest first (natural reading order).
 */
commentsRouter.get('/posts/:postId/comments', async (req: Request, res: Response) => {
  try {
    const result = await query(
      `SELECT id, author_name, content, created_at
      FROM comments
      WHERE post_id = $1 AND status = 'approved'
      ORDER BY created_at ASC`,
      [req.params.postId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching comments:', err);
    res.status(500).json({ error: 'Failed to fetch comments' });
  }
});

/**
 * POST /posts/:postId/comments - Submit a new comment
 *
 * Anyone can comment (no login required).
 * New comments start with status "pending" until moderated.
 * After saving, runs Comprehend sentiment analysis in the background (non-blocking).
 */
commentsRouter.post('/posts/:postId/comments', async (req: Request, res: Response) => {
  try {
    const { postId } = req.params;
    const { author_name, author_email, content } = req.body as CreateCommentRequest;

    // Validate required fields
    if (!author_name || !content) {
      res.status(400).json({ error: 'author_name and content are required' });
      return;
    }

    // Check if the post exists
    // Also fetch title for the Telegram notification
    const postCheck = await query('SELECT id, title FROM posts WHERE id = $1', [postId]);
    if (postCheck.rows.length === 0) {
      res.status(404).json({ error: 'Post not found' });
      return;
    }

    // Fetch post title for the notification message
    const postTitle = postCheck.rows[0].title || 'Unknown post';

    const result = await query(
      `INSERT INTO comments (post_id, author_name, author_email, content)
      VALUES ($1, $2, $3, $4)
      RETURNING id, author_name, content, status, created_at`,
      [postId, author_name, author_email || null, content]
    );

    const commentId = result.rows[0].id;

    // Send Telegram notification (non-blocking, never fails the request)
    notifyNewComment({
      authorName: author_name,
      postTitle: postTitle,
      content: content,
      postId: Number(postId),
      commentId: commentId,
    }).catch(() => {});

    // Run Comprehend sentiment analysis in the background (non-blocking).
    // Updates the comment's sentiment columns after the response is sent.
    // If Comprehend is unavailable (local dev), analyzeSentiment returns null.
    analyzeSentiment(content)
      .then((sentimentResult) => {
        if (sentimentResult) {
          query('UPDATE comments SET sentiment = $1, sentiment_score = $2 WHERE id = $3', [
            sentimentResult.sentiment,
            sentimentResult.confidence,
            commentId,
          ]).catch((err) => {
            console.warn('Failed to save sentiment result:', (err as Error).message);
          });
        }
      })
      .catch(() => {});

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error creating comment:', err);
    res.status(500).json({ error: 'Failed to create comment' });
  }
});

/**
 * PUT /comments/:id/status - Moderate a comment (approve, flag, delete)
 *
 * Changes the status of a comment.
 * Protected: requires valid Cognito JWT (admin only).
 */
commentsRouter.put('/comments/:id/status', requireAuth, async (req: Request, res: Response) => {
  try {
    const { status } = req.body;
    const validStatuses = ['pending', 'approved', 'flagged', 'deleted'];

    if (!status || !validStatuses.includes(status)) {
      res.status(400).json({ error: `Status must be one of: ${validStatuses.join(', ')}` });
      return;
    }

    const result = await query('UPDATE comments SET status = $1 WHERE id = $2 RETURNING *', [
      status,
      req.params.id,
    ]);

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Comment not found' });
      return;
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updating comment:', err);
    res.status(500).json({ error: 'Failed to update comment status' });
  }
});
