# Panduan Operator — Sistem Informasi Madrasah PPI

## 1. Login

Buka aplikasi di browser, lalu login dengan akun yang sudah disediakan:

| Role | Username | Password Default |
|------|----------|------------------|
| Admin | admin | admin123 |
| Kepala Sekolah | kepsek | kepsek123 |
| Wakil Kurikulum | wakil_kurikulum | wk123 |
| Guru Mapel / Wali Kelas | guru | guru123 |
| Guru BK | guru_bk | bk123 |

> **Penting:** Ganti password default setelah login pertama!

---

## 2. Alur Kerja Tahunan

### Awal Tahun Ajaran
1. **Admin:** Buat Tahun Ajaran baru + Semester (Ganjil/Genap)
2. **Admin:** Input/update data Guru, Siswa, Kelas
3. **WK:** Atur distribusi mengajar (guru → mapel → kelas)
4. **WK:** Generate jadwal otomatis → validasi → publikasi

### Selama Semester
5. **Guru:** Input absensi setiap pertemuan
6. **Guru:** Input nilai harian, tugas, PTS, PAS
7. **BK:** Monitor pengaduan & lakukan konseling

### Akhir Semester
8. **Wali Kelas:** Isi nilai rapor + catatan wali kelas
9. **WK:** Monitoring status pengumpulan nilai
10. **Admin:** Cetak rapor
11. **WK:** Backup database

### Akhir Tahun Ajaran
12. **WK:** Proses kenaikan kelas
13. **WK:** Kelulusan → pindah ke alumni
14. **Admin:** Backup database akhir tahun

---

## 3. Tips Penggunaan

### Master Data
- Input data secara berurutan: Tahun Ajaran → Semester → Jurusan → Tingkat → Ruangan → Mapel → Guru → Kelas → Siswa
- Gunakan fitur **Search** untuk mencari data cepat
- Hapus data akan terkendala jika masih digunakan (FK constraint)

### Absensi
- Guru bisa input absensi massal (pilih kelas → centang hadir semua → ubah individual)
- Absensi yang sudah diinput bisa diedit (upsert)

### Nilai
- Input per jenis: Harian → Tugas → UTS → UAS
- Bobot nilai diatur oleh WK (default: 20% harian, 20% tugas, 30% UTS, 30% UAS)
- Simpan sebagai draft dulu, finalkan setelah yakin

### Rapor
- Hanya Wali Kelas yang bisa input rapor
- Isi catatan wali kelas untuk setiap siswa
- Status: Draft → Selesai (setelah final)

### Backup
- Lakukan backup secara rutin (minimal 1x minggu)
- Backup akan mendownload semua data sebagai JSON
- Simpan file backup di tempat aman

---

## 4. Troubleshooting

| Masalah | Solusi |
|---------|--------|
| Lupa password | Hubungi Admin untuk reset password |
| Data tidak muncul | Refresh halaman (tombol refresh di pojok kanan) |
| Error 401 | Sesi habis, login ulang |
| Error 403 | Tidak punya akses ke modul tersebut |
| Halaman tidak responsif | Refresh atau clear cache browser |

---

## 5. Kontak

- **Admin Sistem:** [nama admin]
- **Developer:** [nama developer]
- **Laporan Bug:** Laporkan ke Admin atau buat pengaduan
