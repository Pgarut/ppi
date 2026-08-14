KRITIS

Filter monitoring nilai rusak — daurdoh.ts:793 memakai n.status, tapi kolom aslinya status_hafalan → filter status tak pernah cocok.
password_hash bocor ke API — daurdoh.ts:336 (SELECT m.*) dan :352 (SELECT *) mengirim hash password musyrifah ke frontend.
Tidak bisa input nilai pertama — nilai_daurdoh_page.dart membangun dropdown program dari hasil listNilai() (kosong) bukan dari getJadwal() → musyrifah tak bisa menyimpan nilai sebelum ada nilai.
Preview nilai ≠ nilai tersimpan — backend index.ts:811-813 menghitung 40 - sum (sempurna = 36), frontend nilai_daurdoh_page.dart:696-698 menghitung 40 - (sum - 4) (sempurna = 40) → tampilan preview salah, nilai sebenarnya disimpan DB.

SEDANG

Time zone absensi UTC — [FIXED] sekarang pakai helper WIB (Asia/Jakarta, UTC+7): wibDate()/wibTime() di musyrifah/index.ts & dauroh.ts:729. Absensi masuk/keluar, absensi santri, dashboard, dan default monitoring tercatat waktu lokal.
QR token hardcoded — [FIXED] index.ts baca env.QR_DAUROH_TOKEN || 'PPI_DAUROH_QR_2026', konsisten dengan admin dauroh.ts:685; scan page mengirim nilai hasil scan. (PPI_ABSENSI_QR_2026 di env.dart itu modul absensi umum, bukan dauroh.)
Scan tanpa jadwal_id — [FIXED] bila musyrifah punya >1 jadwal aktif hari ini, backend balas action:'pilih_jadwal' + daftar jadwal; frontend menampilkan dialog pilihan lalu scan ulang dengan jadwal_id.
Threshold warna nilai salah — [FIXED] nilai_monitoring_page.dart pakai persentase terhadap max 40/30/30.

KECIL

Enum 'hafalan' masih dipakai — [FIXED] → 'tahfidz' di dashboard_musyrifah_page.dart:297 & jadwal_dauroh_page.dart:123.
TextEditingController dibuat di dalam build() — [FIXED] absensi_monitoring_page.dart kini instance proper + dispose.
UNIQUE(program_id,santri_id,surat_nomor,dari_ayat,sampai_ayat) dengan kolom nullable → duplikat bisa lolos. [TERCATAT — SQLite perlakukan NULL beda di UNIQUE; biarkan karena 1 santri boleh punya beberapa baris nilai per rentang surat]
listNilaiMusyrifah tidak dipaginasi — [FIXED] backend LIMIT/OFFSET (default 100, max 200) + meta pagination; frontend service mengumpulkan semua halaman.