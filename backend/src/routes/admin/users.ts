import bcrypt from 'bcryptjs';
import { Env, UserPayload } from '../../types';
import { success, created, notFound, badRequest, list, getById, remove } from '../../utils/crud';
import { CrudConfig } from '../../utils/crud';

const userCfg: CrudConfig = {
  table: 'users',
  columns: ['username', 'role', 'guru_id', 'is_active'],
  label: 'User',
  searchFields: ['username'],
  timestamp: true,
};

export async function handleAdminUsers(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const isList = pathParts.length === 3 && request.method === 'GET';
  const isById = pathParts.length === 4 && request.method === 'GET';
  const isCreate = pathParts.length === 3 && request.method === 'POST';
  const isUpdate = pathParts.length === 4 && request.method === 'PUT';
  const isDelete = pathParts.length === 4 && request.method === 'DELETE';

  try {
    if (isList) return list(env, userCfg, url, user);

    if (isById) return getById(env, userCfg, parseInt(pathParts[3]));

    if (isCreate) {
      const body = await request.json() as Record<string, unknown>;
      const { username, password, role, guru_id, is_active } = body;

      if (!username || !password || !role) {
        return badRequest('Field username, password, dan role wajib diisi');
      }

      const validRoles = ['admin', 'kepala_sekolah', 'wakil_kurikulum', 'guru_mapel_wali_kelas', 'guru_bk'];
      if (!validRoles.includes(role as string)) {
        return badRequest(`Role tidak valid. Pilihan: ${validRoles.join(', ')}`);
      }

      const passwordHash = await bcrypt.hash(password as string, 10);

      try {
        const result = await env.DB.prepare(
          "INSERT INTO users (username, password_hash, role, guru_id, is_active, created_at, updated_at) VALUES (?, ?, ?, ?, ?, datetime('now'), datetime('now'))"
        ).bind(username, passwordHash, role, guru_id || null, is_active ?? 1).run();

        await env.DB.prepare(
          "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'users', ?, ?)"
        ).bind(user.sub, `Tambah user ${username}`, ip).run();

        return created({ id: result.meta?.last_row_id });
      } catch (e) {
        const msg = e instanceof Error ? e.message : '';
        if (msg.includes('UNIQUE')) return badRequest('Username sudah digunakan');
        return badRequest(msg);
      }
    }

    if (isUpdate) {
      const body = await request.json() as Record<string, unknown>;
      const id = parseInt(pathParts[3]);

      const existing = await env.DB.prepare('SELECT id FROM users WHERE id = ?').bind(id).first();
      if (!existing) return notFound('User');

      const setClauses: string[] = [];
      const vals: unknown[] = [];

      if (body.username !== undefined) {
        setClauses.push('username = ?');
        vals.push(body.username);
      }
      if (body.password !== undefined) {
        const hash = await bcrypt.hash(body.password as string, 10);
        setClauses.push('password_hash = ?');
        vals.push(hash);
      }
      if (body.role !== undefined) {
        setClauses.push('role = ?');
        vals.push(body.role);
      }
      if (body.guru_id !== undefined) {
        setClauses.push('guru_id = ?');
        vals.push(body.guru_id);
      }
      if (body.is_active !== undefined) {
        setClauses.push('is_active = ?');
        vals.push(body.is_active);
      }

      if (setClauses.length === 0) return badRequest('Tidak ada field yang diupdate');

      setClauses.push("updated_at = datetime('now')");
      vals.push(id);

      try {
        await env.DB.prepare(`UPDATE users SET ${setClauses.join(', ')} WHERE id = ?`).bind(...vals).run();
        await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'users', ?, ?)")
          .bind(user.sub, `Update user id=${id}`, ip).run();
        return success({ id });
      } catch (e) {
        return badRequest(e instanceof Error ? e.message : 'Update gagal');
      }
    }

    if (isDelete) return remove(env, userCfg, parseInt(pathParts[3]), user, ip);
  } catch (e) {
    return badRequest(e instanceof Error ? e.message : 'Invalid request');
  }

  return badRequest('Method tidak didukung');
}

export async function handleHakAkses(request: Request, env: Env, user: UserPayload, pathParts: string[]): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

  if (request.method === 'GET') {
    const rows = await env.DB.prepare('SELECT * FROM hak_akses_modul ORDER BY role, modul').all();
    return success(rows.results);
  }

  if (request.method === 'POST') {
    const body = await request.json() as Record<string, unknown>;
    const { role, modul, aksi } = body;

    if (!role || !modul || !aksi) {
      return badRequest('Field role, modul, dan aksi wajib diisi');
    }

    const validAksi = ['view', 'create', 'edit', 'delete', 'validate'];
    if (!validAksi.includes(aksi as string)) {
      return badRequest(`Aksi tidak valid. Pilihan: ${validAksi.join(', ')}`);
    }

    try {
      await env.DB.prepare(
        'INSERT INTO hak_akses_modul (role, modul, aksi) VALUES (?, ?, ?)'
      ).bind(role, modul, aksi).run();

      await env.DB.prepare(
        "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'hak_akses', ?, ?)"
      ).bind(user.sub, `Tambah hak akses: ${role} - ${modul} - ${aksi}`, ip).run();

      return created({ role, modul, aksi });
    } catch (e) {
      return badRequest(e instanceof Error ? e.message : 'Gagal tambah hak akses');
    }
  }

  if (request.method === 'DELETE') {
    const id = parseInt(pathParts[3]);
    if (!id) return badRequest('ID diperlukan');

    const deleted = await env.DB.prepare('SELECT role, modul, aksi FROM hak_akses_modul WHERE id = ?').bind(id).first<{ role: string; modul: string; aksi: string }>();
    await env.DB.prepare('DELETE FROM hak_akses_modul WHERE id = ?').bind(id).run();
    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'delete', 'hak_akses', ?, ?)")
      .bind(user.sub, `Hapus hak akses: ${deleted?.role} - ${deleted?.modul} - ${deleted?.aksi}`, ip).run();
    return success({ id });
  }

  return badRequest('Method tidak didukung');
}
