import { Env, UserPayload } from '../../types';
import { success, badRequest } from '../../utils/response';

export async function handleWaliKelas(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const subPath = pathParts.slice(2).join('/');
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

  if (!user.guru_id) return badRequest('Anda tidak memiliki data guru');

  // Cari kelas wali
  const waliKelas = await env.DB.prepare(
    'SELECT id, nama FROM kelas WHERE wali_kelas_id = ?'
  ).bind(user.guru_id).first<{ id: number; nama: string }>();

  if (!waliKelas) return success({ wali_kelas: null, message: 'Anda bukan wali kelas' });

  // GET data siswa kelas
  if (subPath === 'data-siswa' && request.method === 'GET') {
    const siswa = await env.DB.prepare(
      "SELECT id, nis, nisn, nama, jenis_kelamin, tempat_lahir, tanggal_lahir, alamat, status FROM siswa WHERE kelas_id = ? AND status = 'aktif' ORDER BY nama"
    ).bind(waliKelas.id).all();

    return success({ kelas: waliKelas, siswa: siswa.results });
  }

  // GET rekap absensi kelas
  if (subPath === 'rekap-absensi' && request.method === 'GET') {
    const rows = await env.DB.prepare(
      `SELECT a.status, COUNT(*) as jumlah
       FROM absensi_siswa a WHERE a.kelas_id = ?
       GROUP BY a.status`
    ).bind(waliKelas.id).all();

    return success({ kelas: waliKelas, rekap: rows.results });
  }

  // GET rekap nilai kelas
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
