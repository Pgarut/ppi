# 🎨 Desain Modul Dauroh - Master Data Admin
## Sistem Informasi Madrasah PPI

---

## 📐 Arsitektur Modul

```
Master Data Admin
├── 📚 Dauroh (Menu Baru)
│   ├── 1. Program Kegiatan
│   ├── 2. Musyrifah
│   ├── 3. Atur Jadwal
│   └── 4. Monitoring
│       ├── Absensi
│       └── Nilai
```

---

## 1️⃣ PROGRAM KEGIATAN

### Tampilan List (Table)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  📚 Program Kegiatan Dauroh                                    [+ Tambah]  │
├─────────────────────────────────────────────────────────────────────────────┤
│ 🔍 Cari program...                                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│ No │ Nama Program    │ Jenis      │ Jenis Dauroh │ Kelas │ Status │ Aksi   │
├────┼─────────────────┼────────────┼──────────────┼───────┼────────┼────────┤
│ 1  │ Tahfidz Juz 30  │ Khusus     │ Hafalan      │ 15    │ Aktif  │ ✏️ 🗑️ │
│ 2  │ Qira'ati        │ Kelas      │ Bacaan       │ 8     │ Aktif  │ ✏️ 🗑️ │
│ 3  │ Hadist 40       │ Khusus     │ Hafalan      │ 20    │ Aktif  │ ✏️ 🗑️ │
│ 4  │ Adab & Akhlak   │ Kelas      │ Hafalan      │ 12    │ Aktif  │ ✏️ 🗑️ │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                  ◀ 1/2 ▶   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Form Tambah/Edit Program Kegiatan

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  📚 Tambah Program Kegiatan Dauroh                                    [X]  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─ Data Program ──────────────────────────────────────────────────────┐   │
│  │                                                                     │   │
│  │  Nama Program Kegiatan                                              │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ Tahfidz Juz 30                                              │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  Jenis Program            │  Jenis Dauroh                          │   │
│  │  ┌──────────────────────┐ │  ┌──────────────────────┐              │   │
│  │  │ ○ Program Khusus  ▼ │ │  │ ○ Hafalan          ▼ │              │   │
│  │  │ ○ Program Kelas      │ │  │ ○ Bacaan             │              │   │
│  │  └──────────────────────┘ │  └──────────────────────┘              │   │
│  │                                                                     │   │
│  │  Keterangan                                                         │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ Program hafalan untuk santri pilihan                        │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─ Pilih Kelas (Program Khusus) ─────────────────────────────────────┐   │
│  │                                                                     │   │
│  │  Jenjang: [  Semua Jenjang  ▼]                                     │   │
│  │                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ ☑ X MIPA 1        ☐ X MIPA 2        ☐ X MIPA 3            │   │   │
│  │  │ ☑ XI MIPA 1       ☐ XI MIPA 2       ☐ XI MIPA 3           │   │   │
│  │  │ ☐ XII MIPA 1      ☐ XII MIPA 2      ☐ XII MIPA 3          │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  ☑ Pilih Semua Kelas di Jenjang Ini                                │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─ Pilih Santri ─────────────────────────────────────────────────────┐   │
│  │                                                                     │   │
│  │  Filter: Jenjang [  Semua  ▼]  Kelas [  Semua  ▼]                  │   │
│  │                                                                     │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ ☑ Ahmad Fadillah    │ NIS: 00123  │ X MIPA 1                │   │   │
│  │  │ ☑ Fitri Anjani      │ NIS: 00124  │ X MIPA 1                │   │   │
│  │  │ ☐ Muhammad Rizki    │ NIS: 00125  │ X MIPA 2                │   │   │
│  │  │ ☐ Aisyah Putri      │ NIS: 00126  │ XI MIPA 1               │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  Total terpilih: 2 santri                                           │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│                                    [ Batal ]              [ Simpan ]        │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Logic Program:
```
IF jenis_program == 'Khusus':
    Tampilkan pemilihan Jenjang → Kelas → Santri
    Santri dipilih secara individu
    
IF jenis_program == 'Kelas':
    Tampilkan pemilihan Jenjang → Kelas saja
    Semua santri di kelas tersebut otomatis ikut
```

---

## 2️⃣ MUSYRIFAH

### Tampilan List (Table)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  👩‍🏫 Data Musyrifah Dauroh                                    [+ Tambah]  │
├─────────────────────────────────────────────────────────────────────────────┤
│ 🔍 Cari musyrifah...                                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│ No │ NIPMUS     │ Nama            │ JK  │ Status      │ Gelar │ Username  │
├────┼────────────┼─────────────────┼─────┼─────────────┼───────┼───────────┤
│ 1  │ MUS001     │ Siti Aminah     │ P   │ Selesai     │ S.Pd  │ siti_aminah│
│ 2  │ MUS002     │ Abdul Rahman    │ L   │ Mahasiswa   │ -     │ abdul_r   │
│ 3  │ MUS003     │ Fatimah Zahra   │ P   │ Selesai     │ S.Pd.I│ fatimah_z │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                  ◀ 1/1 ▶   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Form Tambah/Edit Musyrifah

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  👩‍🏫 Tambah Data Musyrifah                                        [X]     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─ Data Diri ─────────────────────────────────────────────────────────┐   │
│  │                                                                     │   │
│  │  NIPMUS (Nomor Induk Pengawai)                                      │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ MUS001                                                      │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  Nama Lengkap Musyrifah                                             │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ Siti Aminah                                                  │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  Jenis Kelamin            │  Status Pendidikan                      │   │
│  │  ┌──────────────────────┐ │  ┌──────────────────────┐              │   │
│  │  │ ○ Laki-laki (L)  ▼  │ │  │ ○ Selesai (S.Pd)  ▼ │              │   │
│  │  │ ○ Perempuan (P)      │ │  │ ○ Mahasiswa          │              │   │
│  │  └──────────────────────┘ │  └──────────────────────┘              │   │
│  │                                                                     │   │
│  │  Gelar (Opsional)                                                   │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ S.Pd                                                        │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─ Akun Login ────────────────────────────────────────────────────────┐   │
│  │                                                                     │   │
│  │  Username                                                          │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ siti_aminah                                                  │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  Password                                                          │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ ••••••••                                                     │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  ☑ Generate Password Otomatis: [  random_123  ] [ 🔄 Generate]     │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│                                    [ Batal ]              [ Simpan ]        │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3️⃣ ATUR JADWAL PROGRAM

### Tampilan List (Table)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  📅 Atur Jadwal Program Dauroh                                [+ Tambah]  │
├─────────────────────────────────────────────────────────────────────────────┤
│ 🔍 Cari jadwal...                                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│ No │ Program        │ Musyrifah 1   │ Musyrifah 2 │ Hari    │ Jam        │
├────┼────────────────┼───────────────┼─────────────┼─────────┼────────────│
│ 1  │ Tahfidz Juz 30 │ Siti Aminah   │ -           │ Sabtu   │ 08:00-10:00│
│ 2  │ Qira'ati       │ Abdul Rahman  │ Fatimah Z   │ Minggu  │ 07:00-09:00│
│ 3  │ Hadist 40      │ Siti Aminah   │ Abdul R     │ Senin   │ 15:00-17:00│
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                  ◀ 1/1 ▶   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Form Tambah/Edit Jadwal

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  📅 Tambah Jadwal Program Dauroh                                  [X]     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─ Data Jadwal ───────────────────────────────────────────────────────┐   │
│  │                                                                     │   │
│  │  Program Kegiatan                                                   │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ Tahfidz Juz 30                                              ▼ │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  Musyrifah 1 (Wajib)        │  Musyrifah 2 (Opsional)              │   │
│  │  ┌──────────────────────┐   │  ┌──────────────────────┐            │   │
│  │  │ Siti Aminah       ▼  │   │  │ - Pilih Musyrifah ▼ │            │   │
│  │  └──────────────────────┘   │  └──────────────────────┘            │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─ Pilih Kelas ───────────────────────────────────────────────────────┐   │
│  │                                                                     │   │
│  │  Jenjang                                                           │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ Semua Jenjang                                                ▼ │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  Kelas (Bisa pilih lebih dari satu)                                │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ ☑ X MIPA 1        ☑ X MIPA 2        ☐ X MIPA 3            │   │   │
│  │  │ ☑ XI MIPA 1       ☐ XI MIPA 2       ☐ XI MIPA 3           │   │   │
│  │  │ ☐ XII MIPA 1      ☐ XII MIPA 2      ☐ XII MIPA 3          │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  ☑ Pilih Semua Kelas di Jenjang Ini                                │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ┌─ Waktu ─────────────────────────────────────────────────────────────┐   │
│  │                                                                     │   │
│  │  Hari                                                               │   │
│  │  ┌─────────────────────────────────────────────────────────────┐   │   │
│  │  │ ☑ Sabtu    ☐ Minggu   ☐ Senin    ☐ Selasa                  │   │   │
│  │  │ ☐ Rabu     ☐ Kamis    ☐ Semua Hari                         │   │   │
│  │  └─────────────────────────────────────────────────────────────┘   │   │
│  │                                                                     │   │
│  │  Jam Mulai              │  Jam Selesai                              │   │
│  │  ┌──────────────────┐   │  ┌──────────────────┐                    │   │
│  │  │ 08:00          ▼ │   │  │ 10:00          ▼ │                    │   │
│  │  └──────────────────┘   │  └──────────────────┘                    │   │
│  │                                                                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│                                    [ Batal ]              [ Simpan ]        │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4️⃣ MONITORING

### 4.1 Monitoring Absensi

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  📊 Monitoring Absensi Dauroh                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Filter:                                                                   │
│  Program [  Tahfidz Juz 30  ▼]  Kelas [  X MIPA 1  ▼]                     │
│  Tanggal [  06/08/2026  ]                                                  │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ No │ Nama            │ NIS    │ Status    │ Keterangan              │   │
│  ├────┼─────────────────┼────────┼───────────┼─────────────────────────│   │
│  │ 1  │ Ahmad Fadillah  │ 00123  │ ✅ Hadir  │ -                       │   │
│  │ 2  │ Fitri Anjani    │ 00124  │ ⚠️ Izin   │ Sakit flu               │   │
│  │ 3  │ Muhammad Rizki  │ 00125  │ ❌ Alpha  │ -                       │   │
│  │ 4  │ Aisyah Putri    │ 00126  │ ✅ Hadir  │ -                       │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  Rekap: Hadir: 2 | Izin: 1 | Alpha: 1 | Total: 4                          │
│                                                                             │
│                                         [ 📄 Export Excel ] [ 🖨️ Print ]    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 4.2 Monitoring Nilai

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  📊 Monitoring Nilai Dauroh                                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Filter:                                                                   │
│  Jenjang [  Semua Jenjang  ▼]  Kelas [  Semua Kelas  ▼]                    │
│                                                                             │
│  [ 🖨️ Print View ]                                                         │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ No │ Nama            │ NIS    │ Kelas   │ Hafalan │ Bacaan │ Total  │   │
│  ├────┼─────────────────┼────────┼─────────┼─────────┼────────┼────────│   │
│  │ 1  │ Ahmad Fadillah  │ 00123  │ X MIPA1 │ 85      │ 90     │ 87.5   │   │
│  │ 2  │ Fitri Anjani    │ 00124  │ X MIPA1 │ 90      │ 85     │ 87.5   │   │
│  │ 3  │ Muhammad Rizki  │ 00125  │ X MIPA2 │ 78      │ 82     │ 80.0   │   │
│  │ 4  │ Aisyah Putri    │ 00126  │ XI MIPA1│ 92      │ 88     │ 90.0   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│                                         [ 📄 Export Excel ] [ 🖨️ Print ]    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🗄️ Database Schema

### 1. Tabel Program Kegiatan
```sql
CREATE TABLE dauroh_program (
  id SERIAL PRIMARY KEY,
  nama_program VARCHAR(255) NOT NULL,
  jenis_program VARCHAR(20) NOT NULL CHECK (jenis_program IN ('khusus', 'kelas')),
  jenis_dauroh VARCHAR(20) NOT NULL CHECK (jenis_dauroh IN ('hafalan', 'bacaan')),
  keterangan TEXT,
  tahun_ajaran_id INTEGER REFERENCES tahun_ajaran(id),
  is_aktif BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2. Tabel Musyrifah
```sql
CREATE TABLE dauroh_musyrifah (
  id SERIAL PRIMARY KEY,
  nipmus VARCHAR(50) UNIQUE NOT NULL,
  nama VARCHAR(255) NOT NULL,
  jenis_kelamin VARCHAR(1) NOT NULL CHECK (jenis_kelamin IN ('L', 'P')),
  status_pendidikan VARCHAR(20) NOT NULL CHECK (status_pendidikan IN ('selesai', 'mahasiswa')),
  gelar VARCHAR(100),
  username VARCHAR(100) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  is_aktif BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 3. Tabel Jadwal Dauroh
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
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 4. Tabel Relasi Jadwal-Kelas
```sql
CREATE TABLE dauroh_jadwal_kelas (
  id SERIAL PRIMARY KEY,
  jadwal_id INTEGER NOT NULL REFERENCES dauroh_jadwal(id) ON DELETE CASCADE,
  kelas_id INTEGER NOT NULL REFERENCES kelas(id),
  UNIQUE(jadwal_id, kelas_id)
);
```

### 5. Tabel Program Santri (Program Khusus)
```sql
CREATE TABLE dauroh_program_santri (
  id SERIAL PRIMARY KEY,
  program_id INTEGER NOT NULL REFERENCES dauroh_program(id) ON DELETE CASCADE,
  santri_id INTEGER NOT NULL REFERENCES siswa(id),
  UNIQUE(program_id, santri_id)
);
```

### 6. Tabel Absensi Dauroh
```sql
CREATE TABLE dauroh_absensi (
  id SERIAL PRIMARY KEY,
  jadwal_id INTEGER NOT NULL REFERENCES dauroh_jadwal(id),
  santri_id INTEGER NOT NULL REFERENCES siswa(id),
  tanggal DATE NOT NULL,
  status VARCHAR(10) NOT NULL CHECK (status IN ('hadir', 'izin', 'sakit', 'alpha')),
  keterangan TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(jadwal_id, santri_id, tanggal)
);
```

### 7. Tabel Nilai Dauroh
```sql
CREATE TABLE dauroh_nilai (
  id SERIAL PRIMARY KEY,
  program_id INTEGER NOT NULL REFERENCES dauroh_program(id),
  santri_id INTEGER NOT NULL REFERENCES siswa(id),
  nilai_hafalan DECIMAL(5,2),
  nilai_bacaan DECIMAL(5,2),
  catatan TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(program_id, santri_id)
);
```

---

## 🔌 API Endpoints

### Program Kegiatan
```
GET    /api/dauroh/program              - List semua program
GET    /api/dauroh/program/:id          - Detail program
POST   /api/dauroh/program              - Tambah program
PUT    /api/dauroh/program/:id          - Update program
DELETE /api/dauroh/program/:id          - Hapus program
GET    /api/dauroh/program/:id/santri   - List santri di program
POST   /api/dauroh/program/:id/santri   - Tambah santri ke program
DELETE /api/dauroh/program/:id/santri/:santri_id - Hapus santri dari program
```

### Musyrifah
```
GET    /api/dauroh/musyrifah            - List semua musyrifah
GET    /api/dauroh/musyrifah/:id        - Detail musyrifah
POST   /api/dauroh/musyrifah            - Tambah musyrifah
PUT    /api/dauroh/musyrifah/:id        - Update musyrifah
DELETE /api/dauroh/musyrifah/:id        - Hapus musyrifah
```

### Jadwal
```
GET    /api/dauroh/jadwal               - List semua jadwal
GET    /api/dauroh/jadwal/:id           - Detail jadwal
POST   /api/dauroh/jadwal               - Tambah jadwal
PUT    /api/dauroh/jadwal/:id           - Update jadwal
DELETE /api/dauroh/jadwal/:id           - Hapus jadwal
GET    /api/dauroh/jadwal/hari/:hari    - Jadwal per hari
GET    /api/dauroh/jadwal/kelas/:kelas_id - Jadwal per kelas
```

### Absensi
```
GET    /api/dauroh/absensi              - List absensi (filter: jadwal_id, tanggal)
POST   /api/dauroh/absensi              - Tambah absensi
PUT    /api/dauroh/absensi/:id          - Update absensi
DELETE /api/dauroh/absensi/:id          - Hapus absensi
GET    /api/dauroh/absensi/rekap        - Rekap absensi
```

### Monitoring
```
GET    /api/dauroh/monitoring/absensi   - Monitoring absensi (filter: program, kelas, tanggal)
GET    /api/dauroh/monitoring/nilai     - Monitoring nilai (filter: jenjang, kelas)
```

### Santri (Program & Nilai)
```
GET    /api/dauroh/santri/program       - List program yang diikuti santri
GET    /api/dauroh/santri/nilai         - List nilai santri
```

---

## 📁 Struktur File Flutter

```
lib/features/admin/dauroh/
├── dauroh_page.dart                    # Halaman utama dengan tab
├── program_kegiatan/
│   ├── program_list_page.dart          # List program
│   └── program_form_page.dart          # Form tambah/edit
├── musyrifah/
│   ├── musyrifah_list_page.dart        # List musyrifah
│   └── musyrifah_form_page.dart        # Form tambah/edit
├── jadwal/
│   ├── jadwal_list_page.dart           # List jadwal
│   └── jadwal_form_page.dart           # Form tambah/edit
├── monitoring/
│   ├── absensi_monitoring_page.dart    # Monitoring absensi
│   └── nilai_monitoring_page.dart      # Monitoring nilai
└── services/
    └── dauroh_service.dart             # API service
```

---

## 🎯 Implementasi Bertahap

### Fase 1 (Minggu 1): Master Data Dasar
- [ ] Tambah enum `dauroh` di MasterDataType
- [ ] Form Program Kegiatan (sederhana)
- [ ] Form Musyrifah

### Fase 2 (Minggu 2): Atur Jadwal
- [ ] Form Atur Jadwal (kompleks)
- [ ] Multi musyrifah
- [ ] Multi kelas

### Fase 3 (Minggu 3): Monitoring
- [ ] Monitoring Absensi
- [ ] Monitoring Nilai
- [ ] Export Excel

### Fase 4 (Minggu 4): Santri & Testing
- [ ] Ikon Dauroh di dashboard santri
- [ ] Halaman Dauroh santri
- [ ] Testing & bug fix

---

## 💡 Tips Implementasi

1. **Mulai dari yang sederhana** - Program Kegiatan & Musyrifah dulu
2. **Gunakan existing components** - `MasterDataTable`, `ModernField`, `ModernDropdown`
3. **Backend endpoint** - Buat endpoint satu per satu sesuai kebutuhan
4. **Testing** - Test setiap fitur sebelum lanjut ke fitur berikutnya

---

**Mau saya bantu implementasi mulai dari Fase 1?**
