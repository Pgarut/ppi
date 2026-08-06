import { Env, UserPayload } from '../../types';
import { CrudConfig, list, getById, create, update, remove, success, notFound } from '../../utils/crud';
import { json, badRequest, corsHeaders } from '../../utils/response';
import bcrypt from 'bcryptjs';
import * as XLSX from 'xlsx';

function jabatanToRole(jabatan: string): string {
  if (jabatan.includes('guru_bk')) return 'guru_bk';
  if (jabatan.includes('wakil_kurikulum')) return 'wakil_kurikulum';
  if (jabatan.includes('kepala_sekolah')) return 'kepala_sekolah';
  return 'guru_mapel_wali_kelas';
}

async function upsertUserForGuru(env: Env, guruId: number, username: string, password: string, jabatan: string, adminId: number, ip: string) {
  const role = jabatanToRole(jabatan);
  const passwordHash = await bcrypt.hash(password, 10);

  const existing = await env.DB.prepare('SELECT id FROM users WHERE guru_id = ?').bind(guruId).first<{ id: number }>();
  if (existing) {
    await env.DB.prepare('UPDATE users SET username = ?, password_hash = ?, role = ? WHERE guru_id = ?')
      .bind(username, passwordHash, role, guruId).run();
    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'users', ?, ?)")
      .bind(adminId, `Update user untuk guru id=${guruId}`, ip).run();
  } else {
    await env.DB.prepare("INSERT INTO users (username, password_hash, role, guru_id, is_active) VALUES (?, ?, ?, ?, 1)")
      .bind(username, passwordHash, role, guruId).run();
    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'users', ?, ?)")
      .bind(adminId, `Buat user untuk guru id=${guruId} (${username})`, ip).run();
  }
}

const configs: Record<string, CrudConfig> = {
  'tahun-ajaran': { table: 'tahun_ajaran', columns: ['nama', 'is_aktif'], label: 'Tahun Ajaran', searchFields: ['nama'], timestamp: true },
  'semester': { table: 'semester', columns: ['tahun_ajaran_id', 'nama', 'is_aktif'], label: 'Semester', searchFields: ['nama'], timestamp: true },
  'jurusan': { table: 'jurusan', columns: ['nama', 'kode'], label: 'Jurusan', searchFields: ['nama', 'kode'], timestamp: true },
  'tingkat': { table: 'tingkat', columns: ['nama', 'jenjang'], label: 'Tingkat', searchFields: ['nama'], timestamp: true },
  'kelas': { table: 'kelas', columns: ['nama', 'tingkat_id', 'jurusan_id', 'tahun_ajaran_id'], label: 'Kelas', searchFields: ['nama'], timestamp: true },
  'mata-pelajaran': { table: 'mata_pelajaran', columns: ['nama', 'kode'], label: 'Mata Pelajaran', searchFields: ['nama', 'kode'], timestamp: true },
  'guru': { table: 'guru', columns: ['nip', 'nama', 'jenis_kelamin', 'jabatan', 'status_aktif'], label: 'Asatidz', searchFields: ['nama', 'nip'], filterFields: ['jabatan'], timestamp: true },
  'siswa': { table: 'siswa', columns: ['nis', 'nisn', 'nama', 'jenis_kelamin', 'kelas_id', 'status'], label: 'Santri', searchFields: ['nama', 'nis', 'nisn'], timestamp: true },
  'ruangan': { table: 'ruangan', columns: ['nama', 'kapasitas'], label: 'Ruangan', searchFields: ['nama'], timestamp: true },
};

export async function handleAdminMasterData(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

  if (pathParts.length < 3) return badRequest('Resource tidak valid');

  const resource = pathParts[2];

  const isList = pathParts.length === 3 && request.method === 'GET' && !url.searchParams.has('id');
  const isById = pathParts.length === 4 && request.method === 'GET';
  const isCreate = pathParts.length === 3 && request.method === 'POST';
  const isUpdate = pathParts.length === 4 && request.method === 'PUT';
  const isDelete = pathParts.length === 4 && request.method === 'DELETE';

  const cfg = configs[resource];
  if (!cfg) return badRequest(`Resource '${resource}' tidak dikenal`);

  try {
    if (isList) return list(env, cfg, url, user);
    if (isById) return getById(env, cfg, parseInt(pathParts[3]));
    if (isCreate) {
      const body = await request.json() as Record<string, unknown>;
      const result = await create(env, cfg, body, user, ip);
      if (resource === 'guru') {
        const resultBody = await result.clone().json() as { data?: { id?: number } };
        const guruId = resultBody?.data?.id;
        const username = body['username'] as string | undefined;
        const password = body['password'] as string | undefined;
        if (guruId && username && password) {
          await upsertUserForGuru(env, guruId, username, password, (body['jabatan'] as string) || '', user.sub, ip);
        }
      }
      return result;
    }
    if (isUpdate) {
      const body = await request.json() as Record<string, unknown>;
      const guruId = parseInt(pathParts[3]);
      const result = await update(env, cfg, guruId, body, user, ip);
      if (resource === 'guru') {
        const username = body['username'] as string | undefined;
        const password = body['password'] as string | undefined;
        if (username && password) {
          const jabatan = body['jabatan'] as string | undefined;
          const existingGuru = await env.DB.prepare('SELECT jabatan FROM guru WHERE id = ?').bind(guruId).first<{ jabatan: string }>();
          await upsertUserForGuru(env, guruId, username, password, jabatan || existingGuru?.jabatan || '', user.sub, ip);
        }
      }
      return result;
    }
    if (isDelete) return remove(env, cfg, parseInt(pathParts[3]), user, ip);
  } catch (e) {
    return badRequest(e instanceof Error ? e.message : 'Invalid request');
  }

  return badRequest('Method tidak didukung');
}

export async function handleGuruMapelAmpu(request: Request, env: Env, user: UserPayload, pathParts: string[]): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

  if (pathParts.length < 5) return badRequest('URL tidak valid');
  const id = parseInt(pathParts[3]);
  if (!id) return badRequest('ID asatidz diperlukan');

  if (request.method === 'GET') {
    const rows = await env.DB.prepare(
      'SELECT mata_pelajaran_id FROM guru_mapel WHERE guru_id = ?'
    ).bind(id).all();
    return success(rows.results.map(r => (r as { mata_pelajaran_id: number }).mata_pelajaran_id));
  }

  if (request.method === 'PUT') {
    const body = await request.json() as { mapel_ids?: number[] };
    const mapelIds = body.mapel_ids;
    if (!Array.isArray(mapelIds)) return badRequest('Field mapel_ids harus array');

    const existing = await env.DB.prepare('SELECT id FROM guru WHERE id = ?').bind(id).first();
    if (!existing) return notFound('Asatidz');

    await env.DB.prepare('DELETE FROM guru_mapel WHERE guru_id = ?').bind(id).run();
    for (const mid of mapelIds) {
      await env.DB.prepare('INSERT OR IGNORE INTO guru_mapel (guru_id, mata_pelajaran_id) VALUES (?, ?)').bind(id, mid).run();
    }

    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'guru_mapel', ?, ?)")
      .bind(user.sub, `Update mapel guru id=${id} (${mapelIds.length} mapel)`, ip).run();
    return success({ guru_id: id, mapel_ids: mapelIds });
  }

  return badRequest('Method tidak didukung');
}

export async function handleGuruKelasAmpu(request: Request, env: Env, user: UserPayload, pathParts: string[]): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

  if (pathParts.length < 5) return badRequest('URL tidak valid');
  const id = parseInt(pathParts[3]);
  if (!id) return badRequest('ID asatidz diperlukan');

  if (request.method === 'GET') {
    const rows = await env.DB.prepare(
      'SELECT kelas_id FROM guru_kelas WHERE guru_id = ?'
    ).bind(id).all();
    return success(rows.results.map(r => (r as { kelas_id: number }).kelas_id));
  }

  if (request.method === 'PUT') {
    const body = await request.json() as { kelas_ids?: number[] };
    const kelasIds = body.kelas_ids;
    if (!Array.isArray(kelasIds)) return badRequest('Field kelas_ids harus array');

    const existing = await env.DB.prepare('SELECT id FROM guru WHERE id = ?').bind(id).first();
    if (!existing) return notFound('Asatidz');

    await env.DB.prepare('DELETE FROM guru_kelas WHERE guru_id = ?').bind(id).run();
    for (const kid of kelasIds) {
      await env.DB.prepare('INSERT OR IGNORE INTO guru_kelas (guru_id, kelas_id) VALUES (?, ?)').bind(id, kid).run();
    }

    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'guru_kelas', ?, ?)")
      .bind(user.sub, `Update kelas guru id=${id} (${kelasIds.length} kelas)`, ip).run();
    return success({ guru_id: id, kelas_ids: kelasIds });
  }

  return badRequest('Method tidak didukung');
}

export async function handleMapelKelas(request: Request, env: Env, user: UserPayload, pathParts: string[]): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

  // /api/admin/mapel-kelas/:id/kelas
  if (pathParts.length < 5) return badRequest('URL tidak valid');
  const id = parseInt(pathParts[3]);
  if (!id) return badRequest('ID mata pelajaran diperlukan');

  if (request.method === 'GET') {
    const rows = await env.DB.prepare(
      'SELECT kelas_id FROM mapel_kelas WHERE mata_pelajaran_id = ?'
    ).bind(id).all();
    return success(rows.results.map(r => (r as { kelas_id: number }).kelas_id));
  }

  if (request.method === 'PUT') {
    const body = await request.json() as { kelas_ids?: number[] };
    const kelasIds = body.kelas_ids;
    if (!Array.isArray(kelasIds)) return badRequest('Field kelas_ids harus array');

    const existing = await env.DB.prepare('SELECT id FROM mata_pelajaran WHERE id = ?').bind(id).first();
    if (!existing) return notFound('Mata Pelajaran');

    await env.DB.prepare('DELETE FROM mapel_kelas WHERE mata_pelajaran_id = ?').bind(id).run();

    for (const kid of kelasIds) {
      await env.DB.prepare(
        'INSERT OR IGNORE INTO mapel_kelas (mata_pelajaran_id, kelas_id) VALUES (?, ?)'
      ).bind(id, kid).run();
    }

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'mapel_kelas', ?, ?)"
    ).bind(user.sub, `Update kelas untuk mata pelajaran id=${id} (${kelasIds.length} kelas)`, ip).run();

    return success({ mata_pelajaran_id: id, kelas_ids: kelasIds });
  }

  return badRequest('Method tidak didukung');
}

export async function handleWaliKelasList(request: Request, env: Env, _user: UserPayload): Promise<Response> {
  if (request.method !== 'GET') return badRequest('Method tidak didukung');

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

export async function handleSiswaTemplate(env: Env): Promise<Response> {
  const wb = XLSX.utils.book_new();

  const wsData = [
    ['NIS', 'NISN', 'Nama Santri', 'Jenis Kelamin', 'Kelas', 'Status'],
    ['', '', '', 'L/P', '', 'Aktif / Tidak Aktif / Pindah'],
  ];
  const ws = XLSX.utils.aoa_to_sheet(wsData);
  ws['!cols'] = [{ wch: 15 }, { wch: 15 }, { wch: 25 }, { wch: 15 }, { wch: 20 }, { wch: 22 }];
  XLSX.utils.book_append_sheet(wb, ws, 'Data Santri');

  const kelas = await env.DB.prepare('SELECT nama FROM kelas ORDER BY nama').all<{ nama: string }>();
  const refRows: (string | undefined)[][] = [
    ['Jenis Kelamin', 'Status', ''],
    ['L', 'Aktif', ''],
    ['P', 'Tidak Aktif', ''],
    ['', 'Pindah', ''],
    ['', '', ''],
    ['Daftar Kelas', '', ''],
  ];
  for (const k of kelas.results) refRows.push([k.nama, '', '']);
  const wsRef = XLSX.utils.aoa_to_sheet(refRows);
  wsRef['!cols'] = [{ wch: 22 }, { wch: 22 }, { wch: 10 }];
  XLSX.utils.book_append_sheet(wb, wsRef, 'Referensi');

  const base64 = XLSX.write(wb, { type: 'base64', bookType: 'xlsx' });
  return success({ base64, filename: 'template_siswa.xlsx' });
}

export async function handleSiswaPreview(request: Request, env: Env): Promise<Response> {
  if (request.method !== 'POST') return badRequest('Method tidak didukung');

  const body = await request.json() as { file_base64: string };
  if (!body.file_base64) return badRequest('Field file_base64 diperlukan');

  let buf: Uint8Array;
  try {
    buf = Uint8Array.from(atob(body.file_base64), c => c.charCodeAt(0));
  } catch {
    return badRequest('file_base64 tidak valid');
  }

  let wb: XLSX.WorkBook;
  try {
    wb = XLSX.read(buf, { type: 'array' });
  } catch {
    return badRequest('File Excel tidak dapat dibaca');
  }

  const sheet = wb.Sheets['Data Santri'];
  if (!sheet) return badRequest('Sheet "Data Santri" tidak ditemukan');

  const rows = XLSX.utils.sheet_to_json<Record<string, string>>(sheet, { defval: '' });
  if (rows.length === 0) return badRequest('Tidak ada data di sheet Data Santri');

  const kelasMap = new Map<string, number>();
  const kelasRows = await env.DB.prepare('SELECT id, nama FROM kelas').all<{ id: number; nama: string }>();
  for (const k of kelasRows.results) kelasMap.set(k.nama.toLowerCase().trim(), k.id);

  const preview: Record<string, unknown>[] = [];
  const seenNis = new Set<string>();

  for (let i = 0; i < rows.length; i++) {
    const r = rows[i];
    const errors: string[] = [];
    const nis = (r['NIS'] ?? '').toString().trim();
    const nisn = (r['NISN'] ?? '').toString().trim();
    const nama = (r['Nama Santri'] ?? '').toString().trim();
    const jk = (r['Jenis Kelamin'] ?? '').toString().trim().toUpperCase();
    const kelasNama = (r['Kelas'] ?? '').toString().trim();
    const status = (r['Status'] ?? '').toString().trim();

    if (!nis) errors.push('NIS harus diisi');
    else if (seenNis.has(nis)) errors.push(`NIS "${nis}" duplikat dalam file`);
    else seenNis.add(nis);

    if (!nama) errors.push('Nama Santri harus diisi');
    if (jk !== 'L' && jk !== 'P') errors.push('Jenis Kelamin harus L atau P');

    const kelasId = kelasNama ? kelasMap.get(kelasNama.toLowerCase()) : null;
    if (kelasNama && kelasId == null) errors.push(`Kelas "${kelasNama}" tidak ditemukan`);

    if (!status) errors.push('Status harus diisi');
    else if (!['Aktif', 'Tidak Aktif', 'Pindah'].includes(status)) errors.push('Status harus Aktif, Tidak Aktif, atau Pindah');

    preview.push({
      row: i + 2,
      nis,
      nisn,
      nama,
      jenis_kelamin: jk,
      kelas_nama: kelasNama,
      kelas_id: kelasId,
      status,
      errors,
      valid: errors.length === 0,
    });
  }

  return success({ rows: preview, total: preview.length, valid_count: preview.filter(r => r.valid).length });
}

export async function handleSiswaBulk(request: Request, env: Env, user: UserPayload): Promise<Response> {
  if (request.method !== 'POST') return badRequest('Method tidak didukung');

  const body = await request.json() as { data: Record<string, unknown>[] };
  if (!Array.isArray(body.data) || body.data.length === 0) return badRequest('Field data harus array dan tidak boleh kosong');

  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const now = new Date().toISOString().replace('T', ' ').split('.')[0];
  const cols = ['nis', 'nisn', 'nama', 'jenis_kelamin', 'kelas_id', 'status', 'created_at', 'updated_at'];
  const placeholders = cols.map(() => '?').join(', ');
  const stmt = `INSERT INTO siswa (${cols.join(', ')}) VALUES (${placeholders})`;

  let inserted = 0;
  const errors: { row: number; nis: string; error: string }[] = [];

  for (let i = 0; i < body.data.length; i++) {
    const row = body.data[i];
    try {
      await env.DB.prepare(stmt).bind(
        row['nis'] ?? '',
        row['nisn'] ?? '',
        row['nama'] ?? '',
        row['jenis_kelamin'] ?? '',
        row['kelas_id'] ?? null,
        row['status'] ?? '',
        now, now
      ).run();
      inserted++;
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Database error';
      errors.push({ row: i + 2, nis: (row['nis'] ?? '').toString(), error: msg });
    }
  }

  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'bulk_create', 'siswa', ?, ?)"
  ).bind(user.sub, `Import ${inserted} siswa dari Excel${errors.length > 0 ? ` (${errors.length} gagal)` : ''}`, ip).run();

  return success({ inserted, errors });
}

// ── Mata Pelajaran Bulk ──

export async function handleMapelTemplate(_request: Request, env: Env): Promise<Response> {
  const wb = XLSX.utils.book_new();

  const wsData = [
    ['Nama', 'Kode'],
    ['', ''],
  ];
  const ws = XLSX.utils.aoa_to_sheet(wsData);
  ws['!cols'] = [{ wch: 30 }, { wch: 20 }];
  XLSX.utils.book_append_sheet(wb, ws, 'Data Mapel');

  const base64 = XLSX.write(wb, { type: 'base64', bookType: 'xlsx' });
  return success({ base64, filename: 'template_mata_pelajaran.xlsx' });
}

export async function handleMapelPreview(request: Request, env: Env): Promise<Response> {
  if (request.method !== 'POST') return badRequest('Method tidak didukung');

  const body = await request.json() as { file_base64: string };
  if (!body.file_base64) return badRequest('Field file_base64 diperlukan');

  let buf: Uint8Array;
  try {
    buf = Uint8Array.from(atob(body.file_base64), c => c.charCodeAt(0));
  } catch {
    return badRequest('file_base64 tidak valid');
  }

  let wb: XLSX.WorkBook;
  try {
    wb = XLSX.read(buf, { type: 'array' });
  } catch {
    return badRequest('File Excel tidak dapat dibaca');
  }

  const sheet = wb.Sheets['Data Mapel'];
  if (!sheet) return badRequest('Sheet "Data Mapel" tidak ditemukan');

  const rows = XLSX.utils.sheet_to_json<Record<string, string>>(sheet, { defval: '' });
  if (rows.length === 0) return badRequest('Tidak ada data di sheet Data Mapel');

  const preview: Record<string, unknown>[] = [];
  const seenNama = new Set<string>();
  const existingMap = new Map<string, number>();
  const existingRows = await env.DB.prepare('SELECT id, nama FROM mata_pelajaran').all<{ id: number; nama: string }>();
  for (const r of existingRows.results) existingMap.set(r.nama.toLowerCase().trim(), r.id);

  for (let i = 0; i < rows.length; i++) {
    const r = rows[i];
    const errors: string[] = [];
    const nama = (r['Nama'] ?? '').toString().trim();
    const kode = (r['Kode'] ?? '').toString().trim();

    if (!nama) errors.push('Nama harus diisi');
    else if (seenNama.has(nama.toLowerCase())) errors.push(`Nama "${nama}" duplikat dalam file`);
    else seenNama.add(nama.toLowerCase());

    if (existingMap.has(nama.toLowerCase())) errors.push(`Nama "${nama}" sudah ada di database`);

    preview.push({
      row: i + 2,
      nama,
      kode,
      errors,
      valid: errors.length === 0,
    });
  }

  return success({ rows: preview, total: preview.length, valid_count: preview.filter(r => r.valid).length });
}

export async function handleMapelBulk(request: Request, env: Env, user: UserPayload): Promise<Response> {
  if (request.method !== 'POST') return badRequest('Method tidak didukung');

  const body = await request.json() as { data: Record<string, unknown>[] };
  if (!Array.isArray(body.data) || body.data.length === 0) return badRequest('Field data harus array dan tidak boleh kosong');

  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const now = new Date().toISOString().replace('T', ' ').split('.')[0];
  const cols = ['nama', 'kode', 'created_at', 'updated_at'];
  const placeholders = cols.map(() => '?').join(', ');
  const stmt = `INSERT INTO mata_pelajaran (${cols.join(', ')}) VALUES (${placeholders})`;

  let inserted = 0;
  const errors: { row: number; nama: string; error: string }[] = [];

  for (let i = 0; i < body.data.length; i++) {
    const row = body.data[i];
    try {
      await env.DB.prepare(stmt).bind(
        row['nama'] ?? '',
        row['kode'] ?? '',
        now, now
      ).run();
      inserted++;
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Database error';
      errors.push({ row: i + 2, nama: (row['nama'] ?? '').toString(), error: msg });
    }
  }

  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'bulk_create', 'mata_pelajaran', ?, ?)"
  ).bind(user.sub, `Import ${inserted} mata pelajaran dari Excel${errors.length > 0 ? ` (${errors.length} gagal)` : ''}`, ip).run();

  return success({ inserted, errors });
}

// ── Guru Bulk ──

export async function handleGuruTemplate(_request: Request, env: Env): Promise<Response> {
  const wb = XLSX.utils.book_new();

  const wsData = [
    ['NIP', 'Nama', 'Jenis Kelamin', 'Jabatan', 'Status Aktif', 'Username', 'Password'],
    ['', '', 'L/P', 'guru_mapel / wali_kelas / ...', 'Aktif / Tidak Aktif', '', ''],
  ];
  const ws = XLSX.utils.aoa_to_sheet(wsData);
  ws['!cols'] = [{ wch: 20 }, { wch: 25 }, { wch: 18 }, { wch: 30 }, { wch: 20 }, { wch: 20 }, { wch: 20 }];
  XLSX.utils.book_append_sheet(wb, ws, 'Data Asatidz');

  const refRows: (string | undefined)[][] = [
    ['Jenis Kelamin', 'Jabatan', 'Status Aktif', ''],
    ['L', 'guru_mapel', 'Aktif', ''],
    ['P', 'wali_kelas', 'Tidak Aktif', ''],
    ['', 'kepala_sekolah', '', ''],
    ['', 'wakil_kurikulum', '', ''],
    ['', 'guru_bk', '', ''],
  ];
  const wsRef = XLSX.utils.aoa_to_sheet(refRows);
  wsRef['!cols'] = [{ wch: 22 }, { wch: 22 }, { wch: 22 }, { wch: 10 }];
  XLSX.utils.book_append_sheet(wb, wsRef, 'Referensi');

  const base64 = XLSX.write(wb, { type: 'base64', bookType: 'xlsx' });
  return success({ base64, filename: 'template_guru.xlsx' });
}

export async function handleGuruPreview(request: Request, env: Env): Promise<Response> {
  if (request.method !== 'POST') return badRequest('Method tidak didukung');

  const body = await request.json() as { file_base64: string };
  if (!body.file_base64) return badRequest('Field file_base64 diperlukan');

  let buf: Uint8Array;
  try {
    buf = Uint8Array.from(atob(body.file_base64), c => c.charCodeAt(0));
  } catch {
    return badRequest('file_base64 tidak valid');
  }

  let wb: XLSX.WorkBook;
  try {
    wb = XLSX.read(buf, { type: 'array' });
  } catch {
    return badRequest('File Excel tidak dapat dibaca');
  }

  const sheet = wb.Sheets['Data Asatidz'];
  if (!sheet) return badRequest('Sheet "Data Asatidz" tidak ditemukan');

  const rows = XLSX.utils.sheet_to_json<Record<string, string>>(sheet, { defval: '' });
  if (rows.length === 0) return badRequest('Tidak ada data di sheet Data Asatidz');

  const validJabatan = new Set(['guru_mapel', 'wali_kelas', 'kepala_sekolah', 'wakil_kurikulum', 'guru_bk']);
  const preview: Record<string, unknown>[] = [];
  const seenNip = new Set<string>();

  for (let i = 0; i < rows.length; i++) {
    const r = rows[i];
    const errors: string[] = [];
    const nip = (r['NIP'] ?? '').toString().trim();
    const nama = (r['Nama'] ?? '').toString().trim();
    const jk = (r['Jenis Kelamin'] ?? '').toString().trim().toUpperCase();
    const jabatan = (r['Jabatan'] ?? '').toString().trim();
    const status = (r['Status Aktif'] ?? '').toString().trim();
    const username = (r['Username'] ?? '').toString().trim();
    const password = (r['Password'] ?? '').toString().trim();

    if (!nip) errors.push('NIP harus diisi');
    else if (seenNip.has(nip)) errors.push(`NIP "${nip}" duplikat dalam file`);
    else seenNip.add(nip);

    if (!nama) errors.push('Nama harus diisi');
    if (jk !== 'L' && jk !== 'P') errors.push('Jenis Kelamin harus L atau P');
    if (jabatan && !validJabatan.has(jabatan)) errors.push(`Jabatan "${jabatan}" tidak dikenal`);
    if (status && !['Aktif', 'Tidak Aktif'].includes(status)) errors.push('Status Aktif harus Aktif atau Tidak Aktif');
    if (!username) errors.push('Username harus diisi');
    if (!password) errors.push('Password harus diisi');

    preview.push({
      row: i + 2,
      nip,
      nama,
      jenis_kelamin: jk,
      jabatan,
      status_aktif: status === 'Aktif' ? 1 : 0,
      username,
      password,
      errors,
      valid: errors.length === 0,
    });
  }

  return success({ rows: preview, total: preview.length, valid_count: preview.filter(r => r.valid).length });
}

export async function handleGuruBulk(request: Request, env: Env, user: UserPayload): Promise<Response> {
  if (request.method !== 'POST') return badRequest('Method tidak didukung');

  const body = await request.json() as { data: Record<string, unknown>[] };
  if (!Array.isArray(body.data) || body.data.length === 0) return badRequest('Field data harus array dan tidak boleh kosong');

  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const now = new Date().toISOString().replace('T', ' ').split('.')[0];
  const cols = ['nip', 'nama', 'jenis_kelamin', 'jabatan', 'status_aktif', 'created_at', 'updated_at'];
  const placeholders = cols.map(() => '?').join(', ');
  const stmt = `INSERT INTO guru (${cols.join(', ')}) VALUES (${placeholders})`;

  let inserted = 0;
  const errors: { row: number; nip: string; error: string }[] = [];

  for (let i = 0; i < body.data.length; i++) {
    const row = body.data[i];
    try {
      const result = await env.DB.prepare(stmt).bind(
        row['nip'] ?? '',
        row['nama'] ?? '',
        row['jenis_kelamin'] ?? '',
        row['jabatan'] ?? '',
        row['status_aktif'] ?? 1,
        now, now
      ).run();

      if (result.meta?.last_row_id && row['username'] && row['password']) {
        await upsertUserForGuru(
          env, result.meta.last_row_id,
          row['username'] as string,
          row['password'] as string,
          (row['jabatan'] as string) || '',
          user.sub, ip
        );
      }

      inserted++;
    } catch (e) {
      const msg = e instanceof Error ? e.message : 'Database error';
      errors.push({ row: i + 2, nip: (row['nip'] ?? '').toString(), error: msg });
    }
  }

  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'bulk_create', 'guru', ?, ?)"
  ).bind(user.sub, `Import ${inserted} guru dari Excel${errors.length > 0 ? ` (${errors.length} gagal)` : ''}`, ip).run();

  return success({ inserted, errors });
}

export async function handleGuruBKList(request: Request, env: Env, _user: UserPayload): Promise<Response> {
  if (request.method !== 'GET') return badRequest('Method tidak didukung');

  const rows = await env.DB.prepare(`
    SELECT g.id, g.nip, g.nama, g.jabatan
    FROM guru g
    WHERE g.jabatan LIKE '%guru_bk%'
    ORDER BY g.nama
  `).all();

  return success(rows.results);
}
