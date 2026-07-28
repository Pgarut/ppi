# UAT Checklist — PPI Madrasah

## Sebelum UAT
- [ ] Database sudah di-seed (5 user default + data contoh)
- [ ] Backend berjalan (dev: `npm run dev` / prod: URL production)
- [ ] Frontend berjalan (`flutter run -d chrome`)
- [ ] Semua test lulus: `npm test` (164 tests)
- [ ] Typecheck lulus: `npm run typecheck`

---

## Role: Admin
**Login:** admin / admin123

| # | Skenario | Hasil |
|---|----------|-------|
| 1 | Login dengan username & password benar | ✅/❌ |
| 2 | Login dengan password salah → error 401 | ✅/❌ |
| 3 | Dashboard: lihat 6 stat card (guru, siswa, kelas, dll) | ✅/❌ |
| 4 | Master Data: buka tab Tahun Ajaran → tambah baru | ✅/❌ |
| 5 | Master Data: buka tab Siswa → tambah siswa baru | ✅/❌ |
| 6 | Master Data: edit data guru | ✅/❌ |
| 7 | Master Data: hapus data (pastikan ada konfirmasi) | ✅/❌ |
| 8 | Master Data: search & filter berfungsi | ✅/❌ |
| 9 | Pengaturan: tambah user baru dengan role berbeda | ✅/❌ |
| 10 | Pengaturan: nonaktifkan user | ✅/❌ |
| 11 | Pengaturan: backup database → download JSON | ✅/❌ |
| 12 | Pengaturan: restore dari file backup | ✅/❌ |
| 13 | Pengaturan: lihat log aktivitas (filter & pagination) | ✅/❌ |
| 14 | Pengaturan Tampilan: ubah judul/login page | ✅/❌ |
| 15 | Monitoring Absensi: lihat rekap absensi siswa & guru | ✅/❌ |
| 16 | Monitoring Nilai: filter per kelas, lihat daftar nilai | ✅/❌ |
| 17 | Monitoring Rapor: lihat status rapor per siswa | ✅/❌ |
| 18 | Logout | ✅/❌ |

---

## Role: Wakil Kurikulum
**Login:** wakil_kurikulum / wk123

| # | Skenario | Hasil |
|---|----------|-------|
| 1 | Login → Dashboard WK (ringkasan) | ✅/❌ |
| 2 | Penjadwalan: lihat referensi (kelas, guru, mapel) | ✅/❌ |
| 3 | Penjadwalan: generate jadwal otomatis | ✅/❌ |
| 4 | Penjadwalan: verifikasi jadwal tidak bentrok | ✅/❌ |
| 5 | Penjadwalan: publikasi jadwal | ✅/❌ |
| 6 | Penjadwalan: lihat jadwal per kelas | ✅/❌ |
| 7 | Bobot Nilai: atur persentase (total harus 100%) | ✅/❌ |
| 8 | Bobot Nilai: simpan bobot baru | ✅/❌ |
| 9 | Monitoring Nilai: lihat status pengumpulan per guru | ✅/❌ |
| 10 | Kenaikan Kelas: lihat daftar calon naik kelas | ✅/❌ |
| 11 | Kenaikan Kelas: proses kenaikan (naik/tidak naik/lulus) | ✅/❌ |
| 12 | Alumni: lihat daftar alumni | ✅/❌ |
| 13 | Laporan: buka 4 jenis laporan (jadwal/absensi/nilai/rapor) | ✅/❌ |

---

## Role: Guru Mapel / Wali Kelas
**Login:** guru / guru123

| # | Skenario | Hasil |
|---|----------|-------|
| 1 | Login → Dashboard (jadwal hari ini, notifikasi) | ✅/❌ |
| 2 | Lihat jadwal mengajar mingguan | ✅/❌ |
| 3 | Absensi: pilih kelas → input hadir/sakit/izin/alfa massal | ✅/❌ |
| 4 | Absensi: edit absensi yang sudah diinput | ✅/❌ |
| 5 | Nilai: pilih kelas+mapel → input nilai harian per siswa | ✅/❌ |
| 6 | Nilai: input nilai massal (semua siswa sekali simpan) | ✅/❌ |
| 7 | Nilai: edit nilai yang sudah diinput | ✅/❌ |
| 8 | Rapor: lihat daftar siswa kelas wali | ✅/❌ |
| 9 | Rapor: isi catatan wali kelas | ✅/❌ |
| 10 | Rapor: finalisasi rapor (draft → selesai) | ✅/❌ |
| 11 | Pengaduan: buat laporan perilaku/kasus siswa | ✅/❌ |
| 12 | Wali Kelas: lihat data siswa kelas wali | ✅/❌ |
| 13 | Wali Kelas: lihat rekap absensi & nilai kelas | ✅/❌ |
| 14 | Profil: edit data diri | ✅/❌ |

---

## Role: Guru BK
**Login:** guru_bk / bk123

| # | Skenario | Hasil |
|---|----------|-------|
| 1 | Login → Dashboard BK (statistik pengaduan) | ✅/❌ |
| 2 | Pengaduan: lihat semua laporan masuk | ✅/❌ |
| 3 | Pengaduan: filter berdasarkan status | ✅/❌ |
| 4 | Pengaduan: update status (baru → ditindaklanjuti → selesai) | ✅/❌ |
| 5 | Konseling: buat jadwal konseling baru | ✅/❌ |
| 6 | Konseling: lihat daftar sesi konseling | ✅/❌ |
| 7 | Bakat Minat: lihat & input data bakat siswa | ✅/❌ |
| 8 | Monitoring Akademik: lihat grafik nilai & absensi siswa | ✅/❌ |
| 9 | Laporan: lihat statistik bulanan | ✅/❌ |

---

## Role: Kepala Madrasah
**Login:** kepsek / kepsek123

| # | Skenario | Hasil |
|---|----------|-------|
| 1 | Login → Dashboard eksekutif (statistik sekolah) | ✅/❌ |
| 2 | Monitoring Jadwal: lihat jadwal sekolah | ✅/❌ |
| 3 | Monitoring Absensi: lihat rekap & grafik kehadiran | ✅/❌ |
| 4 | Monitoring Nilai: lihat distribusi nilai | ✅/❌ |
| 5 | Monitoring Rapor: lihat status & preview rapor | ✅/❌ |
| 6 | Monitoring BK: lihat rekap pengaduan & konseling | ✅/❌ |
| 7 | Laporan: generate 5 jenis laporan | ✅/❌ |
| 8 | Verifikasi: tidak ada tombol create/edit/delete (read-only) | ✅/❌ |

---

## Flow End-to-End Kritis

| # | Skenario | Hasil |
|---|----------|-------|
| 1 | Admin input master data → WK buat jadwal → Guru input absensi & nilai → Wali kelas isi rapor → Admin cetak rapor | ✅/❌ |
| 2 | Guru buat pengaduan → BK lihat & tindak lanjuti → selesai | ✅/❌ |
| 3 | WK proses kenaikan kelas → siswa naik/lulus → alumni tercatat | ✅/❌ |
| 4 | Backup database → restore → data tetap utuh | ✅/❌ |

---

## Catatan UAT
- Tanggal: _______________
- Penguji: _______________
- Total lulus: ____ / ____
- Bug ditemukan: ____
- Siap go-live: ✅ / ❌
