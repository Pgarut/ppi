# DISAIN MODUL MUROJAAH & TAHFIDZ

**Tanggal:** 09 Agustus 2026
**Status:** Draft - Menunggu Review & Persetujuan

---

## DAFTAR ISI

1. [Overview](#1-overview)
2. [Program Types](#2-program-types)
3. [Skema Penilaian](#3-skema-penilaian)
4. [Database Schema](#4-database-schema)
5. [API Endpoints](#5-api-endpoints)
6. [Form Input Musyrifah](#6-form-input-musyrifah)
7. [Tampilan Halaman Santri](#7-tampilan-halaman-santri)
8. [Monitoring Admin/Wakil Kurikulum](#8-monitoring-adminwakil-kurikulum)
9. [Alur Kerja](#9-alur-kerja)
10. [Validasi & Aturan Bisnis](#10-validasi--aturan-bisnis)
11. [Migrasi Data](#11-migrasi-data)

---

## 1. OVERVIEW

### Tujuan
Menambahkan dua program baru ke modul Dauroh:
- **Murojaah** = Review/Mengulang hafalan Al-Qur'an
- **Tahfidz** = Hafalan Al-Qur'an

### Fitur Utama
- Program baru dengan jenis `murojaah` dan `tahfidz`
- Form penilaian 3 bidang (12 item pengurangan)
- Status hafalan: Mengulang / Melanjutkan / Selesai
- Catatan mengulang (alasan belum lancar)
- Tampilan detail untuk santri melihat nilai

---

## 2. PROGRAM TYPES

### Perubahan `jenis_dauroh`

**Sekarang:**
```
CHECK IN ('hafalan', 'bacaan')
```

**Baru:**
```
CHECK IN ('hafalan', 'bacaan', 'murojaah', 'tahfidz')
```

### Tabel Perbandingan

| jenis_dauroh | Keterangan | Form Penilaian |
|--------------|------------|----------------|
| `hafalan` | Hafalan Al-Qur'an | Form Lama (2 angka) |
| `bacaan` | Bacaan Al-Qur'an | Form Lama (2 angka) |
| `murojaah` | Muroja'ah Hafalan | Form Baru (3 bidang) |
| `tahfidz` | Tahfidz Al-Qur'an | Form Baru (3 bidang) |

### Jenis Program (tetap)

| jenis_program | Keterangan |
|---------------|------------|
| `kelas` | Program untuk seluruh kelas (data via `dauroh_jadwal_kelas`) |
| `khusus` | Program untuk siswa tertentu (data via `dauroh_program_santri`) |

---

## 3. SKEMA PENILAIAN

### Format Form 3 Bidang

Berdasarkan `Nilia.md` - Formulir Penilaian Hafalan/Murojaah Al-Qur'an

#### Bidang 1: Kelancaran Hafalan (Max 40)

| No | Jenis yang Dinilai | Skor Pengurangan |
|----|-------------------|------------------|
| 01 | Kelancaran (tanpa tersendat) | 0-5 |
| 02 | Ketepatan Ayat (tidak tertukar/lompat ayat) | 0-5 |
| 03 | Muroja'ah Sambung Ayat | 0-5 |
| 04 | Konsistensi Hafalan (tidak talqin/dibantu) | 0-5 |

**Rumus:** `Nilai = 40 - (item1 + item2 + item3 + item4)`

#### Bidang 2: Tajwid (Max 30)

| No | Jenis yang Dinilai | Skor Pengurangan |
|----|-------------------|------------------|
| 01 | Makhorijul Huruf | 0-5 |
| 02 | Sifatul Huruf | 0-5 |
| 03 | Ahkamul Huruf | 0-5 |
| 04 | Ahkamul Madd wal Qoshr | 0-5 |

**Rumus:** `Nilai = 30 - (item1 + item2 + item3 + item4)`

#### Bidang 3: Fashohah dan Adab (Max 30)

| No | Jenis yang Dinilai | Skor Pengurangan |
|----|-------------------|------------------|
| 01 | Ahkamul Waqfi wal Ibtida' | 0-5 |
| 02 | Adabut Tilawah | 0-5 |
| 03 | Kerapihan Bacaan | 0-5 |
| 04 | Ketepuan Tempo dan Bacaan | 0-5 |

**Rumus:** `Nilai = 30 - (item1 + item2 + item3 + item4)`

#### Total Nilai

```
Total = Bidang 1 + Bidang 2 + Bidang 3
      = (40 - Σkelancaran) + (30 - Σtajwid) + (30 - Σfashohah)
      = 100 - (Σkelancaran + Σtajwid + Σfashohah)
```

### Status Hafalan

| Status | Keterangan | Catatan Mengulang |
|--------|------------|-------------------|
| `mengulang` | Ayat/surat sama diulang karena belum lancar | **Wajib diisi** |
| `melanjutkan` | Lanjut ke ayat/surat berikutnya | Opsional |
| `selesai` | Target hafalan/murojaah tercapai | Opsional |

### Contoh Catatan Mengulang

- "Belum lancar pada ayat 15-18"
- "Masih sering salah baca pada bagun qalqalah"
- "Perlu perbaikan makhorijul huruf pada huruf ق"
- "Belum hafal surat Al-Mulk ayat 10-15"

---

## 4. DATABASE SCHEMA

### 4.1 Perubahan Tabel `dauroh_program`

```sql
-- Update CHECK constraint jenis_dauroh
ALTER TABLE dauroh_program DROP CONSTRAINT IF EXISTS dauroh_program_jenis_dauroh_check;
ALTER TABLE dauroh_program ADD CONSTRAINT dauroh_program_jenis_dauroh_check 
    CHECK (jenis_dauroh IN ('hafalan', 'bacaan', 'murojaah', 'tahfidz'));
```

### 4.2 Penambahan Kolom ke `dauroh_nilai`

```sql
-- Info Surat/Ayat
ALTER TABLE dauroh_nilai ADD COLUMN surat_juz TEXT;
ALTER TABLE dauroh_nilai ADD COLUMN ayat_awal INTEGER;
ALTER TABLE dauroh_nilai ADD COLUMN ayat_akhir INTEGER;

-- Status & Catatan
ALTER TABLE dauroh_nilai ADD COLUMN status_hafalan TEXT 
    CHECK (status_hafalan IN ('mengulang', 'melanjutkan', 'selesai'));
ALTER TABLE dauroh_nilai ADD COLUMN catatan_mengulang TEXT;

-- Bidang 1: Kelancaran (4 item, pengurangan 0-5)
ALTER TABLE dauroh_nilai ADD COLUMN kelancaran_1 INTEGER DEFAULT 0;
ALTER TABLE dauroh_nilai ADD COLUMN kelancaran_2 INTEGER DEFAULT 0;
ALTER TABLE dauroh_nilai ADD COLUMN kelancaran_3 INTEGER DEFAULT 0;
ALTER TABLE dauroh_nilai ADD COLUMN kelancaran_4 INTEGER DEFAULT 0;

-- Bidang 2: Tajwid (4 item, pengurangan 0-5)
ALTER TABLE dauroh_nilai ADD COLUMN tajwid_1 INTEGER DEFAULT 0;
ALTER TABLE dauroh_nilai ADD COLUMN tajwid_2 INTEGER DEFAULT 0;
ALTER TABLE dauroh_nilai ADD COLUMN tajwid_3 INTEGER DEFAULT 0;
ALTER TABLE dauroh_nilai ADD COLUMN tajwid_4 INTEGER DEFAULT 0;

-- Bidang 3: Fashohah (4 item, pengurangan 0-5)
ALTER TABLE dauroh_nilai ADD COLUMN fashohah_1 INTEGER DEFAULT 0;
ALTER TABLE dauroh_nilai ADD COLUMN fashohah_2 INTEGER DEFAULT 0;
ALTER TABLE dauroh_nilai ADD COLUMN fashohah_3 INTEGER DEFAULT 0;
ALTER TABLE dauroh_nilai ADD COLUMN fashohah_4 INTEGER DEFAULT 0;
```

### 4.3 Struktur Tabel `dauroh_nilai` (Lengkap)

```sql
CREATE TABLE dauroh_nilai (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    program_id      INTEGER NOT NULL REFERENCES dauroh_program(id),
    santri_id       INTEGER NOT NULL REFERENCES siswa(id),
    
    -- Form Lama (nullable - untuk program hafalan/bacaan)
    nilai_hafalan   REAL,
    nilai_bacaan    REAL,
    catatan         TEXT,
    
    -- Form Baru (untuk program murojaah/tahfidz)
    surat_juz       TEXT,
    ayat_awal       INTEGER,
    ayat_akhir      INTEGER,
    status_hafalan  TEXT CHECK (status_hafalan IN ('mengulang', 'melanjutkan', 'selesai')),
    catatan_mengulang TEXT,
    
    -- Bidang 1: Kelancaran (pengurangan 0-5 per item)
    kelancaran_1    INTEGER DEFAULT 0,
    kelancaran_2    INTEGER DEFAULT 0,
    kelancaran_3    INTEGER DEFAULT 0,
    kelancaran_4    INTEGER DEFAULT 0,
    
    -- Bidang 2: Tajwid (pengurangan 0-5 per item)
    tajwid_1        INTEGER DEFAULT 0,
    tajwid_2        INTEGER DEFAULT 0,
    tajwid_3        INTEGER DEFAULT 0,
    tajwid_4        INTEGER DEFAULT 0,
    
    -- Bidang 3: Fashohah (pengurangan 0-5 per item)
    fashohah_1      INTEGER DEFAULT 0,
    fashohah_2      INTEGER DEFAULT 0,
    fashohah_3      INTEGER DEFAULT 0,
    fashohah_4      INTEGER DEFAULT 0,
    
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),
    
    UNIQUE(program_id, santri_id)
);
```

---

## 5. API ENDPOINTS

### 5.1 Backend Musyrifah - Input Nilai

**POST `/api/musyrifah/nilai`** (Create/Update)

Request Body:
```json
{
  "program_id": 5,
  "santri_id": 10,
  "surat_juz": "Juz 30",
  "ayat_awal": 1,
  "ayat_akhir": 20,
  "status_hafalan": "melanjutkan",
  "catatan_mengulang": null,
  "kelancaran_1": 2,
  "kelancaran_2": 1,
  "kelancaran_3": 0,
  "kelancaran_4": 1,
  "tajwid_1": 1,
  "tajwid_2": 0,
  "tajwid_3": 1,
  "tajwid_4": 0,
  "fashohah_1": 0,
  "fashohah_2": 1,
  "fashohah_3": 0,
  "fashohah_4": 0,
  "catatan": "Sudah lancar, tingkatkan tajwid"
}
```

Response:
```json
{
  "success": true,
  "message": "Nilai berhasil disimpan",
  "data": {
    "id": 1,
    "program_id": 5,
    "santri_id": 10,
    "nilai_akhir": 93,
    "bidang1": 36,
    "bidang2": 28,
    "bidang3": 29
  }
}
```

### 5.2 Backend Santri - Lihat Nilai

**GET `/api/siswa/dauroh/nilai`**

Response:
```json
{
  "data": [
    {
      "id": 1,
      "nama_program": "Murojaah Kelas VII",
      "jenis_dauroh": "murojaah",
      "surat_juz": "Juz 30",
      "ayat_awal": 1,
      "ayat_akhir": 20,
      "status_hafalan": "melanjutkan",
      "catatan_mengulang": null,
      "kelancaran": {
        "item1": 2, "item2": 1, "item3": 0, "item4": 1,
        "subtotal": 36, "max": 40
      },
      "tajwid": {
        "item1": 1, "item2": 0, "item3": 1, "item4": 0,
        "subtotal": 28, "max": 30
      },
      "fashohah": {
        "item1": 0, "item2": 1, "item3": 0, "item4": 0,
        "subtotal": 29, "max": 30
      },
      "nilai_akhir": 93,
      "catatan": "Sudah lancar, tingkatkan tajwid",
      "updated_at": "2026-07-15T10:30:00Z"
    }
  ]
}
```

### 5.3 Backend Admin - Monitoring Nilai

**GET `/api/admin/dauroh/monitoring/nilai`**

Query Params:
- `jenjang` - Filter jenjang (VII, VIII, IX, X, XI, XII)
- `kelas_id` - Filter kelas tertentu
- `program_id` - Filter program tertentu
- `page` - Halaman (default: 1)
- `per_page` - Jumlah per halaman (default: 20)

Response:
```json
{
  "data": [
    {
      "id": 1,
      "nama_program": "Murojaah Kelas VII",
      "jenis_dauroh": "murojaah",
      "nama_santri": "Ahmad Fauzi",
      "nis": "2024001",
      "nama_kelas": "VII-A",
      "status_hafalan": "selesai",
      "nilai_akhir": 95,
      "catatan": "Target tercapai"
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 150,
    "total_pages": 8
  },
  "summary": {
    "total_siswa": 150,
    "rata_rata": 81.7,
    "selesai": 68,
    "melanjutkan": 60,
    "mengulang": 22
  }
}
```

---

## 6. FORM INPUT MUSYRIFAH

### 6.1 Layout Form Universal

Form menyesuaikan berdasarkan jenis program yang dipilih.

```
┌────────────────────────────────────────────────────────────┐
│                    FORM PENILAIAN DAUROH                   │
├────────────────────────────────────────────────────────────┤
│ Nama Santri  : [Dropdown/Search]                          │
│ Program      : [Dropdown: Murojaah/Tahfidz/Hafalan/...]  │
│ Surat/Juz    : [Text Input]                               │
│ Dari Ayat    : [Number]  Sampai Ayat: [Number]           │
│ Status       : ( ) Mengulang ( ) Melanjutkan ( ) Selesai  │
├────────────────────────────────────────────────────────────┤
│ JIKA "MENGULANG":                                         │
│ Catatan Mengulang: [Text Area - wajib jika mengulang]    │
├────────────────────────────────────────────────────────────┤
│ JIKA program = 'murojaah' ATAU 'tahfidz':                │
│                                                            │
│ BIDANG 1: KELANCARAN HAFALAN (Max 40)                    │
│ ┌──────────────────────────────────────────────────────┐  │
│ │ 01. Kelancaran (tanpa tersendat)        [Spinner 0-5]│  │
│ │ 02. Ketepatan Ayat (tidak tertukar/lompat) [0-5]    │  │
│ │ 03. Muroja'ah Sambung Ayat             [0-5]        │  │
│ │ 04. Konsistensi Hafalan (tidak talqin)  [0-5]       │  │
│ │                              Subtotal: 40 - ▢ = ▢   │  │
│ └──────────────────────────────────────────────────────┘  │
│                                                            │
│ BIDANG 2: TAJWID (Max 30)                                 │
│ ┌──────────────────────────────────────────────────────┐  │
│ │ 01. Makhorijul Huruf                    [0-5]        │  │
│ │ 02. Sifatul Huruf                       [0-5]        │  │
│ │ 03. Ahkamul Huruf                       [0-5]        │  │
│ │ 04. Ahkamul Madd wal Qoshr              [0-5]        │  │
│ │                              Subtotal: 30 - ▢ = ▢   │  │
│ └──────────────────────────────────────────────────────┘  │
│                                                            │
│ BIDANG 3: FASHOHAH DAN ADAB (Max 30)                      │
│ ┌──────────────────────────────────────────────────────┐  │
│ │ 01. Ahkamul Waqfi wal Ibtida'           [0-5]        │  │
│ │ 02. Adabut Tilawah                      [0-5]        │  │
│ │ 03. Kerapihan Bacaan                    [0-5]        │  │
│ │ 04. Ketepuan Tempo dan Bacaan           [0-5]        │  │
│ │                              Subtotal: 30 - ▢ = ▢   │  │
│ └──────────────────────────────────────────────────────┘  │
│                                                            │
│ ═══════════════════════════════════════════════════════   │
│ TOTAL: 100 - (▢ + ▢ + ▢) = ▢                            │
│                                                            │
│ Catatan Umum: [Text Area]                                 │
│                                                            │
│                              [Batal]  [Simpan]            │
└────────────────────────────────────────────────────────────┘
```

### 6.2 Form Lama (Hafalan/Bacaan)

```
┌────────────────────────────────────────────────────────────┐
│                    FORM PENILAIAN DAUROH                   │
├────────────────────────────────────────────────────────────┤
│ Nama Santri  : [Dropdown/Search]                          │
│ Program      : [Dropdown: Hafalan/Bacaan]                 │
│                                                            │
│ Nilai Hafalan: [Number 0-100]                             │
│ Nilai Bacaan : [Number 0-100]                             │
│                                                            │
│ Catatan: [Text Area]                                      │
│                                                            │
│                              [Batal]  [Simpan]            │
└────────────────────────────────────────────────────────────┘
```

---

## 7. TAMPILAN HALAMAN SANTRI

### 7.1 Ringkasan Nilai

```
┌────────────────────────────────────────────────────────────┐
│  📊 RINGKASAN NILAI DAUROH                                │
│  ─────────────────────────────────────────────────────────  │
│  Program: Murojaah Kelas VII                              │
│  Surat/Juz: Juz 30 (Ayat 1-20)                           │
│                                                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Status: 🔁 MENGULANG                              │   │
│  │  Catatan: "Belum lancar pada ayat 15-18"           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         NILAI AKHIR: 93 / 100                      │   │
│  │         ████████████████████████░░░  93%            │   │
│  │         Predikat: Sangat Baik                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                            │
│  ┌──────────────────┬──────────────────┬─────────────┐    │
│  │ Kelancaran       │ Tajwid           │ Fashohah    │    │
│  │ Max: 40          │ Max: 30          │ Max: 30     │    │
│  │ Nilai: 36        │ Nilai: 28        │ Nilai: 29   │    │
│  │ ████████░░ 90%   │ ███████░░ 93%    │ ███████░ 97%│    │
│  └──────────────────┴──────────────────┴─────────────┘    │
└────────────────────────────────────────────────────────────┘
```

### 7.2 Detail Penilaian (Expandable)

```
┌────────────────────────────────────────────────────────────┐
│  📝 DETAIL PENILAIAN                                       │
│  ─────────────────────────────────────────────────────────  │
│                                                            │
│  ▼ BIDANG 1: KELANCARAN HAFALAN (36/40)                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 01. Kelancaran (tanpa tersendat)        │  ✅ 1    │   │
│  │ 02. Ketepatan Ayat (tidak tertukar)     │  ✅ 0    │   │
│  │ 03. Muroja'ah Sambung Ayat             │  ✅ 0    │   │
│  │ 04. Konsistensi Hafalan                │  ⚠️ 1    │   │
│  │                                         │          │   │
│  │ Pengurangan: 2                          │          │   │
│  │ Nilai: 40 - 2 = 36                     │          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                            │
│  ▼ BIDANG 2: TAJWID (28/30)                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 01. Makhorijul Huruf                    │  ⚠️ 1    │   │
│  │ 02. Sifatul Huruf                       │  ✅ 0    │   │
│  │ 03. Ahkamul Huruf                       │  ⚠️ 1    │   │
│  │ 04. Ahkamul Madd wal Qoshr              │  ✅ 0    │   │
│  │                                         │          │   │
│  │ Pengurangan: 2                          │          │   │
│  │ Nilai: 30 - 2 = 28                     │          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                            │
│  ▼ BIDANG 3: FASHOHAH DAN ADAB (29/30)                    │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 01. Ahkamul Waqfi wal Ibtida'           │  ✅ 0    │   │
│  │ 02. Adabut Tilawah                      │  ⚠️ 1    │   │
│  │ 03. Kerapihan Bacaan                    │  ✅ 0    │   │
│  │ 04. Ketepuan Tempo dan Bacaan           │  ✅ 0    │   │
│  │                                         │          │   │
│  │ Pengurangan: 1                          │          │   │
│  │ Nilai: 30 - 1 = 29                     │          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 📋 Catatan: Sudah lancar, tingkatkan tajwid        │   │
│  └─────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────┘
```

### 7.3 Predikat Nilai

| Nilai | Predikat | Warna |
|-------|----------|-------|
| 90-100 | Sangat Baik | 🟢 Green |
| 80-89 | Baik | 🟢 Light Green |
| 70-79 | Cukup | 🟡 Orange |
| 60-69 | Kurang | 🟠 Deep Orange |
| <60 | Sangat Kurang | 🔴 Red |

---

## 8. MONITORING ADMIN/WAKIL KURIKULUM

### 8.1 Tampilan Monitoring Nilai

```
┌────────────────────────────────────────────────────────────┐
│                    MONITORING NILAI DAUROH                 │
├────────────────────────────────────────────────────────────┤
│ Filter: [Jenjang ▼] [Kelas ▼] [Program ▼] [Reset]       │
├────────────────────────────────────────────────────────────┤
│ No │ Nama      │ Kelas │ Program    │ Status │ Nilai     │
├────────────────────────────────────────────────────────────┤
│ 1  │ Ahmad     │ VII-A │ Murojaah  │ ✅ Selesai │ 95    │
│ 2  │ Fatimah   │ VII-B │ Tahfidz   │ 🔄 Melanjutkan │ 82 │
│ 3  │ Ali       │ VIII-A│ Murojaah  │ 🔁 Mengulang │ 68   │
│    │           │       │           │ "Belum lancar ayat 15-18" │
├────────────────────────────────────────────────────────────┤
│ Rata-rata: 81.7  │  Selesai: 45%  │  Mengulang: 15%      │
└────────────────────────────────────────────────────────────┘
```

---

## 9. ALUR KERJA

### 9.1 Alur Kerja Admin

```
┌─────────────────┐
│  LOGIN (Admin)  │
└────────┬────────┘
         │
         ▼
┌────────────────────────────────┐
│  BUKA MODUL DAUROH            │
└───────────────┬────────────────┘
                │
    ┌───────────┼───────────┐
    │           │           │
    ▼           ▼           ▼
┌────────┐ ┌────────┐ ┌────────┐
│Program │ │Musyrifah│ │ Jadwal │
│(CRUD)  │ │ (CRUD)  │ │ (CRUD) │
└────────┘ └────────┘ └────────┘
    │           │           │
    │           │           ▼
    │           │     ┌────────────┐
    │           │     │ Pilih Kelas│
    │           │     └────────────┘
    │           │
    ▼           ▼
┌────────────────────────────────┐
│  MONITORING                    │
│  • Absensi (by tanggal/program)│
│  • Nilai (by jenjang/kelas)    │
└────────────────────────────────┘
```

### 9.2 Alur Kerja Musyrifah → Santri

```
┌──────────────────┐
│ LOGIN (Musyrifah)│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Dashboard        │
│ • Jadwal Hari Ini│
│ • Status Absensi │
│ • Total Nilai    │
└────────┬─────────┘
         │
    ┌────┼────┐
    │    │    │
    ▼    ▼    ▼
┌──────┐ ┌──────┐ ┌──────┐
│Scan  │ │Lihat │ │Input │
│QR    │ │Jadwal│ │Nilai │
│(Absen)│ │      │ │      │
└──────┘ └──────┘ └──────┘
              │      │
              │      ▼
              │ ┌──────────────────────────────┐
              │ │ Input Form:                  │
              │ │ • Pilih Program              │
              │ │ • Isi Surat/Juz & Ayat       │
              │ │ • Pilih Status               │
              │ │ • Isi 3 Bidang (12 item)     │
              │ │ • Hitung Otomatis            │
              │ │ • Simpan                     │
              │ └──────────────┬───────────────┘
              │                │
              │                ▼
              │ ┌──────────────────────────────┐
              │ │ Tersimpan di dauroh_nilai    │
              │ └──────────────┬───────────────┘
              │                │
              │                │
══════════════╪════════════════╪═══════════════════════
              │                │
              │                ▼
              │ ┌──────────────────────────────┐
              │ │ SANTRI BUKA HALAMAN DAUROH   │
              │ └──────────────┬───────────────┘
              │                │
              │    ┌───────────┼───────────┐
              │    │           │           │
              │    ▼           ▼           ▼
              │ ┌──────┐ ┌──────┐ ┌──────┐
              │ │Program│ │Nilai │ │Absensi│
              │ │Dikuti │ │(3    │ │      │
              │ │      │ │Bidang)│ │      │
              │ └──────┘ └──────┘ └──────┘
              │
              │
              ▼
         ┌──────────┐
         │Monitoring│
         │(Admin/WK)│
         └──────────┘
```

---

## 10. VALIDASI & ATURAN BISNIS

### 10.1 Validasi Input

| Field | Validasi | Error Message |
|-------|----------|---------------|
| `kelancaran_1..4` | 0-5 | "Pengurangan harus antara 0-5" |
| `tajwid_1..4` | 0-5 | "Pengurangan harus antara 0-5" |
| `fashohah_1..4` | 0-5 | "Pengurangan harus antara 0-5" |
| `status_hafalan` | Required untuk murojaah/tahfidz | "Status wajib dipilih" |
| `catatan_mengulang` | Required jika status = 'mengulang' | "Catatan wajib diisi untuk status Mengulang" |
| `surat_juz` | Required untuk murojaah/tahfidz | "Surat/Juz wajib diisi" |
| `ayat_awal` | Number, required | "Ayat awal wajib diisi" |
| `ayat_akhir` | Number, >= ayat_awal | "Ayat akhir harus lebih besar dari ayat awal" |

### 10.2 Aturan Bisnis

1. **Program Murojaah/Tahfidz** wajib menggunakan form 3 bidang
2. **Program Hafalan/Bacaan** tetap menggunakan form lama (2 angka)
3. **Status Mengulang** wajib diisi catatan mengulang
4. **Nilai per item** tidak boleh negatif dan tidak boleh lebih dari 5
5. **Total pengurangan per bidang** tidak boleh melebihi nilai maksimal bidang

### 10.3 Hitungan Otomatis

```typescript
// Backend (TypeScript)
function hitungNilai(detail: NilaiDetail) {
  const bidang1 = 40 - (detail.kelancaran_1 + detail.kelancaran_2 + 
                         detail.kelancaran_3 + detail.kelancaran_4);
  const bidang2 = 30 - (detail.tajwid_1 + detail.tajwid_2 + 
                         detail.tajwid_3 + detail.tajwid_4);
  const bidang3 = 30 - (detail.fashohah_1 + detail.fashohah_2 + 
                         detail.fashohah_3 + detail.fashohah_4);
  
  return {
    bidang1, bidang2, bidang3,
    total: bidang1 + bidang2 + bidang3
  };
}
```

---

## 11. MIGRASI DATA

### 11.1 Data Lama

Data `nilai_hafalan` dan `nilai_bacaan` yang sudah ada **TIDAK DIHAPUS**. Kolom baru bersifat nullable, sehingga:

- Program lama (hafalan/bacaan): `nilai_hafalan` & `nilai_bacaan` terisi, kolom baru null
- Program baru (murojaah/tahfidz): `nilai_hafalan` & `nilai_bacaan` null, kolom baru terisi

### 11.2 File Migrasi

```
migrations/
  0011_add_murojaah_tahfidz.sql
```

---

## 12. FILE YANG PERLU DIUBAH

### Backend

| File | Perubahan |
|------|-----------|
| `src/db/schema.sql` | Update CHECK constraint `jenis_dauroh` |
| `src/routes/admin/dauroh.ts` | Update validasi program type |
| `src/routes/musyrifah/index.ts` | Update `inputNilai` & `updateNilai` untuk handle field baru |
| `src/routes/siswa/dauroh.ts` | Update response untuk tampilkan field baru |
| `src/routes/wakil_kurikulum/dauroh.ts` | Update monitoring nilai |
| `src/routes/kepala_sekolah/dauroh.ts` | Update monitoring nilai |
| `migrations/0011_add_murojaah_tahfidz.sql` | Migrasi baru |

### Frontend

| File | Perubahan |
|------|-----------|
| `features/admin/dauroh/program/program_form_page.dart` | Tambah opsi 'Murojaah' & 'Tahfidz' di dropdown |
| `features/musyrifah/nilai/nilai_dauroh_page.dart` | Form penilaian baru (3 bidang) untuk murojaah/tahfidz |
| `features/santri/dauroh/dauroh_santri_page.dart` | Tampilan baru dengan status + detail 3 bidang |
| `features/admin/dauroh/monitoring/nilai_monitoring_page.dart` | Tampilkan badge jenis program baru |
| `features/musyrifah/services/musyrifah_service.dart` | Update API calls untuk field baru |
| `features/santri/services/dauroh_santri_service.dart` | Update response parsing |

---

## 13. CONTOH DATA

### 13.1 Program Murojaah

```json
{
  "id": 1,
  "nama_program": "Murojaah Kelas VII",
  "jenis_program": "kelas",
  "jenis_dauroh": "murojaah",
  "keterangan": "Murojaah Juz 30 untuk kelas VII",
  "tahun_ajaran_id": 1,
  "is_aktif": 1
}
```

### 13.2 Nilai Murojaah

```json
{
  "id": 1,
  "program_id": 1,
  "santri_id": 10,
  "surat_juz": "Juz 30",
  "ayat_awal": 1,
  "ayat_akhir": 20,
  "status_hafalan": "melanjutkan",
  "catatan_mengulang": null,
  "kelancaran_1": 2,
  "kelancaran_2": 1,
  "kelancaran_3": 0,
  "kelancaran_4": 1,
  "tajwid_1": 1,
  "tajwid_2": 0,
  "tajwid_3": 1,
  "tajwid_4": 0,
  "fashohah_1": 0,
  "fashohah_2": 1,
  "fashohah_3": 0,
  "fashohah_4": 0,
  "catatan": "Sudah lancar, tingkatkan tajwid",
  "nilai_hafalan": null,
  "nilai_bacaan": null
}
```

---

**Dokumen ini dibuat berdasarkan diskusi pada tanggal 09 Agustus 2026.**
**Status: Draft - Menunggu Review & Persetujuan sebelum implementasi.**
