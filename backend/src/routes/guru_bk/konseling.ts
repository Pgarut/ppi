import { Env, UserPayload } from '../../types';
import { success, created, notFound, badRequest } from '../../utils/response';

export async function handleKonselingBK(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPath = pathParts.slice(2).join('/');

  // ── Jadwal Konseling ──

  if (subPath === 'jadwal-konseling' || subPath.startsWith('jadwal-konseling/')) {
    // GET siswa per kelas (untuk form jadwal — pilih kelas → lihat siswa + status jadwal)
    if (subPath === 'jadwal-konseling/siswa' && request.method === 'GET') {
      const kelasId = url.searchParams.get('kelas_id');
      if (!kelasId) return badRequest('kelas_id diperlukan');

      const rows = await env.DB.prepare(
        `SELECT s.id, s.nis, s.nisn, s.nama, s.kelas_id, k.nama as kelas_nama,
                jk.id as jadwal_id, jk.tanggal as jadwal_tanggal, jk.jam as jadwal_jam,
                jk.status as jadwal_status, jk.jenis as jadwal_jenis
         FROM siswa s
         JOIN kelas k ON s.kelas_id = k.id
         LEFT JOIN jadwal_konseling jk ON jk.siswa_id = s.id AND jk.guru_bk_id = ?
         WHERE s.kelas_id = ? AND s.status = 'aktif'
         ORDER BY s.nis ASC`
      ).bind(user.guru_id, parseInt(kelasId)).all();

      return success(rows.results);
    }

    // GET history (jadwal + catatan konseling digabung)
    if (subPath === 'jadwal-konseling/history' && request.method === 'GET') {
      const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
      const perPage = Math.min(50, parseInt(url.searchParams.get('per_page') || '20'));
      const offset = (page - 1) * perPage;

      const total = (await env.DB.prepare(
        `SELECT COUNT(*) as total FROM jadwal_konseling WHERE guru_bk_id = ?`
      ).bind(user.guru_id).first<{ total: number }>())?.total || 0;

      const rows = await env.DB.prepare(
        `SELECT jk.*, s.nama as siswa_nama, s.nis as siswa_nis, s.nisn as siswa_nisn,
                k.nama as kelas_nama, k.id as kelas_id,
                ko.id as konseling_id, ko.catatan, ko.tindak_lanjut as konseling_tindak_lanjut
         FROM jadwal_konseling jk
         LEFT JOIN siswa s ON jk.siswa_id = s.id
         LEFT JOIN kelas k ON s.kelas_id = k.id
         LEFT JOIN konseling ko ON ko.jadwal_id = jk.id
         WHERE jk.guru_bk_id = ?
         ORDER BY jk.tanggal DESC, jk.jam DESC
         LIMIT ? OFFSET ?`
      ).bind(user.guru_id, perPage, offset).all();

      return success({
        items: rows.results,
        pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
      });
    }

    // GET daftar jadwal
    if (request.method === 'GET') {
      const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
      const perPage = Math.min(50, parseInt(url.searchParams.get('per_page') || '20'));
      const offset = (page - 1) * perPage;

      const total = (await env.DB.prepare(
        `SELECT COUNT(*) as total FROM jadwal_konseling WHERE guru_bk_id = ?`
      ).bind(user.guru_id).first<{ total: number }>())?.total || 0;

      const rows = await env.DB.prepare(
        `SELECT jk.*, s.nama as siswa_nama, s.nis as siswa_nis, s.nisn as siswa_nisn,
                k.nama as kelas_nama
         FROM jadwal_konseling jk
         LEFT JOIN siswa s ON jk.siswa_id = s.id
         LEFT JOIN kelas k ON s.kelas_id = k.id
         WHERE jk.guru_bk_id = ?
         ORDER BY jk.tanggal DESC, jk.jam DESC
         LIMIT ? OFFSET ?`
      ).bind(user.guru_id, perPage, offset).all();

      return success({
        items: rows.results,
        pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
      });
    }

    if (request.method === 'POST') {
      const body = await request.json() as Record<string, unknown>;
      const { siswa_id, tanggal, jam, hari, jenis, catatan } = body;
      if (!tanggal || !jenis) return badRequest('tanggal dan jenis wajib diisi');
      const validJenis = ['individu', 'kelompok', 'online'];
      if (!validJenis.includes(jenis as string)) return badRequest('jenis harus individu, kelompok, atau online');

      // Insert jadwal
      const result = await env.DB.prepare(
        'INSERT INTO jadwal_konseling (siswa_id, guru_bk_id, tanggal, jam, hari, jenis, status) VALUES (?, ?, ?, ?, ?, ?, ?)'
      ).bind(siswa_id || null, user.guru_id, tanggal, jam || null, hari || null, jenis, 'dijadwalkan').run();

      const jadwalId = result.meta?.last_row_id;

      // Jika ada catatan, langsung buat entry konseling juga
      if (catatan && catatan.toString().trim() !== '') {
        await env.DB.prepare(
          'INSERT INTO konseling (jadwal_id, siswa_id, guru_bk_id, tanggal, catatan) VALUES (?, ?, ?, ?, ?)'
        ).bind(jadwalId, siswa_id || null, user.guru_id, tanggal, catatan).run();
      }

      await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'konseling', ?, ?)")
        .bind(user.sub, `Buat jadwal konseling: ${tanggal}`, ip).run();
      return created({ id: jadwalId });
    }

    if (request.method === 'PUT') {
      const id = parseInt(subPath.split('/')[2]);
      if (!id) return badRequest('ID diperlukan');
      const body = await request.json() as Record<string, unknown>;
      const setClauses: string[] = [];
      const vals: unknown[] = [];

      for (const f of ['siswa_id', 'tanggal', 'jam', 'hari', 'jenis', 'status']) {
        if (body[f] !== undefined) {
          if (f === 'jenis') {
            const validJenis = ['individu', 'kelompok', 'online'];
            if (!validJenis.includes(body[f] as string)) return badRequest('jenis harus individu, kelompok, atau online');
          }
          if (f === 'status') {
            const validStatus = ['dijadwalkan', 'selesai', 'dibatalkan'];
            if (!validStatus.includes(body[f] as string)) return badRequest('status harus dijadwalkan, selesai, atau dibatalkan');
          }
          setClauses.push(`${f} = ?`); vals.push(body[f]);
        }
      }
      if (setClauses.length === 0) return badRequest('Tidak ada field diupdate');
      vals.push(id);
      await env.DB.prepare(`UPDATE jadwal_konseling SET ${setClauses.join(', ')} WHERE id = ?`).bind(...vals).run();
      return success({ id });
    }

    if (request.method === 'DELETE') {
      const id = parseInt(subPath.split('/')[2]);
      if (!id) return badRequest('ID diperlukan');
      await env.DB.prepare('DELETE FROM jadwal_konseling WHERE id = ?').bind(id).run();
      return success({ id });
    }
  }

  // ── Data Konseling (Catatan) ──

  if (subPath.startsWith('konseling')) {
    if (request.method === 'GET') {
      const id = subPath.split('/').length > 1 ? parseInt(subPath.split('/')[1]) : null;
      if (id) {
        const row = await env.DB.prepare(
          `SELECT k.*, s.nama as siswa_nama, g.nama as guru_bk_nama
           FROM konseling k
           LEFT JOIN siswa s ON k.siswa_id = s.id
           LEFT JOIN guru g ON k.guru_bk_id = g.id
           WHERE k.id = ?`
        ).bind(id).first();
        if (!row) return notFound('Konseling');
        return success(row);
      }
      // List konseling
      const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
      const perPage = Math.min(50, parseInt(url.searchParams.get('per_page') || '20'));
      const offset = (page - 1) * perPage;

      const total = (await env.DB.prepare(
        `SELECT COUNT(*) as total FROM konseling WHERE guru_bk_id = ?`
      ).bind(user.guru_id).first<{ total: number }>())?.total || 0;

      const rows = await env.DB.prepare(
        `SELECT k.*, s.nama as siswa_nama, s.nis as siswa_nis, s.nisn as siswa_nisn,
                kls.nama as kelas_nama
         FROM konseling k
         LEFT JOIN siswa s ON k.siswa_id = s.id
         LEFT JOIN kelas kls ON s.kelas_id = kls.id
         WHERE k.guru_bk_id = ?
         ORDER BY k.tanggal DESC
         LIMIT ? OFFSET ?`
      ).bind(user.guru_id, perPage, offset).all();

      return success({
        items: rows.results,
        pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
      });
    }

    if (request.method === 'POST') {
      const body = await request.json() as Record<string, unknown>;
      const { jadwal_id, siswa_id, tanggal, catatan, tindak_lanjut } = body;
      if (!siswa_id || !tanggal) return badRequest('siswa_id dan tanggal wajib diisi');
      const result = await env.DB.prepare(
        'INSERT INTO konseling (jadwal_id, siswa_id, guru_bk_id, tanggal, catatan, tindak_lanjut) VALUES (?, ?, ?, ?, ?, ?)'
      ).bind(jadwal_id || null, siswa_id, user.guru_id, tanggal, catatan || null, tindak_lanjut || null).run();
      await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'konseling', ?, ?)")
        .bind(user.sub, `Catat konseling siswa=${siswa_id}`, ip).run();
      return created({ id: result.meta?.last_row_id });
    }

    if (request.method === 'PUT') {
      const id = parseInt(subPath.split('/')[1]);
      if (!id) return badRequest('ID diperlukan');
      const body = await request.json() as Record<string, unknown>;
      const setClauses: string[] = [];
      const vals: unknown[] = [];
      for (const f of ['catatan', 'tindak_lanjut']) {
        if (body[f] !== undefined) { setClauses.push(`${f} = ?`); vals.push(body[f]); }
      }
      if (setClauses.length === 0) return badRequest('Tidak ada field diupdate');
      vals.push(id);
      await env.DB.prepare(`UPDATE konseling SET ${setClauses.join(', ')} WHERE id = ?`).bind(...vals).run();
      return success({ id });
    }
  }

  // ── Bakat & Minat ──

  if (subPath.startsWith('bakat-minat')) {
    // GET — dukung filter kelas_id, join kelas_nama
    if (request.method === 'GET') {
      const kelasId = url.searchParams.get('kelas_id');
      let query = `SELECT bm.*, s.nama as siswa_nama, s.nis as siswa_nis, s.nisn as siswa_nisn,
                          k.nama as kelas_nama
                   FROM bakat_minat bm
                   LEFT JOIN siswa s ON bm.siswa_id = s.id
                   LEFT JOIN kelas k ON s.kelas_id = k.id
                   WHERE bm.guru_bk_id = ?`;
      const bindings: unknown[] = [user.guru_id];

      if (kelasId) {
        query += ' AND s.kelas_id = ?';
        bindings.push(parseInt(kelasId));
      }

      query += ' ORDER BY bm.created_at DESC';
      const rows = await env.DB.prepare(query).bind(...bindings).all();
      return success(rows.results);
    }

    // GET siswa per kelas (untuk tabel Bakat & Minat — lihat status input per siswa)
    if (subPath === 'bakat-minat/siswa' && request.method === 'GET') {
      const kelasId = url.searchParams.get('kelas_id');
      if (!kelasId) return badRequest('kelas_id diperlukan');

      const rows = await env.DB.prepare(
        `SELECT s.id, s.nis, s.nisn, s.nama, s.kelas_id, k.nama as kelas_nama,
                bm.id as bm_id, bm.jenis as bm_jenis, bm.deskripsi as bm_deskripsi,
                bm.catatan_pengembangan as bm_catatan
         FROM siswa s
         JOIN kelas k ON s.kelas_id = k.id
         LEFT JOIN bakat_minat bm ON bm.siswa_id = s.id AND bm.guru_bk_id = ?
         WHERE s.kelas_id = ? AND s.status = 'aktif'
         ORDER BY s.nis ASC`
      ).bind(user.guru_id, parseInt(kelasId)).all();

      return success(rows.results);
    }

    if (request.method === 'POST') {
      const body = await request.json() as Record<string, unknown>;
      const { siswa_id, jenis, deskripsi, catatan_pengembangan } = body;
      if (!siswa_id || !jenis || !deskripsi) return badRequest('siswa_id, jenis, deskripsi wajib diisi');
      const validJenisBM = ['bakat', 'minat'];
      if (!validJenisBM.includes(jenis as string)) return badRequest('jenis bakat minat tidak valid (harus bakat atau minat)');
      const result = await env.DB.prepare(
        'INSERT INTO bakat_minat (siswa_id, jenis, deskripsi, catatan_pengembangan, guru_bk_id) VALUES (?, ?, ?, ?, ?)'
      ).bind(siswa_id, jenis, deskripsi, catatan_pengembangan || null, user.guru_id).run();
      await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'bakat_minat', ?, ?)")
        .bind(user.sub, `Catat ${jenis} siswa=${siswa_id}`, ip).run();
      return created({ id: result.meta?.last_row_id });
    }

    if (request.method === 'PUT') {
      const id = parseInt(subPath.split('/')[1]);
      if (!id) return badRequest('ID diperlukan');
      const body = await request.json() as Record<string, unknown>;
      const setClauses: string[] = [];
      const vals: unknown[] = [];
      for (const f of ['jenis', 'deskripsi', 'catatan_pengembangan']) {
        if (body[f] !== undefined) {
          if (f === 'jenis') {
            const validJenisBM = ['bakat', 'minat'];
            if (!validJenisBM.includes(body[f] as string)) return badRequest('jenis bakat minat tidak valid (harus bakat atau minat)');
          }
          setClauses.push(`${f} = ?`); vals.push(body[f]);
        }
      }
      if (setClauses.length === 0) return badRequest('Tidak ada field diupdate');
      vals.push(id);
      await env.DB.prepare(`UPDATE bakat_minat SET ${setClauses.join(', ')} WHERE id = ?`).bind(...vals).run();
      return success({ id });
    }

    if (request.method === 'DELETE') {
      const id = parseInt(subPath.split('/')[1]);
      if (!id) return badRequest('ID diperlukan');
      await env.DB.prepare('DELETE FROM bakat_minat WHERE id = ?').bind(id).run();
      return success({ id });
    }
  }

  return badRequest('Endpoint tidak dikenal');
}
