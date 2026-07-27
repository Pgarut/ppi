import { Env, UserPayload } from '../types';
import { success, created, notFound, badRequest } from './response';
export { success, created, notFound, badRequest };

type Row = Record<string, unknown>;

export interface CrudConfig {
  table: string;
  columns: string[];
  label: string;
  searchFields?: string[];
  filterFields?: string[];
  timestamp?: boolean;
}

function logAction(env: Env, userId: number, aksi: string, modul: string, detail: string, ip: string) {
  return env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, ?, ?, ?, ?)"
  ).bind(userId, aksi, modul, detail, ip).run();
}

export async function list(env: Env, cfg: CrudConfig, url: URL, user: UserPayload) {
  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const perPage = Math.min(100, Math.max(1, parseInt(url.searchParams.get('per_page') || '20')));
  const search = url.searchParams.get('search') || '';
  const offset = (page - 1) * perPage;

  let where = '';
  const bindings: unknown[] = [];

  if (search && cfg.searchFields && cfg.searchFields.length > 0) {
    const conditions = cfg.searchFields.map(f => `${f} LIKE ?`);
    where = `WHERE ${conditions.join(' OR ')}`;
    for (let i = 0; i < cfg.searchFields.length; i++) {
      bindings.push(`%${search}%`);
    }
  }

  // Support filter params: ?jabatan=wali_kelas
  for (const key of cfg.filterFields || []) {
    const val = url.searchParams.get(key);
    if (val) {
      const prefix = where ? ' AND' : 'WHERE';
      where += `${prefix} ${key} = ?`;
      bindings.push(val);
    }
  }

  const countResult = await env.DB.prepare(
    `SELECT COUNT(*) as total FROM ${cfg.table} ${where}`
  ).bind(...bindings).first<{ total: number }>();

  const total = countResult?.total || 0;

  bindings.push(perPage, offset);
  const rows = await env.DB.prepare(
    `SELECT * FROM ${cfg.table} ${where} ORDER BY id DESC LIMIT ? OFFSET ?`
  ).bind(...bindings).all();

  return success({
    items: rows.results,
    pagination: {
      page,
      per_page: perPage,
      total,
      total_pages: Math.ceil(total / perPage),
    },
  });
}

export async function getById(env: Env, cfg: CrudConfig, id: number) {
  const row = await env.DB.prepare(
    `SELECT * FROM ${cfg.table} WHERE id = ?`
  ).bind(id).first<Row>();

  if (!row) return notFound(cfg.label);
  return success(row);
}

export async function create(env: Env, cfg: CrudConfig, body: Record<string, unknown>, user: UserPayload, ip: string) {
  const now = new Date().toISOString().replace('T', ' ').split('.')[0];
  const cols = [...cfg.columns];
  const vals: unknown[] = [];

  if (cfg.timestamp) {
    cols.push('created_at', 'updated_at');
    vals.push(now, now);
  }

  for (const col of cfg.columns) {
    const val = body[col];
    if (val === undefined || val === null) {
      return badRequest(`Field '${col}' wajib diisi`);
    }
    vals.push(val);
  }

  const placeholders = vals.map(() => '?').join(', ');

  try {
    const result = await env.DB.prepare(
      `INSERT INTO ${cfg.table} (${cols.join(', ')}) VALUES (${placeholders})`
    ).bind(...vals).run();

    await logAction(env, user.sub, 'create', cfg.table, `Tambah ${cfg.label}`, ip);

    return created({ id: result.meta?.last_row_id });
  } catch (e) {
    const msg = e instanceof Error ? e.message : 'Database error';
    if (msg.includes('UNIQUE')) {
      return badRequest(`${cfg.label} sudah ada (duplikat)`);
    }
    return badRequest(msg);
  }
}

export async function update(env: Env, cfg: CrudConfig, id: number, body: Record<string, unknown>, user: UserPayload, ip: string) {
  const existing = await env.DB.prepare(
    `SELECT id FROM ${cfg.table} WHERE id = ?`
  ).bind(id).first<Row>();

  if (!existing) return notFound(cfg.label);

  const setClauses: string[] = [];
  const vals: unknown[] = [];

  for (const col of cfg.columns) {
    if (body[col] !== undefined) {
      setClauses.push(`${col} = ?`);
      vals.push(body[col]);
    }
  }

  if (setClauses.length === 0) {
    return badRequest('Tidak ada field yang diupdate');
  }

  if (cfg.timestamp) {
    const now = new Date().toISOString().replace('T', ' ').split('.')[0];
    setClauses.push("updated_at = ?");
    vals.push(now);
  }

  vals.push(id);

  try {
    await env.DB.prepare(
      `UPDATE ${cfg.table} SET ${setClauses.join(', ')} WHERE id = ?`
    ).bind(...vals).run();

    await logAction(env, user.sub, 'update', cfg.table, `Update ${cfg.label} id=${id}`, ip);

    return success({ id });
  } catch (e) {
    const msg = e instanceof Error ? e.message : 'Database error';
    if (msg.includes('UNIQUE')) {
      return badRequest(`${cfg.label} sudah ada (duplikat)`);
    }
    return badRequest(msg);
  }
}

export async function remove(env: Env, cfg: CrudConfig, id: number, user: UserPayload, ip: string) {
  const existing = await env.DB.prepare(
    `SELECT id FROM ${cfg.table} WHERE id = ?`
  ).bind(id).first<Row>();

  if (!existing) return notFound(cfg.label);

  try {
    await env.DB.prepare(`DELETE FROM ${cfg.table} WHERE id = ?`).bind(id).run();
    await logAction(env, user.sub, 'delete', cfg.table, `Hapus ${cfg.label} id=${id}`, ip);
    return success({ id });
  } catch (e) {
    const msg = e instanceof Error ? e.message : 'Database error';
    if (msg.includes('FOREIGN KEY')) {
      return badRequest(`${cfg.label} tidak bisa dihapus karena masih digunakan data lain`);
    }
    return badRequest(msg);
  }
}
