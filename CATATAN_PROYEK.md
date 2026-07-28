# CATATAN PROYEK — Sistem Informasi Madrasah PPI (MA/MTs)

## 1. Ringkasan Proyek

**Aplikasi:** Sistem Informasi Madrasah PPI  
**Stack:** Flutter (Frontend Web + Mobile) + Cloudflare Workers (Backend) + D1 Database (SQLite)  
**Role:** Admin, Kepala Madrasah, Wakil Kurikulum, Guru Mapel/Wali Kelas, Guru BK  
**Target Platform:** Web (responsif mobile+desktop)  
**Warna Tema:** Hijau (#2E7D32), Kuning (#FDD835), Putih

---

## 2. Tahap Perancangan (Dokumentasi)

### Dokumen yang dibuat:

| File | Isi |
|------|-----|
| `Docs/0. PRD.md` | Product Requirements Document — fitur, batasan, pengguna |
| `Docs/1. Menu_Sistem_Informasi_Madrasah_MA_MTs.md` | Menu per role |
| `Docs/2. SRS.md` | Software Requirements Specification |
| `Docs/3. ERD.md` | Entity Relationship Diagram |
| `Docs/4. API.md` | 110+ endpoint API spec |
| `Docs/6. KEAMANAN.md` | Keamanan: bcrypt, JWT, RBAC, log aktivitas |
| `Docs/7. Hak Akses.md` | Hak akses tiap role per modul |
| `Docs/9. ROADMAP.md` | 10 fase pengembangan |
| `Docs/10. Auto Scheduling.md` | Algoritma jadwal otomatis |
| `schema.sql` | 20+ tabel D1/SQLite |

### Struktur Database (tabel utama):
- `users`, `guru`, `siswa`, `kelas`, `jurusan`, `tingkat`
- `mata_pelajaran`, `ruangan`, `tahun_ajaran`, `semester`
- `distribusi_mengajar`, `jadwal_pelajaran`, `jp_slots`
- `absensi_siswa`, `nilai`, `nilai_rapor`
- `pengaduan`, `log_aktivitas`, `hak_akses_modul`
- `alumni`, `kenaikan_kelas`, `bobot_nilai`

---

## 3. Tahap Pembuatan — Backend

### Struktur Folder
```
backend/
├── src/
│   ├── index.ts                  (entry point + routing)
│   ├── types.ts                  (interface Env, UserPayload, Role)
│   ├── middleware/
│   │   └── auth.ts               (JWT generate/verify, role_guard)
│   ├── utils/
│   │   ├── response.ts           (success, error, notFound, etc.)
│   │   └── crud.ts               (generic CRUD helper)
│   └── routes/
│       ├── admin/
│       │   ├── master_data.ts    (9 entity CRUD via config map)
│       │   ├── users.ts          (users CRUD + hak akses)
│       │   ├── dashboard.ts      (7 stat cards)
│       │   └── system.ts         (backup, restore, log_aktivitas)
│       ├── wakil_kurikulum/
│       │   ├── penjadwalan.ts    (CRUD jadwal, auto-generate, JP slots, publikasi)
│       │   ├── nilai.ts          (bobot nilai, monitoring, status pengumpulan)
│       │   ├── kenaikan_kelas.ts (proses naik kelas, alumni)
│       │   └── laporan.ts        (4 jenis laporan)
│       ├── guru_mapel_wali_kelas/
│       │   ├── absensi.ts        (input massal + upsert)
│       │   ├── nilai.ts          (input per jenis + massal)
│       │   ├── rapor.ts          (nilai rapor + catatan)
│       │   ├── pengaduan.ts      (lapor perilaku/kasus)
│       │   └── wali_kelas.ts     (data siswa, rekap absensi/nilai)
│       ├── guru_bk/
│       │   ├── pengaduan.ts      (lihat semua + update status)
│       │   └── laporan.ts        (statistik, bulanan, rekap kasus)
│       └── kepala_sekolah/
│           ├── dashboard.ts      (statistik + grafik)
│           └── laporan.ts        (jadwal, absensi, nilai, rapor)
```

### Fitur Backend per Role

**Auth:** Login bcrypt + JWT (jose), middleware role_guard, log_aktivitas

**Admin:**
- Dashboard 7 stat card (total siswa, guru, kelas, mapel, jadwal, pengguna, log)
- Master data CRUD: tahun_ajaran, semester, jurusan, tingkat, kelas, mata_pelajaran, guru, siswa, ruangan
- Pengaturan: users CRUD, hak akses CRUD, log aktivitas paginated, backup/restore D1

**Wakil Kurikulum:**
- Penjadwalan: CRUD jadwal, 8 JP slots, auto-generate (greedy algo), drag-drop, bentrok detection, reset, publikasi
- Nilai: bobot nilai %, monitoring, status pengumpulan per guru
- Kenaikan Kelas: proses form, alumni CRUD
- Laporan: 4 tab (jadwal, absensi, nilai, rapor)

**Guru Mapel / Wali Kelas:**
- Absensi: input massal per kelas/tanggal, upsert
- Nilai: input per jenis (harian/tugas/uts/uas/akhir), massal
- Rapor: input nilai akhir + predikat + catatan wali kelas
- Pengaduan: lapor perilaku/kasus + upload bukti
- Wali Kelas: data siswa, rekap absensi, rekap nilai, catatan wali

**Guru BK:**
- Pengaduan: lihat semua (filter status), update status + tindak lanjut
- Laporan: statistik dashboard, bulanan, rekap kasus per kategori

**Kepala Madrasah:**
- Dashboard: statistik (siswa/guru/kelas/mapel), jadwal per hari, rekap absensi, distribusi nilai
- Laporan: 4 jenis (jadwal, absensi, nilai, rapor) — view only

---

## 4. Tahap Pembuatan — Frontend

### Struktur Folder
```
frontend/lib/
├── main.dart
├── config/
│   ├── env.dart                  (API URL, app name)
│   └── routes.dart               (route definitions + generate)
├── core/
│   ├── network/api_client.dart   (HTTP GET/POST/PUT/DELETE + token)
│   └── theme/app_theme.dart      (hijau-kuning-putih theme)
├── shared/
│   └── widgets/
│       ├── academic_shell.dart   (sidebar+topbar responsif)
│       └── confirm_dialog.dart
└── features/
    ├── auth/
    │   ├── providers/auth_provider.dart
    │   ├── screens/login_screen.dart    (split screen + mobile)
    │   └── widgets/login_form.dart
    ├── admin/
    │   ├── admin_page.dart              (mini sidebar)
    │   ├── dashboard/dashboard_page.dart
    │   ├── master_data/master_data_page.dart  (9 entity CRUD)
    │   └── pengaturan/pengaturan_page.dart    (users, hak akses, log, backup)
    ├── wakil_kurikulum/
    │   ├── wakil_kurikulum_page.dart
    │   ├── dashboard/dashboard_page.dart
    │   ├── penjadwalan/penjadwalan_page.dart  (timetable grid + drag-drop)
    │   ├── nilai/nilai_page.dart
    │   ├── kenaikan_kelas/kenaikan_kelas_page.dart
    │   ├── laporan/laporan_page.dart
    │   └── services/wakil_kurikulum_service.dart
    ├── guru_mapel_wali_kelas/
    │   ├── guru_mapel_page.dart
    │   ├── dashboard/dashboard_page.dart
    │   ├── absensi/absensi_page.dart
    │   ├── nilai/nilai_page.dart
    │   ├── rapor/rapor_page.dart
    │   ├── pengaduan/pengaduan_page.dart
    │   ├── wali_kelas/wali_kelas_page.dart
    │   └── services/guru_service.dart
    ├── guru_bk/
    │   ├── guru_bk_page.dart
    │   ├── dashboard/dashboard_page_bk.dart
    │   ├── pengaduan/pengaduan_page_bk.dart
    │   ├── laporan/laporan_page_bk.dart
    │   └── services/guru_bk_service.dart
    └── kepala_sekolah/
        ├── kepala_sekolah_page.dart
        ├── dashboard/dashboard_page_ks.dart
        ├── laporan/laporan_page_ks.dart
        └── services/kepala_sekolah_service.dart
```

### Fitur Frontend per Role

**Login:**
- Split screen (desktop): branding hijau→kuning + form putih
- Mobile: layout terpusat dengan icon
- Provider state management, token storage SharedPreferences
- Redirect ke dashboard sesuai role

**Admin:** Mini Sidebar (collapsible), Dashboard stat cards, CRUD dengan search/pagination/forms dropdown

**Role Akademik (WK/Guru/BK/KS):** Academic Shell (mini sidebar + topbar responsif)

**Penjadwalan (WK):** Timetable grid DataTable, LongPressDraggable, JP slot selector, filter dropdown, action buttons (Generate/Reset/Publikasi)

---

## 5. Aturan & Konvensi

- **D1 (SQLite):** Parameterized queries (`?` bindings), no ORM
- **Auth:** bcryptjs hash, JWT dengan jose library, middleware role_guard
- **RBAC:** Tabel `hak_akses_modul` menyimpan role+modul+aksi
- **Logging:** Semua write operation insert ke `log_aktivitas`
- **Siswa:** Bukan system actor (tidak login)
- **Multi Login:** Split screen design
- **Auto Scheduling:** Greedy assignment, cek bentrok guru/kelas, JP limits (Jumat JP1-4), skip slot tervalidasi

---

## 6. Cara Menjalankan

```powershell
# Terminal 1 — Backend
cd C:\PPI\backend
npm install
npm run dev

# Terminal 2 — Frontend
cd C:\PPI\frontend
flutter pub get
flutter run -d chrome
```

Backend: http://localhost:8787  
Frontend: http://localhost: (lihat output flutter run)

---

## 7. Status Penyelesaian

| Fase | Modul | Status |
|------|-------|--------|
| 1 | Project Setup + Auth | ✅ |
| 2 | Modul Admin | ✅ |
| 3 | Modul Wakil Kurikulum (dasar) | ✅ |
| 4 | Penjadwalan + Auto Scheduling | ✅ |
| 5 | Modul Guru Mapel / Wali Kelas | ✅ |
| 6 | Modul Guru BK | ✅ |
| 7 | Dashboard Kepala Madrasah | ✅ |
| 8 | Tema Hijau-Kuning-Putih | ✅ |
| - | Dokumentasi | ✅ |

---

## 8. Catatan Perubahan Tampilan

**Awal (biru):** Primary #1A73E8, Secondary #34A853, Sidebar #1E293B  
**Sekarang (hijau-kuning-putih):** Primary #2E7D32, Secondary #FDD835, Sidebar #1B5E20, Active nav kuning

---

*Dibuat: 26 Juli 2026*  
*Total file backend: ~25 file TypeScript*  
*Total file frontend: ~35 file Dart*
