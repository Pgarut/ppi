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
const HARI = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
const MAX_JP_PER_HARI = 8;
const MAX_JP_PER_MINGGU = 24;

export async function handlePenjadwalan(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPath = pathParts.slice(2).join('/');

  // JP Slots config
  if (subPath === 'jp-slots' && request.method === 'GET') {
    return success(JP_SLOTS.map(s => ({ kode: s, ...JP_TIMES[s] })));
  }

  // Referensi untuk dropdown
  if (subPath === 'referensi' && request.method === 'GET') {
    const [kelas, guru, mapel, ruangan, semester, tingkat] = await Promise.all([
      env.DB.prepare('SELECT id, nama FROM kelas ORDER BY nama').all(),
      env.DB.prepare("SELECT id, nama, nip FROM guru WHERE status_aktif = 1 ORDER BY nama").all(),
      env.DB.prepare('SELECT id, nama, kode FROM mata_pelajaran ORDER BY nama').all(),
      env.DB.prepare('SELECT id, nama FROM ruangan ORDER BY nama').all(),
      env.DB.prepare('SELECT id, nama, tahun_ajaran_id FROM semester ORDER BY tahun_ajaran_id DESC, id').all(),
      env.DB.prepare('SELECT id, nama FROM tingkat ORDER BY nama').all(),
    ]);
    return success({ kelas: kelas.results, guru: guru.results, mapel: mapel.results, ruangan: ruangan.results, semester: semester.results, tingkat: tingkat.results });
  }

  // Auto-generate jadwal
  if (subPath === 'jadwal/generate' && request.method === 'POST') {
    return handleGenerateJadwal(request, env, user, ip);
  }

  // Reset jadwal (hapus semua jadwal semester tertentu)
  if (subPath === 'jadwal/reset' && request.method === 'POST') {
    const body = await request.json() as { semester_id?: number };
    const semId = body.semester_id;
    if (!semId) return badRequest('semester_id diperlukan');

    await env.DB.prepare('DELETE FROM jadwal_pelajaran WHERE semester_id = ?').bind(semId).run();
    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'reset', 'penjadwalan', ?, ?)"
    ).bind(user.sub, `Reset jadwal semester ${semId}`, ip).run();

    return success({ message: 'Jadwal berhasil direset' });
  }

  // Publikasikan (validasi massal semua jadwal draft di semester)
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

  // Jadwal Per Kelas
  if (subPath === 'jadwal-per-kelas' && request.method === 'GET') {
    const kelasId = url.searchParams.get('kelas_id');
    const semesterId = url.searchParams.get('semester_id');
    if (!kelasId || !semesterId) return badRequest('kelas_id dan semester_id diperlukan');

    const rows = await env.DB.prepare(
      `SELECT jp.*, mp.nama as mapel_nama, mp.kode as mapel_kode, g.nama as guru_nama, r.nama as ruangan_nama
       FROM jadwal_pelajaran jp
       LEFT JOIN mata_pelajaran mp ON jp.mata_pelajaran_id = mp.id
       LEFT JOIN guru g ON jp.guru_id = g.id
       LEFT JOIN ruangan r ON jp.ruangan_id = r.id
       WHERE jp.kelas_id = ? AND jp.semester_id = ?
       ORDER BY jp.hari, jp.jam_mulai`
    ).bind(parseInt(kelasId), parseInt(semesterId)).all();
    return success(rows.results);
  }

  // Jadwal Pelajaran CRUD
  if (subPath === 'jadwal' || subPath.startsWith('jadwal/')) {
    const id = subPath === 'jadwal' ? null : parseInt(subPath.split('/')[1]);

    if (request.method === 'GET') {
      if (id) {
        const row = await env.DB.prepare('SELECT * FROM jadwal_pelajaran WHERE id = ?').bind(id).first();
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
         ORDER BY jp.semester_id DESC, jp.kelas_id, jp.hari, jp.jam_mulai LIMIT ? OFFSET ?`
      ).bind(perPage, offset).all();

      return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
    }

    if (request.method === 'POST') {
      const body = await request.json() as Record<string, unknown>;
      const { kelas_id, mata_pelajaran_id, guru_id, ruangan_id, hari, jam_mulai, jam_selesai, semester_id } = body;

      if (!kelas_id || !mata_pelajaran_id || !guru_id || !hari || !jam_mulai || !jam_selesai || !semester_id) {
        return badRequest('Semua field wajib diisi');
      }

      if (!['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'].includes(hari as string)) {
        return badRequest('Hari tidak valid');
      }

      const bentrokGuru = await env.DB.prepare(
        `SELECT id FROM jadwal_pelajaran WHERE guru_id = ? AND hari = ? AND semester_id = ?
         AND ((jam_mulai <= ? AND jam_selesai > ?) OR (jam_mulai < ? AND jam_selesai >= ?))`
      ).bind(guru_id, hari, semester_id, jam_mulai, jam_mulai, jam_selesai, jam_selesai).first();

      if (bentrokGuru) return badRequest('BENTROK: Guru sudah memiliki jadwal di jam tersebut');

      const bentrokKelas = await env.DB.prepare(
        `SELECT id FROM jadwal_pelajaran WHERE kelas_id = ? AND hari = ? AND semester_id = ?
         AND ((jam_mulai <= ? AND jam_selesai > ?) OR (jam_mulai < ? AND jam_selesai >= ?))`
      ).bind(kelas_id, hari, semester_id, jam_mulai, jam_mulai, jam_selesai, jam_selesai).first();

      if (bentrokKelas) return badRequest('BENTROK: Kelas sudah memiliki jadwal di jam tersebut');

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
      const existing = await env.DB.prepare('SELECT id FROM jadwal_pelajaran WHERE id = ?').bind(id).first();
      if (!existing) return notFound('Jadwal');

      const body = await request.json() as Record<string, unknown>;
      const setClauses: string[] = [];
      const vals: unknown[] = [];

      for (const f of ['kelas_id', 'mata_pelajaran_id', 'guru_id', 'ruangan_id', 'hari', 'jam_mulai', 'jam_selesai', 'semester_id']) {
        if (body[f] !== undefined) { setClauses.push(`${f} = ?`); vals.push(body[f]); }
      }

      if (setClauses.length === 0) return badRequest('Tidak ada field diupdate');
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

  // Validasi jadwal
  if (subPath.startsWith('jadwal/') && subPath.endsWith('/validasi') && request.method === 'PUT') {
    const id = parseInt(subPath.split('/')[1]);
    const existing = await env.DB.prepare('SELECT id FROM jadwal_pelajaran WHERE id = ?').bind(id).first();
    if (!existing) return notFound('Jadwal');

    await env.DB.prepare("UPDATE jadwal_pelajaran SET status_validasi = 'tervalidasi' WHERE id = ?").bind(id).run();
    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'validate', 'penjadwalan', ?, ?)")
      .bind(user.sub, `Validasi jadwal id=${id}`, ip).run();
    return success({ id, status_validasi: 'tervalidasi' });
  }

  // Distribusi mengajar CRUD
  if (subPath === 'distribusi-mengajar' || subPath.startsWith('distribusi-mengajar/')) {
    if (request.method === 'GET') {
      const rows = await env.DB.prepare(
        `SELECT gmp.*, g.nama as guru_nama, mp.nama as mapel_nama, k.nama as kelas_nama, s.nama as semester_nama
         FROM guru_mata_pelajaran gmp
         LEFT JOIN guru g ON gmp.guru_id = g.id
         LEFT JOIN mata_pelajaran mp ON gmp.mata_pelajaran_id = mp.id
         LEFT JOIN kelas k ON gmp.kelas_id = k.id
         LEFT JOIN semester s ON gmp.semester_id = s.id
         ORDER BY g.nama`
      ).all();
      return success(rows.results);
    }

    if (request.method === 'POST') {
      const body = await request.json() as Record<string, unknown>;
      const { guru_id, mata_pelajaran_id, kelas_id, semester_id } = body;
      if (!guru_id || !mata_pelajaran_id || !kelas_id || !semester_id) return badRequest('Semua field wajib diisi');

      try {
        const result = await env.DB.prepare(
          'INSERT INTO guru_mata_pelajaran (guru_id, mata_pelajaran_id, kelas_id, semester_id) VALUES (?, ?, ?, ?)'
        ).bind(guru_id, mata_pelajaran_id, kelas_id, semester_id).run();
        await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'distribusi', ?, ?)")
          .bind(user.sub, `Tambah distribusi guru=${guru_id} mapel=${mata_pelajaran_id}`, ip).run();
        return created({ id: result.meta?.last_row_id });
      } catch (e) {
        const msg = e instanceof Error ? e.message : '';
        if (msg.includes('UNIQUE')) return badRequest('Distribusi sudah ada');
        return badRequest(msg);
      }
    }

    if (request.method === 'DELETE') {
      const id = parseInt(subPath.split('/')[1]);
      if (!id) return badRequest('ID diperlukan');
      await env.DB.prepare('DELETE FROM guru_mata_pelajaran WHERE id = ?').bind(id).run();
      await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'delete', 'distribusi', ?, ?)")
        .bind(user.sub, `Hapus distribusi #${id}`, ip).run();
      return success({ id });
    }
  }

  // Beban mengajar
  if (subPath === 'beban-mengajar' && request.method === 'GET') {
    const rows = await env.DB.prepare(
      `SELECT g.id, g.nama, g.nip, COUNT(gmp.id) as total_mapel
       FROM guru g LEFT JOIN guru_mata_pelajaran gmp ON g.id = gmp.guru_id
       WHERE g.status_aktif = 1 GROUP BY g.id ORDER BY g.nama`
    ).all();
    return success(rows.results);
  }

  return badRequest('Endpoint tidak dikenal');
}

// ── Auto-Generate Algorithm ──
export async function handleGenerateJadwal(request: Request, env: Env, user: UserPayload, ip: string): Promise<Response> {
  const body = await request.json() as { semester_id?: number };
  const semesterId = body.semester_id;
  if (!semesterId) return badRequest('Semester_id diperlukan');

  // 1. Hapus jadwal lama semester ini (draft only, jangan hapus yg sudah tervalidasi)
  await env.DB.prepare(
    "DELETE FROM jadwal_pelajaran WHERE semester_id = ? AND status_validasi = 'draft'"
  ).bind(semesterId).run();

  // 2. Ambil distribusi mengajar
  const distribusi = await env.DB.prepare(
    `SELECT gmp.*, mp.nama as mapel_nama
     FROM guru_mata_pelajaran gmp
     LEFT JOIN mata_pelajaran mp ON gmp.mata_pelajaran_id = mp.id
     WHERE gmp.semester_id = ?`
  ).bind(semesterId).all<{
    id: number; guru_id: number; mata_pelajaran_id: number; kelas_id: number; semester_id: number; mapel_nama: string;
  }>();

  if (distribusi.results.length === 0) return badRequest('Tidak ada distribusi mengajar untuk semester ini');

  // 3. Ambil kelas & ruangan
  const kelasList = await env.DB.prepare('SELECT id, nama FROM kelas').all<{ id: number; nama: string }>();
  const ruanganList = await env.DB.prepare('SELECT id, nama FROM ruangan').all<{ id: number; nama: string }>();

  // 4. Ambil jadwal yg sudah tervalidasi (jangan diubah)
  const existingValidated = await env.DB.prepare(
    `SELECT kelas_id, hari, jam_mulai, jam_selesai FROM jadwal_pelajaran
     WHERE semester_id = ? AND status_validasi = 'tervalidasi'`
  ).bind(semesterId).all<{ kelas_id: number; hari: string; jam_mulai: string; jam_selesai: string }>();

  // 5. Bangun slot yang sudah terisi (tervalidasi)
  const occupied = new Set<string>();
  for (const v of existingValidated.results) {
    occupied.add(`${v.kelas_id}|${v.hari}|${v.jam_mulai}`);
  }

  // 6. Greedy assignment: urutkan distribusi, assign ke slot kosong
  const shuffled = [...distribusi.results].sort(() => Math.random() - 0.5);
  let inserted = 0;
  const errors: string[] = [];

  for (const d of shuffled) {
    let assigned = false;

    for (const hari of HARI) {
      if (assigned) break;
      if (hari === 'Jumat') {
        // Jumat: jam khusus (JP1-JP4 only)
        const jumatSlots = ['JP1', 'JP2', 'JP3', 'JP4'];
        for (const jp of jumatSlots) {
          const time = JP_TIMES[jp];
          const key = `${d.kelas_id}|${hari}|${time.mulai}`;
          if (!occupied.has(key)) {
            await env.DB.prepare(
              `INSERT INTO jadwal_pelajaran (kelas_id, mata_pelajaran_id, guru_id, ruangan_id, hari, jam_mulai, jam_selesai, semester_id, status_validasi)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'draft')`
            ).bind(d.kelas_id, d.mata_pelajaran_id, d.guru_id, null, hari, time.mulai, time.selesai, d.semester_id).run();
            occupied.add(key);
            inserted++;
            assigned = true;
            break;
          }
        }
      } else {
        for (const jp of JP_SLOTS) {
          const time = JP_TIMES[jp];
          const key = `${d.kelas_id}|${hari}|${time.mulai}`;
          if (!occupied.has(key)) {
            await env.DB.prepare(
              `INSERT INTO jadwal_pelajaran (kelas_id, mata_pelajaran_id, guru_id, ruangan_id, hari, jam_mulai, jam_selesai, semester_id, status_validasi)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'draft')`
            ).bind(d.kelas_id, d.mata_pelajaran_id, d.guru_id, null, hari, time.mulai, time.selesai, d.semester_id).run();
            occupied.add(key);
            inserted++;
            assigned = true;
            break;
          }
        }
      }
    }

    if (!assigned) {
      errors.push(`${d.mapel_nama || d.mata_pelajaran_id} (kelas ${d.kelas_id})`);
    }
  }

  await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'generate', 'penjadwalan', ?, ?)")
    .bind(user.sub, `Generate jadwal semester ${semesterId}: ${inserted} berhasil`, ip).run();

  return success({
    message: `Generate selesai. ${inserted} jadwal berhasil dibuat.`,
    total_distribusi: distribusi.results.length,
    inserted,
    errors: errors.length > 0 ? `${errors.length} mapel tidak mendapat slot (${errors.join(', ')})` : null,
  });
}
