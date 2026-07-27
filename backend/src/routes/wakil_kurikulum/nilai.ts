import { Env, UserPayload } from '../../types';
import { success, created, notFound, badRequest } from '../../utils/response';

export async function handleNilaiWK(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPath = pathParts.slice(2).join('/');

  // Bobot nilai
  if (subPath.startsWith('bobot-nilai')) {
    if (request.method === 'GET') {
      const id = subPath.split('/').length > 1 ? parseInt(subPath.split('/')[1]) : null;
      if (id) {
        const row = await env.DB.prepare('SELECT * FROM bobot_nilai WHERE id = ?').bind(id).first();
        if (!row) return notFound('Bobot nilai');
        return success(row);
      }
      const rows = await env.DB.prepare(
        `SELECT bn.*, mp.nama as mapel_nama FROM bobot_nilai bn
         LEFT JOIN mata_pelajaran mp ON bn.mata_pelajaran_id = mp.id
         ORDER BY bn.tahun_ajaran_id DESC`
      ).all();
      return success(rows.results);
    }

    if (request.method === 'POST') {
      const body = await request.json() as Record<string, unknown>;
      const { mata_pelajaran_id, tahun_ajaran_id, harian_persen, tugas_persen, uts_persen, uas_persen } = body;

      if (!tahun_ajaran_id) return badRequest('tahun_ajaran_id wajib diisi');

      const hp = Number(harian_persen ?? 20), tp = Number(tugas_persen ?? 20), up = Number(uts_persen ?? 30), uap = Number(uas_persen ?? 30);
      const total = hp + tp + up + uap;
      if (total != 100) return badRequest('Total persentase harus 100%');

      const result = await env.DB.prepare(
        `INSERT INTO bobot_nilai (mata_pelajaran_id, tahun_ajaran_id, harian_persen, tugas_persen, uts_persen, uas_persen)
         VALUES (?, ?, ?, ?, ?, ?)`
      ).bind(mata_pelajaran_id || null, tahun_ajaran_id, harian_persen ?? 20, tugas_persen ?? 20, uts_persen ?? 30, uas_persen ?? 30).run();

      await logAktivitas(env, user.sub, 'create', 'bobot_nilai', `Tambah bobot nilai ta=${tahun_ajaran_id}`, ip);
      return created({ id: result.meta?.last_row_id });
    }

    if (request.method === 'PUT') {
      const id = parseInt(subPath.split('/')[1]);
      if (!id) return badRequest('ID diperlukan');
      const existing = await env.DB.prepare('SELECT id FROM bobot_nilai WHERE id = ?').bind(id).first();
      if (!existing) return notFound('Bobot nilai');

      const body = await request.json() as Record<string, unknown>;
      const setClauses: string[] = [];
      const vals: unknown[] = [];

      for (const f of ['mata_pelajaran_id', 'tahun_ajaran_id', 'harian_persen', 'tugas_persen', 'uts_persen', 'uas_persen']) {
        if (body[f] !== undefined) { setClauses.push(`${f} = ?`); vals.push(body[f]); }
      }
      if (setClauses.length === 0) return badRequest('Tidak ada field diupdate');
      vals.push(id);

      await env.DB.prepare(`UPDATE bobot_nilai SET ${setClauses.join(', ')} WHERE id = ?`).bind(...vals).run();
      await logAktivitas(env, user.sub, 'update', 'bobot_nilai', `Update bobot nilai id=${id}`, ip);
      return success({ id });
    }
  }

  // Monitoring nilai
  if (subPath === 'monitoring-nilai' && request.method === 'GET') {
    const rows = await env.DB.prepare(
      `SELECT n.id, n.nilai, n.jenis, n.status_validasi, n.siswa_id, s.nama as siswa_nama,
              mp.nama as mapel_nama, k.nama as kelas_nama, g.nama as guru_nama
       FROM nilai n
       LEFT JOIN siswa s ON n.siswa_id = s.id
       LEFT JOIN mata_pelajaran mp ON n.mata_pelajaran_id = mp.id
       LEFT JOIN kelas k ON n.kelas_id = k.id
       LEFT JOIN guru g ON n.diinput_oleh = g.id
       ORDER BY n.created_at DESC LIMIT 100`
    ).all();
    return success(rows.results);
  }

  // Status pengumpulan nilai per guru
  if (subPath === 'status-pengumpulan' && request.method === 'GET') {
    const rows = await env.DB.prepare(
      `SELECT g.id as guru_id, g.nama as guru_nama,
              COUNT(DISTINCT n.id) as total_input,
              COUNT(DISTINCT CASE WHEN n.status_validasi = 'draft' THEN n.id END) as draft,
              COUNT(DISTINCT CASE WHEN n.status_validasi = 'tervalidasi' THEN n.id END) as tervalidasi
       FROM guru g
       LEFT JOIN nilai n ON g.id = n.diinput_oleh
       WHERE g.status_aktif = 1
       GROUP BY g.id ORDER BY g.nama`
    ).all();
    return success(rows.results);
  }

  return badRequest('Endpoint tidak dikenal');
}

function logAktivitas(env: Env, userId: number, aksi: string, modul: string, detail: string, ip: string) {
  return env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, ?, ?, ?, ?)"
  ).bind(userId, aksi, modul, detail, ip).run();
}
