import { Env, UserPayload } from '../../types';
import { success, error, badRequest, notFound } from '../../utils/response';
import { generateApiKey, hashApiKey } from '../../middleware/api_key';

// ============================================================
// Admin API Keys Management (CRUD)
// ============================================================

export async function handleAdminApiKeys(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const method = request.method;
  const subPath = pathParts.slice(2).join('/');

  // POST /api/admin/api-keys - Generate new API Key
  if (subPath === 'api-keys' && method === 'POST') {
    return createApiKey(request, env, user);
  }

  // GET /api/admin/api-keys - List all API Keys
  if (subPath === 'api-keys' && method === 'GET') {
    return listApiKeys(request, env, user, url);
  }

  // GET /api/admin/api-keys/:id - Get single API Key (masked)
  if (pathParts.length >= 4 && pathParts[2] === 'api-keys' && method === 'GET') {
    const id = parseInt(pathParts[3]);
    if (isNaN(id)) return badRequest('ID tidak valid');
    return getApiKey(env, user, id);
  }

  // PUT /api/admin/api-keys/:id - Update API Key (toggle aktif, update permissions, rate_limit)
  if (pathParts.length >= 4 && pathParts[2] === 'api-keys' && method === 'PUT') {
    const id = parseInt(pathParts[3]);
    if (isNaN(id)) return badRequest('ID tidak valid');
    return updateApiKey(request, env, user, id);
  }

  // DELETE /api/admin/api-keys/:id - Delete API Key
  if (pathParts.length >= 4 && pathParts[2] === 'api-keys' && method === 'DELETE') {
    const id = parseInt(pathParts[3]);
    if (isNaN(id)) return badRequest('ID tidak valid');
    return deleteApiKey(request, env, user, id);
  }

  return error('Not Found', 404);
}

async function createApiKey(request: Request, env: Env, user: UserPayload): Promise<Response> {
  let body: { nama_pihak: string; permissions?: string; rate_limit?: number };
  try {
    body = await request.json();
  } catch {
    return badRequest('Invalid JSON body');
  }

  const { nama_pihak, permissions = 'readwrite', rate_limit = 5000 } = body;

  if (!nama_pihak || nama_pihak.trim() === '') {
    return badRequest('nama_pihak wajib diisi');
  }

  const validPermissions = ['read', 'write', 'readwrite'];
  if (!validPermissions.includes(permissions)) {
    return badRequest(`permissions harus salah satu dari: ${validPermissions.join(', ')}`);
  }

  if (rate_limit < 1 || rate_limit > 100000) {
    return badRequest('rate_limit harus antara 1 - 100000');
  }

  // Generate API Key
  const plainApiKey = generateApiKey();
  const apiKeyHash = await hashApiKey(plainApiKey);

  // Simpan ke database
  const result = await env.DB.prepare(
    `INSERT INTO api_keys (nama_pihak, api_key_hash, permissions, rate_limit, is_aktif)
     VALUES (?, ?, ?, ?, 1)`
  ).bind(nama_pihak.trim(), apiKeyHash, permissions, rate_limit).run();

  const apiKeyId = result.meta.last_row_id;

  // Log aktivitas
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'api_keys', ?, ?)"
  ).bind(user.sub, `Generate API Key untuk ${nama_pihak} (ID: ${apiKeyId})`, ip).run();

  // Return plain API Key HANYA SEKALI (harus disimpan admin)
  return success({
    id: apiKeyId,
    api_key: plainApiKey, // INI HANYA DITAMPILKAN SEKALI!
    nama_pihak: nama_pihak.trim(),
    permissions,
    rate_limit,
    is_aktif: true,
    created_at: new Date().toISOString(),
    warning: 'Simpan API Key ini sekarang! Tidak dapat ditampilkan lagi.',
  }, 'API Key berhasil dibuat');
}

async function listApiKeys(request: Request, env: Env, user: UserPayload, url: URL): Promise<Response> {
  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const perPage = Math.min(100, Math.max(1, parseInt(url.searchParams.get('per_page') || '20')));
  const offset = (page - 1) * perPage;
  const search = url.searchParams.get('search') || '';
  const status = url.searchParams.get('status'); // 'aktif' | 'nonaktif' | 'all'

  let whereClause = 'WHERE 1=1';
  const params: (string | number)[] = [];

  if (search) {
    whereClause += ' AND nama_pihak LIKE ?';
    params.push(`%${search}%`);
  }

  if (status === 'aktif') {
    whereClause += ' AND is_aktif = 1';
  } else if (status === 'nonaktif') {
    whereClause += ' AND is_aktif = 0';
  }

  const countResult = await env.DB.prepare(
    `SELECT COUNT(*) as total FROM api_keys ${whereClause}`
  ).bind(...params).first<{ total: number }>();

  const total = countResult?.total || 0;

  const rows = await env.DB.prepare(
    `SELECT id, nama_pihak, permissions, rate_limit, is_aktif, last_used_at, created_at, updated_at
     FROM api_keys ${whereClause}
     ORDER BY created_at DESC LIMIT ? OFFSET ?`
  ).bind(...params, perPage, offset).all();

  // Mask sensitive data - don't return hash
  const items = rows.results.map((row: any) => ({
    ...row,
    is_aktif: Boolean(row.is_aktif),
    last_used_at: row.last_used_at || null,
  }));

  return success({
    items,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
  });
}

async function getApiKey(env: Env, user: UserPayload, id: number): Promise<Response> {
  const row = await env.DB.prepare(
    `SELECT id, nama_pihak, permissions, rate_limit, is_aktif, last_used_at, created_at, updated_at
     FROM api_keys WHERE id = ?`
  ).bind(id).first();

  if (!row) return notFound('API Key');

  return success({
    ...row,
    is_aktif: Boolean(row.is_aktif),
    last_used_at: row.last_used_at || null,
  });
}

async function updateApiKey(request: Request, env: Env, user: UserPayload, id: number): Promise<Response> {
  let body: { nama_pihak?: string; permissions?: string; rate_limit?: number; is_aktif?: boolean };
  try {
    body = await request.json();
  } catch {
    return badRequest('Invalid JSON body');
  }

  const { nama_pihak, permissions, rate_limit, is_aktif } = body;

  // Cek existing
  const existing = await env.DB.prepare('SELECT id FROM api_keys WHERE id = ?').bind(id).first();
  if (!existing) return notFound('API Key');

  const updates: string[] = [];
  const params: (string | number | boolean)[] = [];

  if (nama_pihak !== undefined) {
    if (nama_pihak.trim() === '') return badRequest('nama_pihak tidak boleh kosong');
    updates.push('nama_pihak = ?');
    params.push(nama_pihak.trim());
  }

  if (permissions !== undefined) {
    const validPermissions = ['read', 'write', 'readwrite'];
    if (!validPermissions.includes(permissions)) {
      return badRequest(`permissions harus salah satu dari: ${validPermissions.join(', ')}`);
    }
    updates.push('permissions = ?');
    params.push(permissions);
  }

  if (rate_limit !== undefined) {
    if (rate_limit < 1 || rate_limit > 100000) return badRequest('rate_limit harus antara 1 - 100000');
    updates.push('rate_limit = ?');
    params.push(rate_limit);
  }

  if (is_aktif !== undefined) {
    updates.push('is_aktif = ?');
    params.push(is_aktif ? 1 : 0);
  }

  if (updates.length === 0) return badRequest('Tidak ada data yang diupdate');

  updates.push('updated_at = datetime(\'now\')');
  params.push(id);

  await env.DB.prepare(
    `UPDATE api_keys SET ${updates.join(', ')} WHERE id = ?`
  ).bind(...params).run();

  // Log aktivitas
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'api_keys', ?, ?)"
  ).bind(user.sub, `Update API Key ID: ${id}`, ip).run();

  return success({ message: 'API Key berhasil diupdate' });
}

async function deleteApiKey(request: Request, env: Env, user: UserPayload, id: number): Promise<Response> {
  const existing = await env.DB.prepare('SELECT id, nama_pihak FROM api_keys WHERE id = ?').bind(id).first();
  if (!existing) return notFound('API Key');

  await env.DB.prepare('DELETE FROM api_keys WHERE id = ?').bind(id).run();

  // Log aktivitas
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'delete', 'api_keys', ?, ?)"
  ).bind(user.sub, `Hapus API Key: ${existing.nama_pihak} (ID: ${id})`, ip).run();

  return success({ message: 'API Key berhasil dihapus' });
}