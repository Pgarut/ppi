import { Env } from '../../types';
import { success, badRequest } from '../../utils/response';

export async function handleAbsensiWK(request: Request, env: Env, url: URL): Promise<Response> {
  const subPath = url.pathname.replace('/api/wakil-kurikulum/absensi', '');

  // GET /api/wakil-kurikulum/absensi/guru — monitoring absensi guru
  if ((subPath === '' || subPath === '/guru') && request.method === 'GET') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(100, Math.max(1, parseInt(url.searchParams.get('per_page') || '20')));
    const offset = (page - 1) * perPage;
    const tanggal = url.searchParams.get('tanggal') || '';
    const status = url.searchParams.get('status') || '';

    let where = 'WHERE 1=1';
    const bindings: unknown[] = [];
    if (tanggal) { where += ' AND a.tanggal = ?'; bindings.push(tanggal); }
    if (status) { where += ' AND a.status = ?'; bindings.push(status); }

    const total = (await env.DB.prepare(
      `SELECT COUNT(*) as total FROM absensi_guru a ${where}`
    ).bind(...bindings).first<{ total: number }>())?.total || 0;

    bindings.push(perPage, offset);
    const rows = await env.DB.prepare(
      `SELECT a.*, g.nama as guru_nama, g.nip as guru_nip
       FROM absensi_guru a LEFT JOIN guru g ON a.guru_id = g.id
       ${where} ORDER BY a.tanggal DESC, g.nama LIMIT ? OFFSET ?`
    ).bind(...bindings).all();

    return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
  }

  // GET /api/wakil-kurikulum/absensi/siswa — monitoring absensi siswa
  if (subPath === '/siswa' && request.method === 'GET') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
    const offset = (page - 1) * perPage;
    const kelasId = url.searchParams.get('kelas_id') || '';
    const tanggal = url.searchParams.get('tanggal') || '';
    const statusFilter = url.searchParams.get('status') || '';

    let where = 'WHERE 1=1';
    const bindings: unknown[] = [];
    if (kelasId) { where += ' AND a.kelas_id = ?'; bindings.push(parseInt(kelasId)); }
    if (tanggal) { where += ' AND a.tanggal = ?'; bindings.push(tanggal); }
    if (statusFilter) { where += ' AND a.status = ?'; bindings.push(statusFilter); }

    const total = (await env.DB.prepare(
      `SELECT COUNT(*) as total FROM absensi_siswa a ${where}`
    ).bind(...bindings).first<{ total: number }>())?.total || 0;

    bindings.push(perPage, offset);
    const rows = await env.DB.prepare(
      `SELECT a.*, s.nama as siswa_nama, s.nis as siswa_nis, k.nama as kelas_nama, mp.nama as mapel_nama
       FROM absensi_siswa a
       LEFT JOIN siswa s ON a.siswa_id = s.id
       LEFT JOIN kelas k ON a.kelas_id = k.id
       LEFT JOIN mata_pelajaran mp ON a.mata_pelajaran_id = mp.id
       ${where} ORDER BY a.tanggal DESC, k.nama, s.nama LIMIT ? OFFSET ?`
    ).bind(...bindings).all();

    return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
  }

  // GET /api/wakil-kurikulum/absensi/rekap — rekap absensi
  if (subPath === '/rekap' && request.method === 'GET') {
    const tanggalMulai = url.searchParams.get('tanggal_mulai') || '';
    const tanggalSelesai = url.searchParams.get('tanggal_selesai') || '';
    const kelasId = url.searchParams.get('kelas_id') || '';

    let whereSiswa = 'WHERE 1=1';
    const bindings: unknown[] = [];
    if (kelasId) { whereSiswa += ' AND a.kelas_id = ?'; bindings.push(parseInt(kelasId)); }
    if (tanggalMulai) { whereSiswa += ' AND a.tanggal >= ?'; bindings.push(tanggalMulai); }
    if (tanggalSelesai) { whereSiswa += ' AND a.tanggal <= ?'; bindings.push(tanggalSelesai); }

    const rekapSiswa = await env.DB.prepare(
      `SELECT a.status, COUNT(*) as count FROM absensi_siswa a ${whereSiswa} GROUP BY a.status`
    ).bind(...bindings).all<{ status: string; count: number }>();

    let whereGuru = 'WHERE 1=1';
    const guruBindings: unknown[] = [];
    if (tanggalMulai) { whereGuru += ' AND a.tanggal >= ?'; guruBindings.push(tanggalMulai); }
    if (tanggalSelesai) { whereGuru += ' AND a.tanggal <= ?'; guruBindings.push(tanggalSelesai); }

    const rekapGuru = await env.DB.prepare(
      `SELECT a.status, COUNT(*) as count FROM absensi_guru a ${whereGuru} GROUP BY a.status`
    ).bind(...guruBindings).all<{ status: string; count: number }>();

    const rekapSiswaMap: Record<string, number> = {};
    for (const r of rekapSiswa.results) rekapSiswaMap[r.status] = r.count;

    const rekapGuruMap: Record<string, number> = {};
    for (const r of rekapGuru.results) rekapGuruMap[r.status] = r.count;

    return success({
      siswa: rekapSiswaMap,
      guru: rekapGuruMap,
      total_siswa: rekapSiswa.results.reduce((sum, r) => sum + r.count, 0),
      total_guru: rekapGuru.results.reduce((sum, r) => sum + r.count, 0),
    });
  }

  return badRequest('Endpoint tidak dikenal');
}
