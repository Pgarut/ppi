import { Env, UserPayload } from '../../types';
import { success, badRequest, notFound } from '../../utils/response';
import { logAktivitas } from '../../utils/log';

export async function handlePengaturanTampilan(request: Request, env: Env, user: UserPayload, url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const method = request.method;
  const path = new URL(request.url).pathname;
  const isList = path.endsWith('/api/admin/pengaturan-tampilan');
  const isDetail = path.startsWith('/api/admin/pengaturan-tampilan/');

  if (method === 'GET' && isList) {
    const rows = await env.DB.prepare('SELECT key, value FROM pengaturan ORDER BY key').all();
    return success(rows.results);
  }

  if (method === 'GET' && isDetail) {
    const key = path.split('/').pop();
    const row = await env.DB.prepare('SELECT key, value FROM pengaturan WHERE key = ?').bind(key).first();
    if (!row) return notFound('Pengaturan tidak ditemukan');
    return success(row);
  }

  if (method === 'PUT' && isList) {
    const body = await request.json() as Record<string, string>;
    const allowedKeys = ['hero_title', 'hero_subtitle', 'logo_url', 'background_url'];
    const entries = Object.entries(body).filter(([k]) => allowedKeys.includes(k));

    for (const [key, value] of entries) {
      await env.DB.prepare(
        'INSERT INTO pengaturan (key, value, updated_at) VALUES (?, ?, datetime(\'now\')) ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at'
      ).bind(key, value).run();
    }

    await logAktivitas(env, { user_id: user.sub, aksi: 'update', modul: 'pengaturan_tampilan', detail: 'Update tampilan login', ip_address: ip });
    return success({ message: 'Pengaturan tersimpan' });
  }

  return badRequest('Method tidak diizinkan');
}

export async function handleProfilSekolah(request: Request, env: Env, user: UserPayload): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const method = request.method;

  if (method === 'GET') {
    const rows = await env.DB.prepare(
      "SELECT key, value FROM pengaturan WHERE key IN ('profil_nama', 'profil_alamat', 'profil_telepon', 'profil_email')"
    ).all<{ key: string; value: string }>();
    const result: Record<string, string> = {};
    for (const r of rows.results) {
      const k = r.key.replace('profil_', '');
      result[k] = r.value;
    }
    return success(result);
  }

  if (method === 'PUT') {
    const body = await request.json() as Record<string, string>;
    const allowedKeys = ['nama', 'alamat', 'telepon', 'email'];

    for (const k of allowedKeys) {
      const val = body[k] ?? '';
      await env.DB.prepare(
        "INSERT INTO pengaturan (key, value, updated_at) VALUES (?, ?, datetime('now')) ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at"
      ).bind(`profil_${k}`, val).run();
    }

    await logAktivitas(env, { user_id: user.sub, aksi: 'update', modul: 'profil_sekolah', detail: 'Update profil sekolah', ip_address: ip });
    return success({ message: 'Profil sekolah tersimpan' });
  }

  return badRequest('Method tidak didukung');
}
