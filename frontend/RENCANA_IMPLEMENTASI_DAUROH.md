# 📋 Rencana Implementasi Modul Dauroh
## Sistem Informasi Madrasah PPI

---

## 🎯 Ringkasan Implementasi

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    3 KOMPONEN UTAMA                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. ADMIN MASTER DATA                                                      │
│     └── Menu Dauroh di sidebar admin                                       │
│         ├── Program Kegiatan (CRUD)                                        │
│         ├── Musyrifah (CRUD)                                               │
│         ├── Atur Jadwal (CRUD)                                             │
│         ├── QR Code (Cetak)                                                │
│         ├── Monitoring Absensi                                             │
│         └── Monitoring Nilai                                               │
│                                                                             │
│  2. MUSYRIFAH (ROLE BARU)                                                  │
│     └── Login Musyrifah → Dashboard                                        │
│         ├── Ikon Jadwal (Lihat jadwal mengajar)                           │
│         ├── Ikon Scan QR (Absensi)                                         │
│         └── Ikon Nilai (Input/monitoring nilai)                           │
│                                                                             │
│  3. SANTRI                                                                 │
│     └── Ikon Dauroh di dashboard                                           │
│         └── Halaman sederhana (Program + Nilai)                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📁 STRUKTUR FILE

### File yang Perlu Diubah:
```
lib/features/admin/
├── admin_page.dart                    ← Tambah route Dauroh
├── master_data/
│   └── master_data_page.dart          ← Tambah menu Dauroh
└── dashboard/
    └── dashboard_page.dart            ← Tambah ikon Dauroh

lib/features/santri/
├── santri_page.dart                   ← Tambah route Dauroh santri
└── dashboard/
    └── dashboard_santri_page.dart     ← Tambah ikon Dauroh

lib/config/
└── routes.dart                        ← Tambah routes baru
```

### File yang Perlu Dibuat:
```
lib/features/admin/dauroh/
├── dauroh_page.dart                    ← Halaman utama (tab menu)
├── program_kegiatan/
│   ├── program_list_page.dart          ← List program
│   └── program_form_page.dart          ← Form tambah/edit
├── musyrifah/
│   ├── musyrifah_list_page.dart        ← List musyrifah
│   └── musyrifah_form_page.dart        ← Form tambah/edit
├── jadwal/
│   ├── jadwal_list_page.dart           ← List jadwal
│   └── jadwal_form_page.dart           ← Form tambah/edit
├── qr_code/
│   └── qr_dauroh_page.dart            ← Cetak QR Code
├── monitoring/
│   ├── absensi_monitoring_page.dart    ← Monitoring absensi
│   └── nilai_monitoring_page.dart      ← Monitoring nilai
└── services/
    └── dauroh_service.dart             ← API service

lib/features/musyrifah/ (ROLE BARU)
├── musyrifah_page.dart                 ← Halaman utama
├── dashboard/
│   └── dashboard_musyrifah_page.dart   ← Dashboard
├── jadwal/
│   └── jadwal_dauroh_page.dart         ← Lihat jadwal
├── absensi/
│   └── scan_qr_page.dart               ← Scan QR absensi
├── nilai/
│   └── nilai_dauroh_page.dart          ← Input/monitoring nilai
└── services/
    └── musyrifah_service.dart          ← API service

lib/features/santri/dauroh/
├── dauroh_santri_page.dart             ← Halaman Dauroh santri
└── services/
    └── dauroh_santri_service.dart      ← API service
```

---

## 🗄️ DATABASE SCHEMA

### 1. Program Kegiatan
```sql
CREATE TABLE dauroh_program (
  id SERIAL PRIMARY KEY,
  nama_program VARCHAR(255) NOT NULL,
  jenis_program VARCHAR(20) NOT NULL,  -- 'khusus' atau 'kelas'
  jenis_dauroh VARCHAR(20) NOT NULL,   -- 'hafalan' atau 'bacaan'
  keterangan TEXT,
  tahun_ajaran_id INTEGER REFERENCES tahun_ajaran(id),
  is_aktif BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2. Musyrifah
```sql
CREATE TABLE dauroh_musyrifah (
  id SERIAL PRIMARY KEY,
  nipmus VARCHAR(50) UNIQUE NOT NULL,
  nama VARCHAR(255) NOT NULL,
  jenis_kelamin VARCHAR(1) NOT NULL,   -- 'L' atau 'P'
  status_pendidikan VARCHAR(20) NOT NULL, -- 'selesai' atau 'mahasiswa'
  gelar VARCHAR(100),
  username VARCHAR(100) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  is_aktif BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 3. Jadwal Dauroh
```sql
CREATE TABLE dauroh_jadwal (
  id SERIAL PRIMARY KEY,
  program_id INTEGER NOT NULL REFERENCES dauroh_program(id),
  musyrifah_1_id INTEGER NOT NULL REFERENCES dauroh_musyrifah(id),
  musyrifah_2_id INTEGER REFERENCES dauroh_musyrifah(id),
  jenjang VARCHAR(50),
  hari VARCHAR(20) NOT NULL,
  jam_mulai TIME NOT NULL,
  jam_selesai TIME NOT NULL,
  is_aktif BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 4. Relasi Jadwal-Kelas
```sql
CREATE TABLE dauroh_jadwal_kelas (
  id SERIAL PRIMARY KEY,
  jadwal_id INTEGER NOT NULL REFERENCES dauroh_jadwal(id) ON DELETE CASCADE,
  kelas_id INTEGER NOT NULL REFERENCES kelas(id),
  UNIQUE(jadwal_id, kelas_id)
);
```

### 5. Program Santri (Program Khusus)
```sql
CREATE TABLE dauroh_program_santri (
  id SERIAL PRIMARY KEY,
  program_id INTEGER NOT NULL REFERENCES dauroh_program(id) ON DELETE CASCADE,
  santri_id INTEGER NOT NULL REFERENCES siswa(id),
  UNIQUE(program_id, santri_id)
);
```

### 6. Absensi Musyrifah
```sql
CREATE TABLE dauroh_absensi_musyrifah (
  id SERIAL PRIMARY KEY,
  musyrifah_id INTEGER NOT NULL REFERENCES dauroh_musyrifah(id),
  jadwal_id INTEGER NOT NULL REFERENCES dauroh_jadwal(id),
  tanggal DATE NOT NULL,
  waktu_scan TIME NOT NULL,
  status VARCHAR(10) DEFAULT 'hadir',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(musyrifah_id, jadwal_id, tanggal)
);
```

### 7. Absensi Santri
```sql
CREATE TABLE dauroh_absensi_santri (
  id SERIAL PRIMARY KEY,
  jadwal_id INTEGER NOT NULL REFERENCES dauroh_jadwal(id),
  santri_id INTEGER NOT NULL REFERENCES siswa(id),
  tanggal DATE NOT NULL,
  status VARCHAR(10) NOT NULL,  -- 'hadir', 'izin', 'sakit', 'alpha'
  keterangan TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(jadwal_id, santri_id, tanggal)
);
```

### 8. Nilai Dauroh
```sql
CREATE TABLE dauroh_nilai (
  id SERIAL PRIMARY KEY,
  program_id INTEGER NOT NULL REFERENCES dauroh_program(id),
  santri_id INTEGER NOT NULL REFERENCES siswa(id),
  nilai_hafalan DECIMAL(5,2),
  nilai_bacaan DECIMAL(5,2),
  catatan TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(program_id, santri_id)
);
```

---

## 🔌 API ENDPOINTS

### Program Kegiatan
```
GET    /api/dauroh/program              - List program
GET    /api/dauroh/program/:id          - Detail program
POST   /api/dauroh/program              - Tambah program
PUT    /api/dauroh/program/:id          - Update program
DELETE /api/dauroh/program/:id          - Hapus program
```

### Musyrifah
```
GET    /api/dauroh/musyrifah            - List musyrifah
GET    /api/dauroh/musyrifah/:id        - Detail musyrifah
POST   /api/dauroh/musyrifah            - Tambah musyrifah
PUT    /api/dauroh/musyrifah/:id        - Update musyrifah
DELETE /api/dauroh/musyrifah/:id        - Hapus musyrifah
```

### Jadwal
```
GET    /api/dauroh/jadwal               - List jadwal
GET    /api/dauroh/jadwal/:id           - Detail jadwal
POST   /api/dauroh/jadwal               - Tambah jadwal
PUT    /api/dauroh/jadwal/:id           - Update jadwal
DELETE /api/dauroh/jadwal/:id           - Hapus jadwal
```

### QR Absensi (Musyrifah)
```
POST   /api/dauroh/absensi/scan         - Scan QR (Musyrifah)
GET    /api/dauroh/monitoring/absensi   - Monitoring absensi
```

### Monitoring
```
GET    /api/dauroh/monitoring/absensi   - List absensi musyrifah
GET    /api/dauroh/monitoring/nilai     - List nilai santri
```

### Santri
```
GET    /api/dauroh/santri/program       - Program yang diikuti
GET    /api/dauroh/santri/nilai         - Nilai santri
```

---

## 🎨 DESAIN UI

### 1. Admin Master Data - Menu Dauroh

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Master Data                                                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Menu:                                                                      │
│  ├── Tahun Ajaran                                                           │
│  ├── Semester                                                               │
│  ├── Jurusan                                                                │
│  ├── Tingkat                                                                │
│  ├── Kelas                                                                  │
│  ├── Mata Pelajaran                                                         │
│  ├── Asatidz                                                                │
│  ├── Wali Kelas                                                             │
│  ├── Santri                                                                 │
│  ├── 📚 Dauroh  ← MENU BARU                                                │
│  │   ├── Program Kegiatan                                                   │
│  │   ├── Musyrifah                                                         │
│  │   ├── Atur Jadwal                                                       │
│  │   ├── QR Code                                                           │
│  │   ├── Monitoring Absensi                                                │
│  │   └── Monitoring Nilai                                                  │
│  └── Ruangan                                                                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2. Dashboard Musyrifah (Role Baru)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  👩‍🏫 Dashboard Musyrifah                                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Selamat Pagi,                                                              │
│  Siti Aminah                                                                │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  📅 Jadwal Hari Ini                                                 │   │
│  │                                                                      │   │
│  │  08:00 - 10:00  Tahfidz Juz 30 (X MIPA 1, X MIPA 2)               │   │
│  │                  [ 📷 Scan QR ]  ← TOMBOL SCAN                      │   │
│  │                                                                      │   │
│  │  13:00 - 15:00  Qira'ati (XI MIPA 1)                               │   │
│  │                  [ 📷 Scan QR ]                                      │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Menu Utama                                                         │   │
│  │                                                                      │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐                           │   │
│  │  │ 📅       │  │ 📷       │  │ 📊       │                           │   │
│  │  │ Jadwal   │  │ Scan QR  │  │ Nilai    │                           │   │
│  │  └──────────┘  └──────────┘  └──────────┘                           │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3. Dashboard Santri - Ikon Dauroh

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  📱 Dashboard Santri                                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Selamat Pagi,                                                              │
│  Ahmad Fadillah                                                             │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Menu Utama                                                         │   │
│  │                                                                      │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐            │   │
│  │  │ 📅       │  │ ✅       │  │ 📊       │  │ 📚       │            │   │
│  │  │ Jadwal   │  │ Absensi  │  │ Nilai    │  │ Materi   │            │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘            │   │
│  │                                                                      │   │
│  │  ┌──────────┐                                                       │   │
│  │  │ 📖       │  ← IKON BARU                                         │   │
│  │  │ Dauroh   │                                                       │   │
│  │  └──────────┘                                                       │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4. Halaman Dauroh Santri (Program + Nilai)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  📖 Dauroh Saya                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─ Program yang Diikuti ──────────────────────────────────────────────┐   │
│  │                                                                      │   │
│  │  📚 Tahfidz Juz 30                                                  │   │
│  │     Jenis: Hafalan                                                  │   │
│  │     Musyrifah: Siti Aminah                                          │   │
│  │     Status: ✅ Aktif                                                │   │
│  │                                                                      │   │
│  │  📚 Qira'ati                                                        │   │
│  │     Jenis: Bacaan                                                   │   │
│  │     Musyrifah: Abdul Rahman                                         │   │
│  │     Status: ✅ Aktif                                                │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─ Nilai ─────────────────────────────────────────────────────────────┐   │
│  │                                                                      │   │
│  │  Program          │ Hafalan │ Bacaan │ Catatan                       │   │
│  │  ─────────────────┼─────────┼────────┼─────────────────────────────  │   │
│  │  Tahfidz Juz 30   │ 85      │ -      │ Lumayan, teruskan!           │   │
│  │  Qira'ati         │ -       │ 90     │ Sangat bagus!                │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## ⏱️ ESTIMASI WAKTU

| Fase | Deskripsi | Waktu |
|------|-----------|-------|
| 1 | Setup Database & Backend | 3-4 hari |
| 2 | Admin - Program Kegiatan | 2-3 hari |
| 3 | Admin - Musyrifah | 1-2 hari |
| 4 | Admin - Atur Jadwal | 3-4 hari |
| 5 | Admin - QR Code & Monitoring | 2-3 hari |
| 6 | Musyrifah - Dashboard & Scan QR | 3-4 hari |
| 7 | Santri - Ikon & Halaman Dauroh | 2-3 hari |
| 8 | Testing & Bug Fix | 3-4 hari |
| **TOTAL** | | **19-27 hari** |

---

## ✅ CHECKLIST IMPLEMENTASI

### Phase 1: Database & Backend
- [ ] Buat semua tabel database
- [ ] Buat API endpoints
- [ ] Testing API

### Phase 2: Admin - Master Data
- [ ] Tambah menu Dauroh di sidebar
- [ ] Buat halaman Program Kegiatan (CRUD)
- [ ] Buat halaman Musyrifah (CRUD)
- [ ] Buat halaman Atur Jadwal
- [ ] Buat halaman QR Code (cetak)
- [ ] Buat halaman Monitoring Absensi
- [ ] Buat halaman Monitoring Nilai

### Phase 3: Musyrifah (Role Baru)
- [ ] Buat halaman login Musyrifah
- [ ] Buat dashboard Musyrifah
- [ ] Buat halaman Jadwal
- [ ] Buat halaman Scan QR
- [ ] Buat halaman Nilai

### Phase 4: Santri
- [ ] Tambah ikon Dauroh di dashboard
- [ ] Buat halaman Dauroh santri (Program + Nilai)

### Phase 5: Testing
- [ ] Test semua fungsi admin
- [ ] Test login Musyrifah
- [ ] Test scan QR
- [ ] Test halaman santri
- [ ] Fix bug

---

## 🎯 KESIMPULAN

Modul Dauroh membutuhkan:
- **8 tabel database** baru
- **20+ API endpoints**
- **15+ halaman Flutter** baru
- **1 role baru** (Musyrifah)
- **Estimasi waktu**: 3-4 minggu

**Prioritas Implementasi:**
1. Database & Backend
2. Admin Master Data
3. Musyrifah (Role Baru)
4. Santri (Ikon Dauroh)

---

**Mau saya bantu implementasi mulai dari Phase 1 (Database & Backend)?**
