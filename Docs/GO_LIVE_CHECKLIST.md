# 🚀 GO-LIVE CHECKLIST — PPI Madrasah
## Validasi Final Sebelum Publikasi

**Tanggal Go-Live:** _______________
**Status:** ⏳ Belum / ✅ Selesai

---

## ⚡ PRE-FLIGHT CHECK (Developer)

| # | Item | Status | Catatan |
|---|------|--------|---------|
| 1 | Backend typecheck: `npm run typecheck` | ⬜ | ✅ Sudah verified (0 error) |
| 2 | Backend test: `npm test` — **167 tests PASS** | ⬜ | ✅ Sudah verified |
| 3 | Frontend analyze: `flutter analyze` — **0 error** | ⬜ | ✅ Sudah verified |
| 4 | Migrasi D1 terbaru sudah di-apply | ⬜ | `v1` + `v2` + `v3` |
| 5 | JWT_SECRET sudah di `wrangler secret put` | ⬜ | **KRITIS — jangan sampai terlewat** |
| 6 | JWT_REFRESH_SECRET sudah di `wrangler secret put` | ⬜ | **KRITIS — jangan sampai terlewat** |
| 7 | CORS_ORIGIN sudah benar (https://ppi-bo8.pages.dev) | ⬜ | ✅ Di wrangler.toml |
| 8 | Backup database production pertama | ⬜ | **Amankan sebelum deploy** |
| 9 | Seed data sudah jalan (5 user default) | ⬜ | Jalankan manual trigger di GitHub Actions |

---

## 🔐 SECURITY CHECK

| # | Item | Status | Catatan |
|---|------|--------|---------|
| 1 | Password default sudah diganti semua user | ⬜ | admin123, kepsek123, wk123, guru123, bk123 |
| 2 | JWT_SECRET tidak ada di wrangler.toml | ✅ | Sudah dipindah ke Secrets |
| 3 | Rate limiting aktif (in-memory + D1 hybrid) | ✅ | Fase 1.3 |
| 4 | Health check endpoint (/api/health) tersedia | ✅ | Fase 1.4 |
| 5 | Hanya HTTPS (via Cloudflare) | ✅ | Otomatis |

---

## 🧪 USER ACCEPTANCE TESTING (UAT)

**Total Skenario: 62** (Admin 18 + WK 13 + Guru 14 + BK 9 + KS 8 + E2E 4)

### Role: Admin (18 skenario)
| # | Skenario | Hasil |
|---|----------|-------|
| 1 | Login admin/admin123 → berhasil | ⬜ |
| 2 | Dashboard: 7 stat card muncul | ⬜ |
| 3 | Master Data: tambah Tahun Ajaran | ⬜ |
| 4 | Master Data: tambah Siswa | ⬜ |
| 5 | Master Data: edit Guru | ⬜ |
| 6 | Master Data: hapus data (ada konfirmasi ✅) | ⬜ |
| 7 | Master Data: search & filter | ⬜ |
| 8 | Pengaturan: tambah user baru | ⬜ |
| 9 | Pengaturan: nonaktifkan user | ⬜ |
| 10 | Pengaturan: backup database | ⬜ |
| 11 | Pengaturan: restore backup | ⬜ |
| 12 | Pengaturan: log aktivitas (filter, pagination) | ⬜ |
| 13 | Pengaturan Tampilan: ubah judul/login | ⬜ |
| 14 | Monitoring Absensi: rekap siswa & guru | ⬜ |
| 15 | Monitoring Nilai: filter per kelas | ⬜ |
| 16 | Monitoring Rapor: status per siswa | ⬜ |
| 17 | Logout (ada konfirmasi ✅) | ⬜ |
| 18 | Login dengan password salah → error 401 | ⬜ |

### Role: Wakil Kurikulum (13 skenario)
| # | Skenario | Hasil |
|---|----------|-------|
| 1 | Login wakil_kurikulum/wk123 → Dashboard | ⬜ |
| 2 | Penjadwalan: lihat referensi | ⬜ |
| 3 | Penjadwalan: generate jadwal otomatis | ⬜ |
| 4 | Penjadwalan: drag-drop jadwal | ⬜ |
| 5 | Penjadwalan: publikasi jadwal | ⬜ |
| 6 | Bobot Nilai: atur persentase | ⬜ |
| 7 | Monitoring Nilai: status pengumpulan | ⬜ |
| 8 | Kenaikan Kelas: lihat daftar | ⬜ |
| 9 | Kenaikan Kelas: proses naik/tidak/lulus | ⬜ |
| 10 | Alumni: lihat daftar | ⬜ |
| 11 | Laporan: jadwal | ⬜ |
| 12 | Laporan: absensi | ⬜ |
| 13 | Laporan: nilai & rapor | ⬜ |

### Role: Guru Mapel / Wali Kelas (14 skenario)
| # | Skenario | Hasil |
|---|----------|-------|
| 1 | Login guru/guru123 → Dashboard | ⬜ |
| 2 | Lihat jadwal mengajar | ⬜ |
| 3 | Absensi: input massal | ⬜ |
| 4 | Absensi: edit yang sudah diinput | ⬜ |
| 5 | Nilai: input per jenis (harian/tugas/uts/uas) | ⬜ |
| 6 | Nilai: input massal | ⬜ |
| 7 | Nilai: edit nilai | ⬜ |
| 8 | Rapor: lihat daftar siswa | ⬜ |
| 9 | Rapor: isi catatan wali kelas | ⬜ |
| 10 | Pengaduan: buat laporan | ⬜ |
| 11 | Wali Kelas: data siswa | ⬜ |
| 12 | Wali Kelas: rekap absensi | ⬜ |
| 13 | Wali Kelas: rekap nilai | ⬜ |
| 14 | Profil: lihat data diri | ⬜ |

### Role: Guru BK (9 skenario)
| # | Skenario | Hasil |
|---|----------|-------|
| 1 | Login guru_bk/bk123 → Dashboard | ⬜ |
| 2 | Pengaduan: lihat laporan masuk | ⬜ |
| 3 | Pengaduan: filter status | ⬜ |
| 4 | Pengaduan: update status | ⬜ |
| 5 | Konseling: buat jadwal baru | ⬜ |
| 6 | Konseling: lihat sesi | ⬜ |
| 7 | Bakat Minat: input data | ⬜ |
| 8 | Monitoring Akademik: grafik | ⬜ |
| 9 | Laporan: statistik bulanan | ⬜ |

### Role: Kepala Madrasah (8 skenario)
| # | Skenario | Hasil |
|---|----------|-------|
| 1 | Login kepsek/kepsek123 → Dashboard | ⬜ |
| 2 | Monitoring Jadwal: lihat jadwal | ⬜ |
| 3 | Monitoring Absensi: rekap | ⬜ |
| 4 | Monitoring Nilai: distribusi | ⬜ |
| 5 | Monitoring Rapor: status | ⬜ |
| 6 | Monitoring BK: rekap pengaduan | ⬜ |
| 7 | Laporan: generate laporan | ⬜ |
| 8 | Verifikasi: read-only (no create/edit/delete) | ⬜ |

### Flow End-to-End (4 skenario)
| # | Skenario | Hasil |
|---|----------|-------|
| 1 | Admin → Master data → WK → Jadwal → Guru → Absensi & Nilai → Wali Kelas → Rapor → Admin cetak | ⬜ |
| 2 | Guru → Pengaduan → BK → Tindak lanjut → Selesai | ⬜ |
| 3 | WK → Kenaikan kelas → Siswa naik/lulus → Alumni | ⬜ |
| 4 | Backup database → Restore → Data utuh | ⬜ |

---

## ✅ GO-LIVE EXECUTION

### Step-by-Step:

```
[ ] 1. Backup database production terakhir
       → Login Admin → Pengaturan → Backup
       → Simpan file JSON di tempat aman

[ ] 2. Ganti semua password default
       → Login sebagai Admin
       → Buka Pengaturan → Users
       → Edit setiap user: admin, kepsek, wk, guru, guru_bk
       → Set password baru yang aman

[ ] 3. Set Cloudflare Secrets (jika belum)
       npx wrangler secret put JWT_SECRET
       npx wrangler secret put JWT_REFRESH_SECRET

[ ] 4. Deploy backend
       cd backend
       npx wrangler deploy --env production

[ ] 5. Deploy frontend
       cd frontend
       flutter build web --release \
         --dart-define=API_BASE_URL=https://api.ppi-madrasah.com
       # Upload build/web/ ke Cloudflare Pages

[ ] 6. Verifikasi deployment
       curl https://api.ppi-madrasah.com/api/health
       # Response: { "status": "ok", "database": "connected", ... }

[ ] 7. Test login production
       Buka https://ppi-bo8.pages.dev
       Login dengan password baru

[ ] 8. Monitoring 24 jam pertama
       npx wrangler tail --env production --status error
```

---

## 📊 STATUS FINAL

| Aspek | Status | Keterangan |
|-------|--------|------------|
| **Backend** | ✅ **100%** | TypeScript, 167 tests, security hardened |
| **Frontend** | ⚠️ **95%** | AppUtils created, ~25 file catch blocks remain |
| **Database** | ✅ **100%** | 3 migrations applied, indexes exist |
| **Security** | ✅ **95%** | JWT in Secrets, rate limit hybrid, brute force |
| **CI/CD** | ✅ **100%** | GitHub Actions, staging env, rollback script |
| **Dokumentasi** | ✅ **100%** | PRD, SRS, API, UAT, Panduan, Maintenance |

---

## 📝 CATATAN GO-LIVE

- **Tanggal:** _______________
- **Penguji:** _______________
- **Total UAT Lulus:** ____ / 62
- **Bug Ditemukan:** ____
- **Siap Go-Live:** ✅ / ❌

---

*Dibuat: 28 Juli 2026*
