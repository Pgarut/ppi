import { Env, UserPayload } from '../../types';
import { success, badRequest } from '../../utils/response';

export async function handleBackup(request: Request, env: Env, user: UserPayload): Promise<Response> {
  if (request.method !== 'POST') return badRequest('Method tidak didukung');

  try {
    const tables = [
      'users', 'hak_akses_modul', 'log_aktivitas',
      'tahun_ajaran', 'semester', 'jurusan', 'tingkat', 'ruangan',
      'mata_pelajaran', 'guru', 'kelas', 'siswa', 'guru_mata_pelajaran',
      'jadwal_pelajaran', 'absensi_guru', 'absensi_siswa',
      'bobot_nilai', 'nilai', 'nilai_rapor', 'rapor_arsip',
      'pengaduan', 'jadwal_konseling', 'konseling', 'bakat_minat',
      'kenaikan_kelas', 'alumni',
    ];

    const dump: Record<string, unknown[]> = {};

    for (const table of tables) {
      const result = await env.DB.prepare(`SELECT * FROM ${table}`).all();
      dump[table] = result.results;
    }

    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'backup', 'system', 'Backup database', ?)"
    ).bind(user.sub, ip).run();

    return success({
      dumped_at: new Date().toISOString(),
      tables: Object.keys(dump),
      data: dump,
    });
  } catch (e) {
    return badRequest(e instanceof Error ? e.message : 'Backup gagal');
  }
}

export async function handleRestore(request: Request, env: Env, user: UserPayload): Promise<Response> {
  if (request.method !== 'POST') return badRequest('Method tidak didukung');

  try {
    const body = await request.json() as { data?: Record<string, unknown[]> };
    if (!body.data) return badRequest('Body harus berisi field `data`');

    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

    for (const [table, rows] of Object.entries(body.data)) {
      if (!Array.isArray(rows) || rows.length === 0) continue;

      for (const row of rows) {
        const cols = Object.keys(row as Record<string, unknown>);
        const vals = Object.values(row as Record<string, unknown>);
        const placeholders = vals.map(() => '?').join(', ');

        try {
          await env.DB.prepare(
            `INSERT OR REPLACE INTO ${table} (${cols.join(', ')}) VALUES (${placeholders})`
          ).bind(...vals).run();
        } catch {
          // skip rows that cause errors during restore
        }
      }
    }

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'restore', 'system', 'Restore database', ?)"
    ).bind(user.sub, ip).run();

    return success({ message: 'Restore berhasil' });
  } catch (e) {
    return badRequest(e instanceof Error ? e.message : 'Restore gagal');
  }
}

export async function handleLogAktivitas(request: Request, env: Env, _user: UserPayload, url: URL): Promise<Response> {
  if (request.method !== 'GET') return badRequest('Method tidak didukung');

  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const perPage = Math.min(100, Math.max(1, parseInt(url.searchParams.get('per_page') || '20')));
  const offset = (page - 1) * perPage;

  const countResult = await env.DB.prepare('SELECT COUNT(*) as total FROM log_aktivitas').first<{ total: number }>();
  const total = countResult?.total || 0;

  const rows = await env.DB.prepare(
    `SELECT l.*, u.username FROM log_aktivitas l LEFT JOIN users u ON l.user_id = u.id ORDER BY l.created_at DESC LIMIT ? OFFSET ?`
  ).bind(perPage, offset).all();

  return success({
    items: rows.results,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
  });
}
