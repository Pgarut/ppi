import { Env, UserPayload } from '../../types';
import { success, created, notFound, badRequest } from '../../utils/response';

export async function handleKonselingBK(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPath = pathParts.slice(2).join('/');

  // ── Jadwal Konseling ──

  if (subPath.startsWith('jadwal-konseling')) {
    if (request.method === 'GET') {
      const rows = await env.DB.prepare(
        `SELECT jk.*, s.nama as siswa_nama
         FROM jadwal_konseling jk
         LEFT JOIN siswa s ON jk.siswa_id = s.id
         WHERE jk.guru_bk_id = ?
         ORDER BY jk.tanggal DESC`
      ).bind(user.guru_id).all();
      return success(rows.results);
    }

    if (request.method === 'POST') {
      const body = await request.json() as Record<string, unknown>;
      const { siswa_id, tanggal, jam, jenis } = body;
      if (!tanggal || !jenis) return badRequest('tanggal dan jenis wajib diisi');
      const validJenis = ['individu', 'kelompok', 'online'];
      if (!validJenis.includes(jenis as string)) return badRequest('jenis harus individu, kelompok, atau online');
      const result = await env.DB.prepare(
        'INSERT INTO jadwal_konseling (siswa_id, guru_bk_id, tanggal, jam, jenis) VALUES (?, ?, ?, ?, ?)'
      ).bind(siswa_id || null, user.guru_id, tanggal, jam || null, jenis).run();
      await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'konseling', ?, ?)")
        .bind(user.sub, `Buat jadwal konseling: ${tanggal}`, ip).run();
      return created({ id: result.meta?.last_row_id });
    }

    if (request.method === 'PUT') {
      const id = parseInt(subPath.split('/')[2]);
      if (!id) return badRequest('ID diperlukan');
      const body = await request.json() as Record<string, unknown>;
      const setClauses: string[] = [];
      const vals: unknown[] = [];
      for (const f of ['siswa_id', 'tanggal', 'jam', 'jenis', 'status']) {
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

  // ── Data Konseling ──

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
      const rows = await env.DB.prepare(
        `SELECT k.*, s.nama as siswa_nama
         FROM konseling k
         LEFT JOIN siswa s ON k.siswa_id = s.id
         WHERE k.guru_bk_id = ?
         ORDER BY k.tanggal DESC`
      ).bind(user.guru_id).all();
      return success(rows.results);
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
    if (request.method === 'GET') {
      const rows = await env.DB.prepare(
        `SELECT bm.*, s.nama as siswa_nama
         FROM bakat_minat bm
         LEFT JOIN siswa s ON bm.siswa_id = s.id
         WHERE bm.guru_bk_id = ?
         ORDER BY bm.created_at DESC`
      ).bind(user.guru_id).all();
      return success(rows.results);
    }

    if (request.method === 'POST') {
      const body = await request.json() as Record<string, unknown>;
      const { siswa_id, jenis, deskripsi, catatan_pengembangan } = body;
      if (!siswa_id || !jenis || !deskripsi) return badRequest('siswa_id, jenis, deskripsi wajib diisi');
      const validJenisBM = ['akademik', 'olahraga', 'seni', 'keagamaan', 'organisasi', 'lainnya'];
      if (!validJenisBM.includes(jenis as string)) return badRequest('jenis bakat minat tidak valid');
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
            const validJenisBM = ['akademik', 'olahraga', 'seni', 'keagamaan', 'organisasi', 'lainnya'];
            if (!validJenisBM.includes(body[f] as string)) return badRequest('jenis bakat minat tidak valid');
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
