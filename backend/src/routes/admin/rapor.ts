import { Env, UserPayload } from '../../types';
import { success, notFound, badRequest } from '../../utils/response';

export async function handleAdminRapor(request: Request, env: Env, user: UserPayload, url: URL): Promise<Response> {
  const subPath = url.pathname.replace('/api/admin/rapor', '');

  // GET /api/admin/rapor - monitoring rapor
  if ((subPath === '' || subPath === '/') && request.method === 'GET') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
    const offset = (page - 1) * perPage;
    const kelasId = url.searchParams.get('kelas_id') || '';
    const semesterId = url.searchParams.get('semester_id') || '';
    const statusKirim = url.searchParams.get('status_kirim') || '';

    let where = 'WHERE 1=1';
    const bindings: unknown[] = [];
    if (kelasId) { where += ' AND nr.kelas_id = ?'; bindings.push(parseInt(kelasId)); }
    if (semesterId) { where += ' AND nr.semester_id = ?'; bindings.push(parseInt(semesterId)); }
    if (statusKirim) { where += ' AND nr.status_kirim = ?'; bindings.push(statusKirim); }

    const total = (await env.DB.prepare(
      `SELECT COUNT(*) as total FROM nilai_rapor nr ${where}`
    ).bind(...bindings).first<{ total: number }>())?.total || 0;

    bindings.push(perPage, offset);
    const rows = await env.DB.prepare(
      `SELECT nr.*, s.nama as siswa_nama, s.nis as siswa_nis, mp.nama as mapel_nama,
              k.nama as kelas_nama, sem.nama as semester_nama, g.nama as wali_kelas_nama
       FROM nilai_rapor nr
       LEFT JOIN siswa s ON nr.siswa_id = s.id
       LEFT JOIN mata_pelajaran mp ON nr.mata_pelajaran_id = mp.id
       LEFT JOIN kelas k ON nr.kelas_id = k.id
       LEFT JOIN semester sem ON nr.semester_id = sem.id
       LEFT JOIN guru g ON nr.wali_kelas_id = g.id
       ${where} ORDER BY nr.status_kirim, k.nama, s.nama LIMIT ? OFFSET ?`
    ).bind(...bindings).all();

    return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
  }

  // POST /api/admin/rapor/:id/cetak - tandai rapor sebagai dicetak
  const cetakMatch = subPath.match(/^\/(\d+)\/cetak$/);
  if (cetakMatch && request.method === 'POST') {
    const id = parseInt(cetakMatch[1]);
    const existing = await env.DB.prepare('SELECT id FROM nilai_rapor WHERE id = ?').bind(id).first();
    if (!existing) return notFound('Rapor');

    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

    // Simpan ke arsip
    const rapor = await env.DB.prepare(
      'SELECT siswa_id, kelas_id, semester_id FROM nilai_rapor WHERE id = ?'
    ).bind(id).first<{ siswa_id: number; kelas_id: number; semester_id: number }>();

    if (rapor) {
      await env.DB.prepare(
        "INSERT INTO rapor_arsip (siswa_id, semester_id, file_url) VALUES (?, ?, ?)"
      ).bind(rapor.siswa_id, rapor.semester_id, null).run();
    }

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'cetak', 'rapor', ?, ?)"
    ).bind(user.sub, `Cetak rapor id=${id}`, ip).run();

    return success({ id, message: 'Rapor dicetak dan diarsipkan' });
  }

  // GET /api/admin/rapor/arsip - arsip rapor
  if (subPath === '/arsip' && request.method === 'GET') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
    const offset = (page - 1) * perPage;

    const total = (await env.DB.prepare('SELECT COUNT(*) as total FROM rapor_arsip').first<{ total: number }>())?.total || 0;

    const rows = await env.DB.prepare(
      `SELECT ra.*, s.nama as siswa_nama, s.nis as siswa_nis, sem.nama as semester_nama
       FROM rapor_arsip ra
       LEFT JOIN siswa s ON ra.siswa_id = s.id
       LEFT JOIN semester sem ON ra.semester_id = sem.id
       ORDER BY ra.dicetak_pada DESC LIMIT ? OFFSET ?`
    ).bind(perPage, offset).all();

    return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
  }

  return badRequest('Endpoint tidak dikenal');
}
