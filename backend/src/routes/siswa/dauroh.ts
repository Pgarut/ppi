import { Env, UserPayload } from '../../types';
import { success, error } from '../../utils/response';

type Row = Record<string, unknown>;

export async function handleSiswaDauroh(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL
): Promise<Response> {
  const sub = pathParts[3] ?? '';

  if (sub === 'program' && request.method === 'GET') {
    return handleDaurohProgram(env, user);
  }

  if (sub === 'nilai' && request.method === 'GET') {
    return handleDaurohNilai(env, user, url);
  }

  if (sub === 'absensi' && request.method === 'GET') {
    return handleDaurohAbsensi(env, user, url);
  }

  return error('Endpoint tidak ditemukan', 404);
}

// ─── PROGRAM YANG DIIKUTI SISWA ─────────────────────────────
async function handleDaurohProgram(env: Env, user: UserPayload): Promise<Response> {
  const siswaId = user.siswa_id;
  if (!siswaId) return success([]);

  const rows = await env.DB.prepare(`
    SELECT
      dp.id,
      dp.nama_program,
      dp.jenis_program,
      dp.jenis_dauroh,
      dp.keterangan,
      djk.hari,
      djk.jam_mulai,
      djk.jam_selesai,
      dm.nama AS musyrifah_nama
    FROM dauroh_program_santri dps
    JOIN dauroh_program dp ON dps.program_id = dp.id
    LEFT JOIN dauroh_jadwal dj ON dj.program_id = dp.id AND dj.is_aktif = 1
    LEFT JOIN dauroh_jadwal_kelas djk ON djk.jadwal_id = dj.id
    LEFT JOIN dauroh_musyrifah dm ON dj.musyrifah_1_id = dm.id
    WHERE dps.santri_id = ? AND dp.is_aktif = 1
    ORDER BY dp.nama_program
  `).bind(siswaId).all();

  return success(rows.results);
}

// ─── NILAI DAUROH SISWA ─────────────────────────────────────
async function handleDaurohNilai(env: Env, user: UserPayload, url: URL): Promise<Response> {
  const siswaId = user.siswa_id;
  if (!siswaId) return success([]);

  const programId = url.searchParams.get('program_id');
  const limit = Math.min(100, parseInt(url.searchParams.get('limit') || '50'));

  let where = 'WHERE dn.santri_id = ?';
  const bindings: unknown[] = [siswaId];

  if (programId) {
    where += ' AND dn.program_id = ?';
    bindings.push(programId);
  }

  const rows = await env.DB.prepare(`
    SELECT
      dn.id,
      dn.program_id,
      dp.nama_program,
      dp.jenis_program,
      dn.surat_nomor,
      ds.nama as surat_nama,
      ds.jumlah_ayat,
      dn.dari_ayat,
      dn.sampai_ayat,
      dn.status_hafalan,
      dn.nilai_bidang1,
      dn.nilai_bidang2,
      dn.nilai_bidang3,
      dn.total_nilai,
      dn.catatan_umum,
      dn.rencana_tindak_lanjut,
      dm.nama as musyrifah_nama,
      dn.created_at,
      dn.updated_at
    FROM dauroh_nilai dn
    JOIN dauroh_program dp ON dn.program_id = dp.id
    LEFT JOIN dauroh_surat ds ON dn.surat_nomor = ds.nomor
    LEFT JOIN dauroh_musyrifah dm ON dn.diinput_oleh = dm.id
    ${where}
    ORDER BY dn.created_at DESC
    LIMIT ?
  `).bind(...bindings, limit).all();

  return success(rows.results);
}

// ─── ABSENSI DAUROH SISWA ───────────────────────────────────
async function handleDaurohAbsensi(env: Env, user: UserPayload, url: URL): Promise<Response> {
  const siswaId = user.siswa_id;
  if (!siswaId) return success([]);

  const bulan = url.searchParams.get('bulan');
  const tahun = url.searchParams.get('tahun');

  let query = `
    SELECT
      das.tanggal,
      das.status,
      das.keterangan,
      dj.hari,
      dj.jam_mulai,
      dj.jam_selesai,
      dp.nama_program
    FROM dauroh_absensi_santri das
    JOIN dauroh_jadwal dj ON das.jadwal_id = dj.id
    JOIN dauroh_program dp ON dj.program_id = dp.id
    WHERE das.santri_id = ?
  `;
  const params: unknown[] = [siswaId];

  if (bulan && bulan.length > 0) {
    const bulanPadded = bulan.padStart(2, '0');
    query += ` AND strftime('%m', das.tanggal) = ?`;
    params.push(bulanPadded);
  }
  if (tahun && tahun.length > 0) {
    query += ` AND strftime('%Y', das.tanggal) = ?`;
    params.push(tahun);
  }

  query += ` ORDER BY das.tanggal DESC, dj.jam_mulai DESC`;

  const stmt = await env.DB.prepare(query).bind(...params);
  const rows = await stmt.all();

  return success(rows.results);
}