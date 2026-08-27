import { Env, UserPayload } from '../../types';
import { success, error } from '../../utils/response';

export async function handleNilai(
  env: Env,
  user: UserPayload,
  url: URL
): Promise<Response> {
  const semesterId = url.searchParams.get('semester_id');
  const tahunAjaranId = url.searchParams.get('tahun_ajaran_id');

  // Ambil daftar tahun ajaran yang punya data nilai untuk siswa ini
  const { results: taList } = await env.DB.prepare(
    `SELECT DISTINCT ta.id, ta.nama
     FROM tahun_ajaran ta
     JOIN semester s ON s.tahun_ajaran_id = ta.id
     JOIN nilai n ON n.semester_id = s.id
     WHERE n.siswa_id = ?
     ORDER BY ta.nama DESC`
  ).bind(user.siswa_id).all();

  // Ambil daftar semester berdasarkan tahun ajaran yang dipilih
  let semQuery = 'SELECT id, nama, is_aktif FROM semester';
  const semParams: any[] = [];
  if (tahunAjaranId) {
    semQuery += ' WHERE tahun_ajaran_id = ?';
    semParams.push(parseInt(tahunAjaranId));
  }
  semQuery += ' ORDER BY tahun_ajaran_id DESC, nama';
  const { results: semList } = await env.DB.prepare(semQuery).bind(...semParams).all();

  // Ambil semester aktif jika tidak ditentukan
  let semId = semesterId;
  if (!semId) {
    const { results: activeSem } = await env.DB.prepare(
      'SELECT id FROM semester WHERE is_aktif = 1 LIMIT 1'
    ).all();
    if (activeSem.length > 0) semId = String((activeSem[0] as any).id);
  }

  // Cek apakah nilai sudah dipublikasikan untuk semester ini
  if (semId) {
    const sem = await env.DB.prepare(
      'SELECT nilai_published FROM semester WHERE id = ?'
    ).bind(semId).first<{ nilai_published: number }>();
    if (sem && sem.nilai_published === 0) {
      return success({
        rekap: [],
        rata_rata_keseluruhan: 0,
        semester_id: semId,
        published: false,
        message: 'Nilai belum dipublikasikan oleh administrator',
        daftar_tahun_ajaran: taList,
        daftar_semester: semList,
      });
    }
  }

  // Ambil data siswa
  const { results: siswaData } = await env.DB.prepare(
    'SELECT kelas_id FROM siswa WHERE id = ?'
  ).bind(user.siswa_id).all();

  if (siswaData.length === 0) return error('Data siswa tidak ditemukan', 404);
  const kelasId = (siswaData[0] as any).kelas_id;

  // Query nilai per mata pelajaran
  let query = `
    SELECT n.*, mp.nama as mapel_nama, mp.kode as mapel_kode
    FROM nilai n
    JOIN mata_pelajaran mp ON n.mata_pelajaran_id = mp.id
    WHERE n.siswa_id = ? AND n.kelas_id = ?
  `;
  const params: any[] = [user.siswa_id, kelasId];

  if (semId) {
    query += ' AND n.semester_id = ?';
    params.push(semId);

    // Filter by published mapel per semester
    query += ` AND n.mata_pelajaran_id IN (
      SELECT mata_pelajaran_id FROM publikasi_nilai_mapel
      WHERE semester_id = ? AND is_published = 1
    )`;
    params.push(semId);
  }

  query += ' ORDER BY mp.nama, n.jenis';

  const { results } = await env.DB.prepare(query).bind(...params).all();

  // Group by mata_pelajaran
  const grouped: Record<string, any[]> = {};
  for (const n of results as any[]) {
    if (!grouped[n.mapel_nama]) grouped[n.mapel_nama] = [];
    grouped[n.mapel_nama].push(n);
  }

    // Hitung rata-rata per mapel (simple average, tanpa bobot)
    const rekap = Object.entries(grouped).map(([mapel, nilaiList]) => {
      const countMap: Record<string, number> = { harian: 0, tugas: 0, uts: 0, uas: 0, pts1: 0, pas: 0, pts2: 0, pat: 0 };
      const totalMap: Record<string, number> = { harian: 0, tugas: 0, uts: 0, uas: 0, pts1: 0, pas: 0, pts2: 0, pat: 0 };

      for (const n of nilaiList) {
        const jenis = n.jenis as string;
        if (jenis in countMap) {
          countMap[jenis] += 1;
          totalMap[jenis] += n.nilai;
        }
      }

      const avg = (key: string) => countMap[key] > 0 ? totalMap[key] / countMap[key] : 0;

      const avgHarian = avg('harian');
      const avgTugas = avg('tugas');
      const avgUts = avg('uts');
      const avgUas = avg('uas');
      const avgPts1 = avg('pts1');
      const avgPas = avg('pas');
      const avgPts2 = avg('pts2');
      const avgPat = avg('pat');

      // Hitung rata-rata akhir: gunakan jenis yang punya data
      const avgPairs: [number, number][] = [
        [avgHarian, countMap['harian']],
        [avgTugas, countMap['tugas']],
        [avgUts, countMap['uts']],
        [avgUas, countMap['uas']],
        [avgPts1, countMap['pts1']],
        [avgPas, countMap['pas']],
        [avgPts2, countMap['pts2']],
        [avgPat, countMap['pat']],
      ];
      const validAvgs = avgPairs.filter(([, count]) => count > 0).map(([avg]) => avg);
      const avgAkhir = validAvgs.length > 0
        ? Math.round(validAvgs.reduce((s, v) => s + v, 0) / validAvgs.length * 100) / 100
        : 0;

      return {
        mapel_nama: mapel,
        harian: Math.round(avgHarian * 100) / 100,
        tugas: Math.round(avgTugas * 100) / 100,
        uts: Math.round(avgUts * 100) / 100,
        uas: Math.round(avgUas * 100) / 100,
        pts1: Math.round(avgPts1 * 100) / 100,
        pas: Math.round(avgPas * 100) / 100,
        pts2: Math.round(avgPts2 * 100) / 100,
        pat: Math.round(avgPat * 100) / 100,
        rata_rata: avgAkhir,
      };
    });

  // Rata-rata keseluruhan
  const avgKeseluruhan = rekap.length > 0
    ? Math.round(rekap.reduce((sum, r) => sum + r.rata_rata, 0) / rekap.length * 100) / 100
    : 0;

  return success({
    rekap,
    rata_rata_keseluruhan: avgKeseluruhan,
    semester_id: semId,
    daftar_tahun_ajaran: taList,
    daftar_semester: semList,
  });
}
