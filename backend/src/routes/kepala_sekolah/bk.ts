import { Env } from '../../types';
import { success, badRequest } from '../../utils/response';

export async function handleBKKS(request: Request, env: Env, url: URL): Promise<Response> {
  if (request.method !== 'GET') return badRequest('Method tidak diizinkan');

  const [konselingPerBulan, bakatMinatPerJenis, siswaBermasalah] = await Promise.all([
    env.DB.prepare(
      `SELECT strftime('%Y-%m', tanggal) as periode, COUNT(*) as total
       FROM konseling GROUP BY periode ORDER BY periode DESC LIMIT 12`
    ).all(),
    env.DB.prepare(
      `SELECT jenis, COUNT(*) as total, COUNT(DISTINCT siswa_id) as siswa
       FROM bakat_minat GROUP BY jenis`
    ).all(),
    env.DB.prepare(
      `SELECT s.nama as siswa_nama, s.nis, k.nama as kelas_nama,
              COUNT(p.id) as total_pengaduan
       FROM siswa s
       LEFT JOIN kelas k ON s.kelas_id = k.id
       LEFT JOIN pengaduan p ON p.siswa_id = s.id
       WHERE s.status = 'aktif'
       GROUP BY s.id
       ORDER BY total_pengaduan DESC
       LIMIT 10`
    ).all(),
  ]);

  return success({
    konseling_per_bulan: konselingPerBulan.results,
    bakat_minat_per_jenis: bakatMinatPerJenis.results,
    siswa_bermasalah: siswaBermasalah.results,
  });
}
