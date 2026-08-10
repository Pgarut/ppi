import { Env, UserPayload } from '../../types';
import { success, created, notFound, badRequest } from '../../utils/response';

export async function handleKenaikanKelas(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';
  const subPathFull = pathParts.slice(2).join('/');
  const resource = pathParts[2];
  const subPath = subPathFull === resource ? '' : subPathFull.replace(resource + '/', '');

  // GET list kenaikan kelas
  if (subPath === '' && request.method === 'GET') {
    const rows = await env.DB.prepare(
      `SELECT kk.*, s.nama as siswa_nama, s.nis, dk.nama as dari_kelas, tk.nama as ke_kelas
       FROM kenaikan_kelas kk
       LEFT JOIN siswa s ON kk.siswa_id = s.id
       LEFT JOIN kelas dk ON kk.dari_kelas_id = dk.id
       LEFT JOIN kelas tk ON kk.ke_kelas_id = tk.id
       ORDER BY kk.created_at DESC`
    ).all();
    return success(rows.results);
  }

  // Data calon naik kelas (siswa aktif per kelas)
  if (subPath === 'calon' && request.method === 'GET') {
    const kelasId = url.searchParams.get('kelas_id');
    const tahunAjaranId = url.searchParams.get('tahun_ajaran_id');

    if (!kelasId || !tahunAjaranId) return badRequest('kelas_id dan tahun_ajaran_id diperlukan');

    const kelasIdNum = parseInt(kelasId);
    const taIdNum = parseInt(tahunAjaranId);
    if (isNaN(kelasIdNum) || isNaN(taIdNum)) return badRequest('kelas_id dan tahun_ajaran_id harus berupa angka');

    const rows = await env.DB.prepare(
      `SELECT s.id, s.nis, s.nama, s.kelas_id, k.nama as kelas_nama
       FROM siswa s
       LEFT JOIN kelas k ON s.kelas_id = k.id
       WHERE s.kelas_id = ? AND s.tahun_ajaran_id = ? AND s.status = 'aktif'
       ORDER BY s.nis ASC`
    ).bind(kelasIdNum, taIdNum).all();
    return success(rows.results);
  }

  // Data calon batch: siswa + nilai + absensi untuk batch processing
  if (subPath === 'calon-batch' && request.method === 'GET') {
    const kelasId = url.searchParams.get('kelas_id');
    const tahunAjaranId = url.searchParams.get('tahun_ajaran_id');

    if (!kelasId || !tahunAjaranId) return badRequest('kelas_id dan tahun_ajaran_id diperlukan');

    const kelasIdNum2 = parseInt(kelasId);
    const taIdNum2 = parseInt(tahunAjaranId);
    if (isNaN(kelasIdNum2) || isNaN(taIdNum2)) return badRequest('kelas_id dan tahun_ajaran_id harus berupa angka');

    // Ambil data siswa aktif di kelas tersebut
    const siswaRows = await env.DB.prepare(
      `SELECT s.id, s.nis, s.nama, s.kelas_id, s.jenis_kelamin, k.nama as kelas_nama
       FROM siswa s
       LEFT JOIN kelas k ON s.kelas_id = k.id
       WHERE s.kelas_id = ? AND s.tahun_ajaran_id = ? AND s.status = 'aktif'
       ORDER BY s.nis ASC`
    ).bind(kelasIdNum2, taIdNum2).all();

    const siswaList = siswaRows.results as Array<Record<string, unknown>>;
    const siswaIds = siswaList.map(s => s.id as number);

    if (siswaIds.length === 0) {
      return success({ siswa: [], pengaturan: null });
    }

    // Ambil pengaturan batas minimum
    const pengaturanRows = await env.DB.prepare(
      `SELECT * FROM pengaturan_kenaikan_kelas WHERE tahun_ajaran_id = ?`
    ).bind(taIdNum2).all();
    const pengaturan = pengaturanRows.results[0] || null;

    // Ambil data nilai akhir per siswa (dari nilai_rapor)
    const placeholders = siswaIds.map(() => '?').join(',');
    const nilaiRows = await env.DB.prepare(
      `SELECT nr.siswa_id,
              COUNT(CASE WHEN nr.predikat = 'A' THEN 1 END) as mapel_a,
              COUNT(CASE WHEN nr.predikat = 'B' THEN 1 END) as mapel_b,
              COUNT(CASE WHEN nr.predikat = 'C' THEN 1 END) as mapel_c,
              COUNT(CASE WHEN nr.predikat = 'D' THEN 1 END) as mapel_d,
              COUNT(*) as total_mapel,
              ROUND(AVG(nr.nilai_akhir), 1) as rata_rata_nilai
       FROM nilai_rapor nr
       WHERE nr.siswa_id IN (${placeholders})
         AND nr.semester_id IN (
           SELECT id FROM semester WHERE tahun_ajaran_id = ?
         )
       GROUP BY nr.siswa_id`
    ).bind(...siswaIds, taIdNum2).all();

    const nilaiMap = new Map<number, Record<string, unknown>>();
    for (const row of nilaiRows.results) {
      const r = row as Record<string, unknown>;
      const total = (r.total_mapel as number) || 1;
      nilaiMap.set(r.siswa_id as number, {
        mapel_a: r.mapel_a || 0,
        mapel_b: r.mapel_b || 0,
        mapel_c: r.mapel_c || 0,
        mapel_d: r.mapel_d || 0,
        total_mapel: total,
        persen_a: Math.round(((r.mapel_a as number) || 0) / total * 100),
        persen_b: Math.round(((r.mapel_b as number) || 0) / total * 100),
        persen_c: Math.round(((r.mapel_c as number) || 0) / total * 100),
        persen_d: Math.round(((r.mapel_d as number) || 0) / total * 100),
        rata_rata_nilai: r.rata_rata_nilai || 0,
      });
    }

    // Ambil data absensi per siswa
    const absensiRows = await env.DB.prepare(
      `SELECT a.siswa_id,
              COUNT(CASE WHEN a.status = 'hadir' THEN 1 END) as hadir,
              COUNT(CASE WHEN a.status = 'izin' THEN 1 END) as izin,
              COUNT(CASE WHEN a.status = 'sakit' THEN 1 END) as sakit,
              COUNT(CASE WHEN a.status = 'alpa' THEN 1 END) as alpa,
              COUNT(*) as total_hari
       FROM absensi_siswa a
       WHERE a.siswa_id IN (${placeholders})
         AND a.kelas_id = ?
       GROUP BY a.siswa_id`
    ).bind(...siswaIds, kelasIdNum2).all();

    const absensiMap = new Map<number, Record<string, unknown>>();
    for (const row of absensiRows.results) {
      const r = row as Record<string, unknown>;
      const total = (r.total_hari as number) || 1;
      absensiMap.set(r.siswa_id as number, {
        hadir: r.hadir || 0,
        izin: r.izin || 0,
        sakit: r.sakit || 0,
        alpa: r.alpa || 0,
        total_hari: total,
        persen_hadir: Math.round(((r.hadir as number) || 0) / total * 100),
      });
    }

    // Gabungkan data
    const result = siswaList.map(s => ({
      ...s,
      nilai: nilaiMap.get(s.id as number) || {
        mapel_a: 0, mapel_b: 0, mapel_c: 0, mapel_d: 0,
        total_mapel: 0, persen_a: 0, persen_b: 0, persen_c: 0, persen_d: 0,
        rata_rata_nilai: 0,
      },
      absensi: absensiMap.get(s.id as number) || {
        hadir: 0, izin: 0, sakit: 0, alpa: 0,
        total_hari: 0, persen_hadir: 0,
      },
    }));

    return success({ siswa: result, pengaturan });
  }

  // GET kelas tujuan berdasarkan kelas asal (tingkat berikutnya, jurusan tetap)
  if (subPath === 'kelas-tujuan' && request.method === 'GET') {
    const dariKelasId = url.searchParams.get('dari_kelas_id');
    const tahunAjaranId = url.searchParams.get('tahun_ajaran_id');

    if (!dariKelasId || !tahunAjaranId) return badRequest('dari_kelas_id dan tahun_ajaran_id diperlukan');

    const dariKelasIdNum = parseInt(dariKelasId);
    const taIdKelasTujuan = parseInt(tahunAjaranId);
    if (isNaN(dariKelasIdNum) || isNaN(taIdKelasTujuan)) return badRequest('dari_kelas_id dan tahun_ajaran_id harus berupa angka');

    // Ambil info kelas asal
    const kelasAsal = await env.DB.prepare(
      `SELECT k.*, t.nama as tingkat_nama, t.jenjang, j.nama as jurusan_nama, j.kode as jurusan_kode
       FROM kelas k
       LEFT JOIN tingkat t ON k.tingkat_id = t.id
       LEFT JOIN jurusan j ON k.jurusan_id = j.id
       WHERE k.id = ?`
    ).bind(dariKelasIdNum).first() as Record<string, unknown> | null;

    if (!kelasAsal) return notFound('Kelas asal tidak ditemukan');

    // Cari tingkat berikutnya
    const nextTingkat = await env.DB.prepare(
      `SELECT id, nama FROM tingkat WHERE jenjang = ? AND id > ? ORDER BY id LIMIT 1`
    ).bind(kelasAsal.jenjang, kelasAsal.tingkat_id).first() as Record<string, unknown> | null;

    if (!nextTingkat) {
      // Tidak ada tingkat berikutnya = kelas XII terakhir, akan jadi alumni
      return success({ kelas: [], is_last_level: true, message: 'Siswa akan menjadi alumni (kelas XII)' });
    }

    // Ambil kelas tujuan di tingkat berikutnya dengan jurusan yang sama
    let queryKelas = `SELECT k.id, k.nama, k.wali_kelas_id,
       (SELECT COUNT(*) FROM siswa s WHERE s.kelas_id = k.id AND s.status = 'aktif') as jumlah_siswa
       FROM kelas k
       WHERE k.tingkat_id = ? AND k.tahun_ajaran_id = ?`;
    const params: unknown[] = [nextTingkat.id as number, taIdKelasTujuan];

    if (kelasAsal.jurusan_id) {
      queryKelas += ' AND k.jurusan_id = ?';
      params.push(kelasAsal.jurusan_id);
    } else {
      queryKelas += ' AND k.jurusan_id IS NULL';
    }
    queryKelas += ' ORDER BY k.nama';

    const kelasTujuan = await env.DB.prepare(queryKelas).bind(...params).all();

    return success({
      kelas: kelasTujuan.results,
      is_last_level: false,
      next_tingkat: nextTingkat.nama,
    });
  }

  // Proses kenaikan kelas (single)
  if (subPath === 'proses' && request.method === 'POST') {
    const body = await request.json() as { siswa_id: number; dari_kelas_id: number; ke_kelas_id?: number; status: string; tahun_ajaran_id: number; no_surat_keputusan?: string };

    if (!body.siswa_id || !body.dari_kelas_id || !body.status || !body.tahun_ajaran_id) {
      return badRequest('siswa_id, dari_kelas_id, status, tahun_ajaran_id wajib diisi');
    }

    if (!['naik', 'tidak_naik', 'lulus'].includes(body.status)) {
      return badRequest('Status harus naik, tidak_naik, atau lulus');
    }

    // Validasi FK
    const taExist = await env.DB.prepare('SELECT id FROM tahun_ajaran WHERE id = ?').bind(body.tahun_ajaran_id).first();
    if (!taExist) return badRequest('Tahun ajaran tidak ditemukan');

    // Validasi: cek apakah siswa sudah diproses di tahun ajaran yang sama
    const existingProcess = await env.DB.prepare(
      'SELECT id FROM kenaikan_kelas WHERE siswa_id = ? AND tahun_ajaran_id = ?'
    ).bind(body.siswa_id, body.tahun_ajaran_id).first();
    if (existingProcess) {
      return badRequest('Siswa ini sudah diproses kenaikan kelas di tahun ajaran ini');
    }

    const result = await env.DB.prepare(
      `INSERT INTO kenaikan_kelas (siswa_id, dari_kelas_id, ke_kelas_id, tahun_ajaran_id, status, no_surat_keputusan, tanggal_keputusan)
       VALUES (?, ?, ?, ?, ?, ?, date('now'))`
    ).bind(body.siswa_id, body.dari_kelas_id, body.ke_kelas_id || null, body.tahun_ajaran_id, body.status, body.no_surat_keputusan || null).run();

    // Update status dan kelas_id siswa
    if (body.status === 'lulus') {
      await env.DB.prepare("UPDATE siswa SET status = 'lulus' WHERE id = ?").bind(body.siswa_id).run();
    } else if (body.status === 'naik' && body.ke_kelas_id) {
      // Ambil tahun_ajaran_id dari kelas tujuan
      const kelasTujuan = await env.DB.prepare("SELECT tahun_ajaran_id FROM kelas WHERE id = ?").bind(body.ke_kelas_id).first<{ tahun_ajaran_id: number }>();
      const targetTaId = kelasTujuan?.tahun_ajaran_id || body.tahun_ajaran_id;
      await env.DB.prepare("UPDATE siswa SET kelas_id = ?, tahun_ajaran_id = ? WHERE id = ?").bind(body.ke_kelas_id, targetTaId, body.siswa_id).run();
    }

    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'kenaikan_kelas', ?, ?)"
    ).bind(user.sub, `Proses kenaikan kelas siswa=${body.siswa_id} status=${body.status}`, ip).run();

    return created({ id: result.meta?.last_row_id });
  }

  // Proses batch kenaikan kelas
  if (subPath === 'proses-batch' && request.method === 'POST') {
    const body = await request.json() as {
      dari_kelas_id: number;
      tahun_ajaran_id: number;
      siswa_naik: Array<{ siswa_id: number; ke_kelas_id: number }>;
      siswa_tidak_naik: number[];
    };

    if (!body.dari_kelas_id || !body.tahun_ajaran_id) {
      return badRequest('dari_kelas_id dan tahun_ajaran_id wajib diisi');
    }

    // Validasi FK
    const taExistBatch = await env.DB.prepare('SELECT id FROM tahun_ajaran WHERE id = ?').bind(body.tahun_ajaran_id).first();
    if (!taExistBatch) return badRequest('Tahun ajaran tidak ditemukan');

    if ((!body.siswa_naik || body.siswa_naik.length === 0) && (!body.siswa_tidak_naik || body.siswa_tidak_naik.length === 0)) {
      return badRequest('Tidak ada siswa yang diproses');
    }

    // Validasi: cek apakah siswa sudah diproses di tahun ajaran yang sama
    const allSiswaIds = [
      ...(body.siswa_naik?.map(s => s.siswa_id) || []),
      ...(body.siswa_tidak_naik || []),
    ];
    if (allSiswaIds.length > 0) {
      const placeholders = allSiswaIds.map(() => '?').join(',');
      const existingProcess = await env.DB.prepare(
        `SELECT siswa_id FROM kenaikan_kelas WHERE siswa_id IN (${placeholders}) AND tahun_ajaran_id = ?`
      ).bind(...allSiswaIds, body.tahun_ajaran_id).all<{ siswa_id: number }>();

      if (existingProcess.results.length > 0) {
        const dupSiswaIds = existingProcess.results.map(r => r.siswa_id);
        return badRequest(`Siswa dengan ID ${dupSiswaIds.join(', ')} sudah diproses kenaikan kelas di tahun ajaran ini`);
      }
    }

    const results: Array<{ siswa_id: number; status: string; kelas_nama?: string }> = [];

    // Proses siswa yang naik kelas
    if (body.siswa_naik && body.siswa_naik.length > 0) {
      for (const s of body.siswa_naik) {
        await env.DB.prepare(
          `INSERT INTO kenaikan_kelas (siswa_id, dari_kelas_id, ke_kelas_id, tahun_ajaran_id, status, tanggal_keputusan)
           VALUES (?, ?, ?, ?, 'naik', date('now'))`
        ).bind(s.siswa_id, body.dari_kelas_id, s.ke_kelas_id, body.tahun_ajaran_id).run();

        // Ambil tahun_ajaran_id dari kelas tujuan
        const kelasTujuan = await env.DB.prepare("SELECT tahun_ajaran_id FROM kelas WHERE id = ?").bind(s.ke_kelas_id).first<{ tahun_ajaran_id: number }>();
        const targetTaId = kelasTujuan?.tahun_ajaran_id || body.tahun_ajaran_id;

        // Update kelas_id dan tahun_ajaran_id siswa ke kelas tujuan
        await env.DB.prepare("UPDATE siswa SET kelas_id = ?, tahun_ajaran_id = ? WHERE id = ?").bind(s.ke_kelas_id, targetTaId, s.siswa_id).run();

        // Ambil nama kelas tujuan untuk response
        const kelasNama = await env.DB.prepare("SELECT nama FROM kelas WHERE id = ?").bind(s.ke_kelas_id).first() as Record<string, unknown> | null;

        results.push({ siswa_id: s.siswa_id, status: 'naik', kelas_nama: kelasNama?.nama as string });
      }
    }

    // Proses siswa yang tidak naik kelas
    if (body.siswa_tidak_naik && body.siswa_tidak_naik.length > 0) {
      for (const siswaId of body.siswa_tidak_naik) {
        await env.DB.prepare(
          `INSERT INTO kenaikan_kelas (siswa_id, dari_kelas_id, ke_kelas_id, tahun_ajaran_id, status, tanggal_keputusan)
           VALUES (?, ?, NULL, ?, 'tidak_naik', date('now'))`
        ).bind(siswaId, body.dari_kelas_id, body.tahun_ajaran_id).run();

        results.push({ siswa_id: siswaId, status: 'tidak_naik' });
      }
    }

    // Cek apakah ini kelas XII (terakhir) → otomatis jadi alumni
    const kelasAsal = await env.DB.prepare(
      `SELECT k.*, t.nama as tingkat_nama, t.jenjang
       FROM kelas k
       LEFT JOIN tingkat t ON k.tingkat_id = t.id
       WHERE k.id = ?`
    ).bind(body.dari_kelas_id).first() as Record<string, unknown> | null;

    const isLastLevel = await env.DB.prepare(
      `SELECT COUNT(*) as cnt FROM tingkat WHERE jenjang = ? AND id > ?`
    ).bind(kelasAsal?.jenjang, kelasAsal?.tingkat_id).first() as Record<string, unknown> | null;

    if (isLastLevel && (isLastLevel.cnt as number) === 0) {
      // Kelas XII → otomatis masuk alumni
      const tahunLulus = await env.DB.prepare(
        `SELECT nama FROM tahun_ajaran WHERE id = ?`
      ).bind(body.tahun_ajaran_id).first() as Record<string, unknown> | null;

      for (const r of results) {
        if (r.status === 'naik') {
          // Update status siswa jadi lulus
          await env.DB.prepare("UPDATE siswa SET status = 'lulus' WHERE id = ?").bind(r.siswa_id).run();

          // Insert ke alumni
          await env.DB.prepare(
            `INSERT OR IGNORE INTO alumni (siswa_id, tahun_lulus) VALUES (?, ?)`
          ).bind(r.siswa_id, tahunLulus?.nama || String(body.tahun_ajaran_id)).run();

          r.status = 'lulus_alumni';
        }
      }
    }

    // Log aktivitas
    await env.DB.prepare(
      "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'kenaikan_kelas', ?, ?)"
    ).bind(user.sub, `Batch kenaikan kelas dari kelas ${body.dari_kelas_id}: ${results.length} siswa diproses`, ip).run();

    return created({ processed: results.length, details: results });
  }

  // Pengaturan kenaikan kelas
  if (subPath === 'pengaturan' || resource === 'pengaturan-kenaikan-kelas') {
    const tahunAjaranId = url.searchParams.get('tahun_ajaran_id');

    if (request.method === 'GET') {
      if (!tahunAjaranId) return badRequest('tahun_ajaran_id diperlukan');
      const taIdNum = parseInt(tahunAjaranId);
      if (isNaN(taIdNum)) return badRequest('tahun_ajaran_id harus berupa angka');

      const row = await env.DB.prepare(
        `SELECT * FROM pengaturan_kenaikan_kelas WHERE tahun_ajaran_id = ?`
      ).bind(taIdNum).first();

      return success(row || { min_absensi_persen: 75, min_nilai_akhir: 60 });
    }

    if (request.method === 'POST' || request.method === 'PUT') {
      const body = await request.json() as { tahun_ajaran_id: number; min_absensi_persen?: number; min_nilai_akhir?: number };

      if (!body.tahun_ajaran_id) return badRequest('tahun_ajaran_id wajib diisi');

      // Validasi FK
      const taExistPengaturan = await env.DB.prepare('SELECT id FROM tahun_ajaran WHERE id = ?').bind(body.tahun_ajaran_id).first();
      if (!taExistPengaturan) return badRequest('Tahun ajaran tidak ditemukan');

      const existing = await env.DB.prepare(
        'SELECT id FROM pengaturan_kenaikan_kelas WHERE tahun_ajaran_id = ?'
      ).bind(body.tahun_ajaran_id).first();

      if (existing) {
        await env.DB.prepare(
          `UPDATE pengaturan_kenaikan_kelas
           SET min_absensi_persen = COALESCE(?, min_absensi_persen),
               min_nilai_akhir = COALESCE(?, min_nilai_akhir),
               updated_at = datetime('now')
           WHERE tahun_ajaran_id = ?`
        ).bind(body.min_absensi_persen ?? null, body.min_nilai_akhir ?? null, body.tahun_ajaran_id).run();
      } else {
        await env.DB.prepare(
          `INSERT INTO pengaturan_kenaikan_kelas (tahun_ajaran_id, min_absensi_persen, min_nilai_akhir)
           VALUES (?, ?, ?)`
        ).bind(body.tahun_ajaran_id, body.min_absensi_persen ?? 75, body.min_nilai_akhir ?? 60).run();
      }

      await env.DB.prepare(
        "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'kenaikan_kelas', ?, ?)"
      ).bind(user.sub, `Update pengaturan kenaikan kelas tahun ajaran ${body.tahun_ajaran_id}`, ip).run();

      return success({ message: 'Pengaturan berhasil disimpan' });
    }
  }

  // Alumni CRUD
  if (resource === 'alumni' || (resource === 'kenaikan-kelas' && subPath.startsWith('alumni'))) {
    const alumniSubPath = resource === 'alumni' ? subPath : subPath.replace('alumni', '');
    if (request.method === 'GET') {
      const rows = await env.DB.prepare(
        `SELECT a.*, s.nama as siswa_nama, s.nis FROM alumni a
         LEFT JOIN siswa s ON a.siswa_id = s.id ORDER BY a.tahun_lulus DESC`
      ).all();
      return success(rows.results);
    }

    if (request.method === 'POST') {
      const body = await request.json() as Record<string, unknown>;
      const { siswa_id, tahun_lulus, kontak, catatan } = body;

      if (!siswa_id || !tahun_lulus) return badRequest('siswa_id dan tahun_lulus wajib diisi');

      const result = await env.DB.prepare(
        'INSERT INTO alumni (siswa_id, tahun_lulus, kontak, catatan) VALUES (?, ?, ?, ?)'
      ).bind(siswa_id, tahun_lulus, kontak || null, catatan || null).run();

      await env.DB.prepare(
        "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'create', 'alumni', ?, ?)"
      ).bind(user.sub, `Tambah alumni siswa=${siswa_id}`, ip).run();

      return created({ id: result.meta?.last_row_id });
    }

    if (request.method === 'PUT') {
      const id = parseInt(alumniSubPath);
      if (!id) return badRequest('ID diperlukan');
      const body = await request.json() as Record<string, unknown>;

      const setClauses: string[] = [];
      const vals: unknown[] = [];
      for (const f of ['tahun_lulus', 'kontak', 'catatan']) {
        if (body[f] !== undefined) { setClauses.push(`${f} = ?`); vals.push(body[f]); }
      }
      if (setClauses.length === 0) return badRequest('Tidak ada field diupdate');
      setClauses.push("updated_at = datetime('now')");
      vals.push(id);

      await env.DB.prepare(`UPDATE alumni SET ${setClauses.join(', ')} WHERE id = ?`).bind(...vals).run();
      await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'alumni', ?, ?)")
        .bind(user.sub, `Update alumni #${id}`, ip).run();
      return success({ id });
    }

    if (request.method === 'DELETE') {
      const id = parseInt(alumniSubPath);
      if (!id) return badRequest('ID diperlukan');
      await env.DB.prepare('DELETE FROM alumni WHERE id = ?').bind(id).run();
      await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'delete', 'alumni', ?, ?)")
        .bind(user.sub, `Hapus alumni #${id}`, ip).run();
      return success({ id });
    }
  }

  return badRequest('Endpoint tidak dikenal');
}
