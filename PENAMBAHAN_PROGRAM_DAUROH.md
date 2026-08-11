# Perencanaan Modul Dauroh: Program Murojaah & Tahfidz

**Versi:** 1.0  
**Tanggal:** 10 Agustus 2026  
**Status:** Disetujui

---

## 📋 Ringkasan Eksekutif

| Komponen | Murojaah | Tahfidz |
|----------|----------|---------|
| **Definisi** | Mengulang hafalan yang sudah pernah hafal | Menghafal surat baru untuk pertama kali |
| **Target** | Memperbaiki & mempertahankan hafalan | Mencapai target hafalan baru |
| **Skema Penilaian** | 3 Bidang (40+30+30) | 3 Bidang (40+30+30) |
| **Status Khusus** | Mengulang (skip penilaian) | Tidak ada |

---

## 🏗️ ARSITEKTUR MODUL

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    MODUL DAUROH - ARSITEKTUR                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         PROGRAM DAUROH                              │   │
│  │                                                                     │   │
│  │    ┌─────────────────┐              ┌─────────────────┐            │   │
│  │    │   MUROJAAH      │              │    TAHFIDZ      │            │   │
│  │    │                 │              │                 │            │   │
│  │    │ • Mengulang     │              │ • Hafalan baru  │            │   │
│  │    │ • Perbaikan     │              │ • Target awal   │            │   │
│  │    │ • Konsolidasi   │              │ • Progressif    │            │   │
│  │    └─────────────────┘              └─────────────────┘            │   │
│  │                                                                     │   │
│  │    ┌─────────────────────────────────────────────────────────┐     │   │
│  │    │              SKEMA PENILAIAN SAMA                       │     │   │
│  │    │                                                         │     │   │
│  │    │  Bidang 1: Kelancaran Hafalan (Max 40)                 │     │   │
│  │    │  Bidang 2: Tajwid (Max 30)                             │     │   │
│  │    │  Bidang 3: Fashohah dan Adab (Max 30)                  │     │   │
│  │    │                                                         │     │   │
│  │    │  Status: Mengulang | Melanjutkan | Selesai              │     │   │
│  │    └─────────────────────────────────────────────────────────┘     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         USER ROLES                                 │   │
│  │                                                                     │   │
│  │  ┌───────────┐    ┌───────────┐    ┌───────────┐                  │   │
│  │  │   ADMIN   │    │MUSYRIFAH  │    │  SANTRI   │                  │   │
│  │  │           │    │           │    │           │                  │   │
│  │  │ • Setup   │    │ • Input   │    │ • Lihat   │                  │   │
│  │  │ • Monitor │    │ • Absensi │    │ • Progress│                  │   │
│  │  │ • Export  │    │ • Nilai   │    │ • Riwayat │                  │   │
│  │  └───────────┘    └───────────┘    └───────────┘                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 👨‍💼 FITUR ADMIN

### 1. Setup Program

#### 1.1 Buat Program Baru

| Field | Tipe | Validasi | Keterangan |
|-------|------|----------|------------|
| Nama Program | Text | Wajib | Contoh: "Tahfidz Kelas VII-A" |
| Jenis Program | Radio | Wajib | Kelas / Khusus |
| Jenis Dauroh | Radio | Wajib | Murojaah / Tahfidz |
| Skema Penilaian | Dropdown | Wajib | Standar / Sederhana / Custom |
| Tahun Ajaran | Dropdown | Wajib | 2025/2026 |
| Keterangan | Text | Opsional | Deskripsi program |
| Aktif | Toggle | Wajib | Status aktif/nonaktif |

#### 1.2 Konfigurasi Skema Penilaian

| Field | Default | Keterangan |
|-------|---------|------------|
| Label Bidang 1 | Kelancaran Hafalan | Bisa diubah |
| Max Bidang 1 | 40 | Bisa diubah |
| Label Bidang 2 | Tajwid | Bisa diubah |
| Max Bidang 2 | 30 | Bisa diubah |
| Label Bidang 3 | Fashohah dan Adab | Bisa diubah |
| Max Bidang 3 | 30 | Bisa diubah |

### 2. Assign Musyrifah

| Field | Tipe | Validasi | Keterangan |
|-------|------|----------|------------|
| NIP | Text | Wajib, Unique | Nomor Induk Pegawai |
| Nama | Text | Wajib | Nama lengkap |
| Jenis Kelamin | Radio | Wajib | Laki-laki / Perempuan |
| No HP | Text | Wajib | Nomor handphone |
| Username | Text | Wajib, Unique | Untuk login |
| Password | Password | Wajib | Minimal 8 karakter |
| Status | Toggle | Wajib | Aktif / Nonaktif |

### 3. Atur Jadwal

| Field | Tipe | Validasi | Keterangan |
|-------|------|----------|------------|
| Program | Dropdown | Wajib | Pilih program |
| Musyrifah 1 | Dropdown | Wajib | Musyrifah utama |
| Musyrifah 2 | Dropdown | Opsional | Musyrifah pendamping |
| Hari | Checkbox | Wajib | Senin - Jumat |
| Jam Mulai | Time | Wajib | Format: HH:MM |
| Jam Selesai | Time | Wajib | Format: HH:MM |
| Kelas | Checkbox | Wajib | Kelas yang diampu |
| Surat | Dropdown | Wajib | Target hafalan |
| Dari Ayat | Number | Wajib | Ayat awal |
| Sampai Ayat | Number | Wajib | Ayat akhir |

### 4. Assign Santri ke Program

| Field | Tipe | Validasi | Keterangan |
|-------|------|----------|------------|
| Program | Dropdown | Wajib | Pilih program |
| Kelas | Dropdown | Wajib | Filter kelas |
| Santri | Checkbox | Wajib | Pilih santri |

### 5. Monitoring & Export

#### 5.1 Monitoring Nilai

| Filter | Opsi |
|--------|------|
| Program | Semua / Pilih Program |
| Kelas | Semua / Pilih Kelas |
| Status | Semua / Mengulang / Melanjutkan / Selesai |
| Search | Nama santri |

| Aksi | Keterangan |
|------|------------|
| Export Excel | Download file .xlsx |
| Download PDF | Download file .pdf |
| Print | Cetak langsung |

#### 5.2 Generate QR Code

| Field | Keterangan |
|-------|------------|
| Pilih Jadwal | Jadwal yang aktif |
| QR Code | Auto-generated |
| Berlaku | Selama jam mengajar |

---

## 👨‍🏫 FITUR MUSYRIFAH

### 1. Login & Dashboard

| Komponen | Keterangan |
|----------|------------|
| Login Form | Username + Password |
| Dashboard | Statistik jadwal, santri, nilai |
| Jadwal Hari Ini | Daftar jadwal aktif |

### 2. Absensi

#### 2.1 QR Code Absensi

| Komponen | Keterangan |
|----------|------------|
| QR Code | Auto-generated per jadwal |
| Berlaku | Selama jam mengajar |
| Hadir | Counter santri yang sudah scan |

#### 2.2 Manual Absensi

| Field | Tipe | Keterangan |
|-------|------|------------|
| Nama Santri | Text | Auto-fill dari jadwal |
| Status | Dropdown | Hadir / Izin / Sakit / Alpa |
| Keterangan | Text | Opsional |

### 3. Input Penilaian

#### 3.1 Pilih Mode Input

| Mode | Cocok Untuk | Keterangan |
|------|-------------|------------|
| Card | Mobile/HP | Input per santri, swipe untuk lanjut |
| Batch | Tablet/Desktop | Input untuk semua sekaligus |

#### 3.2 Metadata Hafalan

| Field | Tipe | Validasi | Keterangan |
|-------|------|----------|------------|
| Nama Santri | Dropdown | Wajib | Santri yang dinilai |
| Program | Dropdown | Wajib | Program yang diikuti |
| Surat | Dropdown | Wajib | Surat yang dihafal |
| Dari Ayat | Number | Wajib | Ayat awal |
| Sampai Ayat | Number | Wajib | Ayat akhir |
| Status | Radio | Wajib | Mengulang / Melanjutkan / Selesai |

#### 3.3 Form Penilaian (Status: Melanjutkan/Selesai)

**Bidang 1: Kelancaran Hafalan (Max 40)**

| No | Kriteria | Skala |
|----|----------|-------|
| 01 | Kelancaran (tanpa tersendat) | 1-5 |
| 02 | Ketepatan Ayat (tidak tertukar/lompat ayat) | 1-5 |
| 03 | Muroja'ah Sambung Ayat | 1-5 |
| 04 | Konsistensi Hafalan (tidak talqin/dibantu) | 1-5 |

**Bidang 2: Tajwid (Max 30)**

| No | Kriteria | Skala |
|----|----------|-------|
| 01 | Makhorijul Huruf | 1-5 |
| 02 | Sifatul Huruf | 1-5 |
| 03 | Ahkamul Huruf | 1-5 |
| 04 | Ahkamul Madd wal Qoshr | 1-5 |

**Bidang 3: Fashohah dan Adab (Max 30)**

| No | Kriteria | Skala |
|----|----------|-------|
| 01 | Ahkamul Waqfi wal Ibtida' | 1-5 |
| 02 | Adabut Tilawah | 1-5 |
| 03 | Kerapihan Bacaan | 1-5 |
| 04 | Ketepatan Tempo dan Bacaan | 1-5 |

**Catatan per Bidang:** Text (opsional)

**Catatan Umum:** Text (opsional)

#### 3.4 Form Penilaian (Status: Mengulang)

| Field | Tipe | Validasi | Keterangan |
|-------|------|----------|------------|
| Alasan Mengulang | Text | Wajib | Kenapa perlu mengulang |
| Rencana Tindak Lanjut | Radio | Wajib | Opsi tindak lanjut |

**Opsi Rencana Tindak Lanjut:**
- Ulang minggu depan (ayat sama)
- Perlu bimbingan khusus musyrifah
- Koordinasi dengan guru BK

#### 3.5 Auto-Calculation

```
Nilai Bidang 1 = 40 - (Kelancaran + Ketepatan + Murojaah + Konsistensi)
Nilai Bidang 2 = 30 - (Makhorijul + Sifatul + Ahkamul Huruf + Ahkamul Madd)
Nilai Bidang 3 = 30 - (Waqfi + Adabut + Kerapihan + Ketepatan Tempo)
Total Nilai = Bidang 1 + Bidang 2 + Bidang 3
```

#### 3.6 Quick Actions (Mode Batch)

| Aksi | Keterangan |
|------|------------|
| Isi Semua: 3 | Set semua skor jadi 3 |
| Isi Semua: 4 | Set semua skor jadi 4 |
| Isi Semua: 5 | Set semua skor jadi 5 |
| Reset Semua | Kosongkan semua input |

---

## 🎓 FITUR SANTRI

### 1. Menu Dauroh

| Menu | Keterangan |
|------|------------|
| Program Aktif | Info program yang diikuti |
| Nilai & Hafalan | Lihat nilai dan progress |
| Jadwal | Lihat jadwal mengajar |
| Absensi | Lihat riwayat kehadiran |

### 2. Lihat Nilai & Progress

| Komponen | Keterangan |
|----------|------------|
| Progress Bar | Visual progress hafalan |
| Riwayat Penilaian | Daftar semua penilaian |
| Rata-rata Nilai | Rata-rata keseluruhan |
| Download PDF | Download riwayat dalam PDF |

### 3. Detail Penilaian

| Komponen | Keterangan |
|----------|------------|
| Metadata | Surat, ayat, status, tanggal |
| Bidang 1 | Detail skor kelancaran |
| Bidang 2 | Detail skor tajwid |
| Bidang 3 | Detail skor fashohah |
| Total | Total nilai akhir |
| Catatan | Catatan dari musyrifah |

---

## 🗄️ DATABASE SCHEMA

### Tabel: dauroh_program

```sql
CREATE TABLE dauroh_program (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nama_program TEXT NOT NULL,
    jenis_program TEXT NOT NULL CHECK(jenis_program IN ('kelas', 'khusus')),
    jenis_dauroh TEXT NOT NULL CHECK(jenis_dauroh IN ('murojaah', 'tahfidz')),
    skema_penilaian TEXT DEFAULT 'murojaah_tahfidz',
    keterangan TEXT,
    tahun_ajaran_id INTEGER REFERENCES tahun_ajaran(id),
    is_aktif INTEGER DEFAULT 1,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
);
```

### Tabel: dauroh_surat

```sql
CREATE TABLE dauroh_surat (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nomor INTEGER NOT NULL UNIQUE,
    nama TEXT NOT NULL,
    nama_arab TEXT,
    jumlah_ayat INTEGER NOT NULL,
    juz INTEGER NOT NULL,
    type TEXT NOT NULL CHECK(type IN ('makkiyah', 'madaniyah')),
    created_at TEXT DEFAULT (datetime('now'))
);
```

### Tabel: dauroh_nilai (Enhanced)

```sql
CREATE TABLE dauroh_nilai (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    
    -- Foreign Keys
    program_id INTEGER NOT NULL REFERENCES dauroh_program(id),
    santri_id INTEGER NOT NULL REFERENCES siswa(id),
    jadwal_id INTEGER REFERENCES dauroh_jadwal(id),
    
    -- Metadata Hafalan
    surat_nomor INTEGER REFERENCES dauroh_surat(nomor),
    dari_ayat INTEGER,
    sampai_ayat INTEGER,
    status_hafalan TEXT NOT NULL DEFAULT 'melanjutkan' 
        CHECK(status_hafalan IN ('mengulang', 'melanjutkan', 'selesai')),
    
    -- Bidang 1: Kelancaran Hafalan (Max 40)
    kelancaran INTEGER CHECK(kelancaran BETWEEN 1 AND 5),
    ketepatan_ayat INTEGER CHECK(ketepatan_ayat BETWEEN 1 AND 5),
    murojaah_sambung INTEGER CHECK(murojaah_sambung BETWEEN 1 AND 5),
    konsistensi_hafalan INTEGER CHECK(konsistensi_hafalan BETWEEN 1 AND 5),
    catatan_bidang1 TEXT,
    
    -- Bidang 2: Tajwid (Max 30)
    makhorijul_huruf INTEGER CHECK(makhorijul_huruf BETWEEN 1 AND 5),
    sifatul_huruf INTEGER CHECK(sifatul_huruf BETWEEN 1 AND 5),
    ahkamul_huruf INTEGER CHECK(ahkamul_huruf BETWEEN 1 AND 5),
    ahkamul_madd INTEGER CHECK(ahkamul_madd BETWEEN 1 AND 5),
    catatan_bidang2 TEXT,
    
    -- Bidang 3: Fashohah dan Adab (Max 30)
    ahkamul_waqfi INTEGER CHECK(ahkamul_waqfi BETWEEN 1 AND 5),
    adabut_tilawah INTEGER CHECK(adabut_tilawah BETWEEN 1 AND 5),
    kerapihan_bacaan INTEGER CHECK(kerapihan_bacaan BETWEEN 1 AND 5),
    ketepatan_tempo INTEGER CHECK(ketepatan_tempo BETWEEN 1 AND 5),
    catatan_bidang3 TEXT,
    
    -- Catatan
    catatan_umum TEXT,
    rencana_tindak_lanjut TEXT,
    
    -- Computed Columns
    nilai_bidang1 INTEGER GENERATED ALWAYS AS (
        40 - COALESCE(kelancaran, 0) - COALESCE(ketepatan_ayat, 0) - 
        COALESCE(murojaah_sambung, 0) - COALESCE(konsistensi_hafalan, 0)
    ) STORED,
    
    nilai_bidang2 INTEGER GENERATED ALWAYS AS (
        30 - COALESCE(makhorijul_huruf, 0) - COALESCE(sifatul_huruf, 0) - 
        COALESCE(ahkamul_huruf, 0) - COALESCE(ahkamul_madd, 0)
    ) STORED,
    
    nilai_bidang3 INTEGER GENERATED ALWAYS AS (
        30 - COALESCE(ahkamul_waqfi, 0) - COALESCE(adabut_tilawah, 0) - 
        COALESCE(kerapihan_bacaan, 0) - COALESCE(ketepatan_tempo, 0)
    ) STORED,
    
    total_nilai INTEGER GENERATED ALWAYS AS (
        (40 - COALESCE(kelancaran, 0) - COALESCE(ketepatan_ayat, 0) - 
         COALESCE(murojaah_sambung, 0) - COALESCE(konsistensi_hafalan, 0)) +
        (30 - COALESCE(makhorijul_huruf, 0) - COALESCE(sifatul_huruf, 0) - 
         COALESCE(ahkamul_huruf, 0) - COALESCE(ahkamul_madd, 0)) +
        (30 - COALESCE(ahkamul_waqfi, 0) - COALESCE(adabut_tilawah, 0) - 
         COALESCE(kerapihan_bacaan, 0) - COALESCE(ketepatan_tempo, 0))
    ) STORED,
    
    -- Audit
    diinput_oleh INTEGER REFERENCES dauroh_musyrifah(id),
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    
    UNIQUE(program_id, santri_id, surat_nomor, dari_ayat, sampai_ayat)
);
```

---

## 📡 API ENDPOINTS

### Admin API

```
GET    /admin/dauroh/program              - List programs
POST   /admin/dauroh/program              - Create program
GET    /admin/dauroh/program/:id          - Get program detail
PUT    /admin/dauroh/program/:id          - Update program
DELETE /admin/dauroh/program/:id          - Delete program

GET    /admin/dauroh/musyrifah            - List musyrifah
POST   /admin/dauroh/musyrifah            - Create musyrifah
GET    /admin/dauroh/musyrifah/:id        - Get musyrifah detail
PUT    /admin/dauroh/musyrifah/:id        - Update musyrifah
DELETE /admin/dauroh/musyrifah/:id        - Delete musyrifah

GET    /admin/dauroh/jadwal               - List jadwal
POST   /admin/dauroh/jadwal               - Create jadwal
PUT    /admin/dauroh/jadwal/:id           - Update jadwal
DELETE /admin/dauroh/jadwal/:id           - Delete jadwal

GET    /admin/dauroh/monitoring/nilai     - Monitor nilai
GET    /admin/dauroh/monitoring/absensi   - Monitor absensi
GET    /admin/dauroh/monitoring/export    - Export PDF/Excel
```

### Musyrifah API

```
GET    /musyrifah/dashboard               - Dashboard data
GET    /musyrifah/jadwal                  - List jadwal
GET    /musyrifah/jadwal/:id              - Jadwal detail

POST   /musyrifah/absensi/scan            - Scan QR absensi
POST   /musyrifah/absensi/santri          - Manual absensi
GET    /musyrifah/absensi                 - List absensi

GET    /musyrifah/nilai                   - List nilai
POST   /musyrifah/nilai                   - Input nilai
PUT    /musyrifah/nilai/:id               - Update nilai
GET    /musyrifah/nilai/:id               - Nilai detail
GET    /musyrifah/riwayat/:santri_id      - Riwayat hafalan

GET    /musyrifah/surat                   - List 114 surat
GET    /musyrifah/surat/:nomor            - Surat detail
```

### Santri API

```
GET    /siswa/dauroh/program              - Program aktif
GET    /siswa/dauroh/nilai                - Nilai saya
GET    /siswa/dauroh/riwayat              - Riwayat hafalan
GET    /siswa/dauroh/absensi              - Absensi saya
GET    /siswa/dauroh/jadwal               - Jadwal saya
```

---

## 📁 FILE STRUCTURE

```
backend/
├── migrations/
│   └── 0016_enhance_dauroh_nilai.sql
├── src/
│   ├── db/
│   │   ├── schema.sql
│   │   └── seed_dauroh_surat.sql
│   ├── routes/
│   │   ├── admin/dauroh.ts
│   │   ├── musyrifah/index.ts
│   │   └── siswa/dauroh.ts
│   └── utils/
│       └── pdf-generator.ts

frontend/
├── lib/
│   ├── shared/
│   │   ├── models/
│   │   │   ├── dauroh_nilai_model.dart
│   │   │   └── dauroh_surat_model.dart
│   │   ├── services/
│   │   │   └── download_service.dart
│   │   └── widgets/
│   │       └── responsive_builder.dart
│   └── features/
│       ├── admin/dauroh/
│       │   ├── program/program_form_page.dart
│       │   ├── musyrifah/musyrifah_form_page.dart
│       │   ├── jadwal/jadwal_form_page.dart
│       │   └── monitoring/nilai_monitoring_page.dart
│       ├── musyrifah/nilai/
│       │   ├── nilai_dauroh_page.dart
│       │   ├── widgets/
│       │   │   ├── penilaian_radio_group.dart
│       │   │   ├── bidang_section.dart
│       │   │   ├── rekapitulasi_section.dart
│       │   │   ├── metadata_santri_form.dart
│       │   │   ├── input_nilai_form.dart
│       │   │   └── input_batch_form.dart
│       │   └── utils/
│       │       └── pdf_template.dart
│       └── santri/dauroh/
│           ├── dauroh_page.dart
│           ├── nilai_page.dart
│           └── riwayat_page.dart
```

---

## ⏱️ IMPLEMENTATION TIMELINE

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  PHASE 1: DATABASE              ████████████████████  Minggu 1            │
│  PHASE 2: BACKEND API           ░░░░░░░░░░████████████  Minggu 2          │
│  PHASE 3: FRONTEND MODELS       ░░░░░░░░░░░░░░████████  Minggu 3          │
│  PHASE 4: ADMIN FEATURES        ░░░░░░░░░░░░░░░░████████  Minggu 3-4      │
│  PHASE 5: MUSYRIFAH FEATURES    ░░░░░░░░░░░░░░░░░░████████  Minggu 4-5    │
│  PHASE 6: SANTRI FEATURES       ░░░░░░░░░░░░░░░░░░░░░░████  Minggu 5      │
│  PHASE 7: PDF EXPORT            ░░░░░░░░░░░░░░░░░░░░░░░░████  Minggu 5-6   │
│  PHASE 8: TESTING & UAT         ░░░░░░░░░░░░░░░░░░░░░░░░░░████  Minggu 6   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## ✅ CHECKLIST KELENGKAPAN

### Admin Features
- [ ] Buat Program (Murojaah/Tahfidz)
- [ ] Konfigurasi Skema Penilaian
- [ ] Assign Musyrifah
- [ ] Atur Jadwal
- [ ] Assign Santri
- [ ] Generate QR Code
- [ ] Monitoring Nilai
- [ ] Monitoring Absensi
- [ ] Export PDF

### Musyrifah Features
- [ ] Login & Dashboard
- [ ] Lihat Jadwal
- [ ] Absensi QR
- [ ] Absensi Manual
- [ ] Input Nilai Mode Card
- [ ] Input Nilai Mode Batch
- [ ] Status Mengulang
- [ ] Auto-Calculation

### Santri Features
- [ ] Menu Dauroh
- [ ] Lihat Program
- [ ] Lihat Nilai
- [ ] Lihat Progress
- [ ] Lihat Riwayat
- [ ] Download PDF

---

## 📊 ANALISIS CLOUDFLARE FREE TIER

### Limit Free Tier (April 2026)

| Metrik | Free Tier | Estimasi (500 Santri) | Status |
|--------|-----------|----------------------|--------|
| Workers Requests | 100,000/hari | ~5,000 | ✅ Aman |
| D1 Rows Read | 5,000,000/hari | ~100,000 | ✅ Aman |
| D1 Rows Written | 100,000/hari | ~5,000 | ✅ Aman |
| Storage | 500 MB | ~50 MB/tahun | ✅ Aman |
| CPU per request | 10 ms | ~3-5 ms | ⚠️ Waspadai |

### Rekomendasi
- Gunakan Free Tier untuk tahun 1-2
- Upgrade ke Paid ($5/bulan) jika diperlukan
- Optimasi query untuk hindari CPU timeout
- PDF generation di client-side (Flutter)

---

## 📝 CATATAN

1. **Data 114 Surat** - User akan menyediakan data lengkap
2. **Skema Penilaian** - Predefined 3 skema, admin bisa custom max nilai
3. **Computed Fields** - Hybrid approach (DB + Application)
4. **Export PDF** - Client-side menggunakan Flutter
5. **Responsive Design** - Mobile First, adaptive mode

---

## 🔄 REVISI

| Versi | Tanggal | Perubahan |
|-------|---------|-----------|
| 1.0 | 10/08/2026 | Dokumen awal |

---

**Dokumen ini merupakan perencanaan lengkap untuk pengembangan Modul Dauroh dengan Program Murojaah dan Tahfidz.**
