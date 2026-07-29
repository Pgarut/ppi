import { Env } from '../types';
import { success } from '../utils/response';

export async function handleHealth(env: Env): Promise<Response> {
  try {
    // Verifikasi koneksi database
    const dbCheck = await env.DB.prepare('SELECT 1 as ok').first<{ ok: number }>();
    const dbOk = dbCheck?.ok === 1;

    return success({
      status: dbOk ? 'ok' : 'degraded',
      timestamp: new Date().toISOString(),
      database: dbOk ? 'connected' : 'error',
      version: '1.0.0',
    });
  } catch {
    return success({
      status: 'degraded',
      timestamp: new Date().toISOString(),
      database: 'disconnected',
      version: '1.0.0',
    });
  }
}
