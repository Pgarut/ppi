import { Env, UserPayload } from '../../types';
import { success, error, unauthorized } from '../../utils/response';

// ============================================================
// HANDLER: Musyrifah Routes
// ============================================================

export async function handleMusyrifahRoutes(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL
): Promise<Response> {
  const subPath = pathParts.slice(2).join('/'); // /api/musyrifah/...

  // ─── JADWAL ─────────────────────────────────────────────────
  if (subPath === 'jadwal' || subPath.startsWith('jadwal/')) {
    return handleJadwalMusyrifah(request, env, user, pathParts, url);
  }

  // ─── ABSENSI ────────────────────────────────────────────────
  if (subPath === 'absensi' || subPath.startsWith('absensi/')) {
    return handleAbsensiMusyrifah(request, env, user, pathParts, url);
  }

  // ─── NILAI ──────────────────────────────────────────────────
  if (subPath === 'nilai' || subPath.startsWith('nilai/')) {
    return handleNilaiMusyrifah(request, env, user, pathParts, url);
  }

  // ─── PROFIL ─────────────────────────────────────────────────
  if (subPath === 'profil' && request.method === 'GET') {
    return handleProfilMusyrifah(env, user);
  }

  // ─── DASHBOARD ──────────────────────────────────────────────
  if (subPath === 'dashboard' && request.method === 'GET') {
    return handleDashboardMusyrifah(env, user);
  }

  return error('Endpoint tidak dikenal', 404);
}

// ============================================================
// DASHBOARD
// ============================================================

async function handleDashboardMusyrifah(env: Env, user: UserPayload): Promise<Response> {
  // Cari musyrifah_id dari username
  const musyrifah = await env.DB.prepare(
    'SELECT id, nama FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number; nama: string }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  const today = new Date().toISOString().split('T')[0];
  const hariIni = ['Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'][new Date().getDay()];

  const [jadwalHari, absensiHari, nilaiCount] = await Promise.all([
    // Jadwal hari ini
    env.DB.prepare(`
      SELECT j.*, p.nama_program, p.jenis_dauroh,
             m1.nama as musyrifah_1_nama,
             (SELECT GROUP_CONCAT(k.nama, ', ') FROM dauroh_jadwal_kelas jdk JOIN kelas k ON jdk.kelas_id = k.id WHERE jdk.jadwal_id = j.id) as kelas_nama
      FROM dauroh_jadwal j
      JOIN dauroh_program p ON j.program_id = p.id
      JOIN dauroh_musyrifah m1 ON j.musyrifah_1_id = m1.id
      WHERE (j.musyrifah_1_id = ? OR j.musyrifah_2_id = ?)
        AND j.hari = ? AND j.is_aktif = 1
      ORDER BY j.jam_mulai
    `).bind(musyrifah.id, musyrifah.id, hariIni).all(),
    // Absensi musyrifah hari ini
    env.DB.prepare(`
      SELECT COUNT(*) as total FROM dauroh_absensi_musyrifah
      WHERE musyrifah_id = ? AND tanggal = ?
    `).bind(musyrifah.id, today).first<{ total: number }>(),
    // Total nilai yang diinput
    env.DB.prepare('SELECT COUNT(*) as total FROM dauroh_nilai WHERE program_id IN (SELECT program_id FROM dauroh_jadwal WHERE musyrifah_1_id = ? OR musyrifah_2_id = ?)')
      .bind(musyrifah.id, musyrifah.id).first<{ total: number }>(),
  ]);

  return success({
    nama: musyrifah.nama,
    jadwal_hari_ini: jadwalHari.results,
    sudah_absen: (absensiHari?.total || 0) > 0,
    total_nilai: nilaiCount?.total || 0,
  });
}

// ============================================================
// PROFIL
// ============================================================

async function handleProfilMusyrifah(env: Env, user: UserPayload): Promise<Response> {
  const musyrifah = await env.DB.prepare(`
    SELECT id, nipmus, nama, jenis_kelamin, status_pendidikan, gelar, username, is_aktif
    FROM dauroh_musyrifah WHERE username = ?
  `).bind(user.username).first();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  return success(musyrifah);
}

// ============================================================
// JADWAL MUSYRIFAH
// ============================================================

async function handleJadwalMusyrifah(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL
): Promise<Response> {
  const method = request.method;

  // GET /api/musyrifah/jadwal - List jadwal musyrifah
  if (method === 'GET' && pathParts.length === 3) {
    return listJadwalMusyrifah(env, user, url);
  }

  // GET /api/musyrifah/jadwal/:id - Detail jadwal
  if (method === 'GET' && pathParts.length === 4) {
    const id = parseInt(pathParts[3]);
    return getJadwalDetail(env, id, user);
  }

  return error('Method tidak didukung', 405);
}

async function listJadwalMusyrifah(env: Env, user: UserPayload, url: URL) {
  const musyrifah = await env.DB.prepare(
    'SELECT id FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  const hariFilter = url.searchParams.get('hari');
  const programFilter = url.searchParams.get('program_id');

  let where = 'WHERE (j.musyrifah_1_id = ? OR j.musyrifah_2_id = ?) AND j.is_aktif = 1';
  const bindings: unknown[] = [musyrifah.id, musyrifah.id];

  if (hariFilter) {
    where += ' AND j.hari = ?';
    bindings.push(hariFilter);
  }
  if (programFilter) {
    where += ' AND j.program_id = ?';
    bindings.push(programFilter);
  }

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
  `).bind(...bindings).all();

  return success(rows.results);
}

async function getJadwalDetail(env: Env, id: number, user: UserPayload) {
  const musyrifah = await env.DB.prepare(
    'SELECT id FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  const jadwal = await env.DB.prepare(`
    SELECT j.*, 
           p.nama_program, p.jenis_program, p.jenis_dauroh,
           m1.nama as musyrifah_1_nama,
           m2.nama as musyrifah_2_nama
    FROM dauroh_jadwal j
    JOIN dauroh_program p ON j.program_id = p.id
    JOIN dauroh_musyrifah m1 ON j.musyrifah_1_id = m1.id
    LEFT JOIN dauroh_musyrifah m2 ON j.musyrifah_2_id = m2.id
    WHERE j.id = ? AND (j.musyrifah_1_id = ? OR j.musyrifah_2_id = ?)
  `).bind(id, musyrifah.id, musyrifah.id).first();

  if (!jadwal) return error('Jadwal tidak ditemukan', 404);

  // Ambil kelas
  const kelas = await env.DB.prepare(`
    SELECT k.id, k.nama
    FROM dauroh_jadwal_kelas jdk
    JOIN kelas k ON jdk.kelas_id = k.id
    WHERE jdk.jadwal_id = ?
  `).bind(id).all();

  // Ambil absensi santri terakhir
  const absensi = await env.DB.prepare(`
    SELECT da.*, s.nama as santri_nama
    FROM dauroh_absensi_santri da
    JOIN siswa s ON da.santri_id = s.id
    WHERE da.jadwal_id = ?
    ORDER BY da.tanggal DESC, s.nama
    LIMIT 50
  `).bind(id).all();

  return success({ ...jadwal, kelas: kelas.results, absensi_terakhir: absensi.results });
}

// ============================================================
// ABSENSI MUSYRIFAH (QR Scan)
// ============================================================

async function handleAbsensiMusyrifah(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL
): Promise<Response> {
  const method = request.method;

  // POST /api/musyrifah/absensi/scan - QR Scan absensi musyrifah
  if (method === 'POST' && pathParts[3] === 'scan') {
    return scanAbsensiMusyrifah(request, env, user);
  }

  // GET /api/musyrifah/absensi - Riwayat absensi
  if (method === 'GET' && pathParts.length === 3) {
    return listAbsensiMusyrifah(env, user, url);
  }

  // POST /api/musyrifah/absensi/santri - Input absensi santri manual
  if (method === 'POST' && pathParts[3] === 'santri') {
    return inputAbsensiSantri(request, env, user);
  }

  return error('Method tidak didukung', 405);
}

async function scanAbsensiMusyrifah(request: Request, env: Env, user: UserPayload) {
  const body = await request.json() as { token?: string; jadwal_id?: number };
  const { token, jadwal_id } = body;

  const QR_TOKEN = 'PPI_DAUROH_QR_2026';
  if (token !== QR_TOKEN) {
    return error('QR token tidak valid', 400);
  }

  const musyrifah = await env.DB.prepare(
    'SELECT id, nama FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number; nama: string }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  const now = new Date();
  const today = now.toISOString().split('T')[0];
  const currentTime = now.toTimeString().split(' ')[0];
  const hariIni = ['Minggu','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu'][now.getDay()];

  // Cari jadwal aktif hari ini
  let jadwalFilter = '';
  const jadwalBindings: unknown[] = [musyrifah.id, musyrifah.id, hariIni];
  
  if (jadwal_id) {
    jadwalFilter = ' AND j.id = ?';
    jadwalBindings.push(jadwal_id);
  }

  const jadwal = await env.DB.prepare(`
    SELECT j.*, p.nama_program
    FROM dauroh_jadwal j
    JOIN dauroh_program p ON j.program_id = p.id
    WHERE (j.musyrifah_1_id = ? OR j.musyrifah_2_id = ?)
      AND j.hari = ? AND j.is_aktif = 1
      ${jadwalFilter}
    LIMIT 1
  `).bind(...jadwalBindings).first<{ id: number; nama_program: string }>();

  if (!jadwal) {
    return error(`Tidak ada jadwal dauroh aktif hari ini (${hariIni})`, 400);
  }

  // Cek apakah sudah absen
  const existing = await env.DB.prepare(
    'SELECT id FROM dauroh_absensi_musyrifah WHERE musyrifah_id = ? AND jadwal_id = ? AND tanggal = ?'
  ).bind(musyrifah.id, jadwal.id, today).first();

  if (existing) {
    return error('Anda sudah melakukan absensi untuk jadwal ini hari ini', 400);
  }

  // Insert absensi
  await env.DB.prepare(`
    INSERT INTO dauroh_absensi_musyrifah (musyrifah_id, jadwal_id, tanggal, waktu_scan, status)
    VALUES (?, ?, ?, ?, 'hadir')
  `).bind(musyrifah.id, jadwal.id, today, currentTime).run();

  return success({
    action: 'absen_musyrifah',
    time: currentTime,
    jadwal: jadwal.nama_program,
    message: `Absensi musyrifah tercatat pukul ${currentTime}`,
  });
}

async function listAbsensiMusyrifah(env: Env, user: UserPayload, url: URL) {
  const musyrifah = await env.DB.prepare(
    'SELECT id FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
  const bulan = url.searchParams.get('bulan'); // format: YYYY-MM
  const offset = (page - 1) * perPage;

  let where = 'WHERE am.musyrifah_id = ?';
  const bindings: unknown[] = [musyrifah.id];

  if (bulan) {
    where += ' AND am.tanggal LIKE ?';
    bindings.push(`${bulan}%`);
  }

  const countResult = await env.DB.prepare(
    `SELECT COUNT(*) as total FROM dauroh_absensi_musyrifah am ${where}`
  ).bind(...bindings).first<{ total: number }>();

  const total = countResult?.total || 0;
  bindings.push(perPage, offset);

  const rows = await env.DB.prepare(`
    SELECT am.*, j.hari, j.jam_mulai, j.jam_selesai, p.nama_program
    FROM dauroh_absensi_musyrifah am
    JOIN dauroh_jadwal j ON am.jadwal_id = j.id
    JOIN dauroh_program p ON j.program_id = p.id
    ${where}
    ORDER BY am.tanggal DESC, j.jam_mulai
    LIMIT ? OFFSET ?
  `).bind(...bindings).all();

  return success({
    items: rows.results,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
  });
}

async function inputAbsensiSantri(request: Request, env: Env, user: UserPayload) {
  const body = await request.json() as { jadwal_id: number; santri_id: number; status: string; keterangan?: string };
  const { jadwal_id, santri_id, status, keterangan } = body;

  if (!jadwal_id || !santri_id || !status) {
    return error('jadwal_id, santri_id, status wajib diisi', 400);
  }

  if (!['hadir', 'izin', 'sakit', 'alpha'].includes(status)) {
    return error('Status harus hadir/izin/sakit/alpha', 400);
  }

  // Validasi musyrifah
  const musyrifah = await env.DB.prepare(
    'SELECT id FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  // Validasi jadwal
  const jadwal = await env.DB.prepare(`
    SELECT id FROM dauroh_jadwal 
    WHERE id = ? AND (musyrifah_1_id = ? OR musyrifah_2_id = ?) AND is_aktif = 1
  `).bind(jadwal_id, musyrifah.id, musyrifah.id).first();

  if (!jadwal) return error('Jadwal tidak ditemukan atau bukan jadwal Anda', 404);

  const today = new Date().toISOString().split('T')[0];

  // Upsert absensi
  await env.DB.prepare(`
    INSERT INTO dauroh_absensi_santri (jadwal_id, santri_id, tanggal, status, keterangan)
    VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(jadwal_id, santri_id, tanggal) 
    DO UPDATE SET status = excluded.status, keterangan = excluded.keterangan
  `).bind(jadwal_id, santri_id, today, status, keterangan || null).run();

  return success({ message: `Absensi santri berhasil diinput` });
}

// ============================================================
// NILAI MUSYRIFAH
// ============================================================

async function handleNilaiMusyrifah(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL
): Promise<Response> {
  const method = request.method;

  // GET /api/musyrifah/nilai - List nilai santri
  if (method === 'GET' && pathParts.length === 3) {
    return listNilaiMusyrifah(env, user, url);
  }

  // POST /api/musyrifah/nilai - Input/update nilai
  if (method === 'POST' && pathParts.length === 3) {
    return inputNilai(request, env, user);
  }

  // PUT /api/musyrifah/nilai/:id - Update nilai
  if (method === 'PUT' && pathParts.length === 4) {
    const id = parseInt(pathParts[3]);
    return updateNilai(request, env, id, user);
  }

  return error('Method tidak didukung', 405);
}

async function listNilaiMusyrifah(env: Env, user: UserPayload, url: URL) {
  const musyrifah = await env.DB.prepare(
    'SELECT id FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  const programId = url.searchParams.get('program_id');
  const kelasId = url.searchParams.get('kelas_id');
  const search = url.searchParams.get('search') || '';

  let where = 'WHERE n.program_id IN (SELECT program_id FROM dauroh_jadwal WHERE musyrifah_1_id = ? OR musyrifah_2_id = ?)';
  const bindings: unknown[] = [musyrifah.id, musyrifah.id];

  if (programId) {
    where += ' AND n.program_id = ?';
    bindings.push(programId);
  }
  if (kelasId) {
    where += ' AND s.kelas_id = ?';
    bindings.push(kelasId);
  }
  if (search) {
    where += ' AND (s.nama LIKE ? OR s.nis LIKE ?)';
    bindings.push(`%${search}%`, `%${search}%`);
  }

  const rows = await env.DB.prepare(`
    SELECT n.*, s.nis, s.nama as santri_nama, 
           k.nama as kelas_nama, p.nama_program
    FROM dauroh_nilai n
    JOIN siswa s ON n.santri_id = s.id
    JOIN kelas k ON s.kelas_id = k.id
    JOIN dauroh_program p ON n.program_id = p.id
    ${where}
    ORDER BY p.nama_program, k.nama, s.nama
  `).bind(...bindings).all();

  return success(rows.results);
}

async function inputNilai(request: Request, env: Env, user: UserPayload) {
  const body = await request.json() as { program_id: number; santri_id: number; nilai_hafalan?: number; nilai_bacaan?: number; catatan?: string };
  const { program_id, santri_id, nilai_hafalan, nilai_bacaan, catatan } = body;

  if (!program_id || !santri_id) {
    return error('program_id, santri_id wajib diisi', 400);
  }

  // Validasi musyrifah
  const musyrifah = await env.DB.prepare(
    'SELECT id FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  // Validasi program
  const program = await env.DB.prepare(`
    SELECT id FROM dauroh_jadwal 
    WHERE program_id = ? AND (musyrifah_1_id = ? OR musyrifah_2_id = ?)
  `).bind(program_id, musyrifah.id, musyrifah.id).first();

  if (!program) return error('Program tidak ditemukan atau bukan program Anda', 404);

  // Upsert nilai
  const result = await env.DB.prepare(`
    INSERT INTO dauroh_nilai (program_id, santri_id, nilai_hafalan, nilai_bacaan, catatan)
    VALUES (?, ?, ?, ?, ?)
    ON CONFLICT(program_id, santri_id)
    DO UPDATE SET 
      nilai_hafalan = COALESCE(excluded.nilai_hafalan, dauroh_nilai.nilai_hafalan),
      nilai_bacaan = COALESCE(excluded.nilai_bacaan, dauroh_nilai.nilai_bacaan),
      catatan = COALESCE(excluded.catatan, dauroh_nilai.catatan),
      updated_at = datetime('now')
  `).bind(program_id, santri_id, nilai_hafalan || null, nilai_bacaan || null, catatan || null).run();

  return success({ message: 'Nilai berhasil disimpan' });
}

async function updateNilai(request: Request, env: Env, id: number, user: UserPayload) {
  const body = await request.json() as { nilai_hafalan?: number; nilai_bacaan?: number; catatan?: string };

  // Validasi musyrifah
  const musyrifah = await env.DB.prepare(
    'SELECT id FROM dauroh_musyrifah WHERE username = ?'
  ).bind(user.username).first<{ id: number }>();

  if (!musyrifah) return error('Data musyrifah tidak ditemukan', 404);

  // Validasi nilai
  const existing = await env.DB.prepare(`
    SELECT n.id FROM dauroh_nilai n
    JOIN dauroh_jadwal j ON n.program_id = j.program_id
    WHERE n.id = ? AND (j.musyrifah_1_id = ? OR j.musyrifah_2_id = ?)
  `).bind(id, musyrifah.id, musyrifah.id).first();

  if (!existing) return error('Data nilai tidak ditemukan atau bukan program Anda', 404);

  await env.DB.prepare(`
    UPDATE dauroh_nilai SET
      nilai_hafalan = COALESCE(?, nilai_hafalan),
      nilai_bacaan = COALESCE(?, nilai_bacaan),
      catatan = COALESCE(?, catatan),
      updated_at = datetime('now')
    WHERE id = ?
  `).bind(body.nilai_hafalan, body.nilai_bacaan, body.catatan, id).run();

  return success({ message: 'Nilai berhasil diupdate' });
}
