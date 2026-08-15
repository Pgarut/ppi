import { Env, UserPayload } from '../../types';
import { success, created, notFound, badRequest } from '../../utils/response';

function getJenisList(namaSemester: string): string[] {
  const lower = namaSemester.toLowerCase();
  if (lower.includes('1') || lower.includes('ganjil') || lower.includes('i')) {
    return ['harian', 'pts1', 'pas'];
  }
  return ['harian', 'pts2', 'pat'];
}

async function getSemesterAktif(env: Env): Promise<{ id: number; nama: string } | null> {
  return env.DB.prepare("SELECT id, nama FROM semester WHERE is_aktif = 1 LIMIT 1").first<{ id: number; nama: string }>();
}

export async function handleNilaiGuru(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPath = pathParts.slice(2).join('/');

  if (!user.guru_id) return badRequest('Anda tidak memiliki data asatidz');

  // GET assignments (mapel+kelas) untuk dropdown nilai
  if (subPath === 'nilai/assignments' && request.method === 'GET') {
    const semester = await getSemesterAktif(env);
    if (!semester) return success([]);

    let assignments = await env.DB.prepare(`
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

    return success(assignments.results);
  }

  // GET semester aktif dengan info jenis nilai
  if (subPath === 'nilai/semester-aktif' && request.method === 'GET') {
    const semester = await getSemesterAktif(env);
    if (!semester) return success(null);
    return success({
      id: semester.id,
      nama: semester.nama,
      jenis_list: getJenisList(semester.nama),
    });
  }

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

  // POST single nilai
  if ((subPath === '' || subPath === 'nilai') && request.method === 'POST') {
    const body = await request.json() as Record<string, unknown>;
    const { siswa_id, mata_pelajaran_id, kelas_id, semester_id, jenis, nilai, keterangan } = body;

    if (!siswa_id || !mata_pelajaran_id || !kelas_id || !semester_id || !jenis || nilai === undefined) {
      return badRequest('siswa_id, mata_pelajaran_id, kelas_id, semester_id, jenis, nilai wajib diisi');
    }

    const semester = await env.DB.prepare('SELECT nama FROM semester WHERE id = ?').bind(semester_id).first<{ nama: string }>();
    if (semester) {
      const valid = getJenisList(semester.nama);
      if (!valid.includes(jenis as string)) {
        return badRequest(`Jenis nilai untuk semester ini harus: ${valid.join(', ')}`);
      }
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
    if (!id) return badRequest('ID diperlukan');
    const existing = await env.DB.prepare('SELECT id, diinput_oleh FROM nilai WHERE id = ?').bind(id).first<{ id: number; diinput_oleh: number }>();
    if (!existing) return notFound('Nilai');
    if (existing.diinput_oleh !== user.guru_id) return badRequest('Anda hanya bisa mengedit nilai sendiri');

    const body = await request.json() as Record<string, unknown>;
    const setClauses: string[] = ['status_validasi = ?'];
    const vals: unknown[] = ['draft'];

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

  // DELETE hapus nilai
  if (subPath.startsWith('nilai/') && request.method === 'DELETE') {
    const id = parseInt(subPath.split('/')[1]);
    if (!id) return badRequest('ID diperlukan');
    const existing = await env.DB.prepare('SELECT id, diinput_oleh, status_validasi FROM nilai WHERE id = ?').bind(id).first<{ id: number; diinput_oleh: number; status_validasi: string }>();
    if (!existing) return notFound('Nilai');
    if (existing.diinput_oleh !== user.guru_id) return badRequest('Anda hanya bisa menghapus nilai sendiri');
    if (existing.status_validasi === 'tervalidasi') return badRequest('Tidak bisa menghapus nilai yang sudah tervalidasi');

    const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
    await env.DB.prepare('DELETE FROM nilai WHERE id = ?').bind(id).run();
    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'delete', 'nilai', ?, ?)")
      .bind(user.sub, `Hapus nilai #${id}`, ip).run();
    return success({ id });
  }

  // GET siswa per kelas untuk input nilai massal
  if (subPath === 'nilai/siswa-per-kelas' && request.method === 'GET') {
    const kelasId = url.searchParams.get('kelas_id');
    const mapelId = url.searchParams.get('mata_pelajaran_id');
    const semesterId = url.searchParams.get('semester_id');
    const jenis = url.searchParams.get('jenis') || 'harian';

    if (!kelasId || !mapelId || !semesterId) return badRequest('kelas_id, mata_pelajaran_id, semester_id diperlukan');

    const siswa = await env.DB.prepare(
      "SELECT id, nis, nisn, nama FROM siswa WHERE kelas_id = ? AND status = 'aktif' ORDER BY nama"
    ).bind(parseInt(kelasId)).all();

    const existing = await env.DB.prepare(
      'SELECT siswa_id, nilai, keterangan FROM nilai WHERE kelas_id = ? AND mata_pelajaran_id = ? AND semester_id = ? AND jenis = ? AND diinput_oleh = ?'
    ).bind(parseInt(kelasId), parseInt(mapelId), parseInt(semesterId), jenis, user.guru_id).all<{ siswa_id: number; nilai: number; keterangan?: string }>();

    const nilaiMap: Record<number, { nilai: number; keterangan?: string }> = {};
    for (const e of existing.results) { nilaiMap[e.siswa_id] = { nilai: e.nilai, keterangan: e.keterangan }; }

    return success({ siswa: siswa.results, existing: nilaiMap });
  }

  // GET template data for Excel download (all jenis)
  if (subPath === 'nilai/template' && request.method === 'GET') {
    const kelasId = url.searchParams.get('kelas_id');
    const mapelId = url.searchParams.get('mata_pelajaran_id');
    const semesterId = url.searchParams.get('semester_id');

    if (!kelasId || !mapelId || !semesterId) return badRequest('kelas_id, mata_pelajaran_id, semester_id diperlukan');

    const semester = await env.DB.prepare('SELECT nama FROM semester WHERE id = ?').bind(parseInt(semesterId)).first<{ nama: string }>();
    if (!semester) return badRequest('Semester tidak ditemukan');

    const kelas = await env.DB.prepare('SELECT nama FROM kelas WHERE id = ?').bind(parseInt(kelasId)).first<{ nama: string }>();
    if (!kelas) return badRequest('Kelas tidak ditemukan');

    const jenisList = getJenisList(semester.nama);

    const siswa = await env.DB.prepare(
      "SELECT id, nis, nisn, nama FROM siswa WHERE kelas_id = ? AND status = 'aktif' ORDER BY nama"
    ).bind(parseInt(kelasId)).all();

    // Get existing nilai for all jenis
    const placeholders = jenisList.map(() => '?').join(',');
    const allExisting = await env.DB.prepare(
      `SELECT siswa_id, jenis, nilai FROM nilai WHERE kelas_id = ? AND mata_pelajaran_id = ? AND semester_id = ? AND jenis IN (${placeholders}) AND diinput_oleh = ?`
    ).bind(parseInt(kelasId), parseInt(mapelId), parseInt(semesterId), ...jenisList, user.guru_id).all<{ siswa_id: number; jenis: string; nilai: number }>();

    const nilaiBySiswa: Record<number, Record<string, number>> = {};
    for (const e of allExisting.results) {
      if (!nilaiBySiswa[e.siswa_id]) nilaiBySiswa[e.siswa_id] = {};
      nilaiBySiswa[e.siswa_id][e.jenis] = e.nilai;
    }

    const rows = siswa.results.map((s: Record<string, unknown>) => {
      const row: Record<string, unknown> = {
        id: s.id, nis: s.nis, nisn: s.nisn, nama: s.nama,
        kelas_nama: kelas.nama,
      };
      for (const j of jenisList) {
        row[j] = nilaiBySiswa[s.id as number]?.[j] ?? null;
      }
      return row;
    });

    return success({ rows, jenis_list: jenisList, kelas_nama: kelas.nama, semester_nama: semester.nama });
  }

  // POST nilai massal (single jenis)
  if (subPath === 'nilai/nilai-massal' && request.method === 'POST') {
    const body = await request.json() as {
      kelas_id: number; mata_pelajaran_id: number; semester_id: number; jenis: string;
      entries: Array<{ siswa_id: number; nilai: number; keterangan?: string }>;
    };

    if (!body.kelas_id || !body.mata_pelajaran_id || !body.semester_id || !body.jenis || !body.entries?.length) {
      return badRequest('Semua field wajib diisi');
    }

    const semester = await env.DB.prepare('SELECT nama FROM semester WHERE id = ?').bind(body.semester_id).first<{ nama: string }>();
    if (semester) {
      const valid = getJenisList(semester.nama);
      if (!valid.includes(body.jenis)) {
        return badRequest(`Jenis nilai untuk semester ini harus: ${valid.join(', ')}`);
      }
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

    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'nilai', ?, ?)")
      .bind(user.sub, `Input nilai massal ${body.jenis} ${inserted} siswa`, ip).run();

    return success({ message: `${inserted} nilai tersimpan`, inserted });
  }

  // POST upload massal (multi jenis dari Excel)
  if (subPath === 'nilai/upload-massal' && request.method === 'POST') {
    const body = await request.json() as {
      kelas_id: number; mata_pelajaran_id: number; semester_id: number;
      entries: Array<{ siswa_id: number; jenis: string; nilai: number }>;
    };

    if (!body.kelas_id || !body.mata_pelajaran_id || !body.semester_id || !body.entries?.length) {
      return badRequest('Semua field wajib diisi');
    }

    const semester = await env.DB.prepare('SELECT nama FROM semester WHERE id = ?').bind(body.semester_id).first<{ nama: string }>();
    if (!semester) return badRequest('Semester tidak ditemukan');
    const valid = getJenisList(semester.nama);

    let inserted = 0;
    for (const e of body.entries) {
      if (!valid.includes(e.jenis)) continue;
      const existing = await env.DB.prepare(
        'SELECT id FROM nilai WHERE siswa_id = ? AND mata_pelajaran_id = ? AND semester_id = ? AND jenis = ?'
      ).bind(e.siswa_id, body.mata_pelajaran_id, body.semester_id, e.jenis).first();

      if (existing) {
        await env.DB.prepare('UPDATE nilai SET nilai = ? WHERE id = ?')
          .bind(e.nilai, existing.id).run();
      } else {
        await env.DB.prepare(
          'INSERT INTO nilai (siswa_id, mata_pelajaran_id, kelas_id, semester_id, jenis, nilai, diinput_oleh) VALUES (?, ?, ?, ?, ?, ?, ?)'
        ).bind(e.siswa_id, body.mata_pelajaran_id, body.kelas_id, body.semester_id, e.jenis, e.nilai, user.guru_id).run();
      }
      inserted++;
    }

    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'nilai', ?, ?)")
      .bind(user.sub, `Upload massal ${inserted} nilai`, ip).run();

    return success({ message: `${inserted} nilai tersimpan dari upload`, inserted });
  }

  return badRequest('Endpoint tidak dikenal');
}
