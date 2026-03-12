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
import { requireAuth } from '../middleware/auth';
import { translatePost, getCachedTranslation } from '../services/translate';
import { getPostAudioUrl } from '../services/polly';

export const postsRouter = Router();

/**
 * GET /posts - List published posts with optional filtering
 *
 * Query parameters:
 *   ?search=terraform    - Search in title and excerpt (case-insensitive)
 *   ?category=devops-ci-cd - Filter by category slug
 *   ?tag=aws             - Filter by tag slug
 *   ?lang=en             - Return translated content (cached via Amazon Translate)
 *
 * Returns posts sorted by publish date (newest first).
 * Includes category name and tags for each post.
 * Only returns published posts (not drafts or archived).
 */
postsRouter.get('/', async (req: Request, res: Response) => {
  try {
    const { search, category, tag, lang } = req.query;
    const targetLang = typeof lang === 'string' && lang === 'en' ? 'en' : null;

    // Build WHERE clause dynamically with parameterized queries
    const conditions: string[] = ["p.status = 'published'"];
    const values: unknown[] = [];
    let paramIndex = 1;

    if (search && typeof search === 'string' && search.trim()) {
      conditions.push(`(p.title ILIKE $${paramIndex} OR p.excerpt ILIKE $${paramIndex})`);
      values.push(`%${search.trim()}%`);
      paramIndex++;
    }

    if (category && typeof category === 'string' && category.trim()) {
      conditions.push(`c.slug = $${paramIndex}`);
      values.push(category.trim());
      paramIndex++;
    }

    // Tag filter requires a subquery to check post_tags + tags
    let tagJoinClause = '';
    if (tag && typeof tag === 'string' && tag.trim()) {
      tagJoinClause = `JOIN post_tags pt_filter ON p.id = pt_filter.post_id
        JOIN tags t_filter ON pt_filter.tag_id = t_filter.id AND t_filter.slug = $${paramIndex}`;
      values.push(tag.trim());
      paramIndex++;
    }

    const result = await query(
      `SELECT
        p.id, p.title, p.slug, p.excerpt, p.cover_image_url,
        p.featured, p.reading_time_minutes, p.view_count, p.like_count,
        p.published_at,
        c.name AS category_name, c.slug AS category_slug,
        u.display_name AS author_name,
        (SELECT COUNT(*) FROM comments WHERE post_id = p.id AND status = 'approved')::int AS comment_count,
        COALESCE(
          json_agg(json_build_object('name', t.name, 'slug', t.slug))
          FILTER (WHERE t.id IS NOT NULL), '[]'
        ) AS tags
      FROM posts p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN users u ON p.author_id = u.id
      LEFT JOIN post_tags pt ON p.id = pt.post_id
      LEFT JOIN tags t ON pt.tag_id = t.id
      ${tagJoinClause}
      WHERE ${conditions.join(' AND ')}
      GROUP BY p.id, c.name, c.slug, u.display_name
      ORDER BY p.published_at DESC`,
      values
    );

    let posts = result.rows;

    // If English translation requested, translate title + excerpt for each post.
    // Uses cache when available, calls Amazon Translate on-demand for uncached posts.
    // First request may be slower (translates all posts), subsequent requests are instant.
    if (targetLang === 'en') {
      const translated = await Promise.all(
        posts.map(
          async (post: { id: number; title: string; content: string; excerpt: string | null }) => {
            const cached = await getCachedTranslation(post.id, 'en');
            if (cached) {
              return { ...post, title: cached.title, excerpt: cached.excerpt };
            }
            // No cache -- translate on-demand (also caches full content for single-post view)
            const translation = await translatePost(
              post.id,
              post.title,
              post.content,
              post.excerpt
            );
            if (translation) {
              return { ...post, title: translation.title, excerpt: translation.excerpt };
            }
            return post;
          }
        )
      );
      posts = translated;
    }

    res.json(posts);
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
 *
 * Query parameters:
 *   ?lang=en - Return English translation (on-demand via Amazon Translate, cached in DB)
 */
postsRouter.get('/:slug', async (req: Request, res: Response) => {
  try {
    const { lang } = req.query;
    const targetLang = typeof lang === 'string' && lang === 'en' ? 'en' : null;

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

    // If English requested, translate on-demand (cached after first call)
    let translatedFields = null;
    if (targetLang === 'en') {
      translatedFields = await translatePost(post.id, post.title, post.content, post.excerpt);
    }

    // Merge translation into response (original fields stay as fallback)
    const responsePost = translatedFields
      ? {
          ...post,
          title: translatedFields.title,
          content: translatedFields.content,
          excerpt: translatedFields.excerpt,
          original_language: 'de',
          language: 'en',
        }
      : { ...post, language: 'de' };

    res.json({
      ...responsePost,
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
 * Protected: requires valid Cognito JWT (admin only).
 */
postsRouter.post('/', requireAuth, async (req: Request, res: Response) => {
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
 * Protected: requires valid Cognito JWT (admin only).
 */
postsRouter.put('/:id', requireAuth, async (req: Request, res: Response) => {
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
 * GET /posts/:id/audio - Get audio URL for a post (text-to-speech)
 *
 * Returns a pre-signed S3 URL for the MP3 audio file.
 * First request generates audio via Amazon Polly (~5-15 seconds).
 * Subsequent requests return cached URL instantly.
 *
 * Query parameters:
 *   ?lang=en - Get English audio (default: German)
 */
postsRouter.get('/:id/audio', async (req: Request, res: Response) => {
  try {
    const { lang } = req.query;
    const language = typeof lang === 'string' && lang === 'en' ? 'en' : 'de';

    // Fetch the post content
    const postResult = await query('SELECT id, title, content FROM posts WHERE id = $1', [
      req.params.id,
    ]);

    if (postResult.rows.length === 0) {
      res.status(404).json({ error: 'Post not found' });
      return;
    }

    const post = postResult.rows[0];

    // For English audio, use translated content if available
    let title = post.title;
    let content = post.content;

    if (language === 'en') {
      const translation = await getCachedTranslation(post.id, 'en');
      if (translation) {
        title = translation.title;
        content = translation.content;
      }
    }

    // Generate or retrieve cached audio URL
    const audioUrl = await getPostAudioUrl(post.id, title, content, language);

    if (!audioUrl) {
      res.status(503).json({ error: 'Audio generation not available' });
      return;
    }

    res.json({ audio_url: audioUrl, language });
  } catch (err) {
    console.error('Error generating audio:', err);
    res.status(500).json({ error: 'Failed to generate audio' });
  }
});

/**
 * POST /posts/:id/like - Like a post
 *
 * Public endpoint. Increments like_count by 1.
 * Client-side localStorage prevents duplicate likes per browser.
 */
postsRouter.post('/:id/like', async (req: Request, res: Response) => {
  try {
    const result = await query(
      'UPDATE posts SET like_count = like_count + 1 WHERE id = $1 RETURNING like_count',
      [req.params.id]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Post not found' });
      return;
    }

    res.json({ like_count: result.rows[0].like_count });
  } catch (err) {
    console.error('Error liking post:', err);
    res.status(500).json({ error: 'Failed to like post' });
  }
});

/**
 * DELETE /posts/:id - Delete a post
 *
 * Permanently removes the post and its tag associations.
 * Comments are also deleted (CASCADE in schema).
 * Protected: requires valid Cognito JWT (admin only).
 */
postsRouter.delete('/:id', requireAuth, async (req: Request, res: Response) => {
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
