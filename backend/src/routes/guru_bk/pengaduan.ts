import { Env, UserPayload } from '../../types';
import { success, created, notFound, badRequest } from '../../utils/response';

export async function handlePengaduanBK(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPath = pathParts.slice(2).join('/');

  // GET daftar semua pengaduan
  if ((subPath === '' || subPath === 'pengaduan') && request.method === 'GET') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(50, parseInt(url.searchParams.get('per_page') || '20'));
    const offset = (page - 1) * perPage;
    const status = url.searchParams.get('status');
    const kategori = url.searchParams.get('kategori');

    let query = `SELECT p.*, s.nama as siswa_nama, s.nis as siswa_nis,
                 g.nama as pelapor_nama
                 FROM pengaduan p
                 LEFT JOIN siswa s ON p.siswa_id = s.id
                 LEFT JOIN guru g ON p.dilaporkan_oleh = g.id`;
    const bindings: unknown[] = [];
    const conditions: string[] = [];

    if (status) { conditions.push('p.status = ?'); bindings.push(status); }
    if (kategori) { conditions.push('p.kategori = ?'); bindings.push(kategori); }

    if (conditions.length > 0) query += ' WHERE ' + conditions.join(' AND ');
    query += ' ORDER BY p.created_at DESC';

    const countQuery = conditions.length > 0
      ? `SELECT COUNT(*) as total FROM pengaduan p WHERE ${conditions.join(' AND ')}`
      : 'SELECT COUNT(*) as total FROM pengaduan';

    const total = bindings.length > 0
      ? (await env.DB.prepare(countQuery).bind(...bindings).first<{ total: number }>())?.total || 0
      : (await env.DB.prepare(countQuery).first<{ total: number }>())?.total || 0;

    query += ' LIMIT ? OFFSET ?';
    bindings.push(perPage, offset);

    const rows = await env.DB.prepare(query).bind(...bindings).all();
    return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
  }

  // PUT update status pengaduan
  if (subPath.startsWith('pengaduan/') && request.method === 'PUT') {
    const id = parseInt(subPath.split('/')[1]);
    const existing = await env.DB.prepare('SELECT id FROM pengaduan WHERE id = ?').bind(id).first<{ id: number }>();
    if (!existing) return notFound('Pengaduan');

    const body = await request.json() as Record<string, unknown>;
    const { status } = body;

    if (!status) return badRequest('status wajib diisi');
    const validStatus = ['baru', 'diproses', 'selesai'];
    if (!validStatus.includes(status as string)) return badRequest('Status tidak valid');

    const { tindak_lanjut } = body;
    if (tindak_lanjut) {
      await env.DB.prepare('UPDATE pengaduan SET status = ?, tindak_lanjut = ? WHERE id = ?')
        .bind(status, tindak_lanjut, id).run();
    } else {
      await env.DB.prepare('UPDATE pengaduan SET status = ? WHERE id = ?')
        .bind(status, id).run();
    }

    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'pengaduan', ?, ?)")
      .bind(user.sub, `Update pengaduan #${id} -> ${status}`, ip).run();

    return success({ id });
  }

  return badRequest('Endpoint tidak dikenal');
}
