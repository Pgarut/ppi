import { Env, UserPayload } from '../../types';
import { success, created, notFound, badRequest } from '../../utils/response';
import bcrypt from 'bcryptjs';

type Row = Record<string, unknown>;

function logAction(env: Env, userId: number, aksi: string, modul: string, detail: string, ip: string) {
  return env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, ?, ?, ?, ?)"
  ).bind(userId, aksi, modul, detail, ip).run();
}

// ============================================================
// HANDLER: Admin Dauroh Routes
// ============================================================

export async function handleAdminDauroh(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL
): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPath = pathParts.slice(3).join('/'); // /api/admin/dauroh/...

  // ─── PROGRAM KEGIATAN ───────────────────────────────────────
  if (subPath === 'program' || subPath.startsWith('program/')) {
    return handleProgram(request, env, user, pathParts, url, ip);
  }

  // ─── MUSYRIFAH ──────────────────────────────────────────────
  if (subPath === 'musyrifah' || subPath.startsWith('musyrifah/')) {
    return handleMusyrifah(request, env, user, pathParts, url, ip);
  }

  // ─── JADWAL ─────────────────────────────────────────────────
  if (subPath === 'jadwal' || subPath.startsWith('jadwal/')) {
    return handleJadwal(request, env, user, pathParts, url, ip);
  }

  // ─── QR CODE ────────────────────────────────────────────────
  if (subPath === 'qr') {
    return handleGetQR(env);
  }
  if (subPath === 'qr/generate' && request.method === 'POST') {
    return handleGenerateQR(request, env, user, ip);
  }

  // ─── MONITORING ABSENSI ─────────────────────────────────────
  if (subPath === 'monitoring/absensi') {
    return handleMonitoringAbsensi(request, env, url);
  }

  // ─── MONITORING NILAI ───────────────────────────────────────
  if (subPath === 'monitoring/nilai') {
    return handleMonitoringNilai(request, env, url);
  }

  return badRequest('Endpoint tidak dikenal');
}

// ============================================================
// PROGRAM KEGIATAN
// ============================================================

async function handleProgram(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL,
  ip: string
): Promise<Response> {
  const method = request.method;
  const id = pathParts.length > 4 ? parseInt(pathParts[4]) : null;

  // GET /api/admin/dauroh/program
  if (method === 'GET' && !id) {
    return listProgram(env, url);
  }

  // GET /api/admin/dauroh/program/:id
  if (method === 'GET' && id) {
    return getProgram(env, id);
  }

  // POST /api/admin/dauroh/program
  if (method === 'POST') {
    return createProgram(request, env, user, ip);
  }

  // PUT /api/admin/dauroh/program/:id
  if (method === 'PUT' && id) {
    return updateProgram(request, env, id, user, ip);
  }

  // DELETE /api/admin/dauroh/program/:id
  if (method === 'DELETE' && id) {
    return deleteProgram(env, id, user, ip);
  }

  return badRequest('Method tidak didukung');
}

async function listProgram(env: Env, url: URL) {
  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
  const search = url.searchParams.get('search') || '';
  const offset = (page - 1) * perPage;

  let where = '';
  const bindings: unknown[] = [];

  if (search) {
    where = 'WHERE p.nama_program LIKE ?';
    bindings.push(`%${search}%`);
  }

  const countResult = await env.DB.prepare(
    `SELECT COUNT(*) as total FROM dauroh_program p ${where}`
  ).bind(...bindings).first<{ total: number }>();

  const total = countResult?.total || 0;
  bindings.push(perPage, offset);

  const rows = await env.DB.prepare(`
    SELECT p.*, 
           (SELECT COUNT(*) FROM dauroh_jadwal j WHERE j.program_id = p.id) as jumlah_jadwal
    FROM dauroh_program p
    ${where}
    ORDER BY p.nama_program ASC
    LIMIT ? OFFSET ?
  `).bind(...bindings).all();

  return success({
    items: rows.results,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
  });
}

async function getProgram(env: Env, id: number) {
  const program = await env.DB.prepare(
    'SELECT * FROM dauroh_program WHERE id = ?'
  ).bind(id).first<Row>();

  if (!program) return notFound('Program');

  // Ambil kelas yang terkait
  const kelas = await env.DB.prepare(`
    SELECT DISTINCT k.id, k.nama 
    FROM dauroh_jadwal jdk
    JOIN kelas k ON jdk.kelas_id = k.id
    WHERE jdk.program_id = ?
  `).bind(id).all();

  // Ambil santri yang terkait (untuk program khusus)
  const santri = await env.DB.prepare(`
    SELECT s.id, s.nis, s.nama, k.nama as kelas_nama
    FROM dauroh_program_santri ps
    JOIN siswa s ON ps.santri_id = s.id
    LEFT JOIN kelas k ON s.kelas_id = k.id
    WHERE ps.program_id = ?
  `).bind(id).all();

  return success({ ...program, kelas: kelas.results, santri: santri.results });
}

async function createProgram(request: Request, env: Env, user: UserPayload, ip: string) {
  const body = await request.json() as Record<string, unknown>;
  const { 
    nama_program, jenis_program, jenis_dauroh, keterangan, tahun_ajaran_id,
    skema_penilaian, max_bidang1, max_bidang2, max_bidang3,
    label_bidang1, label_bidang2, label_bidang3, konfigurasi_nilai
  } = body;

  if (!nama_program || !jenis_program || !jenis_dauroh) {
    return badRequest('nama_program, jenis_program, jenis_dauroh wajib diisi');
  }

  const result = await env.DB.prepare(`
    INSERT INTO dauroh_program (
      nama_program, jenis_program, jenis_dauroh, keterangan, tahun_ajaran_id,
      skema_penilaian, max_bidang1, max_bidang2, max_bidang3,
      label_bidang1, label_bidang2, label_bidang3, konfigurasi_nilai
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `).bind(
    nama_program, jenis_program, jenis_dauroh, keterangan || null, tahun_ajaran_id || null,
    skema_penilaian || 'murojaah_tahfidz', max_bidang1 ?? 40, max_bidang2 ?? 30, max_bidang3 ?? 30,
    label_bidang1 || 'Kelancaran Hafalan', label_bidang2 || 'Tajwid', label_bidang3 || 'Fashohah dan Adab',
    konfigurasi_nilai || null
  ).run();

  const newId = result.meta.last_row_id;

  // Simpan kelas (untuk program khusus)
  if (jenis_program === 'khusus' && Array.isArray(body.kelas_ids)) {
    for (const kelasId of body.kelas_ids) {
      await env.DB.prepare(
        'INSERT OR IGNORE INTO dauroh_jadwal_kelas (jadwal_id, kelas_id) VALUES (?, ?)'
      ).bind(newId, kelasId).run();
    }
  }

  // Simpan santri (untuk program khusus)
  if (jenis_program === 'khusus' && Array.isArray(body.santri_ids)) {
    for (const santriId of body.santri_ids) {
      await env.DB.prepare(
        'INSERT OR IGNORE INTO dauroh_program_santri (program_id, santri_id) VALUES (?, ?)'
      ).bind(newId, santriId).run();
    }
  }

  await logAction(env, user.sub, 'create', 'dauroh_program', `Buat program: ${nama_program}`, ip);

  return created({ id: newId, nama_program });
}

async function updateProgram(request: Request, env: Env, id: number, user: UserPayload, ip: string) {
  const body = await request.json() as Record<string, unknown>;
  const { 
    nama_program, jenis_program, jenis_dauroh, keterangan, tahun_ajaran_id, is_aktif,
    skema_penilaian, max_bidang1, max_bidang2, max_bidang3,
    label_bidang1, label_bidang2, label_bidang3, konfigurasi_nilai
  } = body;

  const existing = await env.DB.prepare('SELECT id FROM dauroh_program WHERE id = ?').bind(id).first();
  if (!existing) return notFound('Program');

  await env.DB.prepare(`
    UPDATE dauroh_program SET
      nama_program = COALESCE(?, nama_program),
      jenis_program = COALESCE(?, jenis_program),
      jenis_dauroh = COALESCE(?, jenis_dauroh),
      keterangan = COALESCE(?, keterangan),
      tahun_ajaran_id = COALESCE(?, tahun_ajaran_id),
      is_aktif = COALESCE(?, is_aktif),
      skema_penilaian = COALESCE(?, skema_penilaian),
      max_bidang1 = COALESCE(?, max_bidang1),
      max_bidang2 = COALESCE(?, max_bidang2),
      max_bidang3 = COALESCE(?, max_bidang3),
      label_bidang1 = COALESCE(?, label_bidang1),
      label_bidang2 = COALESCE(?, label_bidang2),
      label_bidang3 = COALESCE(?, label_bidang3),
      konfigurasi_nilai = COALESCE(?, konfigurasi_nilai),
      updated_at = datetime('now')
    WHERE id = ?
  `).bind(
    nama_program, jenis_program, jenis_dauroh, keterangan, tahun_ajaran_id, is_aktif,
    skema_penilaian, max_bidang1, max_bidang2, max_bidang3,
    label_bidang1, label_bidang2, label_bidang3, konfigurasi_nilai, id
  ).run();

  await logAction(env, user.sub, 'update', 'dauroh_program', `Update program id=${id}`, ip);

  return success({ id, message: 'Program berhasil diupdate' });
}

async function deleteProgram(env: Env, id: number, user: UserPayload, ip: string) {
  const existing = await env.DB.prepare('SELECT id, nama_program FROM dauroh_program WHERE id = ?').bind(id).first<Row>();
  if (!existing) return notFound('Program');

  // Hapus relasi dulu
  await env.DB.prepare('DELETE FROM dauroh_program_santri WHERE program_id = ?').bind(id).run();
  await env.DB.prepare('DELETE FROM dauroh_jadwal WHERE program_id = ?').bind(id).run();
  await env.DB.prepare('DELETE FROM dauroh_program WHERE id = ?').bind(id).run();

  await logAction(env, user.sub, 'delete', 'dauroh_program', `Hapus program: ${existing.nama_program}`, ip);

  return success({ message: 'Program berhasil dihapus' });
}

// ============================================================
// MUSYRIFAH
// ============================================================

async function handleMusyrifah(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL,
  ip: string
): Promise<Response> {
  const method = request.method;
  const id = pathParts.length > 4 ? parseInt(pathParts[4]) : null;

  // GET /api/admin/dauroh/musyrifah
  if (method === 'GET' && !id) {
    return listMusyrifah(env, url);
  }

  // GET /api/admin/dauroh/musyrifah/:id
  if (method === 'GET' && id) {
    return getMusyrifah(env, id);
  }

  // POST /api/admin/dauroh/musyrifah
  if (method === 'POST') {
    return createMusyrifah(request, env, user, ip);
  }

  // PUT /api/admin/dauroh/musyrifah/:id
  if (method === 'PUT' && id) {
    return updateMusyrifah(request, env, id, user, ip);
  }

  // DELETE /api/admin/dauroh/musyrifah/:id
  if (method === 'DELETE' && id) {
    return deleteMusyrifah(env, id, user, ip);
  }

  return badRequest('Method tidak didukung');
}

async function listMusyrifah(env: Env, url: URL) {
  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
  const search = url.searchParams.get('search') || '';
  const offset = (page - 1) * perPage;

  let where = '';
  const bindings: unknown[] = [];

  if (search) {
    where = 'WHERE (m.nama LIKE ? OR m.nipmus LIKE ?)';
    bindings.push(`%${search}%`, `%${search}%`);
  }

  const countResult = await env.DB.prepare(
    `SELECT COUNT(*) as total FROM dauroh_musyrifah m ${where}`
  ).bind(...bindings).first<{ total: number }>();

  const total = countResult?.total || 0;
  bindings.push(perPage, offset);

  const rows = await env.DB.prepare(`
    SELECT m.*,
           (SELECT COUNT(*) FROM dauroh_jadwal j WHERE j.musyrifah_1_id = m.id OR j.musyrifah_2_id = m.id) as jumlah_jadwal
    FROM dauroh_musyrifah m
    ${where}
    ORDER BY m.nama ASC
    LIMIT ? OFFSET ?
  `).bind(...bindings).all();

  return success({
    items: rows.results,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
  });
}

async function getMusyrifah(env: Env, id: number) {
  const musyrifah = await env.DB.prepare(
    'SELECT * FROM dauroh_musyrifah WHERE id = ?'
  ).bind(id).first<Row>();

  if (!musyrifah) return notFound('Musyrifah');

  // Ambil jadwal yang diampu
  const jadwal = await env.DB.prepare(`
    SELECT j.*, p.nama_program
    FROM dauroh_jadwal j
    JOIN dauroh_program p ON j.program_id = p.id
    WHERE j.musyrifah_1_id = ? OR j.musyrifah_2_id = ?
    ORDER BY j.hari, j.jam_mulai
  `).bind(id, id).all();

  return success({ ...musyrifah, jadwal: jadwal.results });
}

async function createMusyrifah(request: Request, env: Env, user: UserPayload, ip: string) {
  const body = await request.json() as Record<string, unknown>;
  const { nipmus, nama, jenis_kelamin, status_pendidikan, gelar, username, password } = body;

  if (!nipmus || !nama || !jenis_kelamin || !status_pendidikan || !username || !password) {
    return badRequest('nipmus, nama, jenis_kelamin, status_pendidikan, username, password wajib diisi');
  }

  // Cek username duplikat
  const existing = await env.DB.prepare('SELECT id FROM dauroh_musyrifah WHERE username = ? OR nipmus = ?')
    .bind(username, nipmus).first();
  if (existing) {
    return badRequest('Username atau NIPMUS sudah digunakan');
  }

  const passwordHash = await bcrypt.hash(password as string, 10);

  const result = await env.DB.prepare(`
    INSERT INTO dauroh_musyrifah (nipmus, nama, jenis_kelamin, status_pendidikan, gelar, username, password_hash)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).bind(nipmus, nama, jenis_kelamin, status_pendidikan, gelar || null, username, passwordHash).run();

  const newId = result.meta.last_row_id;

  // Buat user account untuk musyrifah
  await env.DB.prepare(`
    INSERT INTO users (username, password_hash, role, is_active)
    VALUES (?, ?, 'musyrifah', 1)
  `).bind(username, passwordHash).run();

  await logAction(env, user.sub, 'create', 'dauroh_musyrifah', `Buat musyrifah: ${nama}`, ip);

  return created({ id: newId, nama, username });
}

async function updateMusyrifah(request: Request, env: Env, id: number, user: UserPayload, ip: string) {
  const body = await request.json() as Record<string, unknown>;
  const { nipmus, nama, jenis_kelamin, status_pendidikan, gelar, username, password, is_aktif } = body;

  const existing = await env.DB.prepare('SELECT id, username FROM dauroh_musyrifah WHERE id = ?').bind(id).first<{ id: number; username: string }>();
  if (!existing) return notFound('Musyrifah');

  let passwordHash = null;
  if (password) {
    passwordHash = await bcrypt.hash(password as string, 10);
  }

  await env.DB.prepare(`
    UPDATE dauroh_musyrifah SET
      nipmus = COALESCE(?, nipmus),
      nama = COALESCE(?, nama),
      jenis_kelamin = COALESCE(?, jenis_kelamin),
      status_pendidikan = COALESCE(?, status_pendidikan),
      gelar = COALESCE(?, gelar),
      username = COALESCE(?, username),
      password_hash = COALESCE(?, password_hash),
      is_aktif = COALESCE(?, is_aktif),
      updated_at = datetime('now')
    WHERE id = ?
  `).bind(nipmus, nama, jenis_kelamin, status_pendidikan, gelar, username, passwordHash, is_aktif, id).run();

  // Update user account jika ada perubahan username/password
  if (username || password) {
    const newUsername = username || existing.username;
    if (passwordHash) {
      await env.DB.prepare('UPDATE users SET username = ?, password_hash = ? WHERE username = ?')
        .bind(newUsername, passwordHash, existing.username).run();
    } else {
      await env.DB.prepare('UPDATE users SET username = ? WHERE username = ?')
        .bind(newUsername, existing.username).run();
    }
  }

  await logAction(env, user.sub, 'update', 'dauroh_musyrifah', `Update musyrifah id=${id}`, ip);

  return success({ id, message: 'Musyrifah berhasil diupdate' });
}

async function deleteMusyrifah(env: Env, id: number, user: UserPayload, ip: string) {
  const existing = await env.DB.prepare('SELECT id, nama, username FROM dauroh_musyrifah WHERE id = ?').bind(id).first<Row>();
  if (!existing) return notFound('Musyrifah');

  // Hapus jadwal terkait
  await env.DB.prepare('UPDATE dauroh_jadwal SET musyrifah_1_id = NULL WHERE musyrifah_1_id = ?').bind(id).run();
  await env.DB.prepare('UPDATE dauroh_jadwal SET musyrifah_2_id = NULL WHERE musyrifah_2_id = ?').bind(id).run();

  // Hapus user account
  await env.DB.prepare("DELETE FROM users WHERE username = ? AND role = 'musyrifah'").bind(existing.username).run();

  // Hapus musyrifah
  await env.DB.prepare('DELETE FROM dauroh_musyrifah WHERE id = ?').bind(id).run();

  await logAction(env, user.sub, 'delete', 'dauroh_musyrifah', `Hapus musyrifah: ${existing.nama}`, ip);

  return success({ message: 'Musyrifah berhasil dihapus' });
}

// ============================================================
// JADWAL
// ============================================================

async function handleJadwal(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL,
  ip: string
): Promise<Response> {
  const method = request.method;
  const id = pathParts.length > 4 ? parseInt(pathParts[4]) : null;

  // GET /api/admin/dauroh/jadwal
  if (method === 'GET' && !id) {
    return listJadwal(env, url);
  }

  // GET /api/admin/dauroh/jadwal/:id
  if (method === 'GET' && id) {
    return getJadwal(env, id);
  }

  // POST /api/admin/dauroh/jadwal
  if (method === 'POST') {
    return createJadwal(request, env, user, ip);
  }

  // PUT /api/admin/dauroh/jadwal/:id
  if (method === 'PUT' && id) {
    return updateJadwal(request, env, id, user, ip);
  }

  // DELETE /api/admin/dauroh/jadwal/:id
  if (method === 'DELETE' && id) {
    return deleteJadwal(env, id, user, ip);
  }

  return badRequest('Method tidak didukung');
}

async function listJadwal(env: Env, url: URL) {
  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
  const search = url.searchParams.get('search') || '';
  const filterProgram = url.searchParams.get('program_id');
  const filterHari = url.searchParams.get('hari');
  const offset = (page - 1) * perPage;

  let where = 'WHERE 1=1';
  const bindings: unknown[] = [];

  if (search) {
    where += ' AND (p.nama_program LIKE ? OR m1.nama LIKE ?)';
    bindings.push(`%${search}%`, `%${search}%`);
  }
  if (filterProgram) {
    where += ' AND j.program_id = ?';
    bindings.push(filterProgram);
  }
  if (filterHari) {
    where += ' AND j.hari = ?';
    bindings.push(filterHari);
  }

  const countResult = await env.DB.prepare(`
    SELECT COUNT(*) as total 
    FROM dauroh_jadwal j
    JOIN dauroh_program p ON j.program_id = p.id
    JOIN dauroh_musyrifah m1 ON j.musyrifah_1_id = m1.id
    ${where}
  `).bind(...bindings).first<{ total: number }>();

  const total = countResult?.total || 0;
  bindings.push(perPage, offset);

  const rows = await env.DB.prepare(`
    SELECT j.*, 
           p.nama_program, p.jenis_program, p.jenis_dauroh,
           m1.nama as musyrifah_1_nama,
           m2.nama as musyrifah_2_nama,
           (SELECT GROUP_CONCAT(k.nama, ', ') FROM dauroh_jadwal_kelas jdk JOIN kelas k ON jdk.kelas_id = k.id WHERE jdk.jadwal_id = j.id) as kelas_nama
    FROM dauroh_jadwal j
    JOIN dauroh_program p ON j.program_id = p.id
    JOIN dauroh_musyrifah m1 ON j.musyrifah_1_id = m1.id
    LEFT JOIN dauroh_musyrifah m2 ON j.musyrifah_2_id = m2.id
    ${where}
    ORDER BY j.hari, j.jam_mulai
    LIMIT ? OFFSET ?
  `).bind(...bindings).all();

  return success({
    items: rows.results,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
  });
}

async function getJadwal(env: Env, id: number) {
  const jadwal = await env.DB.prepare(`
    SELECT j.*, 
           p.nama_program, p.jenis_program, p.jenis_dauroh,
           m1.nama as musyrifah_1_nama, m1.nipmus as musyrifah_1_nipmus,
           m2.nama as musyrifah_2_nama, m2.nipmus as musyrifah_2_nipmus
    FROM dauroh_jadwal j
    JOIN dauroh_program p ON j.program_id = p.id
    JOIN dauroh_musyrifah m1 ON j.musyrifah_1_id = m1.id
    LEFT JOIN dauroh_musyrifah m2 ON j.musyrifah_2_id = m2.id
    WHERE j.id = ?
  `).bind(id).first<Row>();

  if (!jadwal) return notFound('Jadwal');

  // Ambil kelas
  const kelas = await env.DB.prepare(`
    SELECT k.id, k.nama
    FROM dauroh_jadwal_kelas jdk
    JOIN kelas k ON jdk.kelas_id = k.id
    WHERE jdk.jadwal_id = ?
  `).bind(id).all();

  return success({ ...jadwal, kelas: kelas.results });
}

async function createJadwal(request: Request, env: Env, user: UserPayload, ip: string) {
  const body = await request.json() as Record<string, unknown>;
  const { program_id, musyrifah_1_id, musyrifah_2_id, jenjang, hari, jam_mulai, jam_selesai, kelas_ids } = body;

  if (!program_id || !musyrifah_1_id || !hari || !jam_mulai || !jam_selesai) {
    return badRequest('program_id, musyrifah_1_id, hari, jam_mulai, jam_selesai wajib diisi');
  }

  // Validasi program
  const program = await env.DB.prepare('SELECT id FROM dauroh_program WHERE id = ?').bind(program_id).first();
  if (!program) return notFound('Program');

  // Validasi musyrifah
  const musyrifah = await env.DB.prepare('SELECT id FROM dauroh_musyrifah WHERE id = ?').bind(musyrifah_1_id).first();
  if (!musyrifah) return notFound('Musyrifah 1');

  const result = await env.DB.prepare(`
    INSERT INTO dauroh_jadwal (program_id, musyrifah_1_id, musyrifah_2_id, jenjang, hari, jam_mulai, jam_selesai)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).bind(program_id, musyrifah_1_id, musyrifah_2_id || null, jenjang || null, hari, jam_mulai, jam_selesai).run();

  const newId = result.meta.last_row_id;

  // Simpan kelas
  if (Array.isArray(kelas_ids)) {
    for (const kelasId of kelas_ids) {
      await env.DB.prepare(
        'INSERT OR IGNORE INTO dauroh_jadwal_kelas (jadwal_id, kelas_id) VALUES (?, ?)'
      ).bind(newId, kelasId).run();
    }
  }

  await logAction(env, user.sub, 'create', 'dauroh_jadwal', `Buat jadwal program id=${program_id}`, ip);

  return created({ id: newId });
}

async function updateJadwal(request: Request, env: Env, id: number, user: UserPayload, ip: string) {
  const body = await request.json() as Record<string, unknown>;
  const { program_id, musyrifah_1_id, musyrifah_2_id, jenjang, hari, jam_mulai, jam_selesai, kelas_ids, is_aktif } = body;

  const existing = await env.DB.prepare('SELECT id FROM dauroh_jadwal WHERE id = ?').bind(id).first();
  if (!existing) return notFound('Jadwal');

  await env.DB.prepare(`
    UPDATE dauroh_jadwal SET
      program_id = COALESCE(?, program_id),
      musyrifah_1_id = COALESCE(?, musyrifah_1_id),
      musyrifah_2_id = COALESCE(?, musyrifah_2_id),
      jenjang = COALESCE(?, jenjang),
      hari = COALESCE(?, hari),
      jam_mulai = COALESCE(?, jam_mulai),
      jam_selesai = COALESCE(?, jam_selesai),
      is_aktif = COALESCE(?, is_aktif),
      updated_at = datetime('now')
    WHERE id = ?
  `).bind(program_id, musyrifah_1_id, musyrifah_2_id, jenjang, hari, jam_mulai, jam_selesai, is_aktif, id).run();

  // Update kelas
  if (Array.isArray(kelas_ids)) {
    await env.DB.prepare('DELETE FROM dauroh_jadwal_kelas WHERE jadwal_id = ?').bind(id).run();
    for (const kelasId of kelas_ids) {
      await env.DB.prepare(
        'INSERT OR IGNORE INTO dauroh_jadwal_kelas (jadwal_id, kelas_id) VALUES (?, ?)'
      ).bind(id, kelasId).run();
    }
  }

  await logAction(env, user.sub, 'update', 'dauroh_jadwal', `Update jadwal id=${id}`, ip);

  return success({ id, message: 'Jadwal berhasil diupdate' });
}

async function deleteJadwal(env: Env, id: number, user: UserPayload, ip: string) {
  const existing = await env.DB.prepare('SELECT id FROM dauroh_jadwal WHERE id = ?').bind(id).first();
  if (!existing) return notFound('Jadwal');

  await env.DB.prepare('DELETE FROM dauroh_jadwal_kelas WHERE jadwal_id = ?').bind(id).run();
  await env.DB.prepare('DELETE FROM dauroh_jadwal WHERE id = ?').bind(id).run();

  await logAction(env, user.sub, 'delete', 'dauroh_jadwal', `Hapus jadwal id=${id}`, ip);

  return success({ message: 'Jadwal berhasil dihapus' });
}

// ============================================================
// QR CODE
// ============================================================

const DEFAULT_QR_TOKEN = 'PPI_DAUROH_QR_2026';

async function handleGetQR(env: Env) {
  const token = env.QR_DAUROH_TOKEN || DEFAULT_QR_TOKEN;
  return success({
    token,
    message: 'QR Code Dauroh - Token untuk absensi musyrifah',
  });
}

async function handleGenerateQR(request: Request, env: Env, user: UserPayload, ip: string) {
  const body = await request.json() as { jadwal_id?: number; tanggal?: string };
  const { jadwal_id } = body;

  if (!jadwal_id) {
    return badRequest('jadwal_id wajib diisi');
  }

  const jadwal = await env.DB.prepare(`
    SELECT j.*, p.nama_program, m1.nama as musyrifah_nama
    FROM dauroh_jadwal j
    JOIN dauroh_program p ON j.program_id = p.id
    JOIN dauroh_musyrifah m1 ON j.musyrifah_1_id = m1.id
    WHERE j.id = ?
  `).bind(jadwal_id).first<Row>();

  if (!jadwal) return notFound('Jadwal');

  const token = env.QR_DAUROH_TOKEN || DEFAULT_QR_TOKEN;

  return success({
    qr_data: token,
    jadwal: {
      id: jadwal_id,
      program: jadwal.nama_program,
      musyrifah: jadwal.musyrifah_nama,
      hari: jadwal.hari,
      jam_mulai: jadwal.jam_mulai,
      jam_selesai: jadwal.jam_selesai,
    },
  });
}

// ============================================================
// MONITORING
// ============================================================

async function handleMonitoringAbsensi(request: Request, env: Env, url: URL) {
  const tanggal = url.searchParams.get('tanggal') || new Date().toISOString().split('T')[0];
  const programId = url.searchParams.get('program_id');

  let where = 'WHERE am.tanggal = ?';
  const bindings: unknown[] = [tanggal];

  if (programId) {
    where += ' AND j.program_id = ?';
    bindings.push(programId);
  }

  const rows = await env.DB.prepare(`
    SELECT 
      m.nipmus, m.nama, m.jenis_kelamin,
      j.hari, am.waktu_scan, am.status,
      p.nama_program
    FROM dauroh_absensi_musyrifah am
    JOIN dauroh_musyrifah m ON am.musyrifah_id = m.id
    JOIN dauroh_jadwal j ON am.jadwal_id = j.id
    JOIN dauroh_program p ON j.program_id = p.id
    ${where}
    ORDER BY am.waktu_scan ASC
  `).bind(...bindings).all();

  // Rekap
  const rekap = await env.DB.prepare(`
    SELECT 
      COUNT(*) as total,
      SUM(CASE WHEN am.status = 'hadir' THEN 1 ELSE 0 END) as hadir,
      SUM(CASE WHEN am.status = 'izin' THEN 1 ELSE 0 END) as izin,
      SUM(CASE WHEN am.status = 'sakit' THEN 1 ELSE 0 END) as sakit,
      SUM(CASE WHEN am.status = 'alpha' THEN 1 ELSE 0 END) as alpha
    FROM dauroh_absensi_musyrifah am
    ${where}
  `).bind(...bindings).first();

  return success({
    tanggal,
    data: rows.results,
    rekap,
  });
}

async function handleMonitoringNilai(request: Request, env: Env, url: URL) {
  const jenjang = url.searchParams.get('jenjang');
  const kelasId = url.searchParams.get('kelas_id');
  const programId = url.searchParams.get('program_id');
  const status = url.searchParams.get('status');

  let where = 'WHERE 1=1';
  const bindings: unknown[] = [];

  if (jenjang) {
    where += ' AND t.jenjang = ?';
    bindings.push(jenjang);
  }
  if (kelasId) {
    where += ' AND s.kelas_id = ?';
    bindings.push(kelasId);
  }
  if (programId) {
    where += ' AND n.program_id = ?';
    bindings.push(programId);
  }
  if (status) {
    where += ' AND n.status = ?';
    bindings.push(status);
  }

  const rows = await env.DB.prepare(`
    SELECT 
      s.nis, s.nama, s.jenis_kelamin,
      k.nama as kelas_nama,
      p.nama_program, p.jenis_program, p.jenis_dauroh,
      n.surat_nomor,
      ds.nama as surat_nama,
      n.dari_ayat,
      n.sampai_ayat,
      n.status_hafalan,
      n.nilai_bidang1,
      n.nilai_bidang2,
      n.nilai_bidang3,
      n.total_nilai,
      n.catatan_umum,
      n.rencana_tindak_lanjut,
      dm.nama as musyrifah_nama,
      n.created_at
    FROM dauroh_nilai n
    JOIN siswa s ON n.santri_id = s.id
    JOIN kelas k ON s.kelas_id = k.id
    JOIN tingkat t ON k.tingkat_id = t.id
    JOIN dauroh_program p ON n.program_id = p.id
    LEFT JOIN dauroh_surat ds ON n.surat_nomor = ds.nomor
    LEFT JOIN dauroh_musyrifah dm ON n.diinput_oleh = dm.id
    ${where}
    ORDER BY k.nama, s.nama
  `).bind(...bindings).all();

  return success(rows.results);
}
