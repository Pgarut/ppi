import { Env, UserPayload } from '../../types';
import { success, created, notFound, badRequest } from '../../utils/response';

export async function handleAbsensiGuru(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPath = pathParts.slice(2).join('/');

  // GET riwayat absensi
  if ((subPath === '' || subPath === 'absensi') && request.method === 'GET') {
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
  if ((subPath === '' || subPath === 'absensi') && request.method === 'POST') {
    const body = await request.json() as {
      kelas_id: number; mata_pelajaran_id?: number; tanggal: string;
      entries: Array<{ siswa_id: number; status: string; keterangan?: string }>;
    };

    if (!body.kelas_id || !body.tanggal || !body.entries?.length) {
      return badRequest('kelas_id, tanggal, dan entries wajib diisi');
    }

    const validStatus = ['hadir', 'izin', 'sakit', 'alpa'];
    let inserted = 0;

    for (const e of body.entries) {
      if (!e.siswa_id || !validStatus.includes(e.status)) continue;

      // Upsert: insert or update if exists
      const existing = await env.DB.prepare(
        'SELECT id FROM absensi_siswa WHERE siswa_id = ? AND tanggal = ? AND mata_pelajaran_id IS ?'
      ).bind(e.siswa_id, body.tanggal, body.mata_pelajaran_id || null).first();

      if (existing) {
        await env.DB.prepare(
          'UPDATE absensi_siswa SET status = ?, keterangan = ?, diinput_oleh = ? WHERE id = ?'
        ).bind(e.status, e.keterangan || null, user.guru_id, existing.id).run();
      } else {
        await env.DB.prepare(
          'INSERT INTO absensi_siswa (siswa_id, kelas_id, mata_pelajaran_id, tanggal, status, keterangan, diinput_oleh) VALUES (?, ?, ?, ?, ?, ?, ?)'
        ).bind(e.siswa_id, body.kelas_id, body.mata_pelajaran_id || null, body.tanggal, e.status, e.keterangan || null, user.guru_id).run();
      }
      inserted++;
    }

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'absensi_siswa', ?, ?)"
    ).bind(user.sub, `Input absensi kelas ${body.kelas_id} tgl ${body.tanggal} (${inserted} siswa)`, ip).run();

    return success({ message: `${inserted} data absensi tersimpan`, inserted });
  }

  // GET data siswa per kelas untuk form absensi
  if (subPath === 'siswa-per-kelas' && request.method === 'GET') {
    const kelasId = url.searchParams.get('kelas_id');
    const tanggal = url.searchParams.get('tanggal');
    const mapelId = url.searchParams.get('mata_pelajaran_id');

    if (!kelasId) return badRequest('kelas_id diperlukan');

    const siswa = await env.DB.prepare(
      "SELECT id, nis, nama FROM siswa WHERE kelas_id = ? AND status = 'aktif' ORDER BY nama"
    ).bind(parseInt(kelasId)).all();

    // Ambil absensi yang sudah ada (untuk edit)
    let existingAbsensi: Record<number, { status: string; keterangan?: string }> = {};
    if (tanggal) {
      const query = mapelId
        ? env.DB.prepare('SELECT siswa_id, status, keterangan FROM absensi_siswa WHERE kelas_id = ? AND tanggal = ? AND mata_pelajaran_id = ?')
            .bind(parseInt(kelasId), tanggal, parseInt(mapelId))
        : env.DB.prepare('SELECT siswa_id, status, keterangan FROM absensi_siswa WHERE kelas_id = ? AND tanggal = ? AND mata_pelajaran_id IS NULL')
            .bind(parseInt(kelasId), tanggal);

      const existing = await query.all<{ siswa_id: number; status: string; keterangan?: string }>();
      for (const e of existing.results) {
        existingAbsensi[e.siswa_id] = { status: e.status, keterangan: e.keterangan };
      }
    }

    return success({ siswa: siswa.results, existing: existingAbsensi });
  }

  return badRequest('Endpoint tidak dikenal');
}
