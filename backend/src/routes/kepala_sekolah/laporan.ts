import { Env } from '../../types';
import { success, badRequest } from '../../utils/response';

export async function handleLaporanKS(request: Request, env: Env, url: URL): Promise<Response> {
  const subPath = url.searchParams.get('jenis') || '';

  // Laporan Jadwal
  if (subPath === 'jadwal') {
    const kelasId = url.searchParams.get('kelas_id');
    let query = `SELECT jp.*, mp.nama as mapel_nama, g.nama as guru_nama,
                  k.nama as kelas_nama, r.nama as ruangan_nama
                 FROM jadwal_pelajaran jp
                 LEFT JOIN mata_pelajaran mp ON jp.mata_pelajaran_id = mp.id
                 LEFT JOIN guru g ON jp.guru_id = g.id
                 LEFT JOIN kelas k ON jp.kelas_id = k.id
                 LEFT JOIN ruangan r ON jp.ruangan_id = r.id`;
    const bindings: unknown[] = [];
    if (kelasId) { query += ' WHERE jp.kelas_id = ?'; bindings.push(parseInt(kelasId)); }
    query += ` ORDER BY CASE jp.hari
      WHEN 'Sabtu' THEN 1 WHEN 'Minggu' THEN 2 WHEN 'Senin' THEN 3
      WHEN 'Selasa' THEN 4 WHEN 'Rabu' THEN 5 WHEN 'Kamis' THEN 6
      ELSE 7 END, jp.jam_mulai`;

    const rows = bindings.length > 0
      ? await env.DB.prepare(query).bind(...bindings).all()
      : await env.DB.prepare(query).all();
    return success(rows.results);
  }

  // Laporan Absensi
  if (subPath === 'absensi') {
    const kelasId = url.searchParams.get('kelas_id');
    let query = `SELECT a.status, COUNT(*) as jumlah,
                  k.nama as kelas_nama, strftime('%Y-%m', a.tanggal) as periode
                 FROM absensi_siswa a
                 LEFT JOIN kelas k ON a.kelas_id = k.id`;
    const bindings: unknown[] = [];
    const conditions: string[] = [];
    if (kelasId) { conditions.push('a.kelas_id = ?'); bindings.push(parseInt(kelasId)); }
    if (conditions.length > 0) query += ' WHERE ' + conditions.join(' AND ');
    query += ' GROUP BY a.status, periode ORDER BY periode DESC';

    const rows = await env.DB.prepare(query).bind(...bindings).all();
    return success(rows.results);
  }

  // Laporan Nilai
  if (subPath === 'nilai') {
    const kelasId = url.searchParams.get('kelas_id');
    let query = `SELECT n.jenis, COUNT(*) as total, ROUND(AVG(n.nilai), 2) as rata_rata,
                  MIN(n.nilai) as min, MAX(n.nilai) as max,
                  k.nama as kelas_nama, mp.nama as mapel_nama
                 FROM nilai n
                 LEFT JOIN kelas k ON n.kelas_id = k.id
                 LEFT JOIN mata_pelajaran mp ON n.mata_pelajaran_id = mp.id`;
    const bindings: unknown[] = [];
    const conditions: string[] = [];
    if (kelasId) { conditions.push('n.kelas_id = ?'); bindings.push(parseInt(kelasId)); }
    if (conditions.length > 0) query += ' WHERE ' + conditions.join(' AND ');
    query += ' GROUP BY n.jenis, n.kelas_id ORDER BY n.jenis';

    const rows = await env.DB.prepare(query).bind(...bindings).all();
    return success(rows.results);
  }

  // Laporan Rapor
  if (subPath === 'rapor') {
    const kelasId = url.searchParams.get('kelas_id');
    const semesterId = url.searchParams.get('semester_id');
    let query = `SELECT nr.*, s.nama as siswa_nama, s.nis as siswa_nis,
                  mp.nama as mapel_nama, k.nama as kelas_nama
                 FROM nilai_rapor nr
                 LEFT JOIN siswa s ON nr.siswa_id = s.id
                 LEFT JOIN mata_pelajaran mp ON nr.mata_pelajaran_id = mp.id
                 LEFT JOIN kelas k ON nr.kelas_id = k.id`;
    const bindings: unknown[] = [];
    const conditions: string[] = [];
    if (kelasId) { conditions.push('nr.kelas_id = ?'); bindings.push(parseInt(kelasId)); }
    if (semesterId) { conditions.push('nr.semester_id = ?'); bindings.push(parseInt(semesterId)); }
    if (conditions.length > 0) query += ' WHERE ' + conditions.join(' AND ');
    query += ' ORDER BY s.nama';

    const rows = bindings.length > 0
      ? await env.DB.prepare(query).bind(...bindings).all()
      : await env.DB.prepare(query).all();
    return success(rows.results);
  }

  return badRequest('Jenis laporan tidak valid. Gunakan: jadwal, absensi, nilai, rapor');
}
