/**
 * categories.ts - Category API routes
 *
 * Handles blog categories:
 *   GET    /categories      - List all categories
 *   POST   /categories      - Create a new category (admin only, later)
 */

import { Router, Request, Response } from 'express';
import { query } from '../models/database';

export const categoriesRouter = Router();

/**
 * GET /categories - List all categories with post count
 *
 * Returns categories sorted alphabetically.
 * Includes how many published posts each category has.
 */
categoriesRouter.get('/', async (_req: Request, res: Response) => {
  try {
    const result = await query(
      `SELECT
        c.id, c.name, c.slug, c.description,
        COUNT(p.id) AS post_count
      FROM categories c
      LEFT JOIN posts p ON p.category_id = c.id AND p.status = 'published'
      GROUP BY c.id
      ORDER BY c.name ASC`
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching categories:', err);
    res.status(500).json({ error: 'Failed to fetch categories' });
  }
});

/**
 * POST /categories - Create a new category
 *
 * TODO: Add Cognito auth middleware (admin only)
 */
categoriesRouter.post('/', async (req: Request, res: Response) => {
  try {
    const { name, description } = req.body;

    if (!name) {
      res.status(400).json({ error: 'Name is required' });
      return;
    }

    // Generate slug from name
    const slug = name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '');

    const result = await query(
      `INSERT INTO categories (name, slug, description)
      VALUES ($1, $2, $3)
      RETURNING *`,
      [name, slug, description || null]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Error creating category:', err);
    res.status(500).json({ error: 'Failed to create category' });
  }
});
