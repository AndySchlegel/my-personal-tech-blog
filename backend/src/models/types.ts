/**
 * types.ts - TypeScript type definitions matching our database schema
 *
 * These types ensure type safety across the entire backend.
 * Each type mirrors a database table so we catch errors at compile time.
 */

// ----- Users -----

export interface User {
  id: number;
  cognito_id: string;
  email: string;
  display_name: string;
  role: 'admin' | 'editor';
  created_at: Date;
}

// ----- Categories -----

export interface Category {
  id: number;
  name: string;
  slug: string;
  description: string | null;
  created_at: Date;
}

// ----- Posts -----

// All possible post statuses
export type PostStatus = 'draft' | 'published' | 'archived';

export interface Post {
  id: number;
  title: string;
  slug: string;
  content: string; // Markdown
  excerpt: string | null;
  cover_image_url: string | null;
  status: PostStatus;
  featured: boolean;
  reading_time_minutes: number;
  view_count: number;
  author_id: number;
  category_id: number;
  published_at: Date | null;
  created_at: Date;
  updated_at: Date;
}

// Extended version with related data (used in API responses)
export interface PostWithDetails extends Post {
  author: Pick<User, 'display_name'>;
  category: Pick<Category, 'name' | 'slug'>;
  tags: TagOnPost[];
}

// ----- Tags -----

// Where the tag came from
export type TagSource = 'manual' | 'comprehend';

export interface Tag {
  id: number;
  name: string;
  slug: string;
  source: TagSource;
  created_at: Date;
}

// Tag with Comprehend confidence score (from post_tags junction table)
export interface TagOnPost {
  name: string;
  slug: string;
  source: TagSource;
  confidence: number | null;
}

// ----- Comments -----

// Comprehend sentiment values
export type Sentiment = 'POSITIVE' | 'NEGATIVE' | 'NEUTRAL' | 'MIXED';

// Comment moderation statuses
export type CommentStatus = 'pending' | 'approved' | 'flagged' | 'deleted';

export interface Comment {
  id: number;
  post_id: number;
  author_name: string;
  author_email: string | null;
  content: string;
  sentiment: Sentiment | null;
  sentiment_score: number | null;
  status: CommentStatus;
  created_at: Date;
}

// ----- Auth Types -----

// Decoded JWT payload from Cognito token
export interface TokenPayload {
  sub: string; // Cognito user ID
  email: string;
  'cognito:groups'?: string[];
}

// Express Request with authenticated user attached by auth middleware
import { Request } from 'express';

export interface AuthenticatedRequest extends Request {
  user?: TokenPayload;
}

// ----- API Request/Response Types -----

// What the frontend sends when creating a new post
export interface CreatePostRequest {
  title: string;
  content: string;
  excerpt?: string;
  category_id: number;
  status?: PostStatus;
  featured?: boolean;
  tags?: string[]; // Tag names (manual tags)
}

// What the frontend sends when creating a comment
export interface CreateCommentRequest {
  author_name: string;
  author_email?: string;
  content: string;
}
