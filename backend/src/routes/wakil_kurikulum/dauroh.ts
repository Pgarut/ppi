import { Env, UserPayload } from '../../types';
import { success, badRequest } from '../../utils/response';

export async function handleDaurohWK(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL
): Promise<Response> {
  if (request.method !== 'GET') return badRequest('Method tidak diizinkan');

  const sub = pathParts.slice(3).join('/');

  if (sub === 'nilai') {
    return handleMonitoringNilai(env, url);
  }

  if (sub === 'filters') {
    return handleFilters(env);
  }

  return badRequest('Endpoint tidak dikenal');
}

async function handleFilters(env: Env): Promise<Response> {
  const [jenjang, kelas, program] = await Promise.all([
    env.DB.prepare('SELECT id, nama FROM tingkat ORDER BY nama').all(),
    env.DB.prepare(`SELECT k.id, k.nama, t.nama as jenjang FROM kelas k LEFT JOIN tingkat t ON k.tingkat_id = t.id ORDER BY k.nama`).all(),
    env.DB.prepare('SELECT id, nama_program, jenis_dauroh FROM dauroh_program WHERE is_aktif = 1 ORDER BY nama_program').all(),
  ]);

  return success({
    jenjang: jenjang.results,
    kelas: kelas.results,
    program: program.results,
  });
}

async function handleMonitoringNilai(env: Env, url: URL): Promise<Response> {
  const page = parseInt(url.searchParams.get('page') || '1');
  const perPage = parseInt(url.searchParams.get('per_page') || '50');
  const jenjang = url.searchParams.get('jenjang');
  const kelasId = url.searchParams.get('kelas_id');
  const programId = url.searchParams.get('program_id');
  const search = url.searchParams.get('search');
  const offset = (page - 1) * perPage;

  let whereClause = 'WHERE 1=1';
  const params: unknown[] = [];

  if (jenjang) {
    whereClause += ' AND t.nama = ?';
    params.push(jenjang);
  }
  if (kelasId) {
    whereClause += ' AND s.kelas_id = ?';
    params.push(parseInt(kelasId));
  }
  if (programId) {
    whereClause += ' AND dn.program_id = ?';
    params.push(parseInt(programId));
  }
  if (search) {
    whereClause += ' AND (s.nama LIKE ? OR s.nis LIKE ?)';
    params.push(`%${search}%`, `%${search}%`);
  }

  const countResult = await env.DB.prepare(
    `SELECT COUNT(*) as total FROM dauroh_nilai dn
     JOIN siswa s ON dn.santri_id = s.id
     JOIN kelas k ON s.kelas_id = k.id
     LEFT JOIN tingkat t ON k.tingkat_id = t.id
     JOIN dauroh_program dp ON dn.program_id = dp.id
     ${whereClause}`
  ).bind(...params).first<{ total: number }>();

  const total = countResult?.total || 0;
  const totalPages = Math.ceil(total / perPage);

  const rows = await env.DB.prepare(
    `SELECT
       s.id as santri_id, s.nama as nama_santri, s.nis,
       k.nama as kelas_nama, t.nama as jenjang_nama,
       dp.nama_program, dp.jenis_dauroh,
       dn.nilai_hafalan, dn.nilai_bacaan, dn.catatan,
       dn.updated_at
     FROM dauroh_nilai dn
     JOIN siswa s ON dn.santri_id = s.id
     JOIN kelas k ON s.kelas_id = k.id
     LEFT JOIN tingkat t ON k.tingkat_id = t.id
     JOIN dauroh_program dp ON dn.program_id = dp.id
     ${whereClause}
     ORDER BY k.nama, s.nama
     LIMIT ? OFFSET ?`
  ).bind(...params, perPage, offset).all();

  const statsResult = await env.DB.prepare(
    `SELECT
       COUNT(*) as total_santri,
       ROUND(AVG(dn.nilai_hafalan), 1) as rata_hafalan,
       ROUND(AVG(dn.nilai_bacaan), 1) as rata_bacaan,
       COUNT(CASE WHEN dn.nilai_hafalan IS NOT NULL OR dn.nilai_bacaan IS NOT NULL THEN 1 END) as sudah_dinilai,
       COUNT(CASE WHEN dn.nilai_hafalan IS NULL AND dn.nilai_bacaan IS NULL THEN 1 END) as belum_dinilai
     FROM dauroh_nilai dn
     JOIN siswa s ON dn.santri_id = s.id
     JOIN kelas k ON s.kelas_id = k.id
     LEFT JOIN tingkat t ON k.tingkat_id = t.id
     JOIN dauroh_program dp ON dn.program_id = dp.id
     ${whereClause}`
  ).bind(...params).first();

  return success({
    items: rows.results,
    summary: statsResult || { total_santri: 0, rata_hafalan: 0, rata_bacaan: 0, sudah_dinilai: 0, belum_dinilai: 0 },
    pagination: { page, per_page: perPage, total, total_pages: totalPages },
  });
}