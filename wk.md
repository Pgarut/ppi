Ringkasan

Modul terdiri dari 7 halaman fitur (Dashboard, Absensi, Penjadwalan, Nilai, Daurah, Kenaikan Kelas, Laporan) dengan DashboardShell. Struktur rapi, tapi ada beberapa bug fungsional kritis.

🐛 Bug Kritis (fitur inti rusak)
Penjadwalan: daftar mapel selalu kosong — penjadwalan_page.dart:365 membaca _refList('guru_mapel'), tapi backend GET /wakil-kurikulum/referensi (penjadwalan.ts:52) tidak mengembalikan key guru_mapel. Drag-drop tidak bisa dipakai.
Penjadwalan: tabel tidak bisa diisi dari nol — penjadwalan_page.dart:571-573: jika _jadwal.isEmpty langsung tampil empty state menggantikan tabel drop-target (chicken-and-egg).
Penjadwalan: "Kegiatan Tetap" gagal disimpan — _moveToSlot kirim mata_pelajaran_id: null, backend penjadwalan.ts:272-274 menolak.
Penjadwalan: "Simpan Kesiapan" kehilangan semua edit — penjadwalan_page.dart:1041-1053 membuat data baru dari JSON mentah, bukan dari objek yang sudah diedit (data loss).
Kenaikan Kelas: wizard macet — kenaikan_kelas_page.dart:71 membaca ref['tahun_ajaran'], tapi backend referensi tidak menyertakannya → dropdown Tahun Ajaran kosong, tidak bisa lanjut ke step 2.
🐛 Bug Menengah
setState tanpa if (mounted) → risiko crash: absensi_page.dart:128,345,578, penjadwalan_page.dart:74.
Pagination tidak di-reset saat filter berubah → halaman kosong tak jelas: absensi_page.dart:118-129, nilai_page.dart:603-617.
Filter Tingkat & Genre tidak berfungsi — penjadwalan_page.dart:25,82-91,258-265 (tetap loop semua kelas).
Filter Kelas/Mapel monitoring nilai tidak ada UI — nilai_page.dart:28-29,351-353.
Catch kosong di banyak tempat → error tersembunyi, angka 0 menyesatkan (dashboard_page.dart:24).
PUT jadwal/{id}/validasi endpoint tidak ada di backend (dead code, wakil_kurikulum_service.dart:27).
🎨 UX & Lainnya
Label AppBar fitur salah/mentah (dashboard_shell.dart:41-55): "kenaikan-kelas", "laporan" muncul mentah.
Daurah punya Scaffold+AppBar ganda (daurah_nilai_page.dart:163-177) — tidak konsisten dengan halaman lain.
Toolbar penjadwalan overflow di layar sempit (penjadwalan_page.dart:187-246).
Banyak duplikasi kode (pagination, status chip, filter bar, parsing JSON).
🔓 Keamanan: token QR absensi 'PPI_ABSENSI_QR_2026' hanya divalidasi di client (scan_absen_page.dart:52); backend absensi/scan tidak memvalidasi token sama sekali.
Rekomendasi prioritas
Perbaiki endpoint referensi backend (tambah guru_mapel & tahun_ajaran) — memperbaiki 2 bug kritis sekaligus.
Render tabel drop-target saat jadwal kosong.
Perbaiki _simpanKesiapan (data loss).
Pindahkan validasi token QR ke server.