/**
 * telegram.ts - Telegram Bot notification service
 *
 * Sends notifications to a Telegram chat when new comments are posted.
 * Uses the Telegram Bot API via native fetch (Node 18+).
 *
 * Required env vars:
 *   TELEGRAM_BOT_TOKEN  - Bot token from @BotFather
 *   TELEGRAM_CHAT_ID    - Chat/group ID to send notifications to
 *
 * If either env var is missing, notifications are silently skipped.
 * Notification failures never block the comment creation response.
 */

// Base URL for the Telegram Bot API
const TELEGRAM_API = 'https://api.telegram.org/bot';

/**
 * Check if Telegram notifications are configured
 */
function isConfigured(): boolean {
  return !!(process.env.TELEGRAM_BOT_TOKEN && process.env.TELEGRAM_CHAT_ID);
}

/**
 * Send a message to the configured Telegram chat
 *
 * Uses HTML parse mode for basic formatting (bold, italic, links).
 * Silently catches errors so it never breaks the calling code.
 */
async function sendMessage(text: string): Promise<void> {
  if (!isConfigured()) return;

  const url = `${TELEGRAM_API}${process.env.TELEGRAM_BOT_TOKEN}/sendMessage`;

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: process.env.TELEGRAM_CHAT_ID,
        text: text,
        parse_mode: 'HTML',
        // Disable link previews to keep messages compact
        disable_web_page_preview: true,
      }),
    });

    if (!response.ok) {
      const err = await response.text();
      console.warn('Telegram notification failed:', response.status, err);
    }
  } catch (err) {
    console.warn('Telegram notification error:', (err as Error).message);
  }
}

/**
 * Escape special HTML characters for Telegram messages
 */
function escapeHtml(text: string): string {
  return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

/**
 * Send a "new comment" notification
 *
 * Called after a comment is successfully created in the database.
 * Includes author name, post title, and a preview of the comment text.
 */
export async function notifyNewComment(data: {
  authorName: string;
  postTitle: string;
  content: string;
  postId: number;
  commentId: number;
}): Promise<void> {
  if (!isConfigured()) return;

  // Truncate long comments to keep the message readable
  const preview = data.content.length > 200 ? data.content.substring(0, 200) + '...' : data.content;

  const message =
    `<b>Neuer Kommentar</b>\n\n` +
    `<b>Post:</b> ${escapeHtml(data.postTitle)}\n` +
    `<b>Von:</b> ${escapeHtml(data.authorName)}\n\n` +
    `<i>${escapeHtml(preview)}</i>\n\n` +
    `Status: pending (Moderation noetig)`;

  await sendMessage(message);
}
