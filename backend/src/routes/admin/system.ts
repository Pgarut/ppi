import { Env, UserPayload } from '../../types';
import { success, badRequest } from '../../utils/response';

export async function handleBackup(request: Request, env: Env, user: UserPayload): Promise<Response> {
  if (request.method !== 'POST') return badRequest('Method tidak didukung');

  try {
    const tables = [
      'users', 'hak_akses_modul', 'log_aktivitas',
      'tahun_ajaran', 'semester', 'jurusan', 'tingkat', 'ruangan',
      'mata_pelajaran', 'mapel_kelas', 'guru', 'kelas', 'siswa', 'guru_mata_pelajaran',
      'jadwal_pelajaran', 'absensi_guru', 'absensi_siswa',
      'bobot_nilai', 'nilai', 'nilai_rapor', 'rapor_arsip',
      'materi',
      'pengaduan', 'jadwal_konseling', 'konseling', 'bakat_minat',
      'kenaikan_kelas', 'alumni',
      'api_keys', 'jenis_pembayaran', 'pembayaran', 'notifikasi',
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
    const body = await request.json() as { data?: Record<string, unknown[]>; dumped_at?: string };
    if (!body.data) return badRequest('Body harus berisi field `data`');

    // Validasi: pastikan data adalah object dengan array
    if (typeof body.data !== 'object' || Array.isArray(body.data)) {
      return badRequest('Format data tidak valid: data harus berupa object dengan key nama tabel');
    }

    // Validasi: periksa apakah ada tabel yang dikenal
    const validTables = [
      'users', 'hak_akses_modul', 'log_aktivitas',
      'tahun_ajaran', 'semester', 'jurusan', 'tingkat', 'ruangan',
      'mata_pelajaran', 'mapel_kelas', 'guru', 'kelas', 'siswa', 'guru_mata_pelajaran',
      'jadwal_pelajaran', 'absensi_guru', 'absensi_siswa',
      'bobot_nilai', 'nilai', 'nilai_rapor', 'rapor_arsip',
      'materi',
      'pengaduan', 'jadwal_konseling', 'konseling', 'bakat_minat',
      'kenaikan_kelas', 'alumni', 'pengaturan', 'rate_limits',
      'api_keys', 'api_key_rate_limits', 'jenis_pembayaran', 'pembayaran', 'notifikasi',
    ];
    const invalidTables = Object.keys(body.data).filter(t => !validTables.includes(t));
    if (invalidTables.length > 0) {
      return badRequest(`Tabel tidak dikenal: ${invalidTables.join(', ')}`);
    }

    // Validasi: pastikan setiap entry adalah array of objects
    for (const [table, rows] of Object.entries(body.data)) {
      if (!Array.isArray(rows)) {
        return badRequest(`Data untuk tabel '${table}' harus berupa array`);
      }
      for (let i = 0; i < rows.length; i++) {
        if (typeof rows[i] !== 'object' || rows[i] === null || Array.isArray(rows[i])) {
          return badRequest(`Baris ke-${i + 1} di tabel '${table}' tidak valid: harus berupa object`);
        }
      }
    }

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
