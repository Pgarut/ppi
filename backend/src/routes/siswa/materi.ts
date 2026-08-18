import { Env, UserPayload } from '../../types';
import { success, error } from '../../utils/response';

export async function handleMateri(
  env: Env,
  user: UserPayload,
  url: URL
): Promise<Response> {
  const mapelFilter = url.searchParams.get('mapel_id');

  // Ambil kelas_id + tingkat_id siswa
  const { results: siswaData } = await env.DB.prepare(
    'SELECT s.kelas_id, k.tingkat_id FROM siswa s LEFT JOIN kelas k ON s.kelas_id = k.id WHERE s.id = ?'
  ).bind(user.siswa_id).all();

  if (siswaData.length === 0) return error('Data siswa tidak ditemukan', 404);
  const kelasId = (siswaData[0] as any).kelas_id;
  const tingkatId = (siswaData[0] as any).tingkat_id;

  // Cek apakah tabel materi ada
  const tableCheck = await env.DB.prepare(
    "SELECT name FROM sqlite_master WHERE type='table' AND name='materi'"
  ).first();

  if (!tableCheck) {
    return success({ data: [], grouped: [] });
  }

  // Query materi (hanya yang aktif) — berlaku untuk seluruh tingkat siswa
  // (tingkat_id) dan kompatibel dengan materi lama berbasis kelas.
  let query = `
    SELECT m.*, mp.nama as mapel_nama, g.nama as guru_nama
    FROM materi m
    JOIN mata_pelajaran mp ON m.mata_pelajaran_id = mp.id
    JOIN guru g ON m.guru_id = g.id
    WHERE m.is_aktif = 1 AND (m.tingkat_id = ? OR m.kelas_id = ?)
  `;
  const params: any[] = [tingkatId, kelasId];

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
