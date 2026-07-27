import { Env, UserPayload } from '../../types';
import { success, badRequest } from '../../utils/response';

export async function handleMonitoringBK(request: Request, env: Env, url: URL): Promise<Response> {
  const subPath = url.pathname.replace('/api/guru-bk/monitoring', '');

  // GET /api/guru-bk/monitoring/nilai — grafik nilai siswa
  if (subPath === '/nilai' && request.method === 'GET') {
    const siswaId = url.searchParams.get('siswa_id') || '';
    const kelasId = url.searchParams.get('kelas_id') || '';

    let where = 'WHERE 1=1';
    const bindings: unknown[] = [];
    if (siswaId) { where += ' AND n.siswa_id = ?'; bindings.push(parseInt(siswaId)); }
    if (kelasId) { where += ' AND n.kelas_id = ?'; bindings.push(parseInt(kelasId)); }

    const rows = await env.DB.prepare(
      `SELECT n.jenis, ROUND(AVG(n.nilai), 2) as rata_rata, COUNT(*) as jumlah,
              s.nama as siswa_nama, mp.nama as mapel_nama
       FROM nilai n
       LEFT JOIN siswa s ON n.siswa_id = s.id
       LEFT JOIN mata_pelajaran mp ON n.mata_pelajaran_id = mp.id
       ${where}
       GROUP BY n.jenis, n.siswa_id
       ORDER BY n.siswa_id, n.jenis`
    ).bind(...bindings).all();
    return success(rows.results);
  }

  // GET /api/guru-bk/monitoring/absensi — grafik absensi
  if (subPath === '/absensi' && request.method === 'GET') {
    const siswaId = url.searchParams.get('siswa_id') || '';
    const kelasId = url.searchParams.get('kelas_id') || '';

    let where = 'WHERE 1=1';
    const bindings: unknown[] = [];
    if (siswaId) { where += ' AND a.siswa_id = ?'; bindings.push(parseInt(siswaId)); }
    if (kelasId) { where += ' AND a.kelas_id = ?'; bindings.push(parseInt(kelasId)); }

    const rows = await env.DB.prepare(
      `SELECT a.status, COUNT(*) as jumlah, s.nama as siswa_nama
       FROM absensi_siswa a
       LEFT JOIN siswa s ON a.siswa_id = s.id
       ${where}
       GROUP BY a.status, a.siswa_id
       ORDER BY a.siswa_id`
    ).bind(...bindings).all();
    return success(rows.results);
  }

  // GET /api/guru-bk/monitoring/pelanggaran — rekap pelanggaran
  if (subPath === '/pelanggaran' && request.method === 'GET') {
    const rows = await env.DB.prepare(
      `SELECT p.kategori, COUNT(*) as jumlah, s.nama as siswa_nama
       FROM pengaduan p
       LEFT JOIN siswa s ON p.siswa_id = s.id
       WHERE p.kategori = 'perilaku'
       GROUP BY p.kategori, p.siswa_id
       ORDER BY jumlah DESC`
    ).all();
    return success(rows.results);
  }

  return badRequest('Endpoint tidak dikenal');
}
