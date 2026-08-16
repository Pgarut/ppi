backend/src/db/migrations/v7.sql
@@ -0,0 +1,33 @@
-- ============================================================
-- MIGRATION v7 — Tabel catatan_wali_kelas
-- Target: Cloudflare D1 (SQLite) — Production
-- Tanggal: 2026-08-15
--
-- Deskripsi: Menyediakan tempat penyimpanan catatan wali kelas
-- per (siswa, semester). Sebelumnya catatan hanya di-UPDATE ke
-- tabel nilai_rapor yang tidak pernah di-INSERT sehingga fitur
-- tidak berfungsi (0 baris terpengaruh).
--
-- CARA PAKAI:
--   1. Buat backup dulu!
--   2. Jalankan via wrangler:
--      wrangler d1 execute ppi-db-prod --remote --file=./src/db/migrations/v7.sql
--   3. atau via Cloudflare Dashboard > D1 > Console
-- ============================================================

CREATE TABLE IF NOT EXISTS catatan_wali_kelas (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id    INTEGER NOT NULL REFERENCES siswa(id) ON DELETE CASCADE,
    semester_id INTEGER NOT NULL REFERENCES semester(id),
    catatan     TEXT NOT NULL DEFAULT '',
    updated_at  TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(siswa_id, semester_id)
);

CREATE INDEX IF NOT EXISTS idx_catatan_wali_siswa    ON catatan_wali_kelas(siswa_id);
CREATE INDEX IF NOT EXISTS idx_catatan_wali_semester ON catatan_wali_kelas(semester_id);

-- ============================================================
-- SELESAI. Verifikasi dengan:
--   SELECT name FROM sqlite_master WHERE name='catatan_wali_kelas';
-- ============================================================

backend/src/routes/guru_mapel_wali_kelas/rapor.ts
@@ -35,14 +35,25 @@ export async function handleRaporGuru(request: Request, env: Env, user: UserPayl
      "SELECT id, nis, nisn, nama FROM siswa WHERE kelas_id = ? AND status = 'aktif' ORDER BY nis ASC"
    ).bind(wali.id).all();

    const mapel = await env.DB.prepare(`
    let mapel = await env.DB.prepare(`
      SELECT DISTINCT mp.id, mp.nama, mp.kode
      FROM jadwal_pelajaran jp
      JOIN mata_pelajaran mp ON jp.mata_pelajaran_id = mp.id
      WHERE jp.kelas_id = ? AND jp.status_validasi = 'tervalidasi'
      ORDER BY mp.nama
    `).bind(wali.id).all();

    // Fallback bila jadwal belum divalidasi: pakai penugasan mapel-kelas guru
    if (mapel.results.length === 0) {
      mapel = await env.DB.prepare(`
        SELECT DISTINCT mp.id, mp.nama, mp.kode
        FROM guru_mapel_kelas gmk
        JOIN mata_pelajaran mp ON gmk.mata_pelajaran_id = mp.id
        WHERE gmk.kelas_id = ?
        ORDER BY mp.nama
      `).bind(wali.id).all();
    }

    return success({
      wali_kelas: wali,
      siswa: siswa.results,
@@ -80,7 +91,7 @@ export async function handleRaporGuru(request: Request, env: Env, user: UserPayl
      ? 'pas' : 'pat';

    // 1. Ambil daftar mapel + guru untuk kelas wali
    const mapelRows = await env.DB.prepare(`
    let mapelRows = await env.DB.prepare(`
      SELECT DISTINCT mp.id as mapel_id, mp.nama as mapel_nama, mp.kode as mapel_kode,
             jp.guru_id, g.nama as guru_nama
      FROM jadwal_pelajaran jp
@@ -90,12 +101,25 @@ export async function handleRaporGuru(request: Request, env: Env, user: UserPayl
      ORDER BY mp.nama
    `).bind(waliKelas.id, semId).all();

    // Fallback bila jadwal belum divalidasi: pakai penugasan mapel-kelas guru
    if (mapelRows.results.length === 0) {
      mapelRows = await env.DB.prepare(`
        SELECT DISTINCT mp.id as mapel_id, mp.nama as mapel_nama, mp.kode as mapel_kode,
               gmk.guru_id, g.nama as guru_nama
        FROM guru_mapel_kelas gmk
        JOIN mata_pelajaran mp ON gmk.mata_pelajaran_id = mp.id
        LEFT JOIN guru g ON gmk.guru_id = g.id
        WHERE gmk.kelas_id = ?
        ORDER BY mp.nama
      `).bind(waliKelas.id).all();
    }

    // 2. Ambil status input nilai (aggregate per mapel)
    const statusRows = await env.DB.prepare(`
      SELECT mata_pelajaran_id,
        MIN(id) as nilai_id,
        MAX(id) as nilai_id,
        MIN(created_at) as tgl_input,
        COUNT(*) as jumlah_santri
        COUNT(DISTINCT siswa_id) as jumlah_santri
      FROM nilai
      WHERE kelas_id = ? AND semester_id = ? AND jenis = ?
      GROUP BY mata_pelajaran_id
@@ -145,17 +169,17 @@ export async function handleRaporGuru(request: Request, env: Env, user: UserPayl
    const sId = parseInt(siswaId);
    const semId = parseInt(semesterId);

    // 1. Ambil data siswa & semester
    // 1. Ambil data siswa, semester & catatan wali
    const [siswa, semester, catatanWali] = await Promise.all([
      env.DB.prepare(
        "SELECT id, nis, nisn, nama, kelas_id FROM siswa WHERE id = ? AND status = 'aktif'"
      ).bind(sId).first<{ id: number; nis: string; nisn: string | null; nama: string; kelas_id: number }>(),
      env.DB.prepare(
        'SELECT id, nama FROM semester WHERE id = ?'
      ).bind(semId).first<{ id: number; nama: string }>(),
        'SELECT id, nama, tahun_ajaran_id FROM semester WHERE id = ?'
      ).bind(semId).first<{ id: number; nama: string; tahun_ajaran_id: number }>(),
      env.DB.prepare(
        'SELECT catatan_wali_kelas FROM nilai_rapor WHERE siswa_id = ? AND semester_id = ? AND catatan_wali_kelas IS NOT NULL LIMIT 1'
      ).bind(sId, semId).first<{ catatan_wali_kelas: string }>(),
        'SELECT catatan FROM catatan_wali_kelas WHERE siswa_id = ? AND semester_id = ?'
      ).bind(sId, semId).first<{ catatan: string }>(),
    ]);

    if (!siswa) return badRequest('Siswa tidak ditemukan');
@@ -167,57 +191,94 @@ export async function handleRaporGuru(request: Request, env: Env, user: UserPayl
    const jenisUjian = (namaSemester.includes('1') || namaSemester.includes('ganjil') || namaSemester.includes('i'))
      ? 'pas' : 'pat';

    // 3. Ambil semua nilai siswa di semester ini
    // 3. Ambil bobot nilai (spesifik mapel, fallback default sekolah)
    const bobotRows = await env.DB.prepare(
      `SELECT mata_pelajaran_id, harian_persen, tugas_persen, uts_persen, uas_persen
       FROM bobot_nilai WHERE tahun_ajaran_id = ?`
    ).bind(semester.tahun_ajaran_id).all<{
      mata_pelajaran_id: number | null;
      harian_persen: number; tugas_persen: number; uts_persen: number; uas_persen: number;
    }>();

    const bobotMap = new Map<number | null, { harian: number; tugas: number; uts: number; uas: number }>();
    for (const b of bobotRows.results) {
      bobotMap.set(b.mata_pelajaran_id, {
        harian: b.harian_persen, tugas: b.tugas_persen, uts: b.uts_persen, uas: b.uas_persen,
      });
    }

    // 4. Ambil semua nilai siswa di semester ini — dedupe per (mapel, jenis)
    //    agar tidak dobel bila nilai diinput oleh lebih dari satu guru.
    const nilaiRows = await env.DB.prepare(`
      SELECT n.mata_pelajaran_id, mp.nama as mapel_nama, mp.kode as mapel_kode,
             n.jenis, n.nilai
      FROM nilai n
      JOIN mata_pelajaran mp ON n.mata_pelajaran_id = mp.id
      WHERE n.siswa_id = ? AND n.semester_id = ?
        AND n.id = (
          SELECT MAX(n2.id) FROM nilai n2
          WHERE n2.siswa_id = ? AND n2.semester_id = ?
            AND n2.mata_pelajaran_id = n.mata_pelajaran_id
            AND n2.jenis = n.jenis
        )
      ORDER BY mp.nama, n.jenis
    `).bind(sId, semId).all<{
    `).bind(sId, semId, sId, semId).all<{
      mata_pelajaran_id: number; mapel_nama: string; mapel_kode: string;
      jenis: string; nilai: number;
    }>();

    // 4. Group by mapel
    // 5. Group by mapel
    const mapelMap = new Map<number, {
      id: number; nama: string; kode: string;
      nilai_harian: number[]; nilai_ujian: number | null;
      nilai_harian: number[]; nilai_pts: number | null; nilai_ujian: number | null;
    }>();

    const jenisPts = jenisUjian === 'pas' ? 'pts1' : 'pts2';

    for (const row of nilaiRows.results) {
      if (!mapelMap.has(row.mata_pelajaran_id)) {
        mapelMap.set(row.mata_pelajaran_id, {
          id: row.mata_pelajaran_id,
          nama: row.mapel_nama,
          kode: row.mapel_kode,
          nilai_harian: [],
          nilai_pts: null,
          nilai_ujian: null,
        });
      }
      const entry = mapelMap.get(row.mata_pelajaran_id)!;
      if (row.jenis === 'harian') {
        entry.nilai_harian.push(row.nilai);
      } else if (row.jenis === jenisPts) {
        entry.nilai_pts = row.nilai;
      } else if (row.jenis === jenisUjian) {
        entry.nilai_ujian = row.nilai;
      }
    }

    // 5. Format response
    // 6. Format response — nilai akhir pakai bobot_nilai + PTS
    const mapel = Array.from(mapelMap.values()).map((m) => {
      const rataHarian = m.nilai_harian.length > 0
        ? Math.round(m.nilai_harian.reduce((a, b) => a + b, 0) / m.nilai_harian.length * 10) / 10
        : null;

      // Nilai akhir: 60% nilai ujian + 40% rata-rata harian
      // Bobot default bila tidak terkonfigurasi (sesuai skema schema.sql)
      const bobot = bobotMap.get(m.id) ?? bobotMap.get(null) ?? { harian: 20, tugas: 20, uts: 30, uas: 30 };

      // Tidak ada input jenis 'tugas' dari guru, jadi bobot tugas diserap ke harian
      const wHarian = bobot.harian + bobot.tugas;
      const wPts = bobot.uts;
      const wUjian = bobot.uas;

      // Hitung rata-rata terbobot atas komponen yang tersedia
      let nilaiAkhir: number | null = null;
      if (m.nilai_ujian !== null && rataHarian !== null) {
        nilaiAkhir = Math.round((m.nilai_ujian * 0.6 + rataHarian * 0.4) * 10) / 10;
      } else if (m.nilai_ujian !== null) {
        nilaiAkhir = m.nilai_ujian;
      } else if (rataHarian !== null) {
        nilaiAkhir = rataHarian;
      let totalBerat = 0;
      let totalNilai = 0;
      if (rataHarian !== null) { totalBerat += wHarian; totalNilai += rataHarian * wHarian; }
      if (m.nilai_pts !== null) { totalBerat += wPts; totalNilai += m.nilai_pts * wPts; }
      if (m.nilai_ujian !== null) { totalBerat += wUjian; totalNilai += m.nilai_ujian * wUjian; }
      if (totalBerat > 0) {
        nilaiAkhir = Math.round(totalNilai / totalBerat * 10) / 10;
      }

      return {
@@ -226,8 +287,11 @@ export async function handleRaporGuru(request: Request, env: Env, user: UserPayl
        kode: m.kode,
        nilai_harian: m.nilai_harian,
        rata_harian: rataHarian,
        nilai_pts: m.nilai_pts,
        jenis_pts: jenisPts,
        nilai_ujian: m.nilai_ujian,
        jenis_ujian: jenisUjian,
        bobot: { harian_persen: wHarian, pts_persen: wPts, ujian_persen: wUjian },
        nilai_akhir: nilaiAkhir,
        predikat: nilaiAkhir !== null ? hitungPredikat(nilaiAkhir) : null,
      };
@@ -247,7 +311,7 @@ export async function handleRaporGuru(request: Request, env: Env, user: UserPayl
        nama: semester.nama,
      },
      mapel,
      catatan_wali: catatanWali?.catatan_wali_kelas || null,
      catatan_wali: catatanWali?.catatan || null,
    });
  }
  
  backend/src/routes/guru_mapel_wali_kelas/wali_kelas.ts
  @ -44,15 +44,20 @@ export async function handleWaliKelas(request: Request, env: Env, user: UserPayl      JOIN kelas k ON s.kelas_id = k.id      LEFT JOIN (        SELECT          siswa_id,          d.siswa_id,          COUNT(*) as total_kehadiran,          SUM(CASE WHEN status = 'hadir' THEN 1 ELSE 0 END) as hadir,          SUM(CASE WHEN status = 'izin' THEN 1 ELSE 0 END) as izin,          SUM(CASE WHEN status = 'sakit' THEN 1 ELSE 0 END) as sakit,          SUM(CASE WHEN status = 'alpa' THEN 1 ELSE 0 END) as alpa        FROM absensi_siswa        ${absensiWhere}        GROUP BY siswa_id          SUM(CASE WHEN d.st = 1 THEN 1 ELSE 0 END) as hadir,          SUM(CASE WHEN d.st = 2 THEN 1 ELSE 0 END) as izin,          SUM(CASE WHEN d.st = 3 THEN 1 ELSE 0 END) as sakit,          SUM(CASE WHEN d.st = 4 THEN 1 ELSE 0 END) as alpa        FROM (          SELECT siswa_id, tanggal,            MAX(CASE status WHEN 'hadir' THEN 1 WHEN 'izin' THEN 2 WHEN 'sakit' THEN 3 WHEN 'alpa' THEN 4 ELSE 0 END) as st          FROM absensi_siswa          ${absensiWhere}          GROUP BY siswa_id, tanggal        ) d        GROUP BY d.siswa_id      ) a ON a.siswa_id = s.id      LEFT JOIN (        SELECT@@ -148,7 +153,7 @@ export async function handleWaliKelas(request: Request, env: Env, user: UserPayl    return success({ kelas: waliKelas, rekap: rows.results });  }  // PUT catatan wali kelas (update nilai_rapor)  // PUT catatan wali kelas (UPSERT ke catatan_wali_kelas)  if (subPath == 'catatan-wali' && request.method === 'PUT') {    const body = await request.json() as { siswa_id: number; semester_id: number; catatan: string };    const { siswa_id, semester_id, catatan } = body;@@ -157,11 +162,14 @@ export async function handleWaliKelas(request: Request, env: Env, user: UserPayl      return badRequest('siswa_id, semester_id, catatan wajib diisi');    }    await env.DB.prepare(      'UPDATE nilai_rapor SET catatan_wali_kelas = ? WHERE siswa_id = ? AND semester_id = ?'    ).bind(catatan, siswa_id, semester_id).run();    await env.DB.prepare(`      INSERT INTO catatan_wali_kelas (siswa_id, semester_id, catatan, updated_at)      VALUES (?, ?, ?, datetime('now'))      ON CONFLICT(siswa_id, semester_id)      DO UPDATE SET catatan = excluded.catatan, updated_at = datetime('now')    `).bind(siswa_id, semester_id, catatan).run();    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'nilai_rapor', ?, ?)")    await env.DB.prepare("INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, 'update', 'catatan_wali_kelas', ?, ?)")      .bind(user.sub, `Update catatan wali: siswa=${siswa_id} semester=${semester_id}`, ip).run();    return success({ message: 'Catatan tersimpan' });
Collapse file‎frontend/lib/features/guru_mapel_wali_kelas/rapor/rapor_page.dart‎Copy file name to clipboardExpand all lines: frontend/lib/features/guru_mapel_wali_kelas/rapor/rapor_page.dart+58-2Lines changed: 58 additions & 2 deletionsOriginal file line numberDiff line numberDiff line change@@ -452,7 +452,7 @@ class _LihatRaporState extends State<_LihatRapor> {          const SizedBox(height: 14),          // Catatan Wali          if ((_raporData!['catatan_wali'] as String?)?.isNotEmpty == true) _buildCatatanCard(),          _buildCatatanCard(),        ] else if (_loadingRapor) ...[          const SizedBox(height: 60), const Center(child: CircularProgressIndicator()),        ] else ...[@@ -563,6 +563,8 @@ class _LihatRaporState extends State<_LihatRapor> {  }  Widget _buildCatatanCard() {    final catatan = _raporData!['catatan_wali'] as String? ?? '';    final catatanCtl = TextEditingController(text: catatan);    return Container(      padding: const EdgeInsets.all(18),      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFF9A825).withValues(alpha: 0.2)), boxShadow: [BoxShadow(color: const Color(0xFFF9A825).withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),@@ -572,11 +574,65 @@ class _LihatRaporState extends State<_LihatRapor> {        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [          const Text('Catatan Wali Kelas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFF9A825))),          const SizedBox(height: 6),          Text(_raporData!['catatan_wali'] as String? ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),          Text(catatan.isNotEmpty ? catatan : 'Belum ada catatan. Klik edit untuk menambahkan.', style: TextStyle(fontSize: 13, color: catatan.isNotEmpty ? Colors.grey[700] : Colors.grey[400], height: 1.5, fontStyle: catatan.isNotEmpty ? FontStyle.normal : FontStyle.italic)),        ])),        IconButton(          tooltip: 'Edit Catatan',          icon: const Icon(Icons.edit_rounded, size: 20, color: Color(0xFFF9A825)),          onPressed: () => _editCatatan(catatanCtl),        ),      ]),    );  }  Future<void> _editCatatan(TextEditingController ctl) async {    final result = await showDialog<String>(      context: context,      builder: (ctx) => AlertDialog(        title: const Text('Catatan Wali Kelas'),        content: TextField(          controller: ctl,          maxLines: 4,          maxLength: 1000,          decoration: const InputDecoration(            hintText: 'Tulis catatan wali kelas untuk santri ini...',            border: OutlineInputBorder(),          ),        ),        actions: [          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),          FilledButton(            onPressed: () => Navigator.pop(ctx, ctl.text.trim()),            child: const Text('Simpan'),          ),        ],      ),    );    if (result == null || !mounted || _siswaId == null || _semesterId == null) return;    try {      await GuruService.saveCatatanWali({        'siswa_id': _siswaId,        'semester_id': _semesterId,        'catatan': result,      });      if (!mounted) return;      ScaffoldMessenger.of(context).clearSnackBars();      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(        content: Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 18), SizedBox(width: 8), Text('Catatan tersimpan')]),        backgroundColor: Color(0xFF2E7D32), behavior: SnackBarBehavior.floating,        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))), margin: EdgeInsets.all(16),      ));      await _loadRapor();    } catch (_) {      if (mounted) {        ScaffoldMessenger.of(context).clearSnackBars();        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(          content: Text('Gagal menyimpan catatan'), backgroundColor: Colors.red,          behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(16),        ));      }    }  }}//
 =====================================================================
 
 frontend/lib/features/guru_mapel_wali_kelas/wali_kelas/wali_kelas_page.dart
@ -703,7 +703,7 @@ class _WaliKelasPageGuruState extends State<WaliKelasPageGuru>    pdf.addPage(      pw.MultiPage(        pageFormat: const PdfPageFormat(215.0, 330.0, marginAll: 15),        pageFormat: const PdfPageFormat(215 * PdfPageFormat.mm, 330 * PdfPageFormat.mm, marginAll: 15),        margin: const pw.EdgeInsets.all(15),        header: (context) => pw.Container(          alignment: pw.Alignment.center,