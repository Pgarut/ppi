import { Env, UserPayload } from '../../types';
import { success, created, notFound, badRequest } from '../../utils/response';

export async function handleNilaiGuru(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPath = pathParts.slice(2).join('/');

  // GET daftar nilai
  if ((subPath === '' || subPath === 'nilai') && request.method === 'GET') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '50'));
    const offset = (page - 1) * perPage;

    const total = (await env.DB.prepare(
      'SELECT COUNT(*) as total FROM nilai WHERE diinput_oleh = ?'
    ).bind(user.guru_id).first<{ total: number }>())?.total || 0;

    const rows = await env.DB.prepare(
      `SELECT n.*, s.nama as siswa_nama, mp.nama as mapel_nama, k.nama as kelas_nama
       FROM nilai n
       LEFT JOIN siswa s ON n.siswa_id = s.id
       LEFT JOIN mata_pelajaran mp ON n.mata_pelajaran_id = mp.id
       LEFT JOIN kelas k ON n.kelas_id = k.id
       WHERE n.diinput_oleh = ?
       ORDER BY n.created_at DESC LIMIT ? OFFSET ?`
    ).bind(user.guru_id, perPage, offset).all();

    return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
  }

  // POST / PUT nilai
  if ((subPath === '' || subPath === 'nilai') && request.method === 'POST') {
    const body = await request.json() as Record<string, unknown>;
    const { siswa_id, mata_pelajaran_id, kelas_id, semester_id, jenis, nilai, keterangan } = body;

    if (!siswa_id || !mata_pelajaran_id || !kelas_id || !semester_id || !jenis || nilai === undefined) {
      return badRequest('siswa_id, mata_pelajaran_id, kelas_id, semester_id, jenis, nilai wajib diisi');
    }

    const validJenis = ['harian', 'tugas', 'uts', 'uas', 'akhir'];
    if (!validJenis.includes(jenis as string)) {
      return badRequest(`Jenis nilai harus: ${validJenis.join(', ')}`);
    }

    const result = await env.DB.prepare(
      `INSERT INTO nilai (siswa_id, mata_pelajaran_id, kelas_id, semester_id, jenis, nilai, keterangan, diinput_oleh, status_validasi)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'draft')`
    ).bind(siswa_id, mata_pelajaran_id, kelas_id, semester_id, jenis, nilai, keterangan || null, user.guru_id).run();

    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'nilai', ?, ?)")
      .bind(user.sub, `Input nilai ${jenis} siswa ${siswa_id}`, ip).run();

    return created({ id: result.meta?.last_row_id });
  }

  // PUT edit nilai
  if (subPath.startsWith('nilai/') && request.method === 'PUT') {
    const id = parseInt(subPath.split('/')[1]);
    const existing = await env.DB.prepare('SELECT id, diinput_oleh FROM nilai WHERE id = ?').bind(id).first<{ id: number; diinput_oleh: number }>();
    if (!existing) return notFound('Nilai');
    if (existing.diinput_oleh !== user.guru_id) return badRequest('Anda hanya bisa mengedit nilai sendiri');

    const body = await request.json() as Record<string, unknown>;
    const setClauses: string[] = [];
    const vals: unknown[] = [];

    for (const f of ['nilai', 'keterangan', 'jenis']) {
      if (body[f] !== undefined) { setClauses.push(`${f} = ?`); vals.push(body[f]); }
    }
    if (setClauses.length === 0) return badRequest('Tidak ada field diupdate');
    vals.push(id);

    await env.DB.prepare(`UPDATE nilai SET ${setClauses.join(', ')} WHERE id = ?`).bind(...vals).run();
    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'nilai', ?, ?)")
      .bind(user.sub, `Update nilai #${id}`, ip).run();
    return success({ id });
  }

  // GET siswa per kelas untuk input nilai massal
  if (subPath === 'siswa-per-kelas' && request.method === 'GET') {
    const kelasId = url.searchParams.get('kelas_id');
    const mapelId = url.searchParams.get('mata_pelajaran_id');
    const semesterId = url.searchParams.get('semester_id');
    const jenis = url.searchParams.get('jenis') || 'harian';

    if (!kelasId || !mapelId || !semesterId) return badRequest('kelas_id, mata_pelajaran_id, semester_id diperlukan');

    const siswa = await env.DB.prepare(
      "SELECT id, nis, nama FROM siswa WHERE kelas_id = ? AND status = 'aktif' ORDER BY nama"
    ).bind(parseInt(kelasId)).all();

    const existing = await env.DB.prepare(
      'SELECT siswa_id, nilai, keterangan FROM nilai WHERE kelas_id = ? AND mata_pelajaran_id = ? AND semester_id = ? AND jenis = ? AND diinput_oleh = ?'
    ).bind(parseInt(kelasId), parseInt(mapelId), parseInt(semesterId), jenis, user.guru_id).all<{ siswa_id: number; nilai: number; keterangan?: string }>();

    const nilaiMap: Record<number, { nilai: number; keterangan?: string }> = {};
    for (const e of existing.results) { nilaiMap[e.siswa_id] = { nilai: e.nilai, keterangan: e.keterangan }; }

    return success({ siswa: siswa.results, existing: nilaiMap });
  }

  // POST nilai massal
  if (subPath === 'nilai-massal' && request.method === 'POST') {
    const body = await request.json() as {
      kelas_id: number; mata_pelajaran_id: number; semester_id: number; jenis: string;
      entries: Array<{ siswa_id: number; nilai: number; keterangan?: string }>;
    };

    if (!body.kelas_id || !body.mata_pelajaran_id || !body.semester_id || !body.jenis || !body.entries?.length) {
      return badRequest('Semua field wajib diisi');
    }

    let inserted = 0;
    for (const e of body.entries) {
      const existing = await env.DB.prepare(
        'SELECT id FROM nilai WHERE siswa_id = ? AND mata_pelajaran_id = ? AND semester_id = ? AND jenis = ?'
      ).bind(e.siswa_id, body.mata_pelajaran_id, body.semester_id, body.jenis).first();

      if (existing) {
        await env.DB.prepare('UPDATE nilai SET nilai = ?, keterangan = ? WHERE id = ?')
          .bind(e.nilai, e.keterangan || null, existing.id).run();
      } else {
        await env.DB.prepare(
          'INSERT INTO nilai (siswa_id, mata_pelajaran_id, kelas_id, semester_id, jenis, nilai, keterangan, diinput_oleh) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
        ).bind(e.siswa_id, body.mata_pelajaran_id, body.kelas_id, body.semester_id, body.jenis, e.nilai, e.keterangan || null, user.guru_id).run();
      }
      inserted++;
    }

    return success({ message: `${inserted} nilai tersimpan`, inserted });
  }

  return badRequest('Endpoint tidak dikenal');
}
