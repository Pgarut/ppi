import { Env } from '../../types';
import { success, badRequest, notFound } from '../../utils/response';
import { logAktivitas } from '../../utils/log';

export async function handlePengaturanTampilan(request: Request, env: Env, url: URL): Promise<Response> {
  const method = request.method;
  const path = new URL(request.url).pathname;
  const isList = path.endsWith('/api/admin/pengaturan-tampilan');
  const isDetail = path.startsWith('/api/admin/pengaturan-tampilan/');

  // GET all settings
  if (method === 'GET' && isList) {
    const rows = await env.DB.prepare('SELECT key, value FROM pengaturan ORDER BY key').all();
    return success(rows.results);
  }

  // GET single setting
  if (method === 'GET' && isDetail) {
    const key = path.split('/').pop();
    const row = await env.DB.prepare('SELECT key, value FROM pengaturan WHERE key = ?').bind(key).first();
    if (!row) return notFound('Pengaturan tidak ditemukan');
    return success(row);
  }

  // PUT update all settings
  if (method === 'PUT' && isList) {
    const body = await request.json() as Record<string, string>;
    const allowedKeys = ['hero_title', 'hero_subtitle', 'logo_url', 'background_url'];
    const entries = Object.entries(body).filter(([k]) => allowedKeys.includes(k));

    for (const [key, value] of entries) {
      await env.DB.prepare(
        'INSERT INTO pengaturan (key, value, updated_at) VALUES (?, ?, datetime(\'now\')) ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at'
      ).bind(key, value).run();
    }

    await logAktivitas(env, { user_id: 0, aksi: 'update', modul: 'pengaturan_tampilan', detail: 'Update tampilan login', ip_address: request.headers.get('CF-Connecting-IP') || 'unknown' });
    return success({ message: 'Pengaturan tersimpan' });
  }

  return badRequest('Method tidak diizinkan');
}
