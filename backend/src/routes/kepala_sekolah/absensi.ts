import { Env } from '../../types';
import { success, badRequest } from '../../utils/response';

export async function handleAbsensiKS(request: Request, env: Env, url: URL): Promise<Response> {
  if (request.method !== 'GET') return badRequest('Method tidak diizinkan');

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
