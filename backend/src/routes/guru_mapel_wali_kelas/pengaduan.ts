import { Env, UserPayload } from '../../types';
import { success, created, notFound, badRequest } from '../../utils/response';

export async function handlePengaduan(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPath = pathParts.slice(2).join('/');

  // GET daftar pengaduan milik guru ini
  if ((subPath === '' || subPath === 'pengaduan') && request.method === 'GET') {
    const status = url.searchParams.get('status');
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(50, parseInt(url.searchParams.get('per_page') || '20'));
    const offset = (page - 1) * perPage;

    let countQuery = 'SELECT COUNT(*) as total FROM pengaduan WHERE dilaporkan_oleh = ?';
    const bindings: unknown[] = [user.guru_id];

    if (status && ['baru', 'diproses', 'selesai'].includes(status)) {
      countQuery += ' AND status = ?';
      bindings.push(status);
    }

    const total = (await env.DB.prepare(countQuery).bind(...bindings).first<{ total: number }>())?.total || 0;

    let dataQuery = `SELECT p.*, s.nama as siswa_nama, s.nis as siswa_nis, s.kelas_id, k.nama as kelas_nama
       FROM pengaduan p
       LEFT JOIN siswa s ON p.siswa_id = s.id
       LEFT JOIN kelas k ON s.kelas_id = k.id
       WHERE p.dilaporkan_oleh = ?`;
    const dataBindings: unknown[] = [user.guru_id];

    if (status && ['baru', 'diproses', 'selesai'].includes(status)) {
      dataQuery += ' AND p.status = ?';
      dataBindings.push(status);
    }

    dataQuery += ' ORDER BY p.created_at DESC LIMIT ? OFFSET ?';
    dataBindings.push(perPage, offset);

    const rows = await env.DB.prepare(dataQuery).bind(...dataBindings).all();
    return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
  }

  // POST pengaduan baru
  if ((subPath === '' || subPath === 'pengaduan') && request.method === 'POST') {
    const body = await request.json() as Record<string, unknown>;
    const { siswa_id, kategori, deskripsi, bukti_url } = body;

    if (!siswa_id || !kategori || !deskripsi) {
      return badRequest('siswa_id, kategori, deskripsi wajib diisi');
    }

    if (!['perilaku', 'kasus'].includes(kategori as string)) {
      return badRequest('kategori harus perilaku atau kasus');
    }

    const result = await env.DB.prepare(
      `INSERT INTO pengaduan (siswa_id, kategori, deskripsi, bukti_url, dilaporkan_oleh, status)
       VALUES (?, ?, ?, ?, ?, 'baru')`
    ).bind(siswa_id, kategori, deskripsi, bukti_url || null, user.guru_id).run();

    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'pengaduan', ?, ?)")
      .bind(user.sub, `Lapor ${kategori} siswa ${siswa_id}`, ip).run();

    return created({ id: result.meta?.last_row_id });
  }

  return badRequest('Endpoint tidak dikenal');
}
