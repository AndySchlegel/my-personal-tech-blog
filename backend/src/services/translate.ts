/**
 * translate.ts - Amazon Translate integration for DE/EN blog translation
 *
 * Translates blog post content (title, content, excerpt) from German to English
 * using AWS Translate. Results are cached in PostgreSQL so each post is only
 * translated once (subsequent requests read from cache).
 *
 * Uses the same graceful-degradation pattern as comprehend.ts:
 * - If AWS credentials are not available (local dev), silently returns null
 * - Errors are logged but never break the calling code
 *
 * Required: @aws-sdk/client-translate package
 * Region: reads AWS_REGION env var, defaults to 'eu-central-1'
 */

import { TranslateClient, TranslateTextCommand } from '@aws-sdk/client-translate';
import { query } from '../models/database';

// Translation result returned to the caller
export interface TranslationResult {
  title: string;
  content: string;
  excerpt: string | null;
}

// Create the Translate client once (reused across requests)
const client = new TranslateClient({
  region: process.env.AWS_REGION || 'eu-central-1',
});

/**
 * Check if Amazon Translate is available
 *
 * Same pattern as Comprehend: on EKS the pod gets AWS credentials via IRSA.
 * In local dev there are typically no credentials, so we skip silently.
 */
function isConfigured(): boolean {
  return !!(process.env.AWS_REGION || process.env.AWS_DEFAULT_REGION);
}

/**
 * Translate a single text from German to English using Amazon Translate
 *
 * Returns the translated text, or null if translation is not available.
 * Handles the 5000 byte limit by splitting long texts into chunks.
 */
async function translateText(text: string): Promise<string | null> {
  if (!text || !text.trim()) return text;

  // Amazon Translate has a 5000 byte limit per request.
  // For long blog posts, split by paragraphs and translate in chunks.
  const byteLength = Buffer.byteLength(text, 'utf-8');
  if (byteLength > 4500) {
    return translateLongText(text);
  }

  try {
    const command = new TranslateTextCommand({
      Text: text,
      SourceLanguageCode: 'de',
      TargetLanguageCode: 'en',
    });

    const response = await client.send(command);
    return response.TranslatedText || null;
  } catch (err) {
    console.warn('Amazon Translate failed:', (err as Error).message);
    return null;
  }
}

/**
 * Translate long text by splitting into paragraph chunks
 *
 * Markdown content can be long. We split by double-newlines (paragraphs)
 * and translate each chunk separately, then reassemble. This preserves
 * Markdown structure (headings, code blocks, lists).
 */
async function translateLongText(text: string): Promise<string | null> {
  // Split by double newlines (paragraph boundaries in Markdown)
  const paragraphs = text.split(/\n\n/);
  const translatedParts: string[] = [];

  let chunk = '';
  for (const para of paragraphs) {
    // If adding this paragraph would exceed the limit, translate current chunk first
    if (Buffer.byteLength(chunk + '\n\n' + para, 'utf-8') > 4500 && chunk) {
      const translated = await translateSingleChunk(chunk);
      if (!translated) return null;
      translatedParts.push(translated);
      chunk = para;
    } else {
      chunk = chunk ? chunk + '\n\n' + para : para;
    }
  }

  // Translate remaining chunk
  if (chunk) {
    const translated = await translateSingleChunk(chunk);
    if (!translated) return null;
    translatedParts.push(translated);
  }

  return translatedParts.join('\n\n');
}

/**
 * Translate a single chunk (must be under 5000 bytes)
 */
async function translateSingleChunk(text: string): Promise<string | null> {
  try {
    const command = new TranslateTextCommand({
      Text: text,
      SourceLanguageCode: 'de',
      TargetLanguageCode: 'en',
    });

    const response = await client.send(command);
    return response.TranslatedText || null;
  } catch (err) {
    console.warn('Amazon Translate chunk failed:', (err as Error).message);
    return null;
  }
}

/**
 * Get cached translation for a post from the database
 *
 * Returns the cached translation if it exists, or null if not cached yet.
 */
export async function getCachedTranslation(
  postId: number,
  language: string
): Promise<TranslationResult | null> {
  try {
    const result = await query(
      'SELECT title, content, excerpt FROM post_translations WHERE post_id = $1 AND language = $2',
      [postId, language]
    );

    if (result.rows.length === 0) return null;

    return {
      title: result.rows[0].title,
      content: result.rows[0].content,
      excerpt: result.rows[0].excerpt,
    };
  } catch (err) {
    console.warn('Failed to read translation cache:', (err as Error).message);
    return null;
  }
}

/**
 * Save a translation to the database cache
 *
 * Uses UPSERT (ON CONFLICT) so re-translating a post updates the cache.
 */
async function saveTranslationCache(
  postId: number,
  language: string,
  translation: TranslationResult
): Promise<void> {
  try {
    await query(
      `INSERT INTO post_translations (post_id, language, title, content, excerpt)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (post_id, language)
       DO UPDATE SET title = $3, content = $4, excerpt = $5, created_at = NOW()`,
      [postId, language, translation.title, translation.content, translation.excerpt]
    );
  } catch (err) {
    console.warn('Failed to save translation cache:', (err as Error).message);
  }
}

/**
 * Translate a blog post from German to English
 *
 * Flow:
 * 1. Check PostgreSQL cache first (instant, no API call)
 * 2. If not cached, call Amazon Translate for title + content + excerpt
 * 3. Save result to cache for future requests
 * 4. Return translated fields (or null if Translate is not available)
 *
 * The caller merges the translated fields into the post response.
 */
export async function translatePost(
  postId: number,
  title: string,
  content: string,
  excerpt: string | null,
  targetLanguage: string = 'en'
): Promise<TranslationResult | null> {
  // Only 'en' is supported for now
  if (targetLanguage !== 'en') return null;

  // Check if Translate is available (EKS only)
  if (!isConfigured()) return null;

  // Step 1: Check cache
  const cached = await getCachedTranslation(postId, targetLanguage);
  if (cached) return cached;

  // Step 2: Translate via Amazon Translate
  try {
    const [translatedTitle, translatedContent, translatedExcerpt] = await Promise.all([
      translateText(title),
      translateText(content),
      excerpt ? translateText(excerpt) : Promise.resolve(null),
    ]);

    // If any required field failed, return null
    if (!translatedTitle || !translatedContent) return null;

    const result: TranslationResult = {
      title: translatedTitle,
      content: translatedContent,
      excerpt: translatedExcerpt,
    };

    // Step 3: Cache for future requests (fire and forget)
    saveTranslationCache(postId, targetLanguage, result);

    return result;
  } catch (err) {
    console.warn('Post translation failed:', (err as Error).message);
    return null;
  }
}
