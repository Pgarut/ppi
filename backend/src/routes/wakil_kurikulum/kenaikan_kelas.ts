import { Env, UserPayload } from '../../types';
import { success, created, notFound, badRequest } from '../../utils/response';

export async function handleKenaikanKelas(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPathFull = pathParts.slice(2).join('/');
  const resource = pathParts[2];
  const subPath = subPathFull === resource ? '' : subPathFull.replace(resource + '/', '');

  // GET list kenaikan kelas
  if (subPath === '' && request.method === 'GET') {
    const rows = await env.DB.prepare(
      `SELECT kk.*, s.nama as siswa_nama, dk.nama as dari_kelas, tk.nama as ke_kelas
       FROM kenaikan_kelas kk
       LEFT JOIN siswa s ON kk.siswa_id = s.id
       LEFT JOIN kelas dk ON kk.dari_kelas_id = dk.id
       LEFT JOIN kelas tk ON kk.ke_kelas_id = tk.id
       ORDER BY kk.created_at DESC`
    ).all();
    return success(rows.results);
  }

  // Data calon naik kelas (siswa aktif per kelas)
  if (subPath === 'calon' && request.method === 'GET') {
    const kelasId = url.searchParams.get('kelas_id');
    const tahunAjaranId = url.searchParams.get('tahun_ajaran_id');

    if (!kelasId || !tahunAjaranId) return badRequest('kelas_id dan tahun_ajaran_id diperlukan');

    const rows = await env.DB.prepare(
      `SELECT s.id, s.nis, s.nama, s.kelas_id, k.nama as kelas_nama
       FROM siswa s
       LEFT JOIN kelas k ON s.kelas_id = k.id
       WHERE s.kelas_id = ? AND s.tahun_ajaran_id = ? AND s.status = 'aktif'
       ORDER BY s.nama`
    ).bind(parseInt(kelasId), parseInt(tahunAjaranId)).all();
    return success(rows.results);
  }

  // Proses kenaikan kelas
  if (subPath === 'proses' && request.method === 'POST') {
    const body = await request.json() as { siswa_id: number; dari_kelas_id: number; ke_kelas_id?: number; status: string; tahun_ajaran_id: number; no_surat_keputusan?: string };

    if (!body.siswa_id || !body.dari_kelas_id || !body.status || !body.tahun_ajaran_id) {
      return badRequest('siswa_id, dari_kelas_id, status, tahun_ajaran_id wajib diisi');
    }

    if (!['naik', 'tidak_naik', 'lulus'].includes(body.status)) {
      return badRequest('Status harus naik, tidak_naik, atau lulus');
    }

    const result = await env.DB.prepare(
      `INSERT INTO kenaikan_kelas (siswa_id, dari_kelas_id, ke_kelas_id, tahun_ajaran_id, status, no_surat_keputusan, tanggal_keputusan)
       VALUES (?, ?, ?, ?, ?, ?, date('now'))`
    ).bind(body.siswa_id, body.dari_kelas_id, body.ke_kelas_id || null, body.tahun_ajaran_id, body.status, body.no_surat_keputusan || null).run();

    // Update status siswa
    if (body.status === 'lulus') {
      await env.DB.prepare("UPDATE siswa SET status = 'lulus' WHERE id = ?").bind(body.siswa_id).run();
    }

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'kenaikan_kelas', ?, ?)"
    ).bind(user.sub, `Proses kenaikan kelas siswa=${body.siswa_id} status=${body.status}`, ip).run();

    return created({ id: result.meta?.last_row_id });
  }

  // Alumni CRUD
  if (resource === 'alumni' || (resource === 'kenaikan-kelas' && subPath.startsWith('alumni'))) {
    const alumniSubPath = resource === 'alumni' ? subPath : subPath.replace('alumni', '');
    if (request.method === 'GET') {
      const rows = await env.DB.prepare(
        `SELECT a.*, s.nama as siswa_nama, s.nis FROM alumni a
         LEFT JOIN siswa s ON a.siswa_id = s.id ORDER BY a.tahun_lulus DESC`
      ).all();
      return success(rows.results);
    }

    if (request.method === 'POST') {
      const body = await request.json() as Record<string, unknown>;
      const { siswa_id, tahun_lulus, kontak, catatan } = body;

      if (!siswa_id || !tahun_lulus) return badRequest('siswa_id dan tahun_lulus wajib diisi');

      const result = await env.DB.prepare(
        'INSERT INTO alumni (siswa_id, tahun_lulus, kontak, catatan) VALUES (?, ?, ?, ?)'
      ).bind(siswa_id, tahun_lulus, kontak || null, catatan || null).run();

      await env.DB.prepare(
        "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'alumni', ?, ?)"
      ).bind(user.sub, `Tambah alumni siswa=${siswa_id}`, ip).run();

      return created({ id: result.meta?.last_row_id });
    }

    if (request.method === 'PUT') {
      const id = parseInt(alumniSubPath);
      if (!id) return badRequest('ID diperlukan');
      const body = await request.json() as Record<string, unknown>;

      const setClauses: string[] = [];
      const vals: unknown[] = [];
      for (const f of ['tahun_lulus', 'kontak', 'catatan']) {
        if (body[f] !== undefined) { setClauses.push(`${f} = ?`); vals.push(body[f]); }
      }
      if (setClauses.length === 0) return badRequest('Tidak ada field diupdate');
      vals.push(id);

      await env.DB.prepare(`UPDATE alumni SET ${setClauses.join(', ')} WHERE id = ?`).bind(...vals).run();
      await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'alumni', ?, ?)")
        .bind(user.sub, `Update alumni #${id}`, ip).run();
      return success({ id });
    }

    if (request.method === 'DELETE') {
      const id = parseInt(alumniSubPath);
      if (!id) return badRequest('ID diperlukan');
      await env.DB.prepare('DELETE FROM alumni WHERE id = ?').bind(id).run();
      await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'delete', 'alumni', ?, ?)")
        .bind(user.sub, `Hapus alumni #${id}`, ip).run();
      return success({ id });
    }
  }

  return badRequest('Endpoint tidak dikenal');
}
