/**
 * comprehend.ts - Amazon Comprehend integration for sentiment analysis
 *
 * Analyzes comment text using AWS Comprehend to detect sentiment
 * (POSITIVE, NEGATIVE, NEUTRAL, MIXED) and extract key phrases.
 *
 * Uses the same graceful-degradation pattern as telegram.ts:
 * - If AWS credentials are not available (local dev), silently returns null
 * - Errors are logged but never break the calling code
 *
 * Required: @aws-sdk/client-comprehend package
 * Region: reads AWS_REGION env var, defaults to 'eu-central-1'
 */

import {
  ComprehendClient,
  DetectSentimentCommand,
  DetectKeyPhrasesCommand,
} from '@aws-sdk/client-comprehend';

// Sentiment result returned to the caller
export interface SentimentResult {
  sentiment: 'POSITIVE' | 'NEGATIVE' | 'NEUTRAL' | 'MIXED';
  confidence: number;
}

// Key phrase result returned to the caller
export interface KeyPhraseResult {
  text: string;
  confidence: number;
}

// Create the Comprehend client once (reused across requests)
// Region comes from env var or defaults to eu-central-1 (same as EKS cluster)
const client = new ComprehendClient({
  region: process.env.AWS_REGION || 'eu-central-1',
});

/**
 * Check if Comprehend is available
 *
 * On EKS, the pod gets AWS credentials via IRSA (IAM Roles for Service Accounts).
 * In local dev, there are typically no credentials, so we skip silently.
 * We detect this by checking if AWS_REGION or AWS_DEFAULT_REGION is set,
 * which indicates we're running in an AWS environment.
 * Even if this check passes, the actual API call may still fail -- that's
 * caught by the try/catch in each function.
 */
function isConfigured(): boolean {
  return !!(process.env.AWS_REGION || process.env.AWS_DEFAULT_REGION);
}

/**
 * Analyze sentiment of a text using Amazon Comprehend
 *
 * Calls DetectSentiment with German language code ('de') since
 * the blog and its comments are in German.
 *
 * Returns the dominant sentiment and its confidence score (0.0 - 1.0).
 * Returns null if Comprehend is not available or the call fails.
 */
export async function analyzeSentiment(text: string): Promise<SentimentResult | null> {
  if (!isConfigured()) {
    return null;
  }

  try {
    const command = new DetectSentimentCommand({
      Text: text,
      LanguageCode: 'de',
    });

    const response = await client.send(command);

    // Extract the dominant sentiment and its confidence score
    const sentiment = response.Sentiment as SentimentResult['sentiment'];
    const scores = response.SentimentScore;

    // Pick the confidence for the dominant sentiment
    let confidence = 0;
    if (scores) {
      switch (sentiment) {
        case 'POSITIVE':
          confidence = scores.Positive ?? 0;
          break;
        case 'NEGATIVE':
          confidence = scores.Negative ?? 0;
          break;
        case 'NEUTRAL':
          confidence = scores.Neutral ?? 0;
          break;
        case 'MIXED':
          confidence = scores.Mixed ?? 0;
          break;
      }
    }

    return { sentiment, confidence: Math.round(confidence * 1000) / 1000 };
  } catch (err) {
    console.warn('Comprehend sentiment analysis failed:', (err as Error).message);
    return null;
  }
}

/**
 * Detect key phrases in a text using Amazon Comprehend
 *
 * Calls DetectKeyPhrases with German language code ('de').
 * Returns the top 5 key phrases sorted by confidence (highest first).
 * Returns null if Comprehend is not available or the call fails.
 */
export async function detectKeyPhrases(text: string): Promise<KeyPhraseResult[] | null> {
  if (!isConfigured()) {
    return null;
  }

  try {
    const command = new DetectKeyPhrasesCommand({
      Text: text,
      LanguageCode: 'de',
    });

    const response = await client.send(command);

    if (!response.KeyPhrases || response.KeyPhrases.length === 0) {
      return [];
    }

    // Sort by confidence (highest first), take top 5
    const phrases = response.KeyPhrases.filter((kp) => kp.Text && kp.Score !== undefined)
      .sort((a, b) => (b.Score ?? 0) - (a.Score ?? 0))
      .slice(0, 5)
      .map((kp) => ({
        text: kp.Text!,
        confidence: Math.round((kp.Score ?? 0) * 1000) / 1000,
      }));

    return phrases;
  } catch (err) {
    console.warn('Comprehend key phrase detection failed:', (err as Error).message);
    return null;
  }
}
