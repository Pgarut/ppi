import { Env, UserPayload } from '../../types';
import { success, error } from '../../utils/response';

export async function handleJadwal(
  env: Env,
  user: UserPayload,
  url: URL
): Promise<Response> {
  const { results: siswaData } = await env.DB.prepare(
    'SELECT kelas_id FROM siswa WHERE id = ?'
  ).bind(user.siswa_id).all();

  if (siswaData.length === 0) return error('Data siswa tidak ditemukan', 404);

  const kelasId = (siswaData[0] as any).kelas_id;
  const hari = url.searchParams.get('hari');

  let query = `
    SELECT jp.*, mp.nama as mapel_nama, mp.kode as mapel_kode,
           g.nama as guru_nama, g.nip as guru_nip,
           r.nama as ruangan_nama
    FROM jadwal_pelajaran jp
    JOIN mata_pelajaran mp ON jp.mata_pelajaran_id = mp.id
    JOIN guru g ON jp.guru_id = g.id
    LEFT JOIN ruangan r ON jp.ruangan_id = r.id
    WHERE jp.kelas_id = ? AND jp.status_validasi = 'tervalidasi'
  `;
  const params: any[] = [kelasId];

  if (hari) {
    query += ' AND jp.hari = ?';
    params.push(hari);
  }

  query += ` ORDER BY CASE jp.hari
    WHEN 'Sabtu' THEN 1 WHEN 'Minggu' THEN 2 WHEN 'Senin' THEN 3
    WHEN 'Selasa' THEN 4 WHEN 'Rabu' THEN 5 WHEN 'Kamis' THEN 6
    ELSE 7 END, jp.jam_mulai`;

  const { results } = await env.DB.prepare(query).bind(...params).all();

  return success(results);
}
