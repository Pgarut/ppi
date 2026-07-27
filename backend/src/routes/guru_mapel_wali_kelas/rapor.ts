import { Env, UserPayload } from '../../types';
import { success, created, notFound, badRequest } from '../../utils/response';

export async function handleRaporGuru(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPath = pathParts.slice(2).join('/');

  // GET rapor
  if ((subPath === '' || subPath === 'rapor') && request.method === 'GET') {
    const siswaId = url.searchParams.get('siswa_id');
    const semesterId = url.searchParams.get('semester_id');

    let query = `SELECT nr.*, s.nama as siswa_nama, mp.nama as mapel_nama, k.nama as kelas_nama
                 FROM nilai_rapor nr
                 LEFT JOIN siswa s ON nr.siswa_id = s.id
                 LEFT JOIN mata_pelajaran mp ON nr.mata_pelajaran_id = mp.id
                 LEFT JOIN kelas k ON nr.kelas_id = k.id`;
    const bindings: unknown[] = [];
    const conditions: string[] = [];

    if (siswaId) { conditions.push('nr.siswa_id = ?'); bindings.push(parseInt(siswaId)); }
    if (semesterId) { conditions.push('nr.semester_id = ?'); bindings.push(parseInt(semesterId)); }

    if (conditions.length > 0) query += ' WHERE ' + conditions.join(' AND ');
    query += ' ORDER BY nr.semester_id DESC, s.nama';

    const rows = bindings.length > 0 ? await env.DB.prepare(query).bind(...bindings).all() : await env.DB.prepare(query).all();
    return success(rows.results);
  }

  // POST / PUT rapor
  if (subPath === '' || subPath === 'rapor' && request.method === 'POST') {
    const body = await request.json() as Record<string, unknown>;
    const { siswa_id, kelas_id, semester_id, mata_pelajaran_id, nilai_akhir, predikat, catatan_wali_kelas } = body;

    if (!siswa_id || !kelas_id || !semester_id || !mata_pelajaran_id) {
      return badRequest('siswa_id, kelas_id, semester_id, mata_pelajaran_id wajib diisi');
    }

    // Upsert
    const existing = await env.DB.prepare(
      'SELECT id FROM nilai_rapor WHERE siswa_id = ? AND semester_id = ? AND mata_pelajaran_id = ?'
    ).bind(siswa_id, semester_id, mata_pelajaran_id).first();

    if (existing) {
      const setClauses: string[] = [];
      const vals: unknown[] = [];
      if (nilai_akhir !== undefined) { setClauses.push('nilai_akhir = ?'); vals.push(nilai_akhir); }
      if (predikat !== undefined) { setClauses.push('predikat = ?'); vals.push(predikat); }
      if (catatan_wali_kelas !== undefined) { setClauses.push('catatan_wali_kelas = ?'); vals.push(catatan_wali_kelas); }

      if (setClauses.length > 0) {
        vals.push(existing.id);
        await env.DB.prepare(`UPDATE nilai_rapor SET ${setClauses.join(', ')} WHERE id = ?`).bind(...vals).run();
        await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'rapor', ?, ?)")
          .bind(user.sub, `Update rapor #${existing.id}`, ip).run();
      }
      return success({ id: existing.id });
    } else {
      const result = await env.DB.prepare(
        `INSERT INTO nilai_rapor (siswa_id, kelas_id, semester_id, mata_pelajaran_id, nilai_akhir, predikat, catatan_wali_kelas, wali_kelas_id)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
      ).bind(siswa_id, kelas_id, semester_id, mata_pelajaran_id, nilai_akhir || null, predikat || null, catatan_wali_kelas || null, user.guru_id).run();

      return created({ id: result.meta?.last_row_id });
    }
  }

  return badRequest('Endpoint tidak dikenal');
}
