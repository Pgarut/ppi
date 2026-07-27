import { Env } from '../types';
import { corsHeaders } from '../utils/response';

interface RateLimitEntry {
  count: number;
  windowStart: number;
}

interface BruteForceEntry {
  attempts: number;
  lockUntil: number;
  lastAttempt: number;
}

const generalLimits = new Map<string, RateLimitEntry>();
const bruteForceLimits = new Map<string, BruteForceEntry>();

const GENERAL_WINDOW_MS = 60_000;
const GENERAL_MAX_REQUESTS = 100;
const BRUTE_MAX_ATTEMPTS = 5;
const BRUTE_WINDOW_MS = 15 * 60_000;
const BRUTE_LOCK_MS = 15 * 60_000;
const CLEANUP_INTERVAL_MS = 60_000;

let lastCleanup = Date.now();

function cleanup() {
  const now = Date.now();
  if (now - lastCleanup < CLEANUP_INTERVAL_MS) return;
  lastCleanup = now;

  for (const [key, entry] of generalLimits) {
    if (now - entry.windowStart > GENERAL_WINDOW_MS) generalLimits.delete(key);
  }
  for (const [key, entry] of bruteForceLimits) {
    if (now - entry.lastAttempt > BRUTE_WINDOW_MS && now > entry.lockUntil) bruteForceLimits.delete(key);
  }
}

function rateLimitResponse(message: string, retryAfter: number, code = 'RATE_LIMITED'): Response {
  return new Response(
    JSON.stringify({ success: false, error: { code, message } }),
    {
      status: 429,
      headers: {
        'Content-Type': 'application/json',
        'Retry-After': String(retryAfter),
        ...corsHeaders(),
      },
    },
  );
}

export async function generalRateLimit(request: Request, _env: Env): Promise<Response | null> {
  cleanup();

  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const now = Date.now();

  let entry = generalLimits.get(ip);
  if (!entry || now - entry.windowStart > GENERAL_WINDOW_MS) {
    entry = { count: 0, windowStart: now };
    generalLimits.set(ip, entry);
  }

  entry.count++;

  if (entry.count > GENERAL_MAX_REQUESTS) {
    const retryAfter = Math.ceil((entry.windowStart + GENERAL_WINDOW_MS - now) / 1000);
    return rateLimitResponse('Terlalu banyak permintaan. Coba lagi dalam beberapa saat.', retryAfter);
  }

  return null;
}

export async function bruteForceCheck(
  username: string,
  request: Request,
  env: Env,
): Promise<Response | null> {
  cleanup();

  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const key = `${ip}:${username}`;
  const now = Date.now();

  let entry = bruteForceLimits.get(key);

  if (entry && entry.lockUntil > now) {
    const retryAfter = Math.ceil((entry.lockUntil - now) / 1000);

    try {
      await env.DB.prepare(
        "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address, created_at) VALUES (?, 'brute_force_blocked', 'auth', ?, ?, datetime('now'))"
      ).bind(0, `Brute force blocked untuk username=${username}`, ip).run();
    } catch {
      // log gagal tidak menggagalkan response
    }

    return rateLimitResponse(
      'Akun diblokir sementara karena terlalu banyak percobaan gagal. Coba lagi dalam 15 menit.',
      retryAfter,
      'ACCOUNT_LOCKED',
    );
  }

  if (!entry || now - entry.lastAttempt > BRUTE_WINDOW_MS) {
    entry = { attempts: 0, lockUntil: 0, lastAttempt: now };
    bruteForceLimits.set(key, entry);
  }

  return null;
}

export async function bruteForceRecordFailure(
  username: string,
  request: Request,
  env: Env,
): Promise<void> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const key = `${ip}:${username}`;
  const now = Date.now();

  let entry = bruteForceLimits.get(key);
  if (!entry || now - entry.lastAttempt > BRUTE_WINDOW_MS) {
    entry = { attempts: 0, lockUntil: 0, lastAttempt: now };
  }

  entry.attempts++;
  entry.lastAttempt = now;

  if (entry.attempts >= BRUTE_MAX_ATTEMPTS) {
    entry.lockUntil = now + BRUTE_LOCK_MS;

    try {
      await env.DB.prepare(
        "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address, created_at) VALUES (?, 'brute_force_lock', 'auth', ?, ?, datetime('now'))"
      ).bind(0, `Akun dikunci: username=${username} setelah ${entry.attempts} percobaan gagal`, ip).run();
    } catch {
      // log gagal tidak menggagalkan proses
    }
  }

  bruteForceLimits.set(key, entry);
}

export async function bruteForceRecordSuccess(username: string): Promise<void> {
  for (const [key] of bruteForceLimits) {
    if (key.endsWith(`:${username}`)) {
      bruteForceLimits.delete(key);
    }
  }
}
