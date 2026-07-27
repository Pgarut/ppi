import { Env } from '../../types';
import { success, badRequest } from '../../utils/response';

export async function handleNilaiKS(request: Request, env: Env, url: URL): Promise<Response> {
  if (request.method !== 'GET') return badRequest('Method tidak diizinkan');

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
