/**
 * polly.ts - Amazon Polly integration for text-to-speech blog audio
 *
 * Converts blog post content to MP3 audio using AWS Polly. Audio files
 * are uploaded to S3 and served via CloudFront using static paths.
 * Results are cached in PostgreSQL so each post is only synthesized once.
 *
 * Flow:
 *   1. Check DB for cached S3 key
 *   2. If cached, return static path /audio/post-{id}-{lang}.mp3 (served by CloudFront)
 *   3. If not cached, strip Markdown, chunk text, call Polly, upload to S3
 *   4. Save S3 key in DB for future requests
 *
 * Audio delivery: CloudFront has an S3 origin with OAC for /audio/* paths.
 * The frontend requests /audio/post-{id}-{lang}.mp3, CloudFront fetches
 * from S3 and caches at edge (7 day TTL). No pre-signed URLs needed.
 *
 * Uses the same graceful-degradation pattern as comprehend.ts / translate.ts:
 * - If AWS credentials are not available (local dev), silently returns null
 * - Errors are logged but never break the calling code
 *
 * Required: @aws-sdk/client-polly, @aws-sdk/client-s3
 * Region: reads AWS_REGION env var, defaults to 'eu-central-1'
 */

import { PollyClient, SynthesizeSpeechCommand, VoiceId } from '@aws-sdk/client-polly';
import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';
import { query } from '../models/database';

// Voice configuration per language
// Vicki = German neural voice, Joanna = English neural voice
const VOICE_MAP: Record<string, VoiceId> = {
  de: 'Vicki' as VoiceId,
  en: 'Joanna' as VoiceId,
};

// Polly has a 3000 character limit per SynthesizeSpeech request.
// We chunk at 2800 to leave some headroom.
const CHUNK_LIMIT = 2800;

// Create clients once (reused across requests)
const pollyClient = new PollyClient({
  region: process.env.AWS_REGION || 'eu-central-1',
});
const s3Client = new S3Client({
  region: process.env.AWS_REGION || 'eu-central-1',
});

/**
 * Check if Polly + S3 are available
 *
 * Requires AWS credentials (IRSA on EKS) and S3_BUCKET_NAME env var.
 */
function isConfigured(): boolean {
  return !!(
    (process.env.AWS_REGION || process.env.AWS_DEFAULT_REGION) &&
    process.env.S3_BUCKET_NAME
  );
}

/**
 * Strip Markdown formatting to get plain text for speech synthesis
 *
 * Removes: headers, code blocks, inline code, links, images, bold,
 * italic, horizontal rules, list markers. Preserves paragraph structure.
 */
function stripMarkdown(text: string): string {
  return (
    text
      // Remove code blocks (```...```) entirely - code doesn't sound good spoken
      .replace(/```[\s\S]*?```/g, '')
      // Remove inline code (`...`)
      .replace(/`[^`]+`/g, '')
      // Remove images ![alt](url)
      .replace(/!\[.*?\]\(.*?\)/g, '')
      // Convert links [text](url) to just text
      .replace(/\[([^\]]+)\]\(.*?\)/g, '$1')
      // Remove headers (##)
      .replace(/^#{1,6}\s+/gm, '')
      // Remove bold/italic markers
      .replace(/(\*{1,3}|_{1,3})(.*?)\1/g, '$2')
      // Remove horizontal rules
      .replace(/^(-{3,}|\*{3,}|_{3,})$/gm, '')
      // Remove list markers (-, *, numbered)
      .replace(/^[\s]*[-*+]\s+/gm, '')
      .replace(/^[\s]*\d+\.\s+/gm, '')
      // Remove blockquote markers
      .replace(/^>\s*/gm, '')
      // Collapse multiple newlines to double (paragraph breaks)
      .replace(/\n{3,}/g, '\n\n')
      .trim()
  );
}

/**
 * Split text into chunks that fit within Polly's character limit.
 * Splits at paragraph boundaries first, then at sentence boundaries.
 */
function chunkText(text: string): string[] {
  const paragraphs = text.split(/\n\n/);
  const chunks: string[] = [];
  let current = '';

  for (const para of paragraphs) {
    // If this paragraph alone exceeds the limit, split by sentences
    if (para.length > CHUNK_LIMIT) {
      // Flush current chunk first
      if (current.trim()) {
        chunks.push(current.trim());
        current = '';
      }
      // Split paragraph by sentences
      const sentences = para.match(/[^.!?]+[.!?]+/g) || [para];
      for (const sentence of sentences) {
        if ((current + ' ' + sentence).length > CHUNK_LIMIT && current.trim()) {
          chunks.push(current.trim());
          current = sentence;
        } else {
          current = current ? current + ' ' + sentence : sentence;
        }
      }
      continue;
    }

    // Check if adding this paragraph exceeds the limit
    const combined = current ? current + '\n\n' + para : para;
    if (combined.length > CHUNK_LIMIT && current.trim()) {
      chunks.push(current.trim());
      current = para;
    } else {
      current = combined;
    }
  }

  // Push remaining text
  if (current.trim()) {
    chunks.push(current.trim());
  }

  return chunks;
}

/**
 * Synthesize a single text chunk to MP3 using Amazon Polly
 *
 * Returns the audio as a Buffer, or null on failure.
 */
async function synthesizeChunk(text: string, language: string): Promise<Buffer | null> {
  const voiceId = VOICE_MAP[language] || VOICE_MAP['de'];

  try {
    const command = new SynthesizeSpeechCommand({
      Text: text,
      OutputFormat: 'mp3',
      VoiceId: voiceId,
      Engine: 'neural',
      LanguageCode: language === 'en' ? 'en-US' : 'de-DE',
    });

    const response = await pollyClient.send(command);

    if (!response.AudioStream) return null;

    // Convert the readable stream to a Buffer
    const chunks: Uint8Array[] = [];
    const stream = response.AudioStream as AsyncIterable<Uint8Array>;
    for await (const chunk of stream) {
      chunks.push(chunk);
    }
    return Buffer.concat(chunks);
  } catch (err) {
    console.warn('Polly synthesis failed:', (err as Error).message);
    return null;
  }
}

/**
 * Upload an MP3 buffer to S3
 *
 * Returns the S3 key on success, or null on failure.
 */
async function uploadToS3(buffer: Buffer, s3Key: string): Promise<string | null> {
  const bucket = process.env.S3_BUCKET_NAME;
  if (!bucket) return null;

  try {
    const command = new PutObjectCommand({
      Bucket: bucket,
      Key: s3Key,
      Body: buffer,
      ContentType: 'audio/mpeg',
    });

    await s3Client.send(command);
    return s3Key;
  } catch (err) {
    console.warn('S3 upload failed:', (err as Error).message);
    return null;
  }
}

/**
 * Convert S3 key to a static URL path served by CloudFront
 *
 * CloudFront has an ordered cache behavior for /audio/* that routes
 * to the S3 origin with OAC. No pre-signed URLs needed.
 * Example: "audio/post-1-de.mp3" -> "/audio/post-1-de.mp3"
 */
function getStaticAudioPath(s3Key: string): string {
  return `/${s3Key}`;
}

/**
 * Get cached audio info from the database
 *
 * Returns the S3 key if audio was previously generated, or null.
 */
async function getCachedAudio(postId: number, language: string): Promise<string | null> {
  try {
    const result = await query(
      'SELECT s3_key FROM post_audio WHERE post_id = $1 AND language = $2',
      [postId, language]
    );
    if (result.rows.length === 0) return null;
    return result.rows[0].s3_key;
  } catch (err) {
    console.warn('Failed to read audio cache:', (err as Error).message);
    return null;
  }
}

/**
 * Save audio cache entry to the database
 */
async function saveAudioCache(postId: number, language: string, s3Key: string): Promise<void> {
  try {
    await query(
      `INSERT INTO post_audio (post_id, language, s3_key)
       VALUES ($1, $2, $3)
       ON CONFLICT (post_id, language)
       DO UPDATE SET s3_key = $3, created_at = NOW()`,
      [postId, language, s3Key]
    );
  } catch (err) {
    console.warn('Failed to save audio cache:', (err as Error).message);
  }
}

/**
 * Get audio URL for a blog post
 *
 * Main entry point. Returns a static audio path (served by CloudFront via S3),
 * or null if Polly/S3 is not available.
 *
 * Flow:
 *   1. Check DB cache for existing S3 key
 *   2. If cached, return static path /audio/post-{id}-{lang}.mp3 (instant)
 *   3. If not cached, generate audio via Polly, upload to S3, cache, return path
 *
 * First request for a post takes ~5-15 seconds (Polly synthesis + S3 upload).
 * Subsequent requests return instantly (just DB lookup + path construction).
 */
export async function getPostAudioUrl(
  postId: number,
  title: string,
  content: string,
  language: string = 'de'
): Promise<string | null> {
  // Only DE and EN are supported
  if (language !== 'de' && language !== 'en') return null;

  // Check if Polly + S3 are available
  if (!isConfigured()) return null;

  // Step 1: Check cache
  const cachedKey = await getCachedAudio(postId, language);
  if (cachedKey) {
    return getStaticAudioPath(cachedKey);
  }

  // Step 2: Prepare text for synthesis
  const plainText = stripMarkdown(content);
  const fullText = title + '.\n\n' + plainText;

  // Step 3: Chunk and synthesize
  const textChunks = chunkText(fullText);
  const audioBuffers: Buffer[] = [];

  for (const chunk of textChunks) {
    const audio = await synthesizeChunk(chunk, language);
    if (!audio) {
      console.warn(`Polly chunk failed for post ${postId}, aborting`);
      return null;
    }
    audioBuffers.push(audio);
  }

  // Step 4: Concatenate all MP3 chunks into one file
  // MP3 is frame-based, so simple concatenation works for playback
  const fullAudio = Buffer.concat(audioBuffers);

  // Step 5: Upload to S3
  const s3Key = `audio/post-${postId}-${language}.mp3`;
  const uploadedKey = await uploadToS3(fullAudio, s3Key);
  if (!uploadedKey) return null;

  // Step 6: Cache the S3 key in DB
  await saveAudioCache(postId, language, s3Key);

  // Step 7: Return static path (served by CloudFront via S3 OAC)
  return getStaticAudioPath(s3Key);
}
