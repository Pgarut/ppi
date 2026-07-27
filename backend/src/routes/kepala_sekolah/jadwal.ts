import { Env } from '../../types';
import { success, badRequest } from '../../utils/response';

export async function handleJadwalKS(request: Request, env: Env, url: URL): Promise<Response> {
  if (request.method !== 'GET') return badRequest('Method tidak diizinkan');

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
  query += ' ORDER BY jp.hari, jp.jam_mulai';

  const rows = await (bindings.length > 0
    ? env.DB.prepare(query).bind(...bindings).all()
    : env.DB.prepare(query).all());

  return success(rows.results);
}
