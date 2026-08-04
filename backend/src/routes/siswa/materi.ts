import { Env, UserPayload } from '../../types';
import { success, error } from '../../utils/response';

export async function handleMateri(
  env: Env,
  user: UserPayload,
  url: URL
): Promise<Response> {
  const mapelFilter = url.searchParams.get('mapel_id');

  // Ambil kelas_id
  const { results: siswaData } = await env.DB.prepare(
    'SELECT kelas_id FROM siswa WHERE id = ?'
  ).bind(user.siswa_id).all();

  if (siswaData.length === 0) return error('Data siswa tidak ditemukan', 404);
  const kelasId = (siswaData[0] as any).kelas_id;

  // Cek apakah tabel materi ada
  const tableCheck = await env.DB.prepare(
    "SELECT name FROM sqlite_master WHERE type='table' AND name='materi'"
  ).first();

  if (!tableCheck) {
    return success({ data: [], grouped: [] });
  }

  // Query materi (hanya yang aktif)
  let query = `
    SELECT m.*, mp.nama as mapel_nama, g.nama as guru_nama
    FROM materi m
    JOIN mata_pelajaran mp ON m.mata_pelajaran_id = mp.id
    JOIN guru g ON m.guru_id = g.id
    WHERE m.kelas_id = ? AND m.is_aktif = 1
  `;
  const params: any[] = [kelasId];

  if (mapelFilter) {
    query += ' AND m.mata_pelajaran_id = ?';
    params.push(mapelFilter);
  }

  query += ' ORDER BY mp.nama, m.pertemuan, m.created_at DESC';

  const { results } = await env.DB.prepare(query).bind(...params).all();

  // Group by mata_pelajaran
  const grouped: Record<string, any> = {};
  for (const m of results as any[]) {
    const key = `${m.mata_pelajaran_id}`;
    if (!grouped[key]) {
      grouped[key] = {
        mapel_id: m.mata_pelajaran_id,
        mapel_nama: m.mapel_nama,
        guru_nama: m.guru_nama,
        materi_list: [],
      };
    }
    grouped[key].materi_list.push({
      id: m.id,
      judul: m.judul,
      deskripsi: m.deskripsi,
      link_url: m.link_url,
      link_youtube: m.link_youtube,
      pertemuan: m.pertemuan,
      created_at: m.created_at,
    });
  }

  return success({
    data: results,
    grouped: Object.values(grouped),
  });
}
