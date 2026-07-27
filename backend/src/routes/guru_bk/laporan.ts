import { Env, UserPayload } from '../../types';
import { success, badRequest } from '../../utils/response';

export async function handleLaporanBK(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const subPath = pathParts.slice(2).join('/');
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

  // Statistik dashboard
  if (subPath === 'statistik' && request.method === 'GET') {
    const [total, proses, selesai, perKategori, totalKonseling] = await Promise.all([
      env.DB.prepare('SELECT COUNT(*) as total FROM pengaduan').first<{ total: number }>(),
      env.DB.prepare("SELECT COUNT(*) as total FROM pengaduan WHERE status = 'ditindaklanjuti'").first<{ total: number }>(),
      env.DB.prepare("SELECT COUNT(*) as total FROM pengaduan WHERE status = 'selesai'").first<{ total: number }>(),
      env.DB.prepare(
        'SELECT kategori, COUNT(*) as jumlah FROM pengaduan GROUP BY kategori'
      ).all<{ kategori: string; jumlah: number }>(),
      env.DB.prepare('SELECT COUNT(*) as total FROM konseling').first<{ total: number }>(),
    ]);

    return success({
      total_pengaduan: total?.total || 0,
      aktif_diproses: proses?.total || 0,
      selesai: selesai?.total || 0,
      per_kategori: perKategori.results,
      total_konseling: totalKonseling?.total || 0,
    });
  }

  // Laporan bulanan
  if (subPath === 'bulanan' && request.method === 'GET') {
    const tahun = url.searchParams.get('tahun') || new Date().getFullYear().toString();
    const bulan = url.searchParams.get('bulan');

    let query = `SELECT strftime('%Y-%m', p.created_at) as periode,
                  COUNT(*) as total,
                  SUM(CASE WHEN p.status = 'baru' THEN 1 ELSE 0 END) as baru,
                  SUM(CASE WHEN p.status = 'ditindaklanjuti' THEN 1 ELSE 0 END) as diproses,
                  SUM(CASE WHEN p.status = 'selesai' THEN 1 ELSE 0 END) as selesai
                 FROM pengaduan p
                 WHERE strftime('%Y', p.created_at) = ?`;
    const bindings: unknown[] = [tahun];

    if (bulan) { query += ' AND strftime("%m", p.created_at) = ?'; bindings.push(bulan.padStart(2, '0')); }

    query += ' GROUP BY periode ORDER BY periode DESC';

    const rows = await env.DB.prepare(query).bind(...bindings).all();
    return success({ tahun, bulan: bulan || null, items: rows.results });
  }

  // Rekap kasus per kategori
  if (subPath === 'rekap-kasus' && request.method === 'GET') {
    const rows = await env.DB.prepare(
      `SELECT p.kategori,
              COUNT(*) as total,
              COUNT(DISTINCT p.siswa_id) as siswa_terlibat
       FROM pengaduan p
       GROUP BY p.kategori`
    ).all();

    return success(rows.results);
  }

  // Laporan konseling
  if (subPath === 'konseling' && request.method === 'GET') {
    const rows = await env.DB.prepare(
      `SELECT strftime('%Y-%m', k.tanggal) as periode,
              COUNT(*) as total,
              COUNT(DISTINCT k.siswa_id) as siswa
       FROM konseling k
       GROUP BY periode ORDER BY periode DESC`
    ).all();
    return success(rows.results);
  }

  // Laporan bakat-minat
  if (subPath === 'bakat-minat' && request.method === 'GET') {
    const rows = await env.DB.prepare(
      `SELECT bm.jenis, COUNT(*) as total,
              COUNT(DISTINCT bm.siswa_id) as siswa
       FROM bakat_minat bm
       GROUP BY bm.jenis`
    ).all();
    return success(rows.results);
  }

  // Laporan monitoring akademik
  if (subPath === 'monitoring' && request.method === 'GET') {
    const [nilaiRata, absensiRekap, pengaduanRekap] = await Promise.all([
      env.DB.prepare(
        'SELECT jenis, ROUND(AVG(nilai), 2) as rata_rata FROM nilai GROUP BY jenis'
      ).all(),
      env.DB.prepare(
        'SELECT status, COUNT(*) as jumlah FROM absensi_siswa GROUP BY status'
      ).all(),
      env.DB.prepare(
        "SELECT kategori, COUNT(*) as jumlah FROM pengaduan GROUP BY kategori"
      ).all(),
    ]);
    return success({
      nilai: nilaiRata.results,
      absensi: absensiRekap.results,
      pengaduan: pengaduanRekap.results,
    });
  }

  return badRequest('Endpoint tidak dikenal');
}
