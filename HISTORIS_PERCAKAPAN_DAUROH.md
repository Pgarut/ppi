# Historis Percakapan - Modul Dauroh
**Tanggal:** 6 Agustus 2026
**Model:** opencode/mimo-v2.5-free

---

## 🎯 Target Sesi Ini
Membangun Modul Dauroh untuk Sistem Informasi Madrasah PPI:
1. Admin - CRUD Program, Musyrifah, Jadwal, QR, Monitoring
2. Musyrifah - Dashboard, Jadwal, Scan QR, Absensi, Nilai, Profil
3. Santri - Program Yang Diikuti + Nilai
4. WK & Kamad - Monitoring Nilai Dauroh (Read-Only + Print)

---

## ✅ Yang Sudah Selesai

### Backend (Cloudflare Workers + D1)

#### Database (8 tabel baru + 16 index)
| Tabel | Fungsi | Migration |
|-------|--------|-----------|
| `dauroh_program` | Program kegiatan | 0010 |
| `dauroh_musyrifah` | Data musyrifah | 0010 |
| `dauroh_jadwal` | Jadwal dauroh | 0010 |
| `dauroh_jadwal_kelas` | Relasi jadwal↔kelas | 0010 |
| `dauroh_program_santri` | Relasi program↔santri | 0010 |
| `dauroh_absensi_musyrifah` | Absensi musyrifah | 0010 |
| `dauroh_absensi_santri` | Absensi santri | 0010 |
| `dauroh_nilai` | Nilai hafalan/bacaan | 0010 |
| `users` (UPDATE) | Role +musyrifah | 0011 |

#### Routes Backend
| File | Endpoint | Role | Fungsi |
|------|----------|------|--------|
| `routes/admin/dauroh.ts` | `/api/admin/dauroh/*` | Admin | CRUD program, musyrifah, jadwal, QR, monitoring |
| `routes/musyrifah/index.ts` | `/api/musyrifah/*` | Musyrifah | Dashboard, jadwal, scan QR, absensi, nilai |
| `routes/siswa/dauroh.ts` | `/api/siswa/dauroh/*` | Siswa | Program, nilai, absensi |
| `routes/wakil_kurikulum/dauroh.ts` | `/api/wakil-kurikulum/dauroh/*` | WK | Monitoring nilai (read-only + print) |
| `routes/kepala_sekolah/dauroh.ts` | `/api/kepala-sekolah/dauroh/*` | Kamad | Monitoring nilai (read-only + print) |

#### Config Backend
| File | Perubahan |
|------|-----------|
| `src/index.ts` | Import + route dispatch untuk semua role |
| `src/types.ts` | Role `musyrifah` ditambahkan |
| `wrangler.toml` | Migration tag v4 (dauroh) + v5 (musyrifah) |
| `src/db/schema.sql` | 8 tabel + 16 index ditambahkan |

### Frontend (Flutter)

#### Admin Dauroh (11 file baru)
| File | Fungsi |
|------|--------|
| `admin/dauroh/dauroh_page.dart` | Tab menu utama (6 sidebar) |
| `admin/dauroh/services/dauroh_service.dart` | API service |
| `admin/dauroh/program/program_list_page.dart` | List program |
| `admin/dauroh/program/program_form_page.dart` | Form CRUD program |
| `admin/dauroh/musyrifah/musyrifah_list_page.dart` | List musyrifah |
| `admin/dauroh/musyrifah/musyrifah_form_page.dart` | Form CRUD musyrifah |
| `admin/dauroh/jadwal/jadwal_list_page.dart` | List jadwal |
| `admin/dauroh/jadwal/jadwal_form_page.dart` | Form CRUD jadwal |
| `admin/dauroh/qr/qr_dauroh_page.dart` | QR generate + preview |
| `admin/dauroh/monitoring/absensi_monitoring_page.dart` | Monitoring absensi |
| `admin/dauroh/monitoring/nilai_monitoring_page.dart` | Monitoring nilai |
| `admin/dauroh/widgets/dauroh_table.dart` | Reusable table |
| `admin/dauroh/widgets/dauroh_form_widgets.dart` | Reusable form widgets |

#### Musyrifah (8 file baru)
| File | Fungsi |
|------|--------|
| `musyrifah/musyrifah_page.dart` | Shell utama (DashboardShell) |
| `musyrifah/services/musyrifah_service.dart` | API service |
| `musyrifah/dashboard/dashboard_musyrifah_page.dart` | Dashboard + jadwal hari ini |
| `musyrifah/jadwal/jadwal_dauroh_page.dart` | Tabel jadwal + filter hari |
| `musyrifah/absensi/scan_qr_musyrifah_page.dart` | QR Scanner (MobileScanner) |
| `musyrifah/absensi/riwayat_absensi_page.dart` | Riwayat + filter bulan |
| `musyrifah/nilai/nilai_dauroh_page.dart` | Tabel nilai + input/edit |
| `musyrifah/profil/profil_musyrifah_page.dart` | Profil musyrifah |

#### Santri Dauroh (2 file baru)
| File | Fungsi |
|------|--------|
| `santri/dauroh/dauroh_santri_page.dart` | Card program + tabel nilai |
| `santri/services/dauroh_santri_service.dart` | API service |

#### WK Dauroh (1 file baru)
| File | Fungsi |
|------|--------|
| `wakil_kurikulum/dauroh/dauroh_nilai_page.dart` | Filter + tabel + print preview |

#### Kamad Dauroh (1 file baru)
| File | Fungsi |
|------|--------|
| `kepala_sekolah/dauroh/dauroh_nilai_page_ks.dart` | Filter + tabel + print preview |

#### File yang Diubah (19 file)
| File | Perubahan |
|------|-----------|
| `config/routes.dart` | `/musyrifah` route + `dashboardByRole` case |
| `shared/models/user_model.dart` | `isMusyrifah` + `roleDisplayName` |
| `admin/admin_page.dart` | Dauroh feature registered |
| `admin/dashboard/dashboard_page.dart` | Dauroh icon |
| `santri/santri_page.dart` | Dauroh feature |
| `santri/dashboard/dashboard_santri_page.dart` | Dauroh icon |
| `wakil_kurikulum/wakil_kurikulum_page.dart` | Dauroh feature |
| `wakil_kurikulum/dashboard/dashboard_page.dart` | Dauroh icon |
| `wakil_kurikulum/services/wakil_kurikulum_service.dart` | +getDaurohFilters, +getDaurohNilai |
| `kepala_sekolah/kepala_sekolah_page.dart` | Dauroh feature |
| `kepala_sekolah/dashboard/dashboard_page_ks.dart` | Dauroh icon |
| `kepala_sekolah/services/kepala_sekolah_service.dart` | +getDaurohFilters, +getDaurohNilai |

---

## 🚀 Deployment Status

### Backend (Cloudflare Workers)
| Item | Status | Detail |
|------|--------|--------|
| Migration 0010 | ✅ | 8 tabel + 16 index |
| Migration 0011 | ✅ | Role musyrifah |
| Deploy | ✅ | `ppi-backend-production` |
| Health Check | ✅ | Database connected |

**URL Backend:**
```
https://ppi-backend-production.pgarut77.workers.dev
```

### Git
| Item | Status | Detail |
|------|--------|--------|
| Commit | ✅ | `59ba460` - 52 files, +8249 lines |
| Push | ✅ | `main` branch → github.com/Pgarut/ppi |

---

## 📊 Arsitektur Modul Dauroh

```
┌─────────────────────────────────────────────────────────────┐
│                        ADMIN                                │
├─────────────────────────────────────────────────────────────┤
│  1. CRUD Program → dauroh_program                           │
│  2. CRUD Musyrifah → dauroh_musyrifah + users               │
│  3. CRUD Jadwal → dauroh_jadwal + dauroh_jadwal_kelas       │
│  4. Generate QR → Token: PPI_DAUROH_QR_2026                 │
│  5. Monitor Absensi → dauroh_absensi_musyrifah              │
│  6. Monitor Nilai → dauroh_nilai                            │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                       MUSYRIFAH                             │
├─────────────────────────────────────────────────────────────┤
│  1. Dashboard (sapaan + jadwal hari ini)                    │
│  2. Jadwal Dauroh (tabel + filter hari)                     │
│  3. Scan QR (MobileScanner + token statis)                  │
│  4. Riwayat Absensi (tabel + filter bulan)                  │
│  5. Input/Update Nilai (dialog + filter program)            │
│  6. Profil                                                  │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                        SANTRI                               │
├─────────────────────────────────────────────────────────────┤
│  1. Card Program (nama, jenis, jadwal, musyrifah)           │
│  2. Tabel Nilai (hafalan, bacaan, catatan)                  │
│  3. Tidak ada QR scan & tidak ada jadwal                    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                WK & KAMAD (Monitoring)                      │
├─────────────────────────────────────────────────────────────┤
│  1. Filter: Jenjang + Kelas + Program + Search              │
│  2. Summary: Total, Rata Hafalan, Rata Bacaan, Dinilai      │
│  3. Tabel: No, Nama, NIS, Kelas, Program, Hafalan, Bacaan   │
│  4. Print Preview (PDF A4 Landscape)                        │
│  5. Read-Only (tidak bisa edit)                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔑 API Endpoints

### Admin
```
GET/POST/PUT/DELETE /api/admin/dauroh/program
GET/POST/PUT/DELETE /api/admin/dauroh/musyrifah
GET/POST/PUT/DELETE /api/admin/dauroh/jadwal
GET /api/admin/dauroh/qr
POST /api/admin/dauroh/qr/generate
GET /api/admin/dauroh/monitoring/absensi
GET /api/admin/dauroh/monitoring/nilai
```

### Musyrifah
```
GET /api/musyrifah/dashboard
GET /api/musyrifah/profil
GET /api/musyrifah/jadwal
POST /api/musyrifah/absensi/scan
GET /api/musyrifah/absensi/santri
GET /api/musyrifah/absensi/riwayat
GET /api/musyrifah/nilai
POST /api/musyrifah/nilai
PUT /api/musyrifah/nilai/:id
```

### Siswa
```
GET /api/siswa/dauroh/program
GET /api/siswa/dauroh/nilai
GET /api/siswa/dauroh/absensi
```

### WK
```
GET /api/wakil-kurikulum/dauroh/filters
GET /api/wakil-kurikulum/dauroh/nilai
```

### Kamad
```
GET /api/kepala-sekolah/dauroh/filters
GET /api/kepala-sekolah/dauroh/nilai
```

---

## ⚙️ Config Penting

| Item | Value |
|------|-------|
| QR Token | `PPI_DAUROH_QR_2026` |
| Backend URL | `https://ppi-backend-production.pgarut77.workers.dev` |
| D1 Database | `ppi-db-prod` (f4f8e08d-1d77-4cd4-8021-225e88ae233c) |
| Region | APAC (SIN) |
| Git Repo | https://github.com/Pgarut/ppi.git |
| Branch | `main` |
| Wrangler | 3.114.17 (outdated, update available 4.x) |

---

## 📝 Catatan Teknis

### Dart Analyzer
- **0 errors, 0 warnings** (hanya info-level: prefer_const, curly_braces)
- Packages sudah ada: `pdf: ^3.11.1`, `printing: ^5.13.4`

### TypeScript
- Error di `@types/chai` (node_modules) - bukan error kode kita
- Target lib issue -不影响 deployment

### Migration Issue
- Migration 0004 gagal karena database sudah ada dari deployment sebelumnya
- Solusi: Jalankan migration 0010 & 0011 manual via `wrangler d1 execute --file`

### Deploy Command
```bash
# Apply migrations
npx wrangler d1 execute ppi-db-prod --remote --file=migrations/0010_add_dauroh_tables.sql
npx wrangler d1 execute ppi-db-prod --remote --file=migrations/0011_add_musyrifah_role.sql

# Deploy backend
npx wrangler deploy --env production

# Health check
Invoke-WebRequest -Uri "https://ppi-backend-production.pgarut77.workers.dev/api/health"
```

---

## 🎯 Selanjutnya (Belum Dikerjakan)

1. **Deploy Frontend** - Build Flutter PWA & deploy ke Cloudflare Pages
2. **Testing** - Test semua endpoint dengan data production
3. **Seed Data** - Insert data program dauroh awal
4. **User Musyrifah** - Buat akun musyrifah pertama

---

## 💡 Design Decisions

1. **QR Code**: Token statis `PPI_DAUROH_QR_2026` (bukan dynamic per sesi)
2. **Jadwal**: Hanya ditampilkan di Musyrifah, TIDAK di Santri
3. **Santri**: Tidak scan QR, hanya lihat program + nilai
4. **WK/Kamad**: Read-only, bisa print preview ke PDF
5. **Absensi Santri**: Diinput oleh Musyrifah (bukan self-scan)
6. **Role Musyrifah**: Separate dari guru, login via `dauroh_musyrifah` + `users` table
