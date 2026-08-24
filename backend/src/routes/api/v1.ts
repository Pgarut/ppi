import { Env, ApiKeyPayload } from '../../types';
import { success, error, badRequest, notFound, unauthorized, forbidden } from '../../utils/response';
import { validateApiKey, requirePermission } from '../../middleware/api_key';

// ============================================================
// Public API Endpoints for Sistem 2 (Pihak Kedua)
// Base path: /api/v1/*
// Auth: X-API-Key header
// ============================================================

export async function handleApiV1Routes(request: Request, env: Env, pathParts: string[], url: URL): Promise<Response> {
  const method = request.method;
  const subPath = pathParts.slice(2).join('/'); // remove 'api', 'v1'

  // Validate API Key for ALL /api/v1/* routes
  const authResult = await validateApiKey(request, env);
  if (!authResult.valid) return authResult.error;

  const { payload: apiKey } = authResult;

  // ============================================================
  // READ ENDPOINTS (require 'read' or 'readwrite' permission)
  // ============================================================

  // GET /api/v1/santri - List santri (with pagination, search, filter)
  if (subPath === 'santri' && method === 'GET') {
    return requirePermission('read')(request, env).then(async (result) => {
      if (!result.valid) return result.error;
      return getSantriList(env, url, result.payload);
    });
  }

  // GET /api/v1/santri/:id - Get single santri detail
  if (subPath.startsWith('santri/') && method === 'GET') {
    const id = parseInt(subPath.split('/')[1]);
    if (isNaN(id)) return badRequest('ID tidak valid');
    return requirePermission('read')(request, env).then(async (result) => {
      if (!result.valid) return result.error;
      return getSantriDetail(env, id);
    });
  }

  // GET /api/v1/kelas - List kelas
  if (subPath === 'kelas' && method === 'GET') {
    return requirePermission('read')(request, env).then(async (result) => {
      if (!result.valid) return result.error;
      return getKelasList(env, url);
    });
  }

  // GET /api/v1/kenaikan-kelas - List kenaikan kelas (history)
  if (subPath === 'kenaikan-kelas' && method === 'GET') {
    return requirePermission('read')(request, env).then(async (result) => {
      if (!result.valid) return result.error;
      return getKenaikanKelasList(env, url);
    });
  }

  // GET /api/v1/kenaikan-kelas/alumni/calon - Get calon alumni (XII belum alumni)
  if (subPath === 'kenaikan-kelas/alumni/calon' && method === 'GET') {
    return requirePermission('read')(request, env).then(async (result) => {
      if (!result.valid) return result.error;
      return getCalonAlumni(env, url);
    });
  }

  // GET /api/v1/jenis-pembayaran - List jenis pembayaran
  if (subPath === 'jenis-pembayaran' && method === 'GET') {
    return requirePermission('read')(request, env).then(async (result) => {
      if (!result.valid) return result.error;
      return getJenisPembayaranList(env);
    });
  }

  // ============================================================
  // WRITE ENDPOINTS (require 'write' or 'readwrite' permission)
  // ============================================================

  // POST /api/v1/pembayaran - Create pembayaran record
  if (subPath === 'pembayaran' && method === 'POST') {
    return requirePermission('write')(request, env).then(async (result) => {
      if (!result.valid) return result.error;
      return createPembayaran(request, env, result.payload);
    });
  }

  // POST /api/v1/notifikasi - Send notifikasi to santri
  if (subPath === 'notifikasi' && method === 'POST') {
    return requirePermission('write')(request, env).then(async (result) => {
      if (!result.valid) return result.error;
      return createNotifikasi(request, env, result.payload);
    });
  }

  // GET /api/v1/pembayaran/santri/:santriId - Get pembayaran for santri (read permission)
  if (subPath.startsWith('pembayaran/santri/') && method === 'GET') {
    const santriId = parseInt(subPath.split('/')[2]);
    if (isNaN(santriId)) return badRequest('ID santri tidak valid');
    return requirePermission('read')(request, env).then(async (result) => {
      if (!result.valid) return result.error;
      return getPembayaranBySantri(env, santriId, url);
    });
  }

  // GET /api/v1/notifikasi/santri/:santriId - Get notifikasi for santri
  if (subPath.startsWith('notifikasi/santri/') && method === 'GET') {
    const santriId = parseInt(subPath.split('/')[2]);
    if (isNaN(santriId)) return badRequest('ID santri tidak valid');
    return requirePermission('read')(request, env).then(async (result) => {
      if (!result.valid) return result.error;
      return getNotifikasiBySantri(env, santriId, url);
    });
  }

  return error('Not Found', 404);
}

// ============================================================
// READ Handlers
// ============================================================

async function getSantriList(env: Env, url: URL, apiKey: { id: number }): Promise<Response> {
  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const perPage = Math.min(100, Math.max(1, parseInt(url.searchParams.get('per_page') || '20')));
  const offset = (page - 1) * perPage;
  const search = url.searchParams.get('search') || '';
  const kelasId = url.searchParams.get('kelas_id');
  const status = url.searchParams.get('status'); // 'aktif' | 'lulus' | 'pindah' | 'keluar'
  const tahunAjaranId = url.searchParams.get('tahun_ajaran_id');

  let whereClause = 'WHERE 1=1';
  const params: (string | number)[] = [];

  if (search) {
    whereClause += ' AND (s.nis LIKE ? OR s.nama LIKE ? OR s.nisn LIKE ?)';
    params.push(`%${search}%`, `%${search}%`, `%${search}%`);
  }

  if (kelasId) {
    whereClause += ' AND s.kelas_id = ?';
    params.push(parseInt(kelasId));
  }

  if (status) {
    whereClause += ' AND s.status = ?';
    params.push(status);
  }

  if (tahunAjaranId) {
    whereClause += ' AND s.tahun_ajaran_id = ?';
    params.push(parseInt(tahunAjaranId));
  }

  const countResult = await env.DB.prepare(
    `SELECT COUNT(*) as total FROM siswa s ${whereClause}`
  ).bind(...params).first<{ total: number }>();

  const total = countResult?.total || 0;

  const rows = await env.DB.prepare(
    `SELECT s.id, s.nis, s.nisn, s.nama, s.jenis_kelamin, s.tempat_lahir, s.tanggal_lahir,
            s.alamat, s.no_hp_ortu, s.nama_ayah, s.nama_ibu, s.pekerjaan_ayah, s.pekerjaan_ibu,
            s.whatsapp, s.kelas_id, s.tahun_ajaran_id, s.status, s.created_at,
            k.nama as kelas_nama, t.nama as tingkat_nama, t.jenjang, j.nama as jurusan_nama,
            ta.nama as tahun_ajaran_nama
     FROM siswa s
     LEFT JOIN kelas k ON s.kelas_id = k.id
     LEFT JOIN tingkat t ON k.tingkat_id = t.id
     LEFT JOIN jurusan j ON k.jurusan_id = j.id
     LEFT JOIN tahun_ajaran ta ON s.tahun_ajaran_id = ta.id
     ${whereClause}
     ORDER BY s.nama ASC LIMIT ? OFFSET ?`
  ).bind(...params, perPage, offset).all();

  return success({
    items: rows.results,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
  });
}

async function getSantriDetail(env: Env, id: number): Promise<Response> {
  const row = await env.DB.prepare(
    `SELECT s.id, s.nis, s.nisn, s.nama, s.jenis_kelamin, s.tempat_lahir, s.tanggal_lahir,
            s.alamat, s.no_hp_ortu, s.nama_ayah, s.nama_ibu, s.pekerjaan_ayah, s.pekerjaan_ibu,
            s.whatsapp, s.kelas_id, s.tahun_ajaran_id, s.status, s.created_at,
            k.nama as kelas_nama, t.nama as tingkat_nama, t.jenjang, j.nama as jurusan_nama,
            ta.nama as tahun_ajaran_nama
     FROM siswa s
     LEFT JOIN kelas k ON s.kelas_id = k.id
     LEFT JOIN tingkat t ON k.tingkat_id = t.id
     LEFT JOIN jurusan j ON k.jurusan_id = j.id
     LEFT JOIN tahun_ajaran ta ON s.tahun_ajaran_id = ta.id
     WHERE s.id = ?`
  ).bind(id).first();

  if (!row) return notFound('Santri');

  return success(row);
}

async function getKelasList(env: Env, url: URL): Promise<Response> {
  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const perPage = Math.min(100, Math.max(1, parseInt(url.searchParams.get('per_page') || '50')));
  const offset = (page - 1) * perPage;
  const tahunAjaranId = url.searchParams.get('tahun_ajaran_id');
  const search = url.searchParams.get('search') || '';

  let whereClause = 'WHERE 1=1';
  const params: (string | number)[] = [];

  if (tahunAjaranId) {
    whereClause += ' AND k.tahun_ajaran_id = ?';
    params.push(parseInt(tahunAjaranId));
  }

  if (search) {
    whereClause += ' AND k.nama LIKE ?';
    params.push(`%${search}%`);
  }

  const countResult = await env.DB.prepare(
    `SELECT COUNT(*) as total FROM kelas k ${whereClause}`
  ).bind(...params).first<{ total: number }>();

  const total = countResult?.total || 0;

  const rows = await env.DB.prepare(
    `SELECT k.id, k.nama, k.tingkat_id, k.jurusan_id, k.wali_kelas_id, k.ruangan_id, k.tahun_ajaran_id,
            t.nama as tingkat_nama, t.jenjang, j.nama as jurusan_nama,
            g.nama as wali_kelas_nama, r.nama as ruangan_nama,
            ta.nama as tahun_ajaran_nama,
            (SELECT COUNT(*) FROM siswa WHERE kelas_id = k.id AND status = 'aktif') as jumlah_siswa
     FROM kelas k
     LEFT JOIN tingkat t ON k.tingkat_id = t.id
     LEFT JOIN jurusan j ON k.jurusan_id = j.id
     LEFT JOIN guru g ON k.wali_kelas_id = g.id
     LEFT JOIN ruangan r ON k.ruangan_id = r.id
     LEFT JOIN tahun_ajaran ta ON k.tahun_ajaran_id = ta.id
     ${whereClause}
     ORDER BY t.jenjang DESC, t.nama, k.nama LIMIT ? OFFSET ?`
  ).bind(...params, perPage, offset).all();

  return success({
    items: rows.results,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
  });
}

async function getKenaikanKelasList(env: Env, url: URL): Promise<Response> {
  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const perPage = Math.min(100, Math.max(1, parseInt(url.searchParams.get('per_page') || '20')));
  const offset = (page - 1) * perPage;
  const search = url.searchParams.get('search') || '';
  const tahunAjaranId = url.searchParams.get('tahun_ajaran_id');

  let whereClause = 'WHERE 1=1';
  const params: (string | number)[] = [];

  if (search) {
    whereClause += ' AND (s.nis LIKE ? OR s.nama LIKE ?)';
    params.push(`%${search}%`, `%${search}%`);
  }

  if (tahunAjaranId) {
    whereClause += ' AND kk.tahun_ajaran_id = ?';
    params.push(parseInt(tahunAjaranId));
  }

  const countResult = await env.DB.prepare(
    `SELECT COUNT(*) as total FROM kenaikan_kelas kk
     JOIN siswa s ON kk.siswa_id = s.id ${whereClause}`
  ).bind(...params).first<{ total: number }>();

  const total = countResult?.total || 0;

  const rows = await env.DB.prepare(
    `SELECT kk.id, kk.siswa_id, kk.dari_kelas_id, kk.ke_kelas_id, kk.tahun_ajaran_id,
            kk.status, kk.no_surat_keputusan, kk.tanggal_keputusan, kk.created_at,
            s.nis, s.nama as siswa_nama,
            dk.nama as dari_kelas_nama,
            kk2.nama as ke_kelas_nama,
            ta.nama as tahun_ajaran_nama
     FROM kenaikan_kelas kk
     JOIN siswa s ON kk.siswa_id = s.id
     LEFT JOIN kelas dk ON kk.dari_kelas_id = dk.id
     LEFT JOIN kelas kk2 ON kk.ke_kelas_id = kk2.id
     LEFT JOIN tahun_ajaran ta ON kk.tahun_ajaran_id = ta.id
     ${whereClause}
     ORDER BY kk.created_at DESC LIMIT ? OFFSET ?`
  ).bind(...params, perPage, offset).all();

  return success({
    items: rows.results,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
  });
}

async function getCalonAlumni(env: Env, url: URL): Promise<Response> {
  // Siswa kelas XII (tingkat MA) yang belum jadi alumni
  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const perPage = Math.min(100, Math.max(1, parseInt(url.searchParams.get('per_page') || '50')));
  const offset = (page - 1) * perPage;
  const search = url.searchParams.get('search') || '';
  const tahunAjaranId = url.searchParams.get('tahun_ajaran_id');

  // Get aktif tahun ajaran if not specified
  let targetTahunAjaranId = tahunAjaranId;
  if (!targetTahunAjaranId) {
    const activeTA = await env.DB.prepare("SELECT id FROM tahun_ajaran WHERE is_aktif = 1 LIMIT 1").first<{ id: number }>();
    if (activeTA) targetTahunAjaranId = String(activeTA.id);
  }

  let whereClause = `WHERE s.status = 'aktif' AND t.nama IN ('X', 'XI', 'XII') AND t.jenjang = 'MA'`;
  const params: (string | number)[] = [];

  if (targetTahunAjaranId) {
    whereClause += ' AND s.tahun_ajaran_id = ?';
    params.push(parseInt(targetTahunAjaranId));
  }

  // Exclude yang sudah jadi alumni
  whereClause += ' AND NOT EXISTS (SELECT 1 FROM alumni a WHERE a.siswa_id = s.id)';

  if (search) {
    whereClause += ' AND (s.nis LIKE ? OR s.nama LIKE ?)';
    params.push(`%${search}%`, `%${search}%`);
  }

  const countResult = await env.DB.prepare(
    `SELECT COUNT(*) as total FROM siswa s
     JOIN kelas k ON s.kelas_id = k.id
     JOIN tingkat t ON k.tingkat_id = t.id
     ${whereClause}`
  ).bind(...params).first<{ total: number }>();

  const total = countResult?.total || 0;

  const rows = await env.DB.prepare(
    `SELECT s.id, s.nis, s.nama, s.kelas_id, s.tahun_ajaran_id,
            k.nama as kelas_nama, t.nama as tingkat_nama, t.jenjang
     FROM siswa s
     JOIN kelas k ON s.kelas_id = k.id
     JOIN tingkat t ON k.tingkat_id = t.id
     ${whereClause}
     ORDER BY t.nama DESC, k.nama, s.nama LIMIT ? OFFSET ?`
  ).bind(...params, perPage, offset).all();

  return success({
    items: rows.results,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
  });
}

async function getJenisPembayaranList(env: Env): Promise<Response> {
  const rows = await env.DB.prepare(
    `SELECT id, nama, kode, deskripsi, is_aktif, created_at
     FROM jenis_pembayaran
     WHERE is_aktif = 1
     ORDER BY nama`
  ).all();

  return success(rows.results);
}

// ============================================================
// WRITE Handlers
// ============================================================

async function createPembayaran(request: Request, env: Env, apiKey: ApiKeyPayload): Promise<Response> {
  let body: {
    santri_id: number;
    jenis_pembayaran_id: number;
    jumlah: number;
    status?: string; // '*' | '**' | '***'
    tanggal_bayar?: string; // YYYY-MM-DD
    bukti_url?: string;
    catatan?: string;
  };

  try {
    body = await request.json();
  } catch {
    return badRequest('Invalid JSON body');
  }

  const { santri_id, jenis_pembayaran_id, jumlah, status = '***', tanggal_bayar, bukti_url, catatan } = body;

  // Validasi required fields
  if (!santri_id || !jenis_pembayaran_id || jumlah === undefined) {
    return badRequest('santri_id, jenis_pembayaran_id, dan jumlah wajib diisi');
  }

  if (typeof jumlah !== 'number' || jumlah <= 0) {
    return badRequest('jumlah harus berupa angka positif');
  }

  const validStatuses = ['*', '**', '***'];
  if (!validStatuses.includes(status)) {
    return badRequest(`status harus salah satu dari: ${validStatuses.join(', ')}`);
  }

  // Cek santri exists
  const santri = await env.DB.prepare('SELECT id, nama FROM siswa WHERE id = ?').bind(santri_id).first();
  if (!santri) return notFound('Santri');

  // Cek jenis pembayaran exists
  const jenis = await env.DB.prepare('SELECT id, nama FROM jenis_pembayaran WHERE id = ? AND is_aktif = 1').bind(jenis_pembayaran_id).first();
  if (!jenis) return notFound('Jenis Pembayaran');

  // Validasi tanggal_bayar jika status '*' (lunas)
  if (status === '*' && !tanggal_bayar) {
    return badRequest('tanggal_bayar wajib diisi untuk status Lunas (*)');
  }

  const result = await env.DB.prepare(
    `INSERT INTO pembayaran (santri_id, jenis_pembayaran_id, jumlah, status, tanggal_bayar, bukti_url, catatan, api_key_id)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
  ).bind(santri_id, jenis_pembayaran_id, jumlah, status, tanggal_bayar || null, bukti_url || null, catatan || null, apiKey.id).run();

  const pembayaranId = result.meta.last_row_id;

  // Log aktivitas
  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'pembayaran_api', ?, ?)"
  ).bind(0, `API Key ${apiKey.nama_pihak} (ID: ${apiKey.id}) membuat pembayaran untuk santri ${santri.nama}`, request.headers.get('CF-Connecting-IP') || 'unknown').run();

  return success({
    id: pembayaranId,
    santri_id,
    jenis_pembayaran_id,
    jumlah,
    status,
    tanggal_bayar,
    bukti_url,
    catatan,
    api_key_id: apiKey.id,
    created_at: new Date().toISOString(),
  }, 'Pembayaran berhasil dicatat');
}

async function createNotifikasi(request: Request, env: Env, apiKey: ApiKeyPayload): Promise<Response> {
  let body: {
    santri_id: number;
    judul: string;
    pesan: string;
    tipe?: 'info' | 'warning' | 'success' | 'error';
  };

  try {
    body = await request.json();
  } catch {
    return badRequest('Invalid JSON body');
  }

  const { santri_id, judul, pesan, tipe = 'info' } = body;

  if (!santri_id || !judul || !pesan) {
    return badRequest('santri_id, judul, dan pesan wajib diisi');
  }

  const validTypes = ['info', 'warning', 'success', 'error'];
  if (!validTypes.includes(tipe)) {
    return badRequest(`tipe harus salah satu dari: ${validTypes.join(', ')}`);
  }

  const santri = await env.DB.prepare('SELECT id, nama FROM siswa WHERE id = ?').bind(santri_id).first();
  if (!santri) return notFound('Santri');

  const result = await env.DB.prepare(
    `INSERT INTO notifikasi (santri_id, judul, pesan, tipe, api_key_id)
     VALUES (?, ?, ?, ?, ?)`
  ).bind(santri_id, judul, pesan, tipe, apiKey.id).run();

  const notifikasiId = result.meta.last_row_id;

  // Log aktivitas
  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'notifikasi_api', ?, ?)"
  ).bind(0, `API Key ${apiKey.nama_pihak} (ID: ${apiKey.id}) kirim notifikasi ke santri ${santri.nama}`, request.headers.get('CF-Connecting-IP') || 'unknown').run();

  // TODO: Push notification ke FCM/device santri (implementasi terpisah)
  // Bisa menggunakan Cloudflare Workers queue atau trigger ke service lain

  return success({
    id: notifikasiId,
    santri_id,
    judul,
    pesan,
    tipe,
    api_key_id: apiKey.id,
    is_read: false,
    created_at: new Date().toISOString(),
  }, 'Notifikasi berhasil dikirim');
}

async function getPembayaranBySantri(env: Env, santriId: number, url: URL): Promise<Response> {
  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const perPage = Math.min(100, Math.max(1, parseInt(url.searchParams.get('per_page') || '20')));
  const offset = (page - 1) * perPage;
  const status = url.searchParams.get('status');

  let whereClause = 'WHERE p.santri_id = ?';
  const params: (string | number)[] = [santriId];

  if (status) {
    whereClause += ' AND p.status = ?';
    params.push(status);
  }

  const countResult = await env.DB.prepare(
    `SELECT COUNT(*) as total FROM pembayaran p ${whereClause}`
  ).bind(...params).first<{ total: number }>();

  const total = countResult?.total || 0;

  const rows = await env.DB.prepare(
    `SELECT p.id, p.santri_id, p.jenis_pembayaran_id, p.jumlah, p.status, p.tanggal_bayar,
            p.bukti_url, p.catatan, p.api_key_id, p.created_at, p.updated_at,
            jp.nama as jenis_nama, jp.kode as jenis_kode,
            ak.nama_pihak as pihak_nama
     FROM pembayaran p
     JOIN jenis_pembayaran jp ON p.jenis_pembayaran_id = jp.id
     LEFT JOIN api_keys ak ON p.api_key_id = ak.id
     ${whereClause}
     ORDER BY p.created_at DESC LIMIT ? OFFSET ?`
  ).bind(...params, perPage, offset).all();

  // Map status to readable
  const items = rows.results.map((r: any) => ({
    ...r,
    status_label: r.status === '*' ? 'Lunas' : r.status === '**' ? 'Proses' : 'Belum Bayar',
  }));

  return success({
    items,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
  });
}

async function getNotifikasiBySantri(env: Env, santriId: number, url: URL): Promise<Response> {
  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const perPage = Math.min(100, Math.max(1, parseInt(url.searchParams.get('per_page') || '20')));
  const offset = (page - 1) * perPage;
  const isRead = url.searchParams.get('is_read');

  let whereClause = 'WHERE n.santri_id = ?';
  const params: (string | number)[] = [santriId];

  if (isRead !== null) {
    whereClause += ' AND n.is_read = ?';
    params.push(isRead === 'true' ? 1 : 0);
  }

  const countResult = await env.DB.prepare(
    `SELECT COUNT(*) as total FROM notifikasi n ${whereClause}`
  ).bind(...params).first<{ total: number }>();

  const total = countResult?.total || 0;

  const rows = await env.DB.prepare(
    `SELECT n.id, n.santri_id, n.judul, n.pesan, n.tipe, n.is_read, n.api_key_id, n.created_at,
            ak.nama_pihak as pihak_nama
     FROM notifikasi n
     LEFT JOIN api_keys ak ON n.api_key_id = ak.id
     ${whereClause}
     ORDER BY n.created_at DESC LIMIT ? OFFSET ?`
  ).bind(...params, perPage, offset).all();

  return success({
    items: rows.results,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
  });
}