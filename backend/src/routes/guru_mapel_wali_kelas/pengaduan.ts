import { Env, UserPayload } from '../../types';
import { success, created, notFound, badRequest } from '../../utils/response';

export async function handlePengaduan(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPath = pathParts.slice(2).join('/');

  // GET daftar pengaduan milik guru ini
  if ((subPath === '' || subPath === 'pengaduan') && request.method === 'GET') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(50, parseInt(url.searchParams.get('per_page') || '20'));
    const offset = (page - 1) * perPage;

    const total = (await env.DB.prepare(
      'SELECT COUNT(*) as total FROM pengaduan WHERE dilaporkan_oleh = ?'
    ).bind(user.guru_id).first<{ total: number }>())?.total || 0;

    const rows = await env.DB.prepare(
      `SELECT p.*, s.nama as siswa_nama
       FROM pengaduan p LEFT JOIN siswa s ON p.siswa_id = s.id
       WHERE p.dilaporkan_oleh = ?
       ORDER BY p.created_at DESC LIMIT ? OFFSET ?`
    ).bind(user.guru_id, perPage, offset).all();

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
