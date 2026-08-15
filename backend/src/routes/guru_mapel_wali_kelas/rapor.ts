import { Env, UserPayload } from '../../types';
import { success, badRequest } from '../../utils/response';

async function getWaliKelas(env: Env, guruId: number): Promise<{ id: number; nama: string } | null> {
  return env.DB.prepare('SELECT id, nama FROM kelas WHERE wali_kelas_id = ?').bind(guruId).first<{ id: number; nama: string }>();
}

function hitungPredikat(nilai: number): string {
  if (nilai >= 90) return 'A';
  if (nilai >= 75) return 'B';
  if (nilai >= 60) return 'C';
  return 'D';
}

export async function handleRaporGuru(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const subPath = pathParts.slice(2).join('/');

  if (!user.guru_id) return badRequest('Anda tidak memiliki data asatidz');

  // ── Cek status wali kelas ──────────────────────────────────────
  if (subPath === 'rapor/cek-wali' && request.method === 'GET') {
    const wali = await getWaliKelas(env, user.guru_id);
    return success({
      is_wali_kelas: wali !== null,
      kelas: wali ? { id: wali.id, nama: wali.nama } : null,
    });
  }

  // ── Data wali: siswa + mapel ───────────────────────────────────
  if (subPath === 'rapor/data-wali' && request.method === 'GET') {
    const wali = await getWaliKelas(env, user.guru_id);
    if (!wali) return success({ wali_kelas: null, siswa: [], mapel: [] });

    const siswa = await env.DB.prepare(
      "SELECT id, nis, nisn, nama FROM siswa WHERE kelas_id = ? AND status = 'aktif' ORDER BY nis ASC"
    ).bind(wali.id).all();

    let mapel = await env.DB.prepare(`
      SELECT DISTINCT mp.id, mp.nama, mp.kode
      FROM jadwal_pelajaran jp
      JOIN mata_pelajaran mp ON jp.mata_pelajaran_id = mp.id
      WHERE jp.kelas_id = ? AND jp.status_validasi = 'tervalidasi'
      ORDER BY mp.nama
    `).bind(wali.id).all();

    // Fallback bila jadwal belum divalidasi: pakai penugasan mapel-kelas guru
    if (mapel.results.length === 0) {
      mapel = await env.DB.prepare(`
        SELECT DISTINCT mp.id, mp.nama, mp.kode
        FROM guru_mapel_kelas gmk
        JOIN mata_pelajaran mp ON gmk.mata_pelajaran_id = mp.id
        WHERE gmk.kelas_id = ?
        ORDER BY mp.nama
      `).bind(wali.id).all();
    }

    return success({
      wali_kelas: wali,
      siswa: siswa.results,
      mapel: mapel.results,
    });
  }

  // ── Daftar semester untuk dropdown ─────────────────────────────
  if (subPath === 'rapor/semester' && request.method === 'GET') {
    const rows = await env.DB.prepare(
      'SELECT s.id, s.nama, ta.nama as tahun_ajaran FROM semester s LEFT JOIN tahun_ajaran ta ON s.tahun_ajaran_id = ta.id ORDER BY s.tahun_ajaran_id DESC, s.nama'
    ).all();
    return success(rows.results);
  }

  // ── Semua endpoint di bawah WAJIB wali kelas ───────────────────
  const waliKelas = await getWaliKelas(env, user.guru_id);
  if (!waliKelas) {
    return badRequest('Hanya wali kelas yang dapat mengakses rapor');
  }

  // ── Status pengiriman nilai PAS/PAT oleh guru_mapel ────────────
  if (subPath === 'rapor/status-pengiriman' && request.method === 'GET') {
    const semesterId = url.searchParams.get('semester_id');
    if (!semesterId) return badRequest('semester_id diperlukan');

    const semId = parseInt(semesterId);

    // Tentukan jenis ujian berdasarkan semester
    const semester = await env.DB.prepare('SELECT nama FROM semester WHERE id = ?').bind(semId).first<{ nama: string }>();
    if (!semester) return badRequest('Semester tidak ditemukan');

    const namaSemester = semester.nama.toLowerCase();
    const jenisUjian = (namaSemester.includes('1') || namaSemester.includes('ganjil') || namaSemester.includes('i'))
      ? 'pas' : 'pat';

    // 1. Ambil daftar mapel + guru untuk kelas wali
    let mapelRows = await env.DB.prepare(`
      SELECT DISTINCT mp.id as mapel_id, mp.nama as mapel_nama, mp.kode as mapel_kode,
             jp.guru_id, g.nama as guru_nama
      FROM jadwal_pelajaran jp
      JOIN mata_pelajaran mp ON jp.mata_pelajaran_id = mp.id
      LEFT JOIN guru g ON jp.guru_id = g.id
      WHERE jp.kelas_id = ? AND jp.semester_id = ? AND jp.status_validasi = 'tervalidasi'
      ORDER BY mp.nama
    `).bind(waliKelas.id, semId).all();

    // Fallback bila jadwal belum divalidasi: pakai penugasan mapel-kelas guru
    if (mapelRows.results.length === 0) {
      mapelRows = await env.DB.prepare(`
        SELECT DISTINCT mp.id as mapel_id, mp.nama as mapel_nama, mp.kode as mapel_kode,
               gmk.guru_id, g.nama as guru_nama
        FROM guru_mapel_kelas gmk
        JOIN mata_pelajaran mp ON gmk.mata_pelajaran_id = mp.id
        LEFT JOIN guru g ON gmk.guru_id = g.id
        WHERE gmk.kelas_id = ?
        ORDER BY mp.nama
      `).bind(waliKelas.id).all();
    }

    // 2. Ambil status input nilai (aggregate per mapel)
    const statusRows = await env.DB.prepare(`
      SELECT mata_pelajaran_id,
        MAX(id) as nilai_id,
        MIN(created_at) as tgl_input,
        COUNT(DISTINCT siswa_id) as jumlah_santri
      FROM nilai
      WHERE kelas_id = ? AND semester_id = ? AND jenis = ?
      GROUP BY mata_pelajaran_id
    `).bind(waliKelas.id, semId, jenisUjian).all();

    // 3. Merge di code
    const statusMap = new Map<number, {
      nilai_id: number; tgl_input: string | null; jumlah_santri: number;
    }>();
    for (const r of statusRows.results as Array<{
      mata_pelajaran_id: number; nilai_id: number; tgl_input: string | null; jumlah_santri: number;
    }>) {
      statusMap.set(r.mata_pelajaran_id, {
        nilai_id: r.nilai_id,
        tgl_input: r.tgl_input,
        jumlah_santri: r.jumlah_santri,
      });
    }

    const result = (mapelRows.results as Array<{
      mapel_id: number; mapel_nama: string; mapel_kode: string;
      guru_id: number | null; guru_nama: string | null;
    }>).map((r) => {
      const status = statusMap.get(r.mapel_id);
      return {
        mapel_id: r.mapel_id,
        mapel_nama: r.mapel_nama,
        mapel_kode: r.mapel_kode,
        guru_id: r.guru_id,
        guru_nama: r.guru_nama,
        nilai_id: status?.nilai_id ?? null,
        tgl_input: status?.tgl_input ?? null,
        jumlah_santri: status?.jumlah_santri ?? 0,
      };
    });

    return success(result);
  }

  // ── GET rapor (aggregate dari nilai) ───────────────────────────
  if ((subPath === '' || subPath === 'rapor') && request.method === 'GET') {
    const siswaId = url.searchParams.get('siswa_id');
    const semesterId = url.searchParams.get('semester_id');

    if (!siswaId || !semesterId) return badRequest('siswa_id dan semester_id diperlukan');

    const sId = parseInt(siswaId);
    const semId = parseInt(semesterId);

    // 1. Ambil data siswa, semester & catatan wali
    const [siswa, semester, catatanWali] = await Promise.all([
      env.DB.prepare(
        "SELECT id, nis, nisn, nama, kelas_id FROM siswa WHERE id = ? AND status = 'aktif'"
      ).bind(sId).first<{ id: number; nis: string; nisn: string | null; nama: string; kelas_id: number }>(),
      env.DB.prepare(
        'SELECT id, nama, tahun_ajaran_id FROM semester WHERE id = ?'
      ).bind(semId).first<{ id: number; nama: string; tahun_ajaran_id: number }>(),
      env.DB.prepare(
        'SELECT catatan FROM catatan_wali_kelas WHERE siswa_id = ? AND semester_id = ?'
      ).bind(sId, semId).first<{ catatan: string }>(),
    ]);

    if (!siswa) return badRequest('Siswa tidak ditemukan');
    if (siswa.kelas_id !== waliKelas.id) return badRequest('Siswa bukan dari kelas wali anda');
    if (!semester) return badRequest('Semester tidak ditemukan');

    // 2. Tentukan jenis ujian berdasarkan semester
    const namaSemester = semester.nama.toLowerCase();
    const jenisUjian = (namaSemester.includes('1') || namaSemester.includes('ganjil') || namaSemester.includes('i'))
      ? 'pas' : 'pat';

    // 3. Ambil bobot nilai (spesifik mapel, fallback default sekolah)
    const bobotRows = await env.DB.prepare(
      `SELECT mata_pelajaran_id, harian_persen, tugas_persen, uts_persen, uas_persen
       FROM bobot_nilai WHERE tahun_ajaran_id = ?`
    ).bind(semester.tahun_ajaran_id).all<{
      mata_pelajaran_id: number | null;
      harian_persen: number; tugas_persen: number; uts_persen: number; uas_persen: number;
    }>();

    const bobotMap = new Map<number | null, { harian: number; tugas: number; uts: number; uas: number }>();
    for (const b of bobotRows.results) {
      bobotMap.set(b.mata_pelajaran_id, {
        harian: b.harian_persen, tugas: b.tugas_persen, uts: b.uts_persen, uas: b.uas_persen,
      });
    }

    // 4. Ambil semua nilai siswa di semester ini — dedupe per (mapel, jenis)
    //    agar tidak dobel bila nilai diinput oleh lebih dari satu guru.
    const nilaiRows = await env.DB.prepare(`
      SELECT n.mata_pelajaran_id, mp.nama as mapel_nama, mp.kode as mapel_kode,
             n.jenis, n.nilai
      FROM nilai n
      JOIN mata_pelajaran mp ON n.mata_pelajaran_id = mp.id
      WHERE n.siswa_id = ? AND n.semester_id = ?
        AND n.id = (
          SELECT MAX(n2.id) FROM nilai n2
          WHERE n2.siswa_id = ? AND n2.semester_id = ?
            AND n2.mata_pelajaran_id = n.mata_pelajaran_id
            AND n2.jenis = n.jenis
        )
      ORDER BY mp.nama, n.jenis
    `).bind(sId, semId, sId, semId).all<{
      mata_pelajaran_id: number; mapel_nama: string; mapel_kode: string;
      jenis: string; nilai: number;
    }>();

    // 5. Group by mapel
    const mapelMap = new Map<number, {
      id: number; nama: string; kode: string;
      nilai_harian: number[]; nilai_pts: number | null; nilai_ujian: number | null;
    }>();

    const jenisPts = jenisUjian === 'pas' ? 'pts1' : 'pts2';

    for (const row of nilaiRows.results) {
      if (!mapelMap.has(row.mata_pelajaran_id)) {
        mapelMap.set(row.mata_pelajaran_id, {
          id: row.mata_pelajaran_id,
          nama: row.mapel_nama,
          kode: row.mapel_kode,
          nilai_harian: [],
          nilai_pts: null,
          nilai_ujian: null,
        });
      }
      const entry = mapelMap.get(row.mata_pelajaran_id)!;
      if (row.jenis === 'harian') {
        entry.nilai_harian.push(row.nilai);
      } else if (row.jenis === jenisPts) {
        entry.nilai_pts = row.nilai;
      } else if (row.jenis === jenisUjian) {
        entry.nilai_ujian = row.nilai;
      }
    }

    // 6. Format response — nilai akhir pakai bobot_nilai + PTS
    const mapel = Array.from(mapelMap.values()).map((m) => {
      const rataHarian = m.nilai_harian.length > 0
        ? Math.round(m.nilai_harian.reduce((a, b) => a + b, 0) / m.nilai_harian.length * 10) / 10
        : null;

      // Bobot default bila tidak terkonfigurasi (sesuai skema schema.sql)
      const bobot = bobotMap.get(m.id) ?? bobotMap.get(null) ?? { harian: 20, tugas: 20, uts: 30, uas: 30 };

      // Tidak ada input jenis 'tugas' dari guru, jadi bobot tugas diserap ke harian
      const wHarian = bobot.harian + bobot.tugas;
      const wPts = bobot.uts;
      const wUjian = bobot.uas;

      // Hitung rata-rata terbobot atas komponen yang tersedia
      let nilaiAkhir: number | null = null;
      let totalBerat = 0;
      let totalNilai = 0;
      if (rataHarian !== null) { totalBerat += wHarian; totalNilai += rataHarian * wHarian; }
      if (m.nilai_pts !== null) { totalBerat += wPts; totalNilai += m.nilai_pts * wPts; }
      if (m.nilai_ujian !== null) { totalBerat += wUjian; totalNilai += m.nilai_ujian * wUjian; }
      if (totalBerat > 0) {
        nilaiAkhir = Math.round(totalNilai / totalBerat * 10) / 10;
      }

      return {
        id: m.id,
        nama: m.nama,
        kode: m.kode,
        nilai_harian: m.nilai_harian,
        rata_harian: rataHarian,
        nilai_pts: m.nilai_pts,
        jenis_pts: jenisPts,
        nilai_ujian: m.nilai_ujian,
        jenis_ujian: jenisUjian,
        bobot: { harian_persen: wHarian, pts_persen: wPts, ujian_persen: wUjian },
        nilai_akhir: nilaiAkhir,
        predikat: nilaiAkhir !== null ? hitungPredikat(nilaiAkhir) : null,
      };
    });

    return success({
      siswa: {
        id: siswa.id,
        nis: siswa.nis,
        nisn: siswa.nisn,
        nama: siswa.nama,
        kelas_id: siswa.kelas_id,
        kelas_nama: waliKelas.nama,
      },
      semester: {
        id: semester.id,
        nama: semester.nama,
      },
      mapel,
      catatan_wali: catatanWali?.catatan || null,
    });
  }

  return badRequest('Endpoint tidak dikenal');
}
