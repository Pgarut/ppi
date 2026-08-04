import { Env } from '../types';

const MAX_SESSIONS = 2;

/**
 * Buat session baru saat login.
 * Jika user sudah memiliki >= 2 session aktif, revoke session tertua.
 */
export async function createSession(
  userId: number,
  tokenHash: string,
  userAgent: string | null,
  env: Env
): Promise<number> {
  // Hitung session aktif
  const { results } = await env.DB.prepare(
    'SELECT id FROM sessions WHERE user_id = ? AND is_active = 1 ORDER BY created_at ASC'
  ).bind(userId).all<{ id: number }>();

  // Revoke session tertua jika sudah mencapai batas
  if (results.length >= MAX_SESSIONS) {
    const toRevoke = results.slice(0, results.length - MAX_SESSIONS + 1);
    for (const s of toRevoke) {
      await env.DB.prepare(
        "UPDATE sessions SET is_active = 0, revoked_at = datetime('now') WHERE id = ?"
      ).bind(s.id).run();
    }
  }

  // Insert session baru
  const result = await env.DB.prepare(
    'INSERT INTO sessions (user_id, user_agent, token_hash) VALUES (?, ?, ?)'
  ).bind(userId, userAgent || 'unknown', tokenHash).run();

  return result.meta.last_row_id as number;
}

/**
 * Validasi session berdasarkan token hash.
 * Return true jika session aktif dan valid.
 */
export async function validateSession(
  tokenHash: string,
  env: Env
): Promise<boolean> {
  const session = await env.DB.prepare(
    'SELECT id FROM sessions WHERE token_hash = ? AND is_active = 1'
  ).bind(tokenHash).first<{ id: number }>();

  if (!session) return false;

  // Update last_active
  await env.DB.prepare(
    "UPDATE sessions SET last_active = datetime('now') WHERE id = ?"
  ).bind(session.id).run();

  return true;
}

/**
 * Revoke session tertentu berdasarkan token hash (untuk logout).
 */
export async function revokeSession(
  tokenHash: string,
  env: Env
): Promise<void> {
  await env.DB.prepare(
    "UPDATE sessions SET is_active = 0, revoked_at = datetime('now') WHERE token_hash = ? AND is_active = 1"
  ).bind(tokenHash).run();
}

/**
 * Revoke semua session aktif untuk user tertentu (opsional: logout all devices).
 */
export async function revokeAllUserSessions(
  userId: number,
  env: Env
): Promise<void> {
  await env.DB.prepare(
    "UPDATE sessions SET is_active = 0, revoked_at = datetime('now') WHERE user_id = ? AND is_active = 1"
  ).bind(userId).run();
}

/**
 * Generate hash sederhana dari token untuk penyimpanan di DB.
 * Menggunakan SHA-256 via Web Crypto API.
 */
export async function hashToken(token: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(token);
  const hashBuffer = await crypto.subtle.digest('SHA-256', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

/**
 * Cleanup session yang sudah revoked atau sangat lama (> 8 hari).
 */
export async function cleanupOldSessions(env: Env): Promise<void> {
  await env.DB.prepare(
    "DELETE FROM sessions WHERE is_active = 0 AND revoked_at < datetime('now', '-8 days')"
  ).run();
}
