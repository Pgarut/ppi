import { Env, UserPayload } from '../../types';
import { success, badRequest } from '../../utils/response';

export async function handleWaliKelas(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const subPath = pathParts.slice(2).join('/');
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

  if (!user.guru_id) return badRequest('Anda tidak memiliki data asatidz');

  // Cari kelas wali
  const waliKelas = await env.DB.prepare(
    'SELECT id, nama FROM kelas WHERE wali_kelas_id = ?'
  ).bind(user.guru_id).first<{ id: number; nama: string }>();

  if (!waliKelas) return success({ wali_kelas: null, message: 'Anda bukan wali kelas' });

  // GET data siswa kelas — LENGKAP dengan absensi per siswa & status pengaduan
  if (subPath === 'data-siswa' && request.method === 'GET') {
    const semesterAktif = await env.DB.prepare(
      "SELECT id, nama FROM semester WHERE is_aktif = 1 LIMIT 1"
    ).first<{ id: number; nama: string }>();

    const bulanTahun = url.searchParams.get('bulan_tahun') || '';

    let absensiWhere = 'WHERE kelas_id = ?';
    const absensiBindings: unknown[] = [waliKelas.id];
    if (bulanTahun) {
      absensiWhere += ' AND substr(tanggal, 1, 7) = ?';
      absensiBindings.push(bulanTahun);
    }

    const rows = await env.DB.prepare(`
      SELECT
        s.id, s.nis, s.nisn, s.nama, s.jenis_kelamin, s.kelas_id,
        k.nama as kelas_nama,
        COALESCE(a.total_kehadiran, 0) as total_kehadiran,
        COALESCE(a.hadir, 0) as hadir,
        COALESCE(a.izin, 0) as izin,
        COALESCE(a.sakit, 0) as sakit,
        COALESCE(a.alpa, 0) as alpa,
        COALESCE(p.total_pengaduan, 0) as total_pengaduan,
        COALESCE(p.pengaduan_disetujui, 0) as pengaduan_disetujui
      FROM siswa s
      JOIN kelas k ON s.kelas_id = k.id
      LEFT JOIN (
        SELECT
          siswa_id,
          COUNT(*) as total_kehadiran,
          SUM(CASE WHEN status = 'hadir' THEN 1 ELSE 0 END) as hadir,
          SUM(CASE WHEN status = 'izin' THEN 1 ELSE 0 END) as izin,
          SUM(CASE WHEN status = 'sakit' THEN 1 ELSE 0 END) as sakit,
          SUM(CASE WHEN status = 'alpa' THEN 1 ELSE 0 END) as alpa
        FROM absensi_siswa
        ${absensiWhere}
        GROUP BY siswa_id
      ) a ON a.siswa_id = s.id
      LEFT JOIN (
        SELECT
          siswa_id,
          COUNT(*) as total_pengaduan,
          SUM(CASE WHEN status IN ('ditindaklanjuti', 'selesai') THEN 1 ELSE 0 END) as pengaduan_disetujui
        FROM pengaduan
        WHERE siswa_id IN (SELECT id FROM siswa WHERE kelas_id = ?)
        GROUP BY siswa_id
      ) p ON p.siswa_id = s.id
      WHERE s.kelas_id = ? AND s.status = 'aktif'
      ORDER BY s.nama
    `).bind(...absensiBindings, waliKelas.id, waliKelas.id).all<{
      id: number; nis: string; nisn: string | null; nama: string;
      jenis_kelamin: string; kelas_id: number; kelas_nama: string;
      total_kehadiran: number; hadir: number; izin: number; sakit: number; alpa: number;
      total_pengaduan: number; pengaduan_disetujui: number;
    }>();

    const siswa = rows.results.map((r) => {
      // Status: jika ada pengaduan yang disetujui, hitung persentase
      let status = 'baik';
      let statusPersen = 100;
      if (r.total_pengaduan > 0) {
        statusPersen = Math.round((r.pengaduan_disetujui / r.total_pengaduan) * 100);
        if (statusPersen >= 75) status = 'baik';
        else if (statusPersen >= 50) status = 'cukup';
        else if (statusPersen >= 25) status = 'kurang';
        else status = 'kritis';
      }
      return {
        id: r.id,
        nis: r.nis,
        nisn: r.nisn,
        nama: r.nama,
        jenis_kelamin: r.jenis_kelamin,
        kelas_id: r.kelas_id,
        kelas_nama: r.kelas_nama,
        total_kehadiran: r.total_kehadiran,
        hadir: r.hadir,
        izin: r.izin,
        sakit: r.sakit,
        alpa: r.alpa,
        status,
        status_persen: statusPersen,
        total_pengaduan: r.total_pengaduan,
        pengaduan_disetujui: r.pengaduan_disetujui,
      };
    });

    const guruWali = await env.DB.prepare(
      'SELECT id, nip, nama FROM guru WHERE id = ?'
    ).bind(user.guru_id).first<{ id: number; nip: string; nama: string }>();

    return success({
      kelas: { id: waliKelas.id, nama: waliKelas.nama },
      wali_guru: guruWali,
      semester: semesterAktif,
      siswa,
    });
  }

  // GET rekap absensi kelas (ringkasan per status — masih dipertahankan)
  if (subPath === 'rekap-absensi' && request.method === 'GET') {
    const bulanTahun = url.searchParams.get('bulan_tahun') || '';

    let where = 'WHERE a.kelas_id = ?';
    const bindings: unknown[] = [waliKelas.id];
    if (bulanTahun) {
      where += ' AND substr(a.tanggal, 1, 7) = ?';
      bindings.push(bulanTahun);
    }

    const rows = await env.DB.prepare(
      `SELECT a.status, COUNT(*) as jumlah
       FROM absensi_siswa a ${where}
       GROUP BY a.status`
    ).bind(...bindings).all();

    return success({ kelas: waliKelas, rekap: rows.results });
  }

  // GET rekap nilai kelas (ringkasan — masih dipertahankan)
  if (subPath === 'rekap-nilai' && request.method === 'GET') {
    const semesterId = url.searchParams.get('semester_id');

    const rows = await env.DB.prepare(
      `SELECT n.jenis, COUNT(*) as total, ROUND(AVG(n.nilai), 2) as rata_rata
       FROM nilai n WHERE n.kelas_id = ? ${semesterId ? 'AND n.semester_id = ?' : ''}
       GROUP BY n.jenis`
    ).bind(...(semesterId ? [waliKelas.id, parseInt(semesterId)] : [waliKelas.id])).all();

    return success({ kelas: waliKelas, rekap: rows.results });
  }

  // PUT catatan wali kelas (update nilai_rapor)
  if (subPath == 'catatan-wali' && request.method === 'PUT') {
    const body = await request.json() as { siswa_id: number; semester_id: number; catatan: string };
    const { siswa_id, semester_id, catatan } = body;

    if (!siswa_id || !semester_id || catatan === undefined) {
      return badRequest('siswa_id, semester_id, catatan wajib diisi');
    }

    await env.DB.prepare(
      'UPDATE nilai_rapor SET catatan_wali_kelas = ? WHERE siswa_id = ? AND semester_id = ?'
    ).bind(catatan, siswa_id, semester_id).run();

    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'nilai_rapor', ?, ?)")
      .bind(user.sub, `Update catatan wali: siswa=${siswa_id} semester=${semester_id}`, ip).run();

    return success({ message: 'Catatan tersimpan' });
  }

  return badRequest('Endpoint tidak dikenal');
}
