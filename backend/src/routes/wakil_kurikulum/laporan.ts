import { Env, UserPayload } from '../../types';
import { success, badRequest } from '../../utils/response';

export async function handleLaporanWK(request: Request, env: Env, _user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  if (request.method !== 'GET') return badRequest('Method tidak didukung');

  const subPathFull = pathParts.slice(2).join('/');
  const resource = pathParts[2];
  const subPath = subPathFull === resource ? '' : subPathFull.replace(resource + '/', '');

  switch (subPath) {
    case 'jadwal': {
      const rows = await env.DB.prepare(
        `SELECT jp.*, mp.nama as mapel, g.nama as guru, k.nama as kelas, r.nama as ruangan
         FROM jadwal_pelajaran jp
         LEFT JOIN mata_pelajaran mp ON jp.mata_pelajaran_id = mp.id
         LEFT JOIN guru g ON jp.guru_id = g.id
         LEFT JOIN kelas k ON jp.kelas_id = k.id
         LEFT JOIN ruangan r ON jp.ruangan_id = r.id
         ORDER BY jp.hari, jp.jam_mulai`
      ).all();
      return success(rows.results);
    }

    case 'absensi': {
      const rows = await env.DB.prepare(
        `SELECT a.*, s.nama as siswa_nama, k.nama as kelas_nama
         FROM absensi_siswa a
         LEFT JOIN siswa s ON a.siswa_id = s.id
         LEFT JOIN kelas k ON a.kelas_id = k.id
         ORDER BY a.tanggal DESC LIMIT 200`
      ).all();
      return success(rows.results);
    }

    case 'nilai': {
      const rows = await env.DB.prepare(
        `SELECT n.*, s.nama as siswa_nama, mp.nama as mapel_nama, k.nama as kelas_nama
         FROM nilai n
         LEFT JOIN siswa s ON n.siswa_id = s.id
         LEFT JOIN mata_pelajaran mp ON n.mata_pelajaran_id = mp.id
         LEFT JOIN kelas k ON n.kelas_id = k.id
         ORDER BY n.created_at DESC LIMIT 200`
      ).all();
      return success(rows.results);
    }

    case 'rapor': {
      const rows = await env.DB.prepare(
        `SELECT nr.*, s.nama as siswa_nama, mp.nama as mapel_nama, k.nama as kelas_nama
         FROM nilai_rapor nr
         LEFT JOIN siswa s ON nr.siswa_id = s.id
         LEFT JOIN mata_pelajaran mp ON nr.mata_pelajaran_id = mp.id
         LEFT JOIN kelas k ON nr.kelas_id = k.id
         ORDER BY nr.semester_id DESC, s.nama`
      ).all();
      return success(rows.results);
    }

    default:
      return badRequest('Jenis laporan tidak dikenal');
  }
}
