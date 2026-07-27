import { Env, UserPayload } from '../../types';
import { success, notFound, badRequest } from '../../utils/response';

export async function handleAdminNilai(request: Request, env: Env, user: UserPayload, url: URL): Promise<Response> {
  const subPath = url.pathname.replace('/api/admin/nilai', '');

  // GET /api/admin/nilai - monitoring semua nilai
  if ((subPath === '' || subPath === '/') && request.method === 'GET') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
    const offset = (page - 1) * perPage;
    const kelasId = url.searchParams.get('kelas_id') || '';
    const mapelId = url.searchParams.get('mata_pelajaran_id') || '';
    const jenis = url.searchParams.get('jenis') || '';
    const status = url.searchParams.get('status_validasi') || '';
    const semesterId = url.searchParams.get('semester_id') || '';

    let where = 'WHERE 1=1';
    const bindings: unknown[] = [];
    if (kelasId) { where += ' AND n.kelas_id = ?'; bindings.push(parseInt(kelasId)); }
    if (mapelId) { where += ' AND n.mata_pelajaran_id = ?'; bindings.push(parseInt(mapelId)); }
    if (jenis) { where += ' AND n.jenis = ?'; bindings.push(jenis); }
    if (status) { where += ' AND n.status_validasi = ?'; bindings.push(status); }
    if (semesterId) { where += ' AND n.semester_id = ?'; bindings.push(parseInt(semesterId)); }

    const total = (await env.DB.prepare(
      `SELECT COUNT(*) as total FROM nilai n ${where}`
    ).bind(...bindings).first<{ total: number }>())?.total || 0;

    bindings.push(perPage, offset);
    const rows = await env.DB.prepare(
      `SELECT n.*, s.nama as siswa_nama, s.nis as siswa_nis, mp.nama as mapel_nama,
              k.nama as kelas_nama, g.nama as guru_nama, sem.nama as semester_nama
       FROM nilai n
       LEFT JOIN siswa s ON n.siswa_id = s.id
       LEFT JOIN mata_pelajaran mp ON n.mata_pelajaran_id = mp.id
       LEFT JOIN kelas k ON n.kelas_id = k.id
       LEFT JOIN guru g ON n.diinput_oleh = g.id
       LEFT JOIN semester sem ON n.semester_id = sem.id
       ${where} ORDER BY n.created_at DESC LIMIT ? OFFSET ?`
    ).bind(...bindings).all();

    return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
  }

  // PUT /api/admin/nilai/:id/validasi - validasi nilai
  const validasiMatch = subPath.match(/^\/(\d+)\/validasi$/);
  if (validasiMatch && request.method === 'PUT') {
    const id = parseInt(validasiMatch[1]);
    const existing = await env.DB.prepare('SELECT id FROM nilai WHERE id = ?').bind(id).first();
    if (!existing) return notFound('Nilai');

    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    await env.DB.prepare("UPDATE nilai SET status_validasi = 'tervalidasi' WHERE id = ?").bind(id).run();

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'validate', 'nilai', ?, ?)"
    ).bind(user.sub, `Validasi nilai id=${id}`, ip).run();

    return success({ id, status_validasi: 'tervalidasi' });
  }

  return badRequest('Endpoint tidak dikenal');
}
