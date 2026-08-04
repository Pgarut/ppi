import { Env, UserPayload } from '../../types';
import { success, created, notFound, badRequest } from '../../utils/response';

const JP_SLOTS = ['JP1', 'JP2', 'JP3', 'JP4', 'JP5', 'JP6', 'JP7', 'JP8'];
const JP_TIMES: Record<string, { mulai: string; selesai: string }> = {
  JP1: { mulai: '07:00', selesai: '07:45' },
  JP2: { mulai: '07:45', selesai: '08:30' },
  JP3: { mulai: '08:30', selesai: '09:15' },
  JP4: { mulai: '09:30', selesai: '10:15' },
  JP5: { mulai: '10:15', selesai: '11:00' },
  JP6: { mulai: '11:00', selesai: '11:45' },
  JP7: { mulai: '12:30', selesai: '13:15' },
  JP8: { mulai: '13:15', selesai: '14:00' },
};
const HARI = ['Sabtu', 'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis'];
const JP_PER_HARI = 8;

export async function handlePenjadwalan(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPath = pathParts.slice(2).join('/');

  // ── JP Slots ──
  if (subPath === 'jp-slots' && request.method === 'GET') {
    return success(JP_SLOTS.map(s => ({ kode: s, ...JP_TIMES[s] })));
  }

  // ── Referensi ──
  if (subPath === 'referensi' && request.method === 'GET') {
    const [kelas, guru, mapel, ruangan, semester, tingkat] = await Promise.all([
      env.DB.prepare('SELECT id, nama, ruangan_id FROM kelas ORDER BY nama').all(),
      env.DB.prepare("SELECT id, nama, nip FROM guru WHERE status_aktif = 1 ORDER BY nama").all(),
      env.DB.prepare('SELECT id, nama, kode FROM mata_pelajaran ORDER BY nama').all(),
      env.DB.prepare('SELECT id, nama FROM ruangan ORDER BY nama').all(),
      env.DB.prepare('SELECT id, nama, tahun_ajaran_id FROM semester ORDER BY tahun_ajaran_id DESC, id').all(),
      env.DB.prepare('SELECT id, nama FROM tingkat ORDER BY nama').all(),
    ]);

    // Ambil mapel per kelas dari mapel_kelas
    const mapelKelasRows = await env.DB.prepare(
      'SELECT kelas_id, mata_pelajaran_id FROM mapel_kelas'
    ).all<{ kelas_id: number; mata_pelajaran_id: number }>();
    const kelasMapelMap = new Map<number, number[]>();
    for (const row of mapelKelasRows.results) {
      if (!kelasMapelMap.has(row.kelas_id)) kelasMapelMap.set(row.kelas_id, []);
      kelasMapelMap.get(row.kelas_id)!.push(row.mata_pelajaran_id);
    }
    const kelasWithMapel = kelas.results.map((k: any) => ({
      ...k,
      mapel_ids: kelasMapelMap.get(k.id) || [],
    }));

    return success({ kelas: kelasWithMapel, guru: guru.results, mapel: mapel.results, ruangan: ruangan.results, semester: semester.results, tingkat: tingkat.results, hari: HARI });
  }

  // ── Guru by Kelas + Mapel ──
  if (subPath === 'guru-by-kelas-mapel' && request.method === 'GET') {
    const kelasId = url.searchParams.get('kelas_id');
    const mapelId = url.searchParams.get('mata_pelajaran_id');
    if (!kelasId || !mapelId) return badRequest('kelas_id dan mata_pelajaran_id diperlukan');

    const rows = await env.DB.prepare(
      `SELECT DISTINCT g.id, g.nama, g.nip
       FROM guru g
       INNER JOIN guru_kelas gk ON g.id = gk.guru_id AND gk.kelas_id = ?
       INNER JOIN guru_mapel gm ON g.id = gm.guru_id AND gm.mata_pelajaran_id = ?
       WHERE g.status_aktif = 1
       ORDER BY g.nama`
    ).bind(parseInt(kelasId), parseInt(mapelId)).all();

    return success(rows.results);
  }

  // ═══════════════════════════════════════════════
  // KESIAPAN MENGAJAR GURU
  // ═══════════════════════════════════════════════

  // GET /kesiapan — daftar semua guru + kesiapan
  if (subPath === 'kesiapan' && request.method === 'GET') {
    const semesterId = url.searchParams.get('semester_id');
    if (!semesterId) return badRequest('semester_id diperlukan');

    const guruList = await env.DB.prepare(
      `SELECT g.id, g.nip, g.nama, g.jabatan,
              gmp.hari_aktif, gmp.jp_max_per_hari, gmp.jp_max_per_minggu,
              COALESCE((SELECT json_group_array(json_object('kelas_id', gk.kelas_id, 'kelas_nama', k.nama))
                        FROM guru_kelas gk
                        LEFT JOIN kelas k ON gk.kelas_id = k.id
                        WHERE gk.guru_id = g.id), '[]') as kelas_diampu,
              COALESCE((SELECT json_group_array(json_object('mapel_id', gm.mata_pelajaran_id, 'mapel_nama', mp.nama))
                        FROM guru_mapel gm
                        LEFT JOIN mata_pelajaran mp ON gm.mata_pelajaran_id = mp.id
                        WHERE gm.guru_id = g.id), '[]') as mapel_diampu
       FROM guru g
       LEFT JOIN guru_mata_pelajaran gmp ON g.id = gmp.guru_id AND gmp.semester_id = ?
       WHERE g.status_aktif = 1
       ORDER BY g.nama`
    ).bind(parseInt(semesterId)).all();

    return success(guruList.results);
  }

  // PUT /kesiapan/:guru_id — upsert kesiapan per guru
  if (subPath.startsWith('kesiapan/') && request.method === 'PUT') {
    const pathParts_local = subPath.split('/');
    const guruId = parseInt(pathParts_local[1]);
    if (!guruId) return badRequest('guru_id tidak valid');

    const body = await request.json() as {
      semester_id: number;
      hari_aktif?: string[];
      jp_max_per_hari?: number;
      jp_max_per_minggu?: number;
    };

    if (!body.semester_id) return badRequest('semester_id diperlukan');

    const hariAktif = JSON.stringify(body.hari_aktif || []);
    const jpMaxHari = body.jp_max_per_hari || 8;
    const jpMaxMinggu = body.jp_max_per_minggu || 24;

    // Cek apakah sudah ada baris kesiapan untuk guru+semester ini
    const existing = await env.DB.prepare(
      `SELECT id FROM guru_mata_pelajaran WHERE guru_id = ? AND semester_id = ? AND hari_aktif IS NOT NULL AND hari_aktif != '[]'`
    ).bind(guruId, body.semester_id).first<{ id: number }>();

    if (existing) {
      await env.DB.prepare(
        `UPDATE guru_mata_pelajaran SET hari_aktif = ?, jp_max_per_hari = ?, jp_max_per_minggu = ? WHERE id = ?`
      ).bind(hariAktif, jpMaxHari, jpMaxMinggu, existing.id).run();
    } else {
      await env.DB.prepare(
        `INSERT INTO guru_mata_pelajaran (guru_id, semester_id, hari_aktif, jp_max_per_hari, jp_max_per_minggu, mata_pelajaran_id, kelas_id)
         VALUES (?, ?, ?, ?, ?, NULL, NULL)`
      ).bind(guruId, body.semester_id, hariAktif, jpMaxHari, jpMaxMinggu).run();
    }

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'kesiapan', ?, ?)"
    ).bind(user.sub, `Update kesiapan guru id=${guruId} semester=${body.semester_id}`, ip).run();

    return success({ guru_id: guruId, semester_id: body.semester_id });
  }

  // PUT /kesiapan — batch upsert
  if (subPath === 'kesiapan' && request.method === 'PUT') {
    const body = await request.json() as {
      semester_id: number;
      data: { guru_id: number; hari_aktif: string[]; jp_max_per_hari: number; jp_max_per_minggu: number }[];
    };

    if (!body.semester_id || !Array.isArray(body.data)) {
      return badRequest('semester_id dan data array diperlukan');
    }

    let updated = 0;
    for (const item of body.data) {
      const hariAktif = JSON.stringify(item.hari_aktif || []);
      const jpMaxHari = item.jp_max_per_hari || 8;
      const jpMaxMinggu = item.jp_max_per_minggu || 24;

      const existing = await env.DB.prepare(
        `SELECT id FROM guru_mata_pelajaran WHERE guru_id = ? AND semester_id = ? AND hari_aktif IS NOT NULL AND hari_aktif != '[]'`
      ).bind(item.guru_id, body.semester_id).first<{ id: number }>();

      if (existing) {
        await env.DB.prepare(
          `UPDATE guru_mata_pelajaran SET hari_aktif = ?, jp_max_per_hari = ?, jp_max_per_minggu = ? WHERE id = ?`
        ).bind(hariAktif, jpMaxHari, jpMaxMinggu, existing.id).run();
      } else {
        await env.DB.prepare(
          `INSERT INTO guru_mata_pelajaran (guru_id, semester_id, hari_aktif, jp_max_per_hari, jp_max_per_minggu, mata_pelajaran_id, kelas_id)
           VALUES (?, ?, ?, ?, ?, NULL, NULL)`
        ).bind(item.guru_id, body.semester_id, hariAktif, jpMaxHari, jpMaxMinggu).run();
      }
      updated++;
    }

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'batch_update', 'kesiapan', ?, ?)"
    ).bind(user.sub, `Batch update ${updated} kesiapan guru semester=${body.semester_id}`, ip).run();

    return success({ updated });
  }

  // ═══════════════════════════════════════════════
  // JADWAL
  // ═══════════════════════════════════════════════

  // Jadwal per kelas
  if (subPath === 'jadwal-per-kelas' && request.method === 'GET') {
    const kelasId = url.searchParams.get('kelas_id');
    const semesterId = url.searchParams.get('semester_id');
    if (!kelasId || !semesterId) return badRequest('kelas_id dan semester_id diperlukan');

    const rows = await env.DB.prepare(
      `SELECT jp.*, mp.nama as mapel_nama, mp.kode as mapel_kode, g.nama as guru_nama, r.nama as ruangan_nama, k.nama as kelas_nama
       FROM jadwal_pelajaran jp
       LEFT JOIN mata_pelajaran mp ON jp.mata_pelajaran_id = mp.id
       LEFT JOIN guru g ON jp.guru_id = g.id
       LEFT JOIN ruangan r ON jp.ruangan_id = r.id
       LEFT JOIN kelas k ON jp.kelas_id = k.id
       WHERE jp.kelas_id = ? AND jp.semester_id = ?
       ORDER BY CASE jp.hari
         WHEN 'Sabtu' THEN 1 WHEN 'Minggu' THEN 2 WHEN 'Senin' THEN 3
         WHEN 'Selasa' THEN 4 WHEN 'Rabu' THEN 5 WHEN 'Kamis' THEN 6
         ELSE 7 END, jp.jam_mulai`
    ).bind(parseInt(kelasId), parseInt(semesterId)).all();
    return success(rows.results);
  }

  // Jadwal CRUD
  if (subPath === 'jadwal' || (subPath.startsWith('jadwal/') && !subPath.includes('/generate') && !subPath.includes('/reset') && !subPath.includes('/publikasi') && !subPath.includes('/simpan') && !subPath.includes('/cek-bentrok'))) {
    const id = subPath === 'jadwal' ? null : parseInt(subPath.split('/')[1]);

    if (request.method === 'GET') {
      if (id) {
        const row = await env.DB.prepare(
          `SELECT jp.*, mp.nama as mapel_nama, g.nama as guru_nama, k.nama as kelas_nama, r.nama as ruangan_nama
           FROM jadwal_pelajaran jp
           LEFT JOIN mata_pelajaran mp ON jp.mata_pelajaran_id = mp.id
           LEFT JOIN guru g ON jp.guru_id = g.id
           LEFT JOIN kelas k ON jp.kelas_id = k.id
           LEFT JOIN ruangan r ON jp.ruangan_id = r.id
           WHERE jp.id = ?`
        ).bind(id).first();
        if (!row) return notFound('Jadwal');
        return success(row);
      }

      const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
      const perPage = Math.min(200, Math.max(1, parseInt(url.searchParams.get('per_page') || '100')));
      const offset = (page - 1) * perPage;
      const total = (await env.DB.prepare('SELECT COUNT(*) as total FROM jadwal_pelajaran').first<{ total: number }>())?.total || 0;

      const rows = await env.DB.prepare(
        `SELECT jp.*, mp.nama as mapel_nama, g.nama as guru_nama, k.nama as kelas_nama, r.nama as ruangan_nama
         FROM jadwal_pelajaran jp
         LEFT JOIN mata_pelajaran mp ON jp.mata_pelajaran_id = mp.id
         LEFT JOIN guru g ON jp.guru_id = g.id
         LEFT JOIN kelas k ON jp.kelas_id = k.id
         LEFT JOIN ruangan r ON jp.ruangan_id = r.id
         ORDER BY jp.semester_id DESC, jp.kelas_id, CASE jp.hari
           WHEN 'Sabtu' THEN 1 WHEN 'Minggu' THEN 2 WHEN 'Senin' THEN 3
           WHEN 'Selasa' THEN 4 WHEN 'Rabu' THEN 5 WHEN 'Kamis' THEN 6
           ELSE 7 END, jp.jam_mulai LIMIT ? OFFSET ?`
      ).bind(perPage, offset).all();

      return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
    }

    if (request.method === 'POST') {
      const body = await request.json() as Record<string, unknown>;
      const { kelas_id, mata_pelajaran_id, guru_id, ruangan_id, hari, jam_mulai, jam_selesai, semester_id } = body;

      if (!kelas_id || !mata_pelajaran_id || !guru_id || !hari || !jam_mulai || !jam_selesai || !semester_id) {
        return badRequest('Semua field wajib diisi');
      }

      if (!HARI.includes(hari as string)) {
        return badRequest('Hari tidak valid. Hari yang tersedia: ' + HARI.join(', '));
      }

      const bentrok = await cekBentrok(env, guru_id as number, kelas_id as number, hari as string, jam_mulai as string, jam_selesai as string, semester_id as number, undefined);
      if (bentrok) {
        return badRequest(bentrok);
      }

      const result = await env.DB.prepare(
        `INSERT INTO jadwal_pelajaran (kelas_id, mata_pelajaran_id, guru_id, ruangan_id, hari, jam_mulai, jam_selesai, semester_id, status_validasi)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'draft')`
      ).bind(kelas_id, mata_pelajaran_id, guru_id, ruangan_id || null, hari, jam_mulai, jam_selesai, semester_id).run();

      await env.DB.prepare(
        "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'penjadwalan', ?, ?)"
      ).bind(user.sub, `Tambah jadwal kelas ${kelas_id}`, ip).run();

      return created({ id: result.meta?.last_row_id });
    }

    if (request.method === 'PUT' && id) {
      const existing = await env.DB.prepare('SELECT * FROM jadwal_pelajaran WHERE id = ?').bind(id).first<Record<string, unknown>>();
      if (!existing) return notFound('Jadwal');

      const body = await request.json() as Record<string, unknown>;
      const setClauses: string[] = [];
      const vals: unknown[] = [];

      for (const f of ['kelas_id', 'mata_pelajaran_id', 'guru_id', 'ruangan_id', 'hari', 'jam_mulai', 'jam_selesai', 'semester_id']) {
        if (body[f] !== undefined) { setClauses.push(`${f} = ?`); vals.push(body[f]); }
      }

      if (setClauses.length === 0) return badRequest('Tidak ada field diupdate');

      // Cek bentrok jika field terkait berubah
      const hariFinal = body['hari'] as string || existing['hari'] as string;
      const jamMulaiFinal = body['jam_mulai'] as string || existing['jam_mulai'] as string;
      const jamSelesaiFinal = body['jam_selesai'] as string || existing['jam_selesai'] as string;
      const guruIdFinal = body['guru_id'] as number || existing['guru_id'] as number;
      const kelasIdFinal = body['kelas_id'] as number || existing['kelas_id'] as number;
      const semesterIdFinal = body['semester_id'] as number || existing['semester_id'] as number;

      const bentrok = await cekBentrok(env, guruIdFinal, kelasIdFinal, hariFinal, jamMulaiFinal, jamSelesaiFinal, semesterIdFinal, id);
      if (bentrok) {
        return badRequest(bentrok);
      }

      vals.push(id);
      await env.DB.prepare(`UPDATE jadwal_pelajaran SET ${setClauses.join(', ')} WHERE id = ?`).bind(...vals).run();
      await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'penjadwalan', ?, ?)")
        .bind(user.sub, `Update jadwal id=${id}`, ip).run();
      return success({ id });
    }

    if (request.method === 'DELETE' && id) {
      await env.DB.prepare('DELETE FROM jadwal_pelajaran WHERE id = ?').bind(id).run();
      await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'delete', 'penjadwalan', ?, ?)")
        .bind(user.sub, `Hapus jadwal id=${id}`, ip).run();
      return success({ id });
    }
  }

  // ── Cek Bentrok (sebelum simpan) ──
  if (subPath === 'jadwal/cek-bentrok' && request.method === 'POST') {
    const body = await request.json() as {
      guru_id: number; kelas_id: number; hari: string;
      jam_mulai: string; jam_selesai: string; semester_id: number;
      exclude_id?: number; exclude_kelas_id?: number;
    };
    const msg = await cekBentrok(env, body.guru_id, body.kelas_id, body.hari, body.jam_mulai, body.jam_selesai, body.semester_id, body.exclude_id);
    return success({ bentrok: !!msg, message: msg });
  }

  // ── Simpan jadwal (dengan conflict check) ──
  if (subPath === 'jadwal/simpan' && request.method === 'POST') {
    const body = await request.json() as {
      jadwal: { id?: number; kelas_id: number; mata_pelajaran_id: number; guru_id: number; ruangan_id?: number; hari: string; jam_mulai: string; jam_selesai: string; semester_id: number }[];
    };

    if (!Array.isArray(body.jadwal) || body.jadwal.length === 0) {
      return badRequest('Data jadwal diperlukan');
    }

    const errors: string[] = [];
    let saved = 0;

    for (const item of body.jadwal) {
      const bentrok = await cekBentrok(env, item.guru_id, item.kelas_id, item.hari, item.jam_mulai, item.jam_selesai, item.semester_id, item.id);
      if (bentrok) {
        errors.push(`Baris ${saved + 1}: ${bentrok}`);
        continue;
      }

      if (item.id) {
        await env.DB.prepare(
          `UPDATE jadwal_pelajaran SET kelas_id=?, mata_pelajaran_id=?, guru_id=?, ruangan_id=?, hari=?, jam_mulai=?, jam_selesai=?, semester_id=?
           WHERE id=?`
        ).bind(item.kelas_id, item.mata_pelajaran_id, item.guru_id, item.ruangan_id || null, item.hari, item.jam_mulai, item.jam_selesai, item.semester_id, item.id).run();
      } else {
        await env.DB.prepare(
          `INSERT INTO jadwal_pelajaran (kelas_id, mata_pelajaran_id, guru_id, ruangan_id, hari, jam_mulai, jam_selesai, semester_id, status_validasi)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'draft')`
        ).bind(item.kelas_id, item.mata_pelajaran_id, item.guru_id, item.ruangan_id || null, item.hari, item.jam_mulai, item.jam_selesai, item.semester_id).run();
      }
      saved++;
    }

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'simpan', 'penjadwalan', ?, ?)"
    ).bind(user.sub, `Simpan ${saved} jadwal (${errors.length} error)`, ip).run();

    return success({ saved, errors: errors.length > 0 ? errors : null });
  }

  // ── Auto-generate ──
  if (subPath === 'jadwal/generate' && request.method === 'POST') {
    return handleGenerateJadwal(request, env, user, ip);
  }

  // ── Reset (hanya draft) ──
  if (subPath === 'jadwal/reset' && request.method === 'POST') {
    const body = await request.json() as { semester_id?: number };
    const semId = body.semester_id;
    if (!semId) return badRequest('semester_id diperlukan');

    await env.DB.prepare(
      "DELETE FROM jadwal_pelajaran WHERE semester_id = ? AND status_validasi = 'draft'"
    ).bind(semId).run();

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'reset', 'penjadwalan', ?, ?)"
    ).bind(user.sub, `Reset jadwal draft semester ${semId}`, ip).run();

    return success({ message: 'Jadwal draft berhasil direset. Jadwal tervalidasi tetap aman.' });
  }

  // ── Publikasi ──
  if (subPath === 'jadwal/publikasi' && request.method === 'POST') {
    const body = await request.json() as { semester_id?: number };
    const semId = body.semester_id;
    if (!semId) return badRequest('semester_id diperlukan');

    const result = await env.DB.prepare(
      "UPDATE jadwal_pelajaran SET status_validasi = 'tervalidasi' WHERE semester_id = ? AND status_validasi = 'draft'"
    ).bind(semId).run();

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'publish', 'penjadwalan', ?, ?)"
    ).bind(user.sub, `Publikasi jadwal semester ${semId}`, ip).run();

    return success({ message: 'Jadwal berhasil dipublikasikan', affected: result.meta?.changes });
  }

  // ── Beban mengajar ──
  if (subPath === 'beban-mengajar' && request.method === 'GET') {
    const semesterId = url.searchParams.get('semester_id');
    if (!semesterId) return badRequest('semester_id diperlukan');

    const rows = await env.DB.prepare(
      `SELECT g.id, g.nama, g.nip,
              COALESCE(gmp.hari_aktif, '[]') as hari_aktif,
              COALESCE(gmp.jp_max_per_hari, 8) as jp_max_per_hari,
              COALESCE(gmp.jp_max_per_minggu, 24) as jp_max_per_minggu,
              (SELECT COUNT(*) FROM jadwal_pelajaran jp WHERE jp.guru_id = g.id AND jp.semester_id = ?) as jp_terisi
       FROM guru g
       LEFT JOIN guru_mata_pelajaran gmp ON g.id = gmp.guru_id AND gmp.semester_id = ?
       WHERE g.status_aktif = 1
       ORDER BY g.nama`
    ).bind(parseInt(semesterId), parseInt(semesterId)).all();
    return success(rows.results);
  }

  // ── Wali Kelas (dari Admin Master Data) ──
  if (subPath === 'wali-kelas' && request.method === 'GET') {
    const rows = await env.DB.prepare(`
      SELECT g.id, g.nip, g.nama, g.jabatan,
             k.id AS kelas_id, k.nama AS kelas_nama,
             (SELECT COUNT(*) FROM siswa WHERE kelas_id = k.id AND status = 'aktif') AS jumlah_siswa
      FROM guru g
      LEFT JOIN kelas k ON k.wali_kelas_id = g.id
      WHERE g.jabatan LIKE '%wali_kelas%'
      ORDER BY g.nama
    `).all();
    return success(rows.results);
  }

  // ── Jadwal Guru (untuk role guru mapel) ──
  if (subPath === 'jadwal-guru' && request.method === 'GET') {
    const guruId = url.searchParams.get('guru_id');
    const semesterId = url.searchParams.get('semester_id');
    if (!guruId || !semesterId) return badRequest('guru_id dan semester_id diperlukan');

    const rows = await env.DB.prepare(
      `SELECT jp.*, mp.nama as mapel_nama, k.nama as kelas_nama
       FROM jadwal_pelajaran jp
       LEFT JOIN mata_pelajaran mp ON jp.mata_pelajaran_id = mp.id
       LEFT JOIN kelas k ON jp.kelas_id = k.id
       WHERE jp.guru_id = ? AND jp.semester_id = ?
       ORDER BY CASE jp.hari
         WHEN 'Sabtu' THEN 1 WHEN 'Minggu' THEN 2 WHEN 'Senin' THEN 3
         WHEN 'Selasa' THEN 4 WHEN 'Rabu' THEN 5 WHEN 'Kamis' THEN 6
         ELSE 7 END, jp.jam_mulai`
    ).bind(parseInt(guruId), parseInt(semesterId)).all();
    return success(rows.results);
  }

  return badRequest('Endpoint tidak dikenal');
}

// ═══════════════════════════════════════════════
// FUNGSI CEK BENTROK
// ═══════════════════════════════════════════════

async function cekBentrok(
  env: Env, guruId: number, kelasId: number,
  hari: string, jamMulai: string, jamSelesai: string,
  semesterId: number, excludeId?: number
): Promise<string | null> {
  // Bentrok guru (guru yang sama, hari sama, jam overlap)
  let queryGuru = `SELECT jp.kelas_id, k.nama as kelas_nama
    FROM jadwal_pelajaran jp
    LEFT JOIN kelas k ON jp.kelas_id = k.id
    WHERE jp.guru_id = ? AND jp.hari = ? AND jp.semester_id = ?
    AND ((jp.jam_mulai <= ? AND jp.jam_selesai > ?) OR (jp.jam_mulai < ? AND jp.jam_selesai >= ?))`;
  const paramsGuru: unknown[] = [guruId, hari, semesterId, jamMulai, jamMulai, jamSelesai, jamSelesai];

  if (excludeId) {
    queryGuru += ' AND jp.id != ?';
    paramsGuru.push(excludeId);
  }

  const bentrokGuru = await env.DB.prepare(queryGuru).bind(...paramsGuru).first<{ kelas_id: number; kelas_nama: string }>();
  if (bentrokGuru) {
    return `BENTROK: Guru ini sudah mengajar di kelas ${bentrokGuru.kelas_nama || '#' + bentrokGuru.kelas_id} di hari dan jam yang sama`;
  }

  // Bentrok kelas (kelas yang sama, hari sama, jam overlap)
  let queryKelas = `SELECT mp.nama as mapel_nama
    FROM jadwal_pelajaran jp
    LEFT JOIN mata_pelajaran mp ON jp.mata_pelajaran_id = mp.id
    WHERE jp.kelas_id = ? AND jp.hari = ? AND jp.semester_id = ?
    AND ((jp.jam_mulai <= ? AND jp.jam_selesai > ?) OR (jp.jam_mulai < ? AND jp.jam_selesai >= ?))`;
  const paramsKelas: unknown[] = [kelasId, hari, semesterId, jamMulai, jamMulai, jamSelesai, jamSelesai];

  if (excludeId) {
    queryKelas += ' AND jp.id != ?';
    paramsKelas.push(excludeId);
  }

  const bentrokKelas = await env.DB.prepare(queryKelas).bind(...paramsKelas).first<{ mapel_nama: string }>();
  if (bentrokKelas) {
    return `BENTROK: Kelas ini sudah memiliki jadwal ${bentrokKelas.mapel_nama || ''} di jam yang sama`;
  }

  return null;
}

// ═══════════════════════════════════════════════
// AUTO-GENERATE JADWAL (Terverifikasi)
// ═══════════════════════════════════════════════

export async function handleGenerateJadwal(request: Request, env: Env, user: UserPayload, ip: string): Promise<Response> {
  const body = await request.json() as { semester_id?: number };
  const semesterId = body.semester_id;
  if (!semesterId) return badRequest('Semester_id diperlukan');

  // 1. Hapus jadwal draft lama
  await env.DB.prepare(
    "DELETE FROM jadwal_pelajaran WHERE semester_id = ? AND status_validasi = 'draft'"
  ).bind(semesterId).run();

  // 2. Ambil kesiapan guru
  const kesiapanList = await env.DB.prepare(
    `SELECT gmp.*, g.nama as guru_nama
     FROM guru_mata_pelajaran gmp
     LEFT JOIN guru g ON gmp.guru_id = g.id
     WHERE gmp.semester_id = ? AND gmp.hari_aktif IS NOT NULL AND gmp.hari_aktif != '[]'`
  ).bind(semesterId).all<{
    guru_id: number; hari_aktif: string; jp_max_per_hari: number;
    jp_max_per_minggu: number; guru_nama: string;
  }>();

  if (kesiapanList.results.length === 0) {
    return badRequest('Belum ada data Kesiapan Mengajar Guru untuk semester ini. Silakan isi Kesiapan Mengajar terlebih dahulu.');
  }

  // 3. Ambil guru_mapel, guru_kelas, mapel_kelas
  const [guruMapel, guruKelas, mapelKelas] = await Promise.all([
    env.DB.prepare('SELECT guru_id, mata_pelajaran_id FROM guru_mapel').all<{ guru_id: number; mata_pelajaran_id: number }>(),
    env.DB.prepare('SELECT guru_id, kelas_id FROM guru_kelas').all<{ guru_id: number; kelas_id: number }>(),
    env.DB.prepare('SELECT mata_pelajaran_id, kelas_id FROM mapel_kelas').all<{ mata_pelajaran_id: number; kelas_id: number }>(),
  ]);

  // Bangun lookup maps
  const guruToMapel = new Map<number, Set<number>>();
  for (const gm of guruMapel.results) {
    if (!guruToMapel.has(gm.guru_id)) guruToMapel.set(gm.guru_id, new Set());
    guruToMapel.get(gm.guru_id)!.add(gm.mata_pelajaran_id);
  }

  const guruToKelas = new Map<number, Set<number>>();
  for (const gk of guruKelas.results) {
    if (!guruToKelas.has(gk.guru_id)) guruToKelas.set(gk.guru_id, new Set());
    guruToKelas.get(gk.guru_id)!.add(gk.kelas_id);
  }

  const mapelToKelas = new Map<number, Set<number>>();
  const kelasToMapel = new Map<number, Set<number>>();
  for (const mk of mapelKelas.results) {
    if (!mapelToKelas.has(mk.mata_pelajaran_id)) mapelToKelas.set(mk.mata_pelajaran_id, new Set());
    mapelToKelas.get(mk.mata_pelajaran_id)!.add(mk.kelas_id);
    if (!kelasToMapel.has(mk.kelas_id)) kelasToMapel.set(mk.kelas_id, new Set());
    kelasToMapel.get(mk.kelas_id)!.add(mk.mata_pelajaran_id);
  }

  // 4. Parse kesiapan guru
  interface Kesiapan {
    guruId: number;
    nama: string;
    hariAktif: Set<string>;
    jpMaxHari: number;
    jpMaxMinggu: number;
    mapelIds: Set<number>;
    kelasIds: Set<number>;
  }

  const guruKesiapan: Kesiapan[] = [];
  for (const k of kesiapanList.results) {
    let hariAktif: string[];
    try { hariAktif = JSON.parse(k.hari_aktif as string); }
    catch { hariAktif = []; }

    if (hariAktif.length === 0) continue;

    guruKesiapan.push({
      guruId: k.guru_id,
      nama: k.guru_nama || `Guru #${k.guru_id}`,
      hariAktif: new Set(hariAktif),
      jpMaxHari: k.jp_max_per_hari || 8,
      jpMaxMinggu: k.jp_max_per_minggu || 24,
      mapelIds: guruToMapel.get(k.guru_id) || new Set(),
      kelasIds: guruToKelas.get(k.guru_id) || new Set(),
    });
  }

  // 5. Ambil jadwal tervalidasi (tidak diubah)
  const existingValidated = await env.DB.prepare(
    `SELECT kelas_id, guru_id, hari, jam_mulai, jam_selesai, mata_pelajaran_id
     FROM jadwal_pelajaran WHERE semester_id = ? AND status_validasi = 'tervalidasi'`
  ).bind(semesterId).all();

  // 6. Tracker occupancy
  const occupiedKelas = new Set<string>();   // kelas_id|hari|jam_mulai
  const occupiedGuru = new Set<string>();    // guru_id|hari|jam_mulai
  const guruJpCount = new Map<number, Map<string, number>>(); // guru_id -> { hari: count, total: count }
  const guruMingguCount = new Map<number, number>();

  for (const v of existingValidated.results) {
    const row = v as { kelas_id: number; guru_id: number; hari: string; jam_mulai: string; jam_selesai: string; mata_pelajaran_id: number };
    occupiedKelas.add(`${row.kelas_id}|${row.hari}|${row.jam_mulai}`);
    occupiedGuru.add(`${row.guru_id}|${row.hari}|${row.jam_mulai}`);

    if (!guruJpCount.has(row.guru_id)) guruJpCount.set(row.guru_id, new Map());
    const hariCount = guruJpCount.get(row.guru_id)!;
    hariCount.set(row.hari, (hariCount.get(row.hari) || 0) + 1);
    guruMingguCount.set(row.guru_id, (guruMingguCount.get(row.guru_id) || 0) + 1);
  }

  // 7. Bangun daftar kebutuhan (kelas_id, mata_pelajaran_id) dari mapel_kelas
  const needed = new Map<string, { kelasId: number; mapelId: number }[]>();
  // Group by kelas
  for (const [mapelId, kelasIds] of mapelToKelas) {
    for (const kelasId of kelasIds) {
      const key = `${kelasId}`;
      if (!needed.has(key)) needed.set(key, []);
      needed.get(key)!.push({ kelasId, mapelId });
    }
  }

  // Filter hanya kelas yang memiliki kesiapan guru
  const allKelasIds = new Set<number>();
  for (const gk of guruKelas.results) allKelasIds.add(gk.kelas_id);

  // 8. Generate: greedy assignment
  const shuffledKesiapan = [...guruKesiapan].sort(() => Math.random() - 0.5);
  let inserted = 0;
  const errors: string[] = [];

  for (const [kelasKey, needs] of needed) {
    const kelasId = parseInt(kelasKey);
    if (!allKelasIds.has(kelasId)) continue;

    for (const need of needs) {
      let assigned = false;

      // Cari guru yang bisa
      for (const guru of shuffledKesiapan) {
        if (assigned) break;

        // Check: guru bisa ngajar mapel ini?
        if (!guru.mapelIds.has(need.mapelId)) continue;

        // Check: guru bisa ngajar kelas ini?
        if (!guru.kelasIds.has(kelasId)) continue;

        // Coba assign di hari yang aktif
        for (const hari of HARI) {
          if (assigned) break;
          if (!guru.hariAktif.has(hari)) continue;

          const jpCount = guruJpCount.get(guru.guruId);
          const hariCount = jpCount?.get(hari) || 0;
          if (hariCount >= guru.jpMaxHari) continue;

          const mingguCount = guruMingguCount.get(guru.guruId) || 0;
          if (mingguCount >= guru.jpMaxMinggu) continue;

          for (const jp of JP_SLOTS) {
            const time = JP_TIMES[jp];
            const kelasKey = `${kelasId}|${hari}|${time.mulai}`;
            const guruKey = `${guru.guruId}|${hari}|${time.mulai}`;

            if (occupiedKelas.has(kelasKey)) continue;
            if (occupiedGuru.has(guruKey)) continue;

            // Assign!
            await env.DB.prepare(
              `INSERT INTO jadwal_pelajaran (kelas_id, mata_pelajaran_id, guru_id, ruangan_id, hari, jam_mulai, jam_selesai, semester_id, status_validasi)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'draft')`
            ).bind(kelasId, need.mapelId, guru.guruId, null, hari, time.mulai, time.selesai, semesterId).run();

            occupiedKelas.add(kelasKey);
            occupiedGuru.add(guruKey);

            if (!guruJpCount.has(guru.guruId)) guruJpCount.set(guru.guruId, new Map());
            const hc = guruJpCount.get(guru.guruId)!;
            hc.set(hari, (hc.get(hari) || 0) + 1);
            guruMingguCount.set(guru.guruId, (guruMingguCount.get(guru.guruId) || 0) + 1);

            inserted++;
            assigned = true;
            break;
          }
        }
      }

      if (!assigned) {
        errors.push(`Mapel #${need.mapelId} untuk kelas #${kelasId} — tidak ada guru tersedia`);
      }
    }
  }

  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'generate', 'penjadwalan', ?, ?)"
  ).bind(user.sub, `Generate jadwal semester ${semesterId}: ${inserted} berhasil`, ip).run();

  return success({
    message: `Generate selesai. ${inserted} jadwal berhasil dibuat.`,
    inserted,
    errors: errors.length > 0 ? errors : null,
  });
}
