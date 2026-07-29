import { Env } from '../../types';
import { success, badRequest } from '../../utils/response';

export async function handleMonitoringBK(request: Request, env: Env, url: URL): Promise<Response> {
  const subPath = url.pathname.replace('/api/guru-bk/monitoring', '');

  // GET /api/guru-bk/monitoring/absensi — rekap absensi per santri
  if (subPath === '/absensi' && request.method === 'GET') {
    const kelasId = url.searchParams.get('kelas_id') || '';

    let where = 'WHERE s.status = ?';
    const bindings: unknown[] = ['aktif'];
    if (kelasId) { where += ' AND s.kelas_id = ?'; bindings.push(parseInt(kelasId)); }

    const rows = await env.DB.prepare(
      `SELECT s.id, s.nis, s.nisn, s.nama as siswa_nama, s.kelas_id, k.nama as kelas_nama,
              COALESCE(SUM(CASE WHEN a.status = 'hadir' THEN 1 ELSE 0 END), 0) as hadir,
              COALESCE(SUM(CASE WHEN a.status = 'izin' THEN 1 ELSE 0 END), 0) as izin,
              COALESCE(SUM(CASE WHEN a.status = 'sakit' THEN 1 ELSE 0 END), 0) as sakit,
              COALESCE(SUM(CASE WHEN a.status = 'alpa' THEN 1 ELSE 0 END), 0) as alpa,
              COUNT(a.id) as total_kehadiran
       FROM siswa s
       JOIN kelas k ON s.kelas_id = k.id
       LEFT JOIN absensi_siswa a ON a.siswa_id = s.id
       ${where}
       GROUP BY s.id, s.nis, s.nisn, s.nama, s.kelas_id, k.nama
       ORDER BY s.nama`
    ).bind(...bindings).all();

    return success(rows.results);
  }

  // GET /api/guru-bk/monitoring/pelanggaran — rekap pelanggaran per santri
  if (subPath === '/pelanggaran' && request.method === 'GET') {
    const kelasId = url.searchParams.get('kelas_id') || '';

    let where = 'WHERE p.kategori = ?';
    const bindings: unknown[] = ['perilaku'];
    if (kelasId) { where += ' AND s.kelas_id = ?'; bindings.push(parseInt(kelasId)); }

    const rows = await env.DB.prepare(
      `SELECT p.siswa_id, s.nis, s.nisn, s.nama as siswa_nama, s.kelas_id, k.nama as kelas_nama,
              COUNT(*) as total_pelanggaran,
              MAX(p.created_at) as terakhir_dilaporkan,
              GROUP_CONCAT(p.deskripsi, ' | ') sebagai daftar_pelanggaran
       FROM pengaduan p
       LEFT JOIN siswa s ON p.siswa_id = s.id
       LEFT JOIN kelas k ON s.kelas_id = k.id
       ${where}
       GROUP BY p.siswa_id
       ORDER BY total_pelanggaran DESC`
    ).bind(...bindings).all();

    return success(rows.results);
  }

  return badRequest('Endpoint tidak dikenal');
}
