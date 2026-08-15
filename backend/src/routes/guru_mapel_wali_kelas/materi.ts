import { Env, UserPayload } from '../../types';
import { success, created, notFound, badRequest } from '../../utils/response';

export async function handleMateriGuru(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL
): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPath = pathParts.slice(2).join('/');

  if (!user.guru_id) return badRequest('Guru ID tidak ditemukan');

  // GET /guru/materi/assignments — daftar mapel+kelas yang diampu
  if (subPath === 'materi/assignments' && request.method === 'GET') {
    const semester = await env.DB.prepare(
      "SELECT id FROM semester WHERE is_aktif = 1 LIMIT 1"
    ).first<{ id: number }>();

    let assignments;
    if (semester) {
      assignments = await env.DB.prepare(`
        SELECT DISTINCT src.mata_pelajaran_id, mp.nama as mapel_nama,
                src.kelas_id, k.nama as kelas_nama
        FROM (
          SELECT mata_pelajaran_id, kelas_id FROM guru_mapel_kelas WHERE guru_id = ?
          UNION
          SELECT mata_pelajaran_id, kelas_id FROM guru_mata_pelajaran
          WHERE guru_id = ? AND semester_id = ? AND mata_pelajaran_id IS NOT NULL AND kelas_id IS NOT NULL
        ) src
        JOIN mata_pelajaran mp ON src.mata_pelajaran_id = mp.id
        JOIN kelas k ON src.kelas_id = k.id
        ORDER BY mp.nama, k.nama
      `).bind(user.guru_id, user.guru_id, semester.id).all();
    } else {
      assignments = await env.DB.prepare(`
        SELECT DISTINCT src.mata_pelajaran_id, mp.nama as mapel_nama,
                src.kelas_id, k.nama as kelas_nama
        FROM (
          SELECT mata_pelajaran_id, kelas_id FROM guru_mapel_kelas WHERE guru_id = ?
          UNION
          SELECT mata_pelajaran_id, kelas_id FROM guru_mata_pelajaran
          WHERE guru_id = ? AND mata_pelajaran_id IS NOT NULL AND kelas_id IS NOT NULL
        ) src
        JOIN mata_pelajaran mp ON src.mata_pelajaran_id = mp.id
        JOIN kelas k ON src.kelas_id = k.id
        ORDER BY mp.nama, k.nama
      `).bind(user.guru_id, user.guru_id).all();
    }

    return success(assignments.results);
  }

  // GET /guru/materi — daftar materi (list)
  if ((subPath === '' || subPath === 'materi') && request.method === 'GET') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '50'));
    const offset = (page - 1) * perPage;
    const kelasId = url.searchParams.get('kelas_id');
    const mapelId = url.searchParams.get('mata_pelajaran_id');

    let where = 'WHERE m.guru_id = ?';
    const params: any[] = [user.guru_id];

    if (kelasId) {
      where += ' AND m.kelas_id = ?';
      params.push(parseInt(kelasId));
    }
    if (mapelId) {
      where += ' AND m.mata_pelajaran_id = ?';
      params.push(parseInt(mapelId));
    }

    const total = (await env.DB.prepare(
      `SELECT COUNT(*) as total FROM materi m ${where}`
    ).bind(...params).first<{ total: number }>())?.total || 0;

    params.push(perPage, offset);
    const rows = await env.DB.prepare(
      `SELECT m.*, mp.nama as mapel_nama, k.nama as kelas_nama
       FROM materi m
       LEFT JOIN mata_pelajaran mp ON m.mata_pelajaran_id = mp.id
       LEFT JOIN kelas k ON m.kelas_id = k.id
       ${where}
       ORDER BY m.created_at DESC
       LIMIT ? OFFSET ?`
    ).bind(...params).all();

    return success({
      items: rows.results,
      pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
    });
  }

  // POST /guru/materi — tambah materi baru
  if ((subPath === '' || subPath === 'materi') && request.method === 'POST') {
    const body = await request.json() as {
      mata_pelajaran_id: number; kelas_id: number; judul: string;
      deskripsi?: string; link_url: string; link_youtube?: string;
      pertemuan?: string; is_aktif?: number;
    };

    if (!body.mata_pelajaran_id || !body.kelas_id || !body.judul || !body.link_url) {
      return badRequest('mata_pelajaran_id, kelas_id, judul, dan link_url wajib diisi');
    }

    const result = await env.DB.prepare(
      `INSERT INTO materi (guru_id, mata_pelajaran_id, kelas_id, judul, deskripsi, link_url, link_youtube, pertemuan, is_aktif)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
    ).bind(
      user.guru_id, body.mata_pelajaran_id, body.kelas_id,
      body.judul, body.deskripsi || null, body.link_url,
      body.link_youtube || null, body.pertemuan || null, body.is_aktif ?? 1
    ).run();

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'materi', ?, ?)"
    ).bind(user.sub, `Tambah materi "${body.judul}" kelas ${body.kelas_id}`, ip).run();

    return created({ id: result.meta?.last_row_id });
  }

  // PUT /guru/materi/:id — edit materi
  if (subPath.startsWith('materi/') && request.method === 'PUT') {
    const id = parseInt(subPath.split('/')[1]);
    if (!id) return badRequest('ID tidak valid');

    const existing = await env.DB.prepare(
      'SELECT id, guru_id FROM materi WHERE id = ?'
    ).bind(id).first<{ id: number; guru_id: number }>();
    if (!existing) return notFound('Materi');
    if (existing.guru_id !== user.guru_id) return badRequest('Anda hanya bisa mengedit materi sendiri');

    const body = await request.json() as Record<string, unknown>;
    const setClauses: string[] = [];
    const vals: unknown[] = [];

    for (const f of ['judul', 'deskripsi', 'link_url', 'link_youtube', 'pertemuan', 'is_aktif', 'mata_pelajaran_id', 'kelas_id']) {
      if (body[f] !== undefined) {
        setClauses.push(`${f} = ?`);
        vals.push(body[f]);
      }
    }
    if (setClauses.length === 0) return badRequest('Tidak ada field diupdate');

    setClauses.push("updated_at = datetime('now')");
    vals.push(id);

    await env.DB.prepare(`UPDATE materi SET ${setClauses.join(', ')} WHERE id = ?`).bind(...vals).run();

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'materi', ?, ?)"
    ).bind(user.sub, `Update materi #${id}`, ip).run();

    return success({ id });
  }

  // DELETE /guru/materi/:id — hapus materi
  if (subPath.startsWith('materi/') && request.method === 'DELETE') {
    const id = parseInt(subPath.split('/')[1]);
    if (!id) return badRequest('ID tidak valid');

    const existing = await env.DB.prepare(
      'SELECT id, guru_id, judul FROM materi WHERE id = ?'
    ).bind(id).first<{ id: number; guru_id: number; judul: string }>();
    if (!existing) return notFound('Materi');
    if (existing.guru_id !== user.guru_id) return badRequest('Anda hanya bisa menghapus materi sendiri');

    await env.DB.prepare('DELETE FROM materi WHERE id = ?').bind(id).run();

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'delete', 'materi', ?, ?)"
    ).bind(user.sub, `Hapus materi "${existing.judul}"`, ip).run();

    return success({ id });
  }

  // PUT /guru/materi/:id/toggle — aktifkan/nonaktifkan
  if (subPath.startsWith('materi/') && subPath.endsWith('/toggle') && request.method === 'PUT') {
    const id = parseInt(subPath.split('/')[1]);
    if (!id) return badRequest('ID tidak valid');

    const existing = await env.DB.prepare(
      'SELECT id, guru_id, is_aktif FROM materi WHERE id = ?'
    ).bind(id).first<{ id: number; guru_id: number; is_aktif: number }>();
    if (!existing) return notFound('Materi');
    if (existing.guru_id !== user.guru_id) return badRequest('Anda hanya bisa mengubah materi sendiri');

    const newStatus = existing.is_aktif === 1 ? 0 : 1;
    await env.DB.prepare("UPDATE materi SET is_aktif = ?, updated_at = datetime('now') WHERE id = ?")
      .bind(newStatus, id).run();

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'toggle', 'materi', ?, ?)"
    ).bind(user.sub, `Toggle materi #${id} → ${newStatus ? 'aktif' : 'nonaktif'}`, ip).run();

    return success({ id, is_aktif: newStatus });
  }

  return badRequest('Endpoint tidak dikenal');
}
