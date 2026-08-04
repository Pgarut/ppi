# PPI Madrasah System — Project History

> Dokumen historis lengkap: penambahan fitur, perbaikan bug, migrasi, deployment, dan rekomendasi.
> Dibuat untuk referensi AI dan pengembang.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Feature Additions](#feature-additions)
4. [Bug Fixes](#bug-fixes)
5. [Schema Changes](#schema-changes)
6. [Migration History](#migration-history)
7. [Deployment](#deployment)
8. [Recommendations](#recommendations)

---

## Project Overview

**Project**: Sistem Informasi Madrasah PPI (MA/MTs)
**Purpose**: Web-based school management system for Islamic schools
**Stack**: Flutter Web (frontend) + Cloudflare Workers + D1 SQLite (backend)

### Roles Supported
| Role | Description |
|---|---|
| `admin` | Full system access |
| `kepala_sekolah` | School principal - dashboards, approvals |
| `wakil_kurikulum` | Academic coordinator - scheduling, grades, promotions |
| `guru_mapel_wali_kelas` | Subject teacher + homeroom teacher |
| `guru_bk` | Guidance counselor |
| `siswa` | Student portal |

---

## Architecture

```
Frontend (Flutter Web)          Backend (Cloudflare Workers)
┌─────────────────────┐         ┌─────────────────────────┐
│  - Login (unified)  │   HTTPS │  - Auth (JWT)           │
│  - Dashboard Shell  │ ──────> │  - Rate Limiting        │
│  - Role-based pages │ <────── │  - D1 SQLite Database    │
│  - Responsive UI    │  JSON   │  - CORS                  │
└─────────────────────┘         └─────────────────────────┘
         │                               │
         │                               │
    Cloudflare Pages              Cloudflare Workers
    (Static Hosting)              (Edge Computing)
```

### Key Files

**Backend** (`C:\ppi\backend`):
- `src/index.ts` — Main entry, routing, auth
- `src/types.ts` — TypeScript types (Env, Role, UserPayload)
- `src/middleware/auth.ts` — JWT sign/verify, authMiddleware
- `src/middleware/rate_limit.ts` — Rate limiting, brute force protection
- `src/db/schema.sql` — Full database schema
- `src/db/migrations/v3.sql` — Production migration (ALTER TABLE + indexes)
- `wrangler.toml` — Cloudflare Workers config

**Frontend** (`C:\ppi\frontend`):
- `lib/config/env.dart` — API URL config (via `--dart-define`)
- `lib/shared/services/auth_service.dart` — Login API calls
- `lib/shared/providers/auth_provider.dart` — Auth state management
- `lib/shared/widgets/dashboard_shell.dart` — Responsive layout
- `lib/shared/widgets/dashboard_template.dart` — Dashboard cards
- `lib/features/auth/` — Login screen & form
- `lib/features/santri/` — Student portal
- `lib/features/guru_mapel_wali_kelas/` — Teacher portal

---

## Feature Additions

### 1. Student/Santri Portal

**Date**: Session work
**Files Changed**:
- Backend: `src/routes/siswa/index.ts`, `src/routes/siswa/absensi.ts`, `src/routes/siswa/nilai.ts`, `src/routes/siswa/jadwal.ts`, `src/routes/siswa/profil.ts`, `src/routes/siswa/materi.ts`
- Frontend: `lib/features/santri/` (new folder with pages)

**What was added**:
- Students can login using NIS (instead of username)
- View their own attendance (absensi)
- View grades (nilai) with 8 types: harian, tugas, uts, uas, akhir, pts1, pas, pts2, pat
- View class schedule (jadwal)
- View profile
- View learning materials (materi) with YouTube + Google Drive links

**API Endpoints**:
```
GET  /api/siswa/absensi      — Student attendance
GET  /api/siswa/nilai        — Student grades
GET  /api/siswa/jadwal       — Student schedule
GET  /api/siswa/profil       — Student profile
GET  /api/siswa/materi       — Materials grouped by subject
GET  /api/siswa/materi/:id   — Material detail
```

### 2. Unified Login

**Date**: Session work
**Problem**: Original design had separate login forms for Admin/Guru and Siswa with a toggle button
**Solution**: Single login form that auto-detects role

**Files Changed**:
- Backend: `src/index.ts` — `handleLogin` tries username → fallback to NIS
- Frontend: `lib/shared/services/auth_service.dart` — `login(credential, password)`
- Frontend: `lib/shared/providers/auth_provider.dart` — `login()` method
- Frontend: `lib/features/auth/widgets/login_form.dart` — Removed toggle
- Frontend: `lib/features/auth/screens/login_screen.dart` — Simplified

**Login Flow**:
```
1. User enters "username_or_nis" + password
2. Backend checks users table (by username)
3. If not found, checks siswa table (by NIS)
4. Returns JWT with role info
5. Frontend routes to appropriate dashboard
```

**Test Credentials**:
| Username/NIS | Password | Role |
|---|---|---|
| `admin019` | `ppi019g` | admin |

### 3. Complete Materi (Learning Materials) Feature

**Date**: Session work
**Problem**: Materi feature was incomplete — no YouTube support, no material listing for students
**Solution**: Full CRUD for teachers, two-level navigation for students

**Files Changed**:
- Backend: `src/routes/guru_mapel_wali_kelas/materi.ts` — CRUD with YouTube, toggle, assignments
- Backend: `src/routes/siswa/materi.ts` — Grouped by subject
- Frontend: `lib/features/guru_mapel_wali_kelas/materi/materi_page.dart` — Teacher view
- Frontend: `lib/features/santri/materi/materi_santri_page.dart` — Student view

**Teacher Features**:
- Create/edit/delete materi
- Set Google Drive link (`link_url`)
- Set YouTube link (`link_youtube`)
- Set pertemuan (session number)
- Toggle active/inactive
- Assign to specific classes

**Student Features**:
- Level 1: List of subjects with active materi count
- Level 2: Detail per subject — YouTube video embed + Google Drive download

**Schema**:
```sql
CREATE TABLE materi (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    guru_id             INTEGER NOT NULL REFERENCES guru(id),
    mata_pelajaran_id   INTEGER NOT NULL REFERENCES mata_pelajaran(id),
    kelas_id            INTEGER NOT NULL REFERENCES kelas(id),
    judul               TEXT NOT NULL,
    deskripsi           TEXT,
    link_url            TEXT NOT NULL,       -- Google Drive link
    link_youtube        TEXT,                -- YouTube link (optional)
    pertemuan           TEXT,                -- Session number/label
    is_aktif            INTEGER NOT NULL DEFAULT 1,
    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT NOT NULL DEFAULT (datetime('now'))
);
```

### 4. Nilai (Grades) with 8 Types

**Date**: Session work
**Problem**: CHECK constraint on `nilai.jenis` only allowed 4 types (harian, tugas, uts, uas)
**Solution**: Extended to 9 types including Indonesian semester exam types

**Added Types**:
| Type | Description |
|---|---|
| `harian` | Daily test |
| `tugas` | Assignment |
| `uts` | Mid-semester exam |
| `uas` | Final exam |
| `akhir` | Final grade |
| `pts1` | Penilaian Tengah Semester 1 |
| `pas` | Penilaian Akhir Semester |
| `pts2` | Penilaian Tengah Semester 2 |
| `pat` | Penilaian Akhir Tahun |

**Frontend**: `nilai_santri_page.dart` uses `Wrap` widget to show only non-zero values

---

## Bug Fixes

### 1. Missing Schema Columns

**Problem**: `schema.sql` was missing columns that code expected:
- `guru_mata_pelajaran.hari_aktif`
- `guru_mata_pelajaran.jp_max_per_hari`
- `guru_mata_pelajaran.jp_max_per_minggu`
- `absensi_siswa.jam`

**Fix**: Added columns to `schema.sql`

### 2. Nilai Jenis Mismatch

**Problem**: Backend code used `pts1, pas, pts2, pat` but schema CHECK constraint only allowed `harian, tugas, uts, uas, akhir`

**Fix**: Updated CHECK constraint in `schema.sql`:
```sql
jenis TEXT NOT NULL CHECK (jenis IN (
    'harian','tugas','uts','uas','akhir',
    'pts1','pas','pts2','pat'
))
```

### 3. Backup/Restore Missing Tables

**Problem**: `system.ts` backup/restore didn't include `materi` and `mapel_kelas` tables

**Fix**: Added both tables to the tables list in `src/routes/admin/system.ts`

### 4. Flutter Analyze Warnings

**Problem**: Multiple `prefer_const_constructors` warnings across codebase

**Fix**: Added `const` to constructors in:
- `dashboard_shell.dart`
- `dashboard_template.dart`
- Various page files

### 5. Widget Test Mismatch

**Problem**: `widget_test.dart` and `login_form_test.dart` had outdated assertions after login form changes

**Fix**: Updated assertions to match "Username / NIS" label

---

## Schema Changes

### Full Schema (schema.sql)

**Tables created** (34 total):
1. `users` — Authentication (with `siswa_id` for student role)
2. `hak_akses_modul` — Module access permissions
3. `log_aktivitas` — Activity audit log
4. `tahun_ajaran` — Academic years
5. `semester` — Semesters (Ganjil/Genap)
6. `jurusan` — Departments/majors
7. `tingkat` — Grade levels (VII, VIII, IX, X, XI, XII)
8. `ruangan` — Classrooms
9. `mata_pelajaran` — Subjects
10. `mapel_kelas` — Subject-class assignments
11. `guru` — Teachers
12. `guru_mapel` — Teacher-subject assignments
13. `guru_kelas` — Teacher-class assignments
14. `kelas` — Classes
15. `siswa` — Students
16. `guru_mata_pelajaran` — Teaching assignments (with schedule limits)
17. `jadwal_pelajaran` — Class schedules
18. `absensi_guru` — Teacher attendance
19. `absensi_siswa` — Student attendance
20. `bobot_nilai` — Grade weightings
21. `nilai` — Grades (9 types)
22. `nilai_rapor` — Report card grades
23. `rapor_arsip` — Report card archives
24. `materi` — Learning materials
25. `pengaduan` — Complaints/reports
26. `jadwal_konseling` — Counseling schedules
27. `konseling` — Counseling records
28. `bakat_minat` — Talents & interests
29. `pengaturan` — System settings
30. `kenaikan_kelas` — Class promotions
31. `alumni` — Alumni data
32. `pengaturan_kenaikan_kelas` — Promotion rules

### Indexes (15 custom)

```sql
-- Student performance
idx_siswa_kelas          ON siswa(kelas_id)
idx_nilai_siswa          ON nilai(siswa_id, semester_id)
idx_nilai_diinput        ON nilai(diinput_oleh)

-- Attendance
idx_absensi_siswa_tgl    ON absensi_siswa(siswa_id, tanggal)
idx_absensi_kelas_tgl    ON absensi_siswa(kelas_id, tanggal)
idx_absensi_guru_tgl     ON absensi_guru(guru_id, tanggal)

-- Scheduling
idx_jadwal_kelas         ON jadwal_pelajaran(kelas_id, semester_id)
idx_jadwal_guru          ON jadwal_pelajaran(guru_id, semester_id)
idx_jadwal_hari          ON jadwal_pelajaran(hari, guru_id)

-- Materials
idx_materi_guru          ON materi(guru_id)
idx_materi_kelas         ON materi(kelas_id, is_aktif)

-- Complaints
idx_pengaduan_siswa      ON pengaduan(siswa_id)
idx_pengaduan_pelapor    ON pengaduan(dilaporkan_oleh)
idx_pengaduan_status     ON pengaduan(status)

-- Counseling
idx_konseling_siswa      ON konseling(siswa_id)
```

---

## Migration History

### v1 — Initial Schema
- All tables created
- Basic indexes

### v2 — Added Features
- Additional tables/indexes

### v3 — Student Portal & Fixes (Latest)

**File**: `src/db/migrations/v3.sql`

**Changes**:
```sql
-- Add missing columns
ALTER TABLE guru_mata_pelajaran ADD COLUMN hari_aktif TEXT DEFAULT '[]';
ALTER TABLE guru_mata_pelajaran ADD COLUMN jp_max_per_hari INTEGER DEFAULT 8;
ALTER TABLE guru_mata_pelajaran ADD COLUMN jp_max_per_minggu INTEGER DEFAULT 24;
ALTER TABLE absensi_siswa ADD COLUMN jam TEXT;

-- Create materi table
CREATE TABLE IF NOT EXISTS materi (...);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_nilai_diinput ON nilai(diinput_oleh);
CREATE INDEX IF NOT EXISTS idx_absensi_kelas_tgl ON absensi_siswa(kelas_id, tanggal);
-- ... (7 more indexes)
```

**How to apply**:
```bash
# Production
npx wrangler d1 execute ppi-db-prod --remote --file=src/db/migrations/v3.sql

# Staging
npx wrangler d1 execute ppi-db-staging --remote --file=src/db/migrations/v3.sql
```

---

## Deployment

### 1. D1 Database Setup

```bash
# List databases
npx wrangler d1 list

# Create new database
npx wrangler d1 create ppi-db-prod

# Apply schema
npx wrangler d1 execute ppi-db-prod --remote --file=src/db/schema.sql

# Apply migration
npx wrangler d1 execute ppi-db-prod --remote --file=src/db/migrations/v3.sql
```

**Production Database**:
| Field | Value |
|---|---|
| Name | `ppi-db-prod` |
| UUID | `f4f8e08d-1d77-4cd4-8021-225e88ae233c` |
| Tables | 34 |
| Size | ~300 KB |

### 2. JWT Secrets

```bash
# Set JWT_SECRET
npx wrangler secret put JWT_SECRET --env production

# Set JWT_REFRESH_SECRET (optional)
npx wrangler secret put JWT_REFRESH_SECRET --env production

# List secrets
npx wrangler secret list --env production
```

**Production Secrets**:
| Secret | Status |
|---|---|
| `JWT_SECRET` | ✅ Set |
| `JWT_REFRESH_SECRET` | ✅ Set |

### 3. Backend Deployment

```bash
# Build check (dry run)
npx wrangler deploy --dry-run --outdir=./dist

# Deploy to production
npx wrangler deploy --env production
```

**Production Backend**:
| Field | Value |
|---|---|
| URL | `https://ppi-backend-production.pgarut77.workers.dev` |
| Startup | ~25 ms |
| Size | 264 KB (gzip) |

**CORS_ORIGIN**:
```
https://ppi-bo8.pages.dev,https://f1198d05.ppi-bo8.pages.dev,https://ppi-frontend.pages.dev
```

### 4. Frontend Deployment

```bash
# Build with production API URL
flutter build web --dart-define=API_BASE_URL=https://ppi-backend-production.pgarut77.workers.dev --release

# Deploy to Cloudflare Pages
npx wrangler pages deploy build/web --project-name=ppi
```

**Production Frontend**:
| Field | Value |
|---|---|
| URL | `https://ppi-bo8.pages.dev` |
| Preview | `https://f1198d05.ppi-bo8.pages.dev` |

### 5. Admin User Creation

```bash
# Generate bcrypt hash
node -e "const bcrypt = require('bcryptjs'); bcrypt.hash('ppi019g', 10).then(h => console.log(h))"

# Insert into D1 (escape $ in PowerShell)
$hash = '$2a$10$...'
$sql = "INSERT INTO users (username, password_hash, role, is_active) VALUES ('admin019', '$hash', 'admin', 1);"
npx wrangler d1 execute ppi-db-prod --remote --command $sql
```

**Admin Credentials**:
| Field | Value |
|---|---|
| Username | `admin019` |
| Password | `ppi019g` |
| Role | `admin` |

---

## Recommendations

### Security

1. **Change default admin password** after first login
2. **Use strong JWT secrets** (64+ characters, mixed case + symbols)
3. **Enable HTTPS-only** for all endpoints
4. **Set CORS_ORIGIN** to specific domains (not `*`)
5. **Implement CSRF protection** for state-changing operations
6. **Add rate limiting** per user role (not just global)

### Performance

1. **Add more indexes** as query patterns emerge
2. **Implement pagination** for large datasets (siswa, nilai, absensi)
3. **Use Cloudflare Cache API** for read-heavy endpoints
4. **Consider D1 Read Replicas** for high-traffic scenarios

### Features to Add

1. **Password reset** flow (email or admin-initiated)
2. **Two-factor authentication** for admin
3. **Bulk import/export** for all data types
4. **PDF generation** for rapor, reports
5. **Email notifications** for important events
6. **Mobile app** (Flutter native)
7. **Offline support** (Service Worker for PWA)

### Testing

1. **Widget tests** — Currently 106 tests passing
2. **Integration tests** — Add for critical flows (login, CRUD)
3. **API tests** — Test all endpoints with different roles
4. **Load testing** — Test D1 under concurrent writes

### Code Quality

1. **Error handling** — Consistent error responses across all endpoints
2. **Input validation** — Server-side validation for all inputs
3. **Logging** — Structured logging for debugging
4. **Documentation** — OpenAPI/Swagger for API docs

---

## Git History Summary

### Files Modified (This Session)

**Backend**:
- `src/index.ts` — Unified login, siswa routes
- `src/types.ts` — Added siswa_id, 'siswa' role
- `src/db/schema.sql` — Added columns, materi table, indexes
- `src/db/migrations/v3.sql` — NEW: production migration
- `src/routes/siswa/*.ts` — NEW: student API endpoints
- `src/routes/guru_mapel_wali_kelas/materi.ts` — NEW: CRUD with YouTube
- `src/routes/admin/system.ts` — Updated backup/restore tables
- `wrangler.toml` — CORS_ORIGIN, staging D1 placeholder

**Frontend**:
- `lib/config/env.dart` — API URL config
- `lib/shared/services/auth_service.dart` — Unified login
- `lib/shared/providers/auth_provider.dart` — Removed loginSiswa
- `lib/shared/widgets/dashboard_shell.dart` — Added Materi menu
- `lib/shared/widgets/dashboard_template.dart` — const constructors
- `lib/features/auth/widgets/login_form.dart` — Removed toggle
- `lib/features/auth/screens/login_screen.dart` — Simplified
- `lib/features/santri/` — NEW: student portal pages
- `lib/features/guru_mapel_wali_kelas/materi/` — NEW: teacher materi
- `lib/features/guru_mapel_wali_kelas/dashboard/dashboard_page.dart` — Materi icon
- `pubspec.yaml` — Added url_launcher
- `test/widget_test.dart` — Updated assertions
- `test/widgets/dashboard_template_test.dart` — NEW: 5 tests
- `test/widgets/common_widgets_test.dart` — NEW: 2 tests
- `test/services/santri_service_test.dart` — NEW: 1 test

### Test Results

| Check | Result |
|---|---|
| `flutter analyze` | 0 errors, 0 warnings |
| `flutter test` | 106/106 passed |
| TypeScript compile | 0 errors |

---

## Lessons Learned

1. **D1 `--command` only executes single statement** — Use `--file` for batch SQL
2. **D1 `PRAGMA foreign_keys` doesn't persist** across wrangler commands — Drop tables in FK order
3. **Flutter `--dart-define`** is compile-time — Must rebuild to change API URL
4. **PowerShell interprets `$`** as variables — Escape with single quotes or variables
5. **Cloudflare Workers CORS** must be updated via wrangler.toml + redeploy
6. **D1 batch upload** can fail with SQLITE_AUTH if not logged in properly

---

*Last updated: 2026-08-04*
*Session: PPI Madrasah System — Full Stack Deployment*
