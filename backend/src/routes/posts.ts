/**
 * posts.ts - Blog post API routes
 *
 * Handles all CRUD operations for blog posts:
 *   GET    /posts          - List all published posts
 *   GET    /posts/:slug    - Get a single post by its URL slug
 *   POST   /posts          - Create a new post (admin only, later)
 *   PUT    /posts/:id      - Update a post (admin only, later)
 *   DELETE /posts/:id      - Delete a post (admin only, later)
 */

import { Router, Request, Response } from 'express';
import { query } from '../models/database';
import { CreatePostRequest } from '../models/types';

export const postsRouter = Router();

/**
 * GET /posts - List all published posts
 *
 * Returns posts sorted by publish date (newest first).
 * Includes category name and tags for each post.
 * Only returns published posts (not drafts or archived).
 */
postsRouter.get('/', async (_req: Request, res: Response) => {
  try {
    const result = await query(
      `SELECT
        p.id, p.title, p.slug, p.excerpt, p.cover_image_url,
        p.featured, p.reading_time_minutes, p.view_count, p.published_at,
        c.name AS category_name, c.slug AS category_slug,
        u.display_name AS author_name,
        COALESCE(
          json_agg(json_build_object('name', t.name, 'slug', t.slug))
          FILTER (WHERE t.id IS NOT NULL), '[]'
        ) AS tags
      FROM posts p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN users u ON p.author_id = u.id
      LEFT JOIN post_tags pt ON p.id = pt.post_id
      LEFT JOIN tags t ON pt.tag_id = t.id
      WHERE p.status = 'published'
      GROUP BY p.id, c.name, c.slug, u.display_name
      ORDER BY p.published_at DESC`
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching posts:', err);
    res.status(500).json({ error: 'Failed to fetch posts' });
  }
});

/**
 * GET /posts/:slug - Get a single post by URL slug
 *
 * Returns the full post including Markdown content, tags, and metadata.
 * Also increments the view counter.
 */
postsRouter.get('/:slug', async (req: Request, res: Response) => {
  try {
    // Fetch the post with category and author info
    const postResult = await query(
      `SELECT
        p.*,
        c.name AS category_name, c.slug AS category_slug,
        u.display_name AS author_name
      FROM posts p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN users u ON p.author_id = u.id
      WHERE p.slug = $1 AND p.status = 'published'`,
      [req.params.slug]
    );

    if (postResult.rows.length === 0) {
      res.status(404).json({ error: 'Post not found' });
      return;
    }

    const post = postResult.rows[0];

    // Fetch tags for this post
    const tagsResult = await query(
      `SELECT t.name, t.slug, t.source, pt.confidence
      FROM tags t
      JOIN post_tags pt ON t.id = pt.tag_id
      WHERE pt.post_id = $1`,
      [post.id]
    );

    // Increment view count (fire and forget - don't wait for it)
    query('UPDATE posts SET view_count = view_count + 1 WHERE id = $1', [post.id]);

    res.json({
      ...post,
      tags: tagsResult.rows,
    });
  } catch (err) {
    console.error('Error fetching post:', err);
    res.status(500).json({ error: 'Failed to fetch post' });
  }
});

/**
 * POST /posts - Create a new blog post
 *
 * Expects JSON body with title, content, category_id.
 * Automatically generates a URL slug from the title.
 * TODO: Add Cognito auth middleware (admin only)
 */
postsRouter.post('/', async (req: Request, res: Response) => {
  try {
    const { title, content, excerpt, category_id, status, featured, tags } =
      req.body as CreatePostRequest;

    // Validate required fields
    if (!title || !content || !category_id) {
      res.status(400).json({ error: 'Title, content, and category_id are required' });
      return;
    }

    // Generate URL slug from title: "My First Post" -> "my-first-post"
    const slug = title
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '');

    // Calculate reading time (~200 words per minute)
    const wordCount = content.split(/\s+/).length;
    const readingTime = Math.max(1, Math.ceil(wordCount / 200));

    // Set published_at if status is "published"
    const publishedAt = status === 'published' ? new Date() : null;

    const result = await query(
      `INSERT INTO posts (title, slug, content, excerpt, category_id, status, featured, reading_time_minutes, published_at)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *`,
      [
        title,
        slug,
        content,
        excerpt || null,
        category_id,
        status || 'draft',
        featured || false,
        readingTime,
        publishedAt,
      ]
    );

    const post = result.rows[0];

    // Handle manual tags if provided
    if (tags && tags.length > 0) {
      for (const tagName of tags) {
        const tagSlug = tagName.toLowerCase().replace(/[^a-z0-9]+/g, '-');

        // Insert tag if it doesn't exist, get its ID
        const tagResult = await query(
          `INSERT INTO tags (name, slug, source)
          VALUES ($1, $2, 'manual')
          ON CONFLICT (slug) DO UPDATE SET name = $1
          RETURNING id`,
          [tagName, tagSlug]
        );

        // Link tag to post
        await query(
          'INSERT INTO post_tags (post_id, tag_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
          [post.id, tagResult.rows[0].id]
        );
      }
    }

    res.status(201).json(post);
  } catch (err) {
    console.error('Error creating post:', err);
    res.status(500).json({ error: 'Failed to create post' });
  }
});

/**
 * PUT /posts/:id - Update an existing post
 *
 * Accepts partial updates (only send the fields you want to change).
 * TODO: Add Cognito auth middleware (admin only)
 */
postsRouter.put('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const { title, content, excerpt, category_id, status, featured } = req.body;

    // Build update query dynamically (only update provided fields)
    const updates: string[] = [];
    const values: unknown[] = [];
    let paramIndex = 1;

    if (title !== undefined) {
      updates.push(`title = $${paramIndex++}`);
      values.push(title);
    }
    if (content !== undefined) {
      updates.push(`content = $${paramIndex++}`);
      values.push(content);

      // Recalculate reading time
      const wordCount = content.split(/\s+/).length;
      updates.push(`reading_time_minutes = $${paramIndex++}`);
      values.push(Math.max(1, Math.ceil(wordCount / 200)));
    }
    if (excerpt !== undefined) {
      updates.push(`excerpt = $${paramIndex++}`);
      values.push(excerpt);
    }
    if (category_id !== undefined) {
      updates.push(`category_id = $${paramIndex++}`);
      values.push(category_id);
    }
    if (status !== undefined) {
      updates.push(`status = $${paramIndex++}`);
      values.push(status);

      // Set published_at when publishing for the first time
      if (status === 'published') {
        updates.push(`published_at = COALESCE(published_at, $${paramIndex++})`);
        values.push(new Date());
      }
    }
    if (featured !== undefined) {
      updates.push(`featured = $${paramIndex++}`);
      values.push(featured);
    }

    if (updates.length === 0) {
      res.status(400).json({ error: 'No fields to update' });
      return;
    }

    // Always update the timestamp
    updates.push(`updated_at = NOW()`);
    values.push(id);

    const result = await query(
      `UPDATE posts SET ${updates.join(', ')} WHERE id = $${paramIndex} RETURNING *`,
      values
    );

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Post not found' });
      return;
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error updating post:', err);
    res.status(500).json({ error: 'Failed to update post' });
  }
});

/**
 * DELETE /posts/:id - Delete a post
 *
 * Permanently removes the post and its tag associations.
 * Comments are also deleted (CASCADE in schema).
 * TODO: Add Cognito auth middleware (admin only)
 */
postsRouter.delete('/:id', async (req: Request, res: Response) => {
  try {
    const result = await query('DELETE FROM posts WHERE id = $1 RETURNING id', [req.params.id]);

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Post not found' });
      return;
    }

    res.json({ message: 'Post deleted' });
  } catch (err) {
    console.error('Error deleting post:', err);
    res.status(500).json({ error: 'Failed to delete post' });
  }
});
