import bcrypt from 'bcryptjs';
import { authMiddleware, generateToken, generateRefreshToken, verifyRefreshToken } from './middleware/auth';
import { generalRateLimit, bruteForceCheck, bruteForceRecordFailure, bruteForceRecordSuccess } from './middleware/rate_limit';
import { Env, Role, UserPayload } from './types';
import { json, success, error, unauthorized, cors, setCorsOrigin, resolveCorsOrigin } from './utils/response';
import { handleAdminMasterData, handleMapelKelas, handleGuruMapelAmpu, handleGuruKelasAmpu, handleWaliKelasList, handleGuruBKList, handleSiswaTemplate, handleSiswaPreview, handleSiswaBulk, handleMapelTemplate, handleMapelPreview, handleMapelBulk, handleGuruTemplate, handleGuruPreview, handleGuruBulk } from './routes/admin/master_data';
import { handleAdminUsers, handleHakAkses } from './routes/admin/users';
import { handleBackup, handleRestore, handleLogAktivitas } from './routes/admin/system';
import { handlePengaturanTampilan, handleProfilSekolah } from './routes/admin/pengaturan_tampilan';
import { handleDashboard } from './routes/admin/dashboard';
import { handleAdminAbsensi } from './routes/admin/absensi';
import { handleAdminNilai } from './routes/admin/nilai';
import { handleAdminRapor } from './routes/admin/rapor';
import { handlePenjadwalan } from './routes/wakil_kurikulum/penjadwalan';
import { handleNilaiWK } from './routes/wakil_kurikulum/nilai';
import { handleAbsensiWK } from './routes/wakil_kurikulum/absensi';
import { handleKenaikanKelas } from './routes/wakil_kurikulum/kenaikan_kelas';
import { handleLaporanWK } from './routes/wakil_kurikulum/laporan';
import { handleAbsensiGuru } from './routes/guru_mapel_wali_kelas/absensi';
import { handleNilaiGuru } from './routes/guru_mapel_wali_kelas/nilai';
import { handleRaporGuru } from './routes/guru_mapel_wali_kelas/rapor';
import { handlePengaduan } from './routes/guru_mapel_wali_kelas/pengaduan';
import { handleWaliKelas } from './routes/guru_mapel_wali_kelas/wali_kelas';
import { handlePengaduanBK } from './routes/guru_bk/pengaduan';
import { handleKonselingBK } from './routes/guru_bk/konseling';
import { handleMonitoringBK } from './routes/guru_bk/monitoring';
import { handleLaporanBK } from './routes/guru_bk/laporan';
import { handleDashboardKS } from './routes/kepala_sekolah/dashboard';
import { handleJadwalKS } from './routes/kepala_sekolah/jadwal';
import { handleAbsensiKS } from './routes/kepala_sekolah/absensi';
import { handleNilaiKS } from './routes/kepala_sekolah/nilai';
import { handleRaporKS } from './routes/kepala_sekolah/rapor';
import { handleBKKS } from './routes/kepala_sekolah/bk';
import { handleLaporanKS } from './routes/kepala_sekolah/laporan';
import { handleHealth } from './routes/health';

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const requestOrigin = request.headers.get('Origin');
    setCorsOrigin(resolveCorsOrigin(requestOrigin, env));

    if (request.method === 'OPTIONS') return cors();

    const url = new URL(request.url);
    const path = url.pathname;
    const pathParts = path.split('/').filter(Boolean);

    try {
      // General rate limit
      const rateLimitResponse = await generalRateLimit(request, env);
      if (rateLimitResponse) return rateLimitResponse;

      // Health check (no auth required)
      if (path === '/api/health' && request.method === 'GET') {
        return handleHealth(env);
      }

      // Auth routes (no auth required)
      if (path === '/api/auth/login' && request.method === 'POST') {
        return handleLogin(request, env);
      }

      // Public pengaturan (GET only, for login page)
      if (path === '/api/pengaturan-tampilan' && request.method === 'GET') {
        const rows = await env.DB.prepare('SELECT key, value FROM pengaturan ORDER BY key').all();
        return success(rows.results);
      }

      // Authenticated routes
      const user = await authMiddleware(request, env);
      if (!user) return unauthorized();

      if (path === '/api/auth/me' && request.method === 'GET') {
        return handleMe(user);
      }

      // Auth routes (no sign-in required)
      if (path === '/api/auth/refresh' && request.method === 'POST') {
        return handleRefresh(request, env);
      }

      // Admin routes
      if (pathParts[0] === 'api' && pathParts[1] === 'admin') {
        if (user.role !== 'admin') {
          return error('Forbidden: admin only', 403);
        }

        const subPath = pathParts.slice(2).join('/');

        // Mapel bulk endpoints (before master CRUD to avoid capture)
        if (subPath === 'mata-pelajaran/template' && request.method === 'GET') {
          return handleMapelTemplate(request, env);
        }
        if (subPath === 'mata-pelajaran/preview' && request.method === 'POST') {
          return handleMapelPreview(request, env);
        }
        if (subPath === 'mata-pelajaran/bulk' && request.method === 'POST') {
          return handleMapelBulk(request, env, user);
        }

        // Guru bulk endpoints (before master CRUD to avoid capture)
        if (subPath === 'guru/template' && request.method === 'GET') {
          return handleGuruTemplate(request, env);
        }
        if (subPath === 'guru/preview' && request.method === 'POST') {
          return handleGuruPreview(request, env);
        }
        if (subPath === 'guru/bulk' && request.method === 'POST') {
          return handleGuruBulk(request, env, user);
        }

        // Siswa bulk endpoints (before master CRUD to avoid capture)
        if (subPath === 'siswa/template' && request.method === 'GET') {
          return handleSiswaTemplate(env);
        }
        if (subPath === 'siswa/preview' && request.method === 'POST') {
          return handleSiswaPreview(request, env);
        }
        if (subPath === 'siswa/bulk' && request.method === 'POST') {
          return handleSiswaBulk(request, env, user);
        }

        // Master data CRUD: /api/admin/:resource or /api/admin/:resource/:id
        const masterResources = ['tahun-ajaran', 'semester', 'jurusan', 'tingkat', 'kelas', 'mata-pelajaran', 'guru', 'siswa', 'ruangan'];
        if (masterResources.includes(pathParts[2] || '')) {
          return handleAdminMasterData(request, env, user, pathParts, url);
        }

        // Guru associations
        if (subPath.startsWith('guru-mapel/')) {
          return handleGuruMapelAmpu(request, env, user, pathParts);
        }
        if (subPath.startsWith('guru-kelas/')) {
          return handleGuruKelasAmpu(request, env, user, pathParts);
        }

        // Wali Kelas & Guru BK list (read-only)
        if (subPath === 'wali-kelas') {
          return handleWaliKelasList(request, env, user);
        }
        if (subPath === 'guru-bk-list') {
          return handleGuruBKList(request, env, user);
        }

        // Mapel-Kelas association
        if (subPath.startsWith('mapel-kelas/')) {
          return handleMapelKelas(request, env, user, pathParts);
        }

        // Users & Hak Akses
        if (subPath === 'users' || subPath.startsWith('users/')) {
          return handleAdminUsers(request, env, user, pathParts, url);
        }
        if (subPath === 'hak-akses' || subPath.startsWith('hak-akses/')) {
          return handleHakAkses(request, env, user, pathParts);
        }

        // System
        if (subPath === 'dashboard') return handleDashboard(env);
        if (subPath === 'backup') return handleBackup(request, env, user);
        if (subPath === 'restore') return handleRestore(request, env, user);
        if (subPath === 'log-aktivitas') return handleLogAktivitas(request, env, user, url);
        if (subPath === 'profil') return handleProfilSekolah(request, env, user);
        if (subPath === 'pengaturan-tampilan') return handlePengaturanTampilan(request, env, user, url);

        // Absensi, Nilai, Rapor monitoring
        if (subPath.startsWith('absensi')) {
          return handleAdminAbsensi(request, env, url);
        }
        if (subPath.startsWith('nilai')) {
          return handleAdminNilai(request, env, user, url);
        }
        if (subPath.startsWith('rapor')) {
          return handleAdminRapor(request, env, user, url);
        }
      }

      // Wakil Kurikulum routes
      if (pathParts[0] === 'api' && pathParts[1] === 'wakil-kurikulum') {
        if (user.role !== 'wakil_kurikulum') return error('Forbidden', 403);

        const subPath = pathParts.slice(2).join('/');

        if (subPath === 'dashboard') return handleDashboardWK(env);
        if (subPath.startsWith('kesiapan') || subPath.startsWith('jp-slots') || subPath.startsWith('referensi') || subPath.startsWith('jadwal') || subPath.startsWith('jadwal-per-kelas') || subPath.startsWith('beban') || subPath.startsWith('jadwal-guru') || subPath.startsWith('jadwal-kelas') || subPath.startsWith('wali-kelas')) {
          return handlePenjadwalan(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('bobot-nilai') || subPath.startsWith('monitoring-nilai') || subPath.startsWith('status-pengumpulan')) {
          return handleNilaiWK(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('absensi')) {
          return handleAbsensiWK(request, env, url);
        }
        if (subPath.startsWith('kenaikan-kelas') || subPath.startsWith('alumni')) {
          return handleKenaikanKelas(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('laporan')) {
          return handleLaporanWK(request, env, user, pathParts, url);
        }
      }

      // Guru Mapel / Wali Kelas routes
      if (pathParts[0] === 'api' && pathParts[1] === 'guru') {
        if (user.role !== 'guru_mapel_wali_kelas') return error('Forbidden', 403);

        const subPath = pathParts.slice(2).join('/');

        if (subPath === 'dashboard') return handleDashboardGuru(env, user);
        if (subPath.startsWith('absensi')) {
          return handleAbsensiGuru(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('nilai')) {
          return handleNilaiGuru(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('rapor')) {
          return handleRaporGuru(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('pengaduan')) {
          return handlePengaduan(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('data-siswa') || subPath.startsWith('rekap-absensi') || subPath.startsWith('rekap-nilai') || subPath.startsWith('catatan-wali')) {
          return handleWaliKelas(request, env, user, pathParts, url);
        }
        if (subPath === 'jadwal' && request.method === 'GET') {
          return handleJadwalGuru(env, user);
        }
        if (subPath === 'profil' && request.method === 'GET') {
          return handleProfilGuru(env, user);
        }
      }

      // Kepala Sekolah routes
      if (pathParts[0] === 'api' && pathParts[1] === 'kepala-sekolah') {
        if (user.role !== 'kepala_sekolah') return error('Forbidden', 403);

        const subPath = pathParts.slice(2).join('/');

        if (subPath === 'dashboard') return handleDashboardKS(env);
        if (subPath === 'jadwal') return handleJadwalKS(request, env, url);
        if (subPath === 'absensi') return handleAbsensiKS(request, env, url);
        if (subPath === 'nilai') return handleNilaiKS(request, env, url);
        if (subPath === 'rapor') return handleRaporKS(request, env, url);
        if (subPath === 'bk') return handleBKKS(request, env, url);
        if (subPath === 'laporan') return handleLaporanKS(request, env, url);
      }

      // Guru BK routes
      if (pathParts[0] === 'api' && pathParts[1] === 'guru-bk') {
        if (user.role !== 'guru_bk') return error('Forbidden', 403);

        const subPath = pathParts.slice(2).join('/');

        if (subPath.startsWith('pengaduan')) {
          return handlePengaduanBK(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('jadwal-konseling') || subPath.startsWith('konseling') || subPath.startsWith('bakat-minat')) {
          return handleKonselingBK(request, env, user, pathParts, url);
        }
        if (subPath.startsWith('monitoring')) {
          return handleMonitoringBK(request, env, url);
        }
        if (subPath.startsWith('statistik') || subPath.startsWith('bulanan') || subPath.startsWith('rekap-kasus') || subPath.startsWith('laporan/')) {
          return handleLaporanBK(request, env, user, pathParts, url);
        }
      }

      // Shared referensi endpoint (any role)
      if (path === '/api/referensi' && request.method === 'GET') {
        return handleReferensi(env);
      }

      return error('Not Found', 404);
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Internal Server Error';
      return error(msg, 500);
    }
  },
};

async function handleLogin(request: Request, env: Env): Promise<Response> {
  let body: { username?: string; password?: string };
  try {
    body = await request.json();
  } catch {
    return error('Invalid JSON body', 400);
  }

  const { username, password } = body;
  if (!username || !password) {
    return error('Username and password are required', 400);
  }

  // Brute force check sebelum memproses login
  const bfCheck = await bruteForceCheck(username, request, env);
  if (bfCheck) return bfCheck;

  const result = await env.DB.prepare(
    'SELECT id, username, password_hash, role, guru_id, is_active FROM users WHERE username = ?'
  ).bind(username).first<{
    id: number; username: string; password_hash: string; role: Role; guru_id: number | null; is_active: number;
  }>();

  if (!result) {
    await bruteForceRecordFailure(username, request, env);
    return error('Invalid username or password', 401);
  }

  if (!result.is_active) return error('Account is disabled', 403);

  const passwordMatch = await bcrypt.compare(password, result.password_hash);
  if (!passwordMatch) {
    await bruteForceRecordFailure(username, request, env);
    return error('Invalid username or password', 401);
  }

  // Login berhasil — reset brute force counter
  await bruteForceRecordSuccess(username, env);

  const userPayload = { sub: result.id, username: result.username, role: result.role as Role, guru_id: result.guru_id };
  const token = await generateToken(userPayload, env);
  const refreshToken = await generateRefreshToken(result.id, env);

  await env.DB.prepare("UPDATE users SET last_login_at = datetime('now') WHERE id = ?").bind(result.id).run();

  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'login', 'auth', ?, ?)"
  ).bind(result.id, `Login user ${result.username}`, ip).run();

  return success({
    token,
    refresh_token: refreshToken,
    user: { id: result.id, username: result.username, role: result.role, guru_id: result.guru_id },
  });
}

function handleMe(user: { sub: number; username: string; role: string; guru_id: number | null }): Response {
  return success({ id: user.sub, username: user.username, role: user.role, guru_id: user.guru_id });
}

async function handleRefresh(request: Request, env: Env): Promise<Response> {
  let body: { refresh_token?: string; username?: string };
  try {
    body = await request.json();
  } catch {
    return error('Invalid JSON body', 400);
  }

  const { refresh_token, username } = body;
  if (!refresh_token) return error('refresh_token is required', 400);

  // Brute force check untuk refresh token (pakai username jika ada)
  if (username) {
    const bfCheck = await bruteForceCheck(username, request, env);
    if (bfCheck) return bfCheck;
  }

  const payload = await verifyRefreshToken(refresh_token, env);
  if (!payload) return error('Invalid or expired refresh token', 401);

  const user = await env.DB.prepare(
    'SELECT id, username, role, guru_id, is_active FROM users WHERE id = ?'
  ).bind(payload.sub).first<{ id: number; username: string; role: Role; guru_id: number | null; is_active: number }>();

  if (!user || !user.is_active) return error('User not found or disabled', 401);

  const userPayload = { sub: user.id, username: user.username, role: user.role, guru_id: user.guru_id };
  const newToken = await generateToken(userPayload, env);
  const newRefreshToken = await generateRefreshToken(user.id, env);

  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'refresh_token', 'auth', ?, ?)"
  ).bind(user.id, `Token refresh untuk user ${user.username}`, ip).run();

  return success({
    token: newToken,
    refresh_token: newRefreshToken,
    user: { id: user.id, username: user.username, role: user.role, guru_id: user.guru_id },
  });
}

async function handleJadwalGuru(env: Env, user: UserPayload): Promise<Response> {
  const guruId = user.guru_id;
  if (!guruId) return success([]);
  const semester = await env.DB.prepare("SELECT id FROM semester WHERE is_aktif = 1 LIMIT 1").first<{ id: number }>();
  if (!semester) return success([]);
  const rows = await env.DB.prepare(`
    SELECT jp.*, mp.nama as mapel_nama, k.nama as kelas_nama, r.nama as ruangan_nama
    FROM jadwal_pelajaran jp
    LEFT JOIN mata_pelajaran mp ON jp.mata_pelajaran_id = mp.id
    LEFT JOIN kelas k ON jp.kelas_id = k.id
    LEFT JOIN ruangan r ON jp.ruangan_id = r.id
    WHERE jp.guru_id = ? AND jp.semester_id = ? AND jp.status_validasi = 'tervalidasi'
    ORDER BY jp.hari, jp.jam_mulai
  `).bind(guruId, semester.id).all();
  return success(rows.results);
}

async function handleProfilGuru(env: Env, user: UserPayload): Promise<Response> {
  const guruId = user.guru_id;
  if (!guruId) return success(null);

  const profil = await env.DB.prepare(
    `SELECT id, nip, nama, jenis_kelamin, tempat_lahir, tanggal_lahir, alamat, no_hp, email, status,
            jabatan, status_aktif, created_at
     FROM guru WHERE id = ?`
  ).bind(guruId).first();

  return success(profil || null);
}

async function handleDashboardGuru(env: Env, user: UserPayload): Promise<Response> {
  const guruId = user.guru_id;
  if (!guruId) return success({ jadwal_hari_ini: 0, total_absensi: 0, total_nilai: 0, pengaduan_aktif: 0 });

  const [jadwal, absensi, nilai, pengaduan] = await Promise.all([
    env.DB.prepare(
      `SELECT COUNT(*) as total FROM jadwal_pelajaran WHERE guru_id = ? AND hari = CASE CAST(strftime('%w', 'now') AS INTEGER) WHEN 1 THEN 'Senin' WHEN 2 THEN 'Selasa' WHEN 3 THEN 'Rabu' WHEN 4 THEN 'Kamis' WHEN 5 THEN 'Jumat' WHEN 6 THEN 'Sabtu' ELSE '' END`
    ).bind(guruId).first<{ total: number }>(),
    env.DB.prepare('SELECT COUNT(*) as total FROM absensi_siswa WHERE diinput_oleh = ?').bind(guruId).first<{ total: number }>(),
    env.DB.prepare('SELECT COUNT(*) as total FROM nilai WHERE diinput_oleh = ?').bind(guruId).first<{ total: number }>(),
    env.DB.prepare("SELECT COUNT(*) as total FROM pengaduan WHERE dilaporkan_oleh = ? AND status = 'baru'").bind(guruId).first<{ total: number }>(),
  ]);

  return success({
    jadwal_hari_ini: jadwal?.total || 0,
    total_absensi: absensi?.total || 0,
    total_nilai: nilai?.total || 0,
    pengaduan_aktif: pengaduan?.total || 0,
  });
}

async function handleReferensi(env: Env): Promise<Response> {
  const [kelas, mataPelajaran, semester, siswa] = await Promise.all([
    env.DB.prepare('SELECT id, nama FROM kelas ORDER BY nama').all(),
    env.DB.prepare('SELECT id, nama, kode FROM mata_pelajaran ORDER BY nama').all(),
    env.DB.prepare('SELECT id, nama FROM semester WHERE is_aktif = 1 ORDER BY tahun_ajaran_id DESC, nama').all(),
    env.DB.prepare("SELECT id, nis, nama FROM siswa WHERE status = 'aktif' ORDER BY nama").all(),
  ]);

  return success({
    kelas: kelas.results,
    mata_pelajaran: mataPelajaran.results,
    semester: semester.results,
    siswa: siswa.results,
  });
}

async function handleDashboardWK(env: Env): Promise<Response> {
  const [jadwalCount, nilaiCount, draftCount] = await Promise.all([
    env.DB.prepare('SELECT COUNT(*) as total FROM jadwal_pelajaran').first<{ total: number }>(),
    env.DB.prepare('SELECT COUNT(*) as total FROM nilai').first<{ total: number }>(),
    env.DB.prepare("SELECT COUNT(*) as total FROM nilai WHERE status_validasi = 'draft'").first<{ total: number }>(),
  ]);

  return success({
    jadwal: jadwalCount?.total || 0,
    total_nilai: nilaiCount?.total || 0,
    nilai_belum_divalidasi: draftCount?.total || 0,
  });
}
