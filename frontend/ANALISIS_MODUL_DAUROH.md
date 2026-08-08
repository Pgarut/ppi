# 📋 Analisis Modul Dauroh
## Sistem Informasi Madrasah PPI

---

## 📖 Ringkasan dari Dauroh.md

Modul Dauroh adalah sistem manajemen kegiatan Dauroh (program kegiatan ekstrakurikuler/keagamaan) yang terdiri dari:

### 1. Program Kegiatan
- **Program Khusus**: Untuk santri dari beberapa jenjang/kelas tertentu
- **Program Kelas**: Untuk satu jenjang pada beberapa kelas

### 2. Musyrifah (Pembimbing)
- Data NIP, Nama, JK, Status Pendidikan, Gelar
- Username & Password untuk login

### 3. Atur Jadwal Program
- Pilih Program Kegiatan
- Pilih Musyrifah (1 utama + 1 opsional)
- Pilih Jenjang & Kelas
- Pilih Hari (Sabtu-Minggu atau semua hari)
- Atur Jam (Mulai - Selesai)

### 4. Monitoring
- QR Code Absensi Musyrifah
- Monitoring Absensi
- Monitoring Nilai (dengan filter Jenjang & Kelas)

### 5. Halaman User/Santri
- Ikon Dauroh di halaman utama santri
- Halaman Dauroh Santri menampilkan:
  1. **Program yang diikuti** (nama program, jenis, musyrifah)
  2. **Nilai** (hafalan/bacaan dari program tersebut)

### 6. Halaman Musyrifah (Role Baru)
- Login Musyrifah → Dashboard Musyrifah
- Ikon **Jadwal Dauroh** → Lihat jadwal mengajar
- Ikon **Absensi** → Input absensi santri
- Ikon **Monitoring Nilai** → Lihatnilai santri

---

## 🔍 Analisis Struktur Saat Ini

### Admin Master Data (`master_data_page.dart`)
```
MasterDataType enum:
├── tahunAjaran
├── semester
├── jurusan
├── tingkat
├── kelas
├── mataPelajaran
├── asatidz
├── waliKelas
├── asatidzBK
├── santri
└── ruangan
```

### Dashboard Santri (`dashboard_santri_page.dart`)
```
Features:
├── Jadwal
├── Absensi
├── Nilai
├── Materi
└── Dauroh (BARU - hanya ikon, tanpa halaman jadwal)
```

### Dashboard Musyrifah (ROLE BARU)
```
Features:
├── Jadwal Dauroh (Lihat jadwal mengajar)
├── Absensi (Input absensi santri)
└── Monitoring Nilai (Lihat nilai santri)
```

---

## 🛠️ Rekomendasi Implementasi

### FASE 1: Tambah Master Data Dauroh

#### 1.1 Tambah Enum `dauroh` di `MasterDataType`
```dart
dauroh(
  label: 'Dauroh',
  resource: 'dauroh',
  icon: Icons.menu_book_outlined, // atau Icons.auto_stories
  columns: ['nama', 'jenis', 'keterangan'],
  displayCols: ['Nama Program', 'Jenis', 'Keterangan'],
),
```

#### 1.2 Tambah Sub-Menu Dauroh
Karena Dauroh punya banyak komponen, sebaiknya buat sub-menu:
```
Master Data
├── Tahun Ajaran
├── Semester
├── ... (existing)
├── Dauroh
│   ├── Program Kegiatan
│   ├── Musyrifah
│   ├── Atur Jadwal
│   ├── QR Absensi
│   ├── Monitoring Absensi
│   └── Monitoring Nilai
└── Ruangan
```

### FASE 2: Form Program Kegiatan

#### Kolom yang Dibutuhkan:
| Kolom | Tipe | Keterangan |
|-------|------|------------|
| nama_program | Text | Nama kegiatan |
| jenis_program | Dropdown | Program Khusus / Program Kelas |
| jenis_dauroh | Dropdown | Hafalan / Bacaan |
| keterangan | Text | Deskripsi singkat |

#### Untuk Program Khusus:
- Pilih beberapa jenjang
- Pilih beberapa kelas per jenjang
- Centang santri yang ikut

#### Untuk Program Kelas:
- Pilih satu jenjang
- Pilih beberapa kelas

### FASE 3: Form Musyrifah

#### Kolom yang Dibutuhkan:
| Kolom | Tipe | Keterangan |
|-------|------|------------|
| nipmus | Text | Nomor Induk Pengawai |
| nama | Text | Nama Musyrifah |
| jenis_kelamin | Dropdown | L / P |
| status_pendidikan | Dropdown | Selesai / Mahasiswa |
| gelar | Text | Opsional |
| username | Text | Untuk login |
| password | Text | Untuk login |

### FASE 4: Form Atur Jadwal

#### ⚠️ Penting: Jadwal Hanya Untuk Musyrifah
Jadwal Dauroh **hanya ditampilkan di halaman Musyrifah**, bukan di santri.

#### Kolom yang Dibutuhkan:
| Kolom | Tipe | Keterangan |
|-------|------|------------|
| program_id | Dropdown | Dari Program Kegiatan |
| musyrifah_1 | Dropdown | Dari List Musyrifah (wajib) |
| musyrifah_2 | Dropdown | Dari List Musyrifah (opsional) |
| jenjang | Dropdown | Pilih Jenjang / Semua Jenjang |
| kelas | Multi-select | Bisa pilih lebih dari satu |
| hari | Dropdown/Multi | Sabtu-Minggu atau Semua Hari |
| jam_mulai | TimePicker | Jam mulai |
| jam_selesai | TimePicker | Jam selesai |

### FASE 5: Halaman Santri (Program & Nilai)

#### Tambah Ikon Dauroh:
```dart
// Di dashboard_santri_page.dart
features: const [
  FeatureItem('Jadwal', 'jadwal', Icons.calendar_today, 'Lihat jadwal pelajaran'),
  FeatureItem('Absensi', 'absensi', Icons.how_to_reg, 'Riwayat kehadiran'),
  FeatureItem('Nilai', 'nilai', Icons.grade, 'Nilai akademik'),
  FeatureItem('Materi', 'materi', Icons.menu_book, 'Materi pelajaran'),
  FeatureItem('Dauroh', 'dauroh', Icons.auto_stories, 'Kegiatan Dauroh'), // TAMBAH INI
],
```

#### Halaman Dauroh Santri (Sederhana):
Tampilkan 2 bagian:
1. **Program yang Diikuti**
   - Nama Program
   - Jenis (Hafalan/Bacaan)
   - Musyrifah
   - Status (Aktif/Selesai)

2. **Nilai**
   - Nilai Hafalan
   - Nilai Bacaan
   - Catatan dari Musyrifah

**Catatan**: Santri TIDAK melihat jadwal, hanya program dan nilai.

### FASE 6: Halaman Musyrifah (Role Baru)

#### Dashboard Musyrifah:
```dart
features: const [
  FeatureItem('Jadwal', 'jadwal-dauroh', Icons.calendar_today, 'Jadwal mengajar Dauroh'),
  FeatureItem('Absensi', 'absensi-dauroh', Icons.how_to_reg, 'Input absensi santri'),
  FeatureItem('Nilai', 'nilai-dauroh', Icons.grade, 'Monitoring nilai santri'),
],
```

---

## 📁 Struktur File yang Perlu Dibuat/Ubah

### File yang Perlu Diubah:
1. `lib/features/admin/master_data/master_data_page.dart`
   - Tambah enum `dauroh` atau sub-menu

2. `lib/features/admin/admin_page.dart`
   - Tambah route untuk halaman Dauroh

3. `lib/features/santri/dashboard/dashboard_santri_page.dart`
   - Tambah ikon Dauroh

4. `lib/features/santri/santri_page.dart`
   - Tambah route untuk halaman Dauroh santri (Program & Nilai)

### File yang Perlu Dibuat:
```
lib/features/admin/dauroh/
├── dauroh_page.dart                    // Halaman utama Dauroh admin
├── program_kegiatan/
│   ├── program_kegiatan_page.dart      // List Program
│   └── program_kegiatan_form.dart      // Form Tambah/Edit
├── musyrifah/
│   ├── musyrifah_page.dart             // List Musyrifah
│   └── musyrifah_form.dart             // Form Tambah/Edit
├── jadwal/
│   ├── jadwal_page.dart                // List Jadwal (Admin)
│   └── jadwal_form.dart                // Form Atur Jadwal
├── monitoring/
│   ├── absensi_monitoring_page.dart    // Monitoring Absensi
│   └── nilai_monitoring_page.dart      // Monitoring Nilai
└── services/
    └── dauroh_service.dart             // API Service

lib/features/musyrifah/ (ROLE BARU)
├── musyrifah_page.dart                 // Halaman utama Musyrifah
├── dashboard/
│   └── dashboard_musyrifah_page.dart   // Dashboard Musyrifah
├── jadwal/
│   └── jadwal_dauroh_page.dart         // Lihat jadwal mengajar
├── absensi/
│   └── absensi_dauroh_page.dart        // Input absensi santri
├── nilai/
│   └── nilai_dauroh_page.dart          // Monitoring nilai
└── services/
    └── musyrifah_service.dart          // API Service

lib/features/santri/dauroh/
├── dauroh_santri_page.dart             // Halaman Dauroh santri (Program & Nilai)
└── services/
    └── dauroh_santri_service.dart      // API Service
```

---

## 🗄️ Database Schema (Backend)

### Tabel Program Kegiatan:
```sql
CREATE TABLE dauroh_program (
  id SERIAL PRIMARY KEY,
  nama_program VARCHAR(255) NOT NULL,
  jenis_program ENUM('khusus', 'kelas') NOT NULL,
  jenis_dauroh ENUM('hafalan', 'bacaan') NOT NULL,
  keterangan TEXT,
  tahun_ajaran_id INT REFERENCES tahun_ajaran(id),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Tabel Musyrifah:
```sql
CREATE TABLE dauroh_musyrifah (
  id SERIAL PRIMARY KEY,
  nipmus VARCHAR(50) UNIQUE NOT NULL,
  nama VARCHAR(255) NOT NULL,
  jenis_kelamin ENUM('L', 'P') NOT NULL,
  status_pendidikan ENUM('selesai', 'mahasiswa') NOT NULL,
  gelar VARCHAR(100),
  username VARCHAR(100) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Tabel Jadwal Dauroh:
```sql
CREATE TABLE dauroh_jadwal (
  id SERIAL PRIMARY KEY,
  program_id INT REFERENCES dauroh_program(id),
  musyrifah_1_id INT REFERENCES dauroh_musyrifah(id),
  musyrifah_2_id INT REFERENCES dauroh_musyrifah(id),
  jenjang VARCHAR(50),
  hari VARCHAR(20) NOT NULL,
  jam_mulai TIME NOT NULL,
  jam_selesai TIME NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Tabel Jadwal Kelas (Relasi):
```sql
CREATE TABLE dauroh_jadwal_kelas (
  id SERIAL PRIMARY KEY,
  jadwal_id INT REFERENCES dauroh_jadwal(id),
  kelas_id INT REFERENCES kelas(id),
  UNIQUE(jadwal_id, kelas_id)
);
```

### Tabel Program Santri (Untuk Program Khusus):
```sql
CREATE TABLE dauroh_program_santri (
  id SERIAL PRIMARY KEY,
  program_id INT REFERENCES dauroh_program(id),
  santri_id INT REFERENCES siswa(id),
  UNIQUE(program_id, santri_id)
);
```

### Tabel Absensi Dauroh:
```sql
CREATE TABLE dauroh_absensi (
  id SERIAL PRIMARY KEY,
  jadwal_id INT REFERENCES dauroh_jadwal(id),
  santri_id INT REFERENCES siswa(id),
  tanggal DATE NOT NULL,
  status ENUM('hadir', 'izin', 'sakit', 'alpha') NOT NULL,
  keterangan TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 📊 Estimasi Waktu Pengerjaan

| Fase | Deskripsi | Estimasi |
|------|-----------|----------|
| 1 | Master Data Program Kegiatan | 2-3 hari |
| 2 | Master Data Musyrifah | 1-2 hari |
| 3 | Form & List Atur Jadwal | 3-4 hari |
| 4 | QR Absensi Musyrifah | 2-3 hari |
| 5 | Monitoring Absensi | 2-3 hari |
| 6 | Monitoring Nilai | 2-3 hari |
| 7 | Halaman Dauroh Santri (Program & Nilai) | 2-3 hari |
| 8 | Dashboard Musyrifah (Role Baru) | 3-4 hari |
| 9 | Testing & Bug Fix | 2-3 hari |
| **TOTAL** | | **17-25 hari** |

---

## ⚠️ Pertimbangan Penting

### 1. Kompleksitas
Dauroh adalah modul yang **cukup kompleks** karena:
- Banyak relasi data (Program → Jadwal → Kelas → Santri)
- Program Khusus vs Program Kelas (logic berbeda)
- Multiple Musyrifah per jadwal
- Filter jenjang/kelas yang dinamis

### 2. Backend Diperlukan
Modul ini membutuhkan **banyak endpoint baru**:
- CRUD Program Kegiatan
- CRUD Musyrifah
- CRUD Jadwal
- Absensi (Create, Read)
- Monitoring (Read with filter)

### 3. Rekomendasi Pendekatan
**Mulai dari yang sederhana:**
1. Buat Master Data Program Kegiatan dulu
2. Buat Master Data Musyrifah
3. Buat Atur Jadwal (complex)
4. Baru Monitoring & QR

### 4. Perubahan: Jadwal Hanya Untuk Musyrifah
**⚠️ Penting**: Jadwal Dauroh **hanya ditampilkan di halaman Musyrifah**, bukan di santri.
- Santri hanya melihat ikon Dauroh di dashboard (info ringkas)
- Musyrifah memiliki halaman jadwal lengkap
- Ini mengurangi kompleksitas di sisi santri

---

## ✅ Checklist Implementasi

### Admin:
- [ ] Tambah menu Dauroh di sidebar Admin
- [ ] Buat halaman Program Kegiatan (CRUD)
- [ ] Buat form Program Khusus (multi jenjang/kelas)
- [ ] Buat form Program Kelas
- [ ] Buat halaman Musyrifah (CRUD)
- [ ] Buat halaman Atur Jadwal
- [ ] Buat form Atur Jadwal (multi musyrifah, multi kelas)
- [ ] Buat halaman QR Absensi Musyrifah
- [ ] Buat halaman Monitoring Absensi
- [ ] Buat halaman Monitoring Nilai

### Santri (Program & Nilai):
- [ ] Tambah ikon Dauroh di dashboard
- [ ] Buat halaman Dauroh Santri
- [ ] Tampilkan program yang diikuti (nama, jenis, musyrifah)
- [ ] Tampilkan nilai dari program (hafalan/bacaan)

### Musyrifah (Role Baru):
- [ ] Buat dashboard Musyrifah
- [ ] Buat halaman Jadwal Dauroh (lihat jadwal mengajar)
- [ ] Buat halaman Absensi Dauroh (input absensi santri)
- [ ] Buat halaman Monitoring Nilai (lihat nilai santri)

---

## 🎯 Kesimpulan

Modul Dauroh adalah **fitur tambahan yang signifikan** untuk sistem informasi madrasah. Implementasinya membutuhkan:

1. **Backend**: 7+ tabel baru, 15+ endpoint API
2. **Frontend**: 12+ halaman baru, form-form kompleks
3. **Waktu**: Estimasi 3-4 minggu untuk full implementasi

**Perubahan Penting**: 
- Jadwal Dauroh **hanya untuk Musyrifah**, bukan santri
- Santri hanya melihat **Program yang diikuti** dan **Nilai**
- Musyrifah memiliki halaman jadwal lengkap

**Rekomendasi**: 
- Mulai dari **Master Data Program Kegiatan** dan **Musyrifah** (paling sederhana)
- Kemudian lanjut ke **Atur Jadwal** (paling kompleks)
- Terakhir **Dashboard Musyrifah** dan **Halaman Dauroh Santri**

Mau saya bantu implementasi mulai dari mana?
