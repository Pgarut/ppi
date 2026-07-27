import { Env } from '../../types';
import { success, badRequest } from '../../utils/response';

export async function handleRaporKS(request: Request, env: Env, url: URL): Promise<Response> {
  if (request.method !== 'GET') return badRequest('Method tidak diizinkan');

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

  const rows = await (bindings.length > 0
    ? env.DB.prepare(query).bind(...bindings).all()
    : env.DB.prepare(query).all());

  return success(rows.results);
}
