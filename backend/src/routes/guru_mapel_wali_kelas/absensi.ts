import { Env, UserPayload } from '../../types';
import { success, badRequest } from '../../utils/response';

export async function handleAbsensiGuru(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPath = pathParts.slice(2).join('/');

  if (!user.guru_id) return badRequest('Guru ID tidak ditemukan');

  // GET assignment mapel + kelas (dari admin)
  if (subPath === 'absensi/assignments' && request.method === 'GET') {
    let assignments = await env.DB.prepare(`
      SELECT DISTINCT src.mata_pelajaran_id, mp.nama as mapel_nama, mp.kode as mapel_kode,
             src.kelas_id, k.nama as kelas_nama
      FROM (
        SELECT mata_pelajaran_id, kelas_id FROM guru_mapel_kelas WHERE guru_id = ?
        UNION
        SELECT mata_pelajaran_id, kelas_id FROM guru_mata_pelajaran
        WHERE guru_id = ? AND mata_pelajaran_id IS NOT NULL AND kelas_id IS NOT NULL
      ) src
      JOIN mata_pelajaran mp ON src.mata_pelajaran_id = mp.id
      JOIN kelas k ON src.kelas_id = k.id
      ORDER BY mp.nama, k.nama
    `).bind(user.guru_id, user.guru_id).all();

    const mapelMap = new Map<number, { id: number; nama: string; kode?: string; kelas: Array<{ id: number; nama: string }> }>();
    for (const row of assignments.results as any[]) {
      if (!mapelMap.has(row.mata_pelajaran_id)) {
        mapelMap.set(row.mata_pelajaran_id, {
          id: row.mata_pelajaran_id,
          nama: row.mapel_nama,
          kode: row.mapel_kode,
          kelas: [],
        });
      }
      mapelMap.get(row.mata_pelajaran_id)!.kelas.push({
        id: row.kelas_id,
        nama: row.kelas_nama,
      });
    }

    return success(Array.from(mapelMap.values()));
  }

  // GET riwayat sesi absensi (group by tanggal + jam + kelas + mapel)
  if (subPath === 'absensi/riwayat-sesi' && request.method === 'GET') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '20'));
    const offset = (page - 1) * perPage;

    const total = (await env.DB.prepare(`
      SELECT COUNT(*) as total FROM (
        SELECT DISTINCT tanggal, jam, kelas_id, mata_pelajaran_id
        FROM absensi_siswa WHERE diinput_oleh = ?
      )
    `).bind(user.guru_id).first<{ total: number }>())?.total || 0;

    const rows = await env.DB.prepare(`
      SELECT a.tanggal, a.jam, a.kelas_id, k.nama as kelas_nama,
             a.mata_pelajaran_id, mp.nama as mapel_nama,
             COUNT(*) as total_siswa,
             SUM(CASE WHEN a.status = 'hadir' THEN 1 ELSE 0 END) as hadir,
             SUM(CASE WHEN a.status = 'izin' THEN 1 ELSE 0 END) as izin,
             SUM(CASE WHEN a.status = 'sakit' THEN 1 ELSE 0 END) as sakit,
             SUM(CASE WHEN a.status = 'alpa' THEN 1 ELSE 0 END) as alpa
      FROM absensi_siswa a
      LEFT JOIN kelas k ON a.kelas_id = k.id
      LEFT JOIN mata_pelajaran mp ON a.mata_pelajaran_id = mp.id
      WHERE a.diinput_oleh = ?
      GROUP BY a.tanggal, a.jam, a.kelas_id, a.mata_pelajaran_id
      ORDER BY a.tanggal DESC, a.jam DESC
      LIMIT ? OFFSET ?
    `).bind(user.guru_id, perPage, offset).all();

    const items = (rows.results as any[]).map(r => {
      const dayNames = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
      const d = new Date(r.tanggal + 'T00:00:00');
      return {
        ...r,
        hari: dayNames[d.getDay()] || '',
        tanggal_label: r.tanggal,
      };
    });

    return success({
      items,
      pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
    });
  }

  // GET detail sesi absensi (per siswa)
  if (subPath === 'absensi/riwayat-sesi/detail' && request.method === 'GET') {
    const tanggal = url.searchParams.get('tanggal');
    const jam = url.searchParams.get('jam');
    const kelasId = url.searchParams.get('kelas_id');
    const mapelId = url.searchParams.get('mata_pelajaran_id');

    if (!tanggal || !kelasId) return badRequest('tanggal dan kelas_id diperlukan');

    const rows = await env.DB.prepare(`
      SELECT a.siswa_id, s.nis, s.nama as siswa_nama, a.status, a.keterangan, a.jam
      FROM absensi_siswa a
      JOIN siswa s ON a.siswa_id = s.id
      WHERE a.tanggal = ? AND a.kelas_id = ? AND a.mata_pelajaran_id IS ? AND a.jam IS ? AND a.diinput_oleh = ?
             ORDER BY s.nis ASC
    `).bind(tanggal, parseInt(kelasId), mapelId ? parseInt(mapelId) : null, jam || null, user.guru_id).all();

    return success({ items: rows.results });
  }

  // GET riwayat absensi (flat list per siswa)
  if (subPath === 'absensi' && request.method === 'GET') {
    const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
    const perPage = Math.min(100, parseInt(url.searchParams.get('per_page') || '50'));
    const offset = (page - 1) * perPage;

    const total = (await env.DB.prepare(
      'SELECT COUNT(*) as total FROM absensi_siswa WHERE diinput_oleh = ?'
    ).bind(user.guru_id).first<{ total: number }>())?.total || 0;

    const rows = await env.DB.prepare(
      `SELECT a.*, s.nama as siswa_nama, k.nama as kelas_nama, mp.nama as mapel_nama
       FROM absensi_siswa a
       LEFT JOIN siswa s ON a.siswa_id = s.id
       LEFT JOIN kelas k ON a.kelas_id = k.id
       LEFT JOIN mata_pelajaran mp ON a.mata_pelajaran_id = mp.id
       WHERE a.diinput_oleh = ?
       ORDER BY a.tanggal DESC LIMIT ? OFFSET ?`
    ).bind(user.guru_id, perPage, offset).all();

    return success({ items: rows.results, pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) } });
  }

  // POST input absensi massal
  if (subPath === 'absensi' && request.method === 'POST') {
    const body = await request.json() as {
      kelas_id: number; mata_pelajaran_id?: number; tanggal: string; jam?: string;
      entries: Array<{ siswa_id: number; status: string; keterangan?: string }>;
    };

    if (!body.kelas_id || !body.tanggal || !body.entries?.length) {
      return badRequest('kelas_id, tanggal, dan entries wajib diisi');
    }

    const validStatus = ['hadir', 'izin', 'sakit', 'alpa'];
    let inserted = 0;

    for (const e of body.entries) {
      if (!e.siswa_id || !validStatus.includes(e.status)) continue;

      const existing = await env.DB.prepare(
        'SELECT id FROM absensi_siswa WHERE siswa_id = ? AND tanggal = ? AND mata_pelajaran_id IS ? AND jam IS ?'
      ).bind(e.siswa_id, body.tanggal, body.mata_pelajaran_id || null, body.jam || null).first();

      if (existing) {
        await env.DB.prepare(
          'UPDATE absensi_siswa SET status = ?, keterangan = ?, diinput_oleh = ? WHERE id = ?'
        ).bind(e.status, e.keterangan || null, user.guru_id, existing.id).run();
      } else {
        await env.DB.prepare(
          'INSERT INTO absensi_siswa (siswa_id, kelas_id, mata_pelajaran_id, tanggal, jam, status, keterangan, diinput_oleh) VALUES (?, ?, ?, ?, ?, ?, ?, ?)'
        ).bind(e.siswa_id, body.kelas_id, body.mata_pelajaran_id || null, body.tanggal, body.jam || null, e.status, e.keterangan || null, user.guru_id).run();
      }
      inserted++;
    }

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'absensi_siswa', ?, ?)"
    ).bind(user.sub, `Input absensi kelas ${body.kelas_id} tgl ${body.tanggal} jam ${body.jam || '-'} (${inserted} siswa)`, ip).run();

    return success({ message: `${inserted} data absensi tersimpan`, inserted });
  }

  // GET data siswa per kelas untuk form absensi
  if (subPath === 'absensi/siswa-per-kelas' && request.method === 'GET') {
    const kelasId = url.searchParams.get('kelas_id');
    const tanggal = url.searchParams.get('tanggal');
    const mapelId = url.searchParams.get('mata_pelajaran_id');
    const jam = url.searchParams.get('jam');

    if (!kelasId) return badRequest('kelas_id diperlukan');

    const siswa = await env.DB.prepare(
      "SELECT id, nis, nama FROM siswa WHERE kelas_id = ? AND status = 'aktif' ORDER BY nis ASC"
    ).bind(parseInt(kelasId)).all();

    let existingAbsensi: Record<number, { status: string; keterangan?: string }> = {};
    if (tanggal) {
      const query = mapelId
        ? env.DB.prepare('SELECT siswa_id, status, keterangan FROM absensi_siswa WHERE kelas_id = ? AND tanggal = ? AND mata_pelajaran_id = ? AND jam IS ?')
            .bind(parseInt(kelasId), tanggal, parseInt(mapelId), jam || null)
        : env.DB.prepare('SELECT siswa_id, status, keterangan FROM absensi_siswa WHERE kelas_id = ? AND tanggal = ? AND mata_pelajaran_id IS NULL AND jam IS ?')
            .bind(parseInt(kelasId), tanggal, jam || null);

      const existing = await query.all<{ siswa_id: number; status: string; keterangan?: string }>();
      for (const e of existing.results) {
        existingAbsensi[e.siswa_id] = { status: e.status, keterangan: e.keterangan };
      }
    }

    return success({ siswa: siswa.results, existing: existingAbsensi });
  }

  return badRequest('Endpoint tidak dikenal');
}