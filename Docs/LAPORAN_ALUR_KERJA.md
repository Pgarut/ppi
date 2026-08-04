# Laporan Alur Kerja Sistem Informasi Madrasah PPI

## Daftar Isi
1. [Arsitektur Umum](#1-arsitektur-umum)
2. [Modul Auth](#2-modul-auth)
3. [Modul Admin](#3-modul-admin)
4. [Modul Wakil Kurikulum](#4-modul-wakil-kurikulum)
5. [Modul Guru Mapel / Wali Kelas](#5-modul-guru-mapel--wali-kelas)
6. [Modul Guru BK](#6-modul-guru-bk)
7. [Modul Kepala Sekolah](#7-modul-kepala-sekolah)
8. [Status Transitions](#8-status-transitions)
9. [Entity Relationship](#9-entity-relationship)

---

## 1. Arsitektur Umum

### Stack
| Layer | Teknologi |
|-------|-----------|
| **Frontend** | Flutter 3.5+ (Web + Mobile) |
| **Backend** | Cloudflare Workers (TypeScript) |
| **Database** | Cloudflare D1 (SQLite) |
| **State Management** | Provider (auth) + setState (per-page) |
| **Auth** | JWT (bcryptjs + jose) |

### Alur Request Umum
```
[Flutter UI] --> ApiClient --> HTTP Request
                                    |
                              [Cloudflare Worker]
                                    |
                              CORS Check
                                    |
                              Rate Limit Check
                                    |
                              Auth Middleware (JWT)
                                    |
                              Role Guard
                                    |
                              Route Handler
                                    |
                              Database (D1)
                                    |
                              Response JSON
```

### Struktur Routing Backend

| Prefix | Role | Method |
|--------|------|--------|
| `/api/auth/*` | Public | POST/GET |
| `/api/admin/*` | Admin | ALL |
| `/api/wakil-kurikulum/*` | Wakil Kurikulum | ALL |
| `/api/guru/*` | Guru Mapel/Wali Kelas | ALL |
| `/api/guru-bk/*` | Guru BK | ALL |
| `/api/kepala-sekolah/*` | Kepala Sekolah | GET only |
| `/api/referensi` | Any Auth | GET |

---

## 2. Modul Auth

### 2.1 Login Flow

```
LoginScreen
  |
  |--> GET /api/pengaturan-tampilan (hero_title, logo, background)
  |
  |--> User input username + password
  |
  |--> POST /api/auth/login { username, password }
         |
         |--> Brute Force Check (rate_limits table)
         |      |--> Jika terlalu banyak gagal -> 429 Too Many Requests
         |
         |--> Cari user di tabel `users` by username
         |      |--> User tidak ditemukan -> 401
         |      |--> is_active = 0 -> 401
         |
         |--> bcrypt.compare(password, hash)
         |      |--> Gagal -> 401 + catat kegagalan
         |      |--> Berhasil -> reset brute force counter
         |
         |--> generate JWT (1 jam expiry)
         |--> generate Refresh Token (disimpan di DB)
         |--> update last_login_at
         |--> log ke log_aktivitas
         |
         |--> Response: { token, refresh_token, user }
  |
  |--> Simpan token ke SharedPreferences
  |--> Navigasi ke Dashboard sesuai role
```

### 2.2 Refresh Token Flow

```
POST /api/auth/refresh { refresh_token, username }
  |
  |--> Verifikasi refresh_token di database
  |--> Generate JWT baru + Refresh Token baru
  |--> Response: { token, refresh_token }
```

### 2.3 Get Current User

```
GET /api/auth/me
  |
  |--> Ekstrak JWT dari Authorization header
  |--> Verify JWT signature + expiry
  |--> Response: { sub, username, role, guru_id, iat, exp }
```

### 2.4 Auto-Logout (Frontend)
```
AuthProvider.startInactivityTimer()
  |--> 30 menit tidak ada aktivitas -> logout otomatis
  |--> Hapus token dari storage
  |--> Navigasi ke /login
```

---

## 3. Modul Admin

Role: `admin` — Manajemen master data, monitoring, konfigurasi sistem.

### 3.1 Dashboard Admin

```
GET /api/admin/dashboard
  |
  |--> Hitung parallel:
  |     - Total guru aktif
  |     - Total siswa aktif
  |     - Total kelas
  |     - Absensi hari ini (by status)
  |     - Nilai (by status validasi)
  |     - Jadwal
  |
  |--> Response: { ringkasan, detail }
```

**Alur UI:**
```
AdminPage --> DashboardShell
  |--> DashboardPage: tampilkan stat grid
  |--> Feature tabs: Master Data, Absensi, Nilai, Rapor, Pengaturan
```

### 3.2 Master Data — CRUD Alur

Setiap resource (`tahun-ajaran`, `semester`, `jurusan`, `tingkat`, `kelas`, `mata-pelajaran`, `guru`, `siswa`, `ruangan`) menggunakan **generic CRUD utility** dengan pola:

```
GET /api/admin/{resource}?page=&per_page=&search=&filter
  |--> Query paginated dengan LIKE search
  |--> Response: { data: [], total, page, per_page }

POST /api/admin/{resource} { ...columns }
  |--> Validasi kolom required
  |--> INSERT
  |--> Log aktivitas
  |--> Response: { id, ... }

PUT /api/admin/{resource}/:id { ...columns }
  |--> Cek record exists
  |--> UPDATE partial
  |--> Log aktivitas

DELETE /api/admin/{resource}/:id
  |--> Cek foreign key constraint
  |--> DELETE
  |--> Log aktivitas
```

#### Relasi Khusus — Guru ↔ Mapel (Many-to-Many)

```
GET /api/admin/guru-mapel/:id
  |--> Return mapel_ids untuk guru tertentu

PUT /api/admin/guru-mapel/:id { mapel_ids: [1,2,3] }
  |--> Hapus semua relasi lama
  |--> Insert relasi baru
  |--> (Replace all pattern)
```

#### Relasi Khusus — Kelas ↔ Mapel

```
GET /api/admin/mapel-kelas/:id/kelas
PUT /api/admin/mapel-kelas/:id/kelas { kelas_ids: [1,2,3] }
```

#### Auto-Create User Saat Input Guru

```
POST /api/admin/guru (dengan username + password opsional)
  |
  |--> INSERT ke tabel guru
  |--> Jika username & password disertakan:
  |     |--> jabatanToRole(jabatan):
  |     |     - 'guru_bk'          -> role 'guru_bk'
  |     |     - 'wakil_kurikulum'   -> role 'wakil_kurikulum'
  |     |     - 'kepala_sekolah'    -> role 'kepala_sekolah'
  |     |     - default            -> role 'guru_mapel_wali_kelas'
  |     |--> bcrip hash password
  |     |--> INSERT ke tabel users (guru_id foreign key)
```

#### Bulk Import via Excel

```
POST /api/admin/{resource}/preview { file_base64 }
  |--> Parse Excel
  |--> Validasi per baris (NIP unik, status valid, dll)
  |--> Response: { rows: [...], errors: [...] }

POST /api/admin/{resource}/bulk { data: [...] }
  |--> INSERT per baris (wrap in try-catch)
  |--> Kembalikan count inserted + errors
```

### 3.3 Manajemen Users

```
GET /api/admin/users
POST /api/admin/users { username, password, role, ... }
PUT /api/admin/users/:id { ... }
DELETE /api/admin/users/:id

GET /api/admin/hak-akses
POST /api/admin/hak-akses { role, modul, aksi }
DELETE /api/admin/hak-akses/:id
```

### 3.4 Monitoring Absensi (Admin)

```
GET /api/admin/absensi/guru?tanggal=&status=
GET /api/admin/absensi/siswa?kelas_id=&tanggal=&status=
GET /api/admin/absensi/rekap?dari=&sampai=
  |--> Aggregasi by status (hadir/izin/sakit/alpa)
GET /api/admin/absensi/analisis
  |--> Per status, per kelas, per bulan, overview
GET /api/admin/absensi/audit
  |--> Log aktivitas untuk modul absensi
```

### 3.5 Monitoring Nilai (Admin)

```
GET /api/admin/nilai?kelas_id=&mapel_id=&jenis=&status=&semester=
PUT /api/admin/nilai/:id/validasi
  |--> Set status_validasi = 'tervalidasi'
GET /api/admin/nilai/analisis
  |--> Rata-rata per mapel, per kelas, overview
GET /api/admin/nilai/audit
```

### 3.6 Monitoring Rapor (Admin)

```
GET /api/admin/rapor?kelas_id=&semester=&status_kirim=
POST /api/admin/rapor/:id/cetak
  |--> Tandai dicetak + arsipkan
GET /api/admin/rapor/arsip
GET /api/admin/rapor/analisis
GET /api/admin/rapor/audit
```

### 3.7 System — Backup & Restore

```
POST /api/admin/backup
  |--> SELECT * FROM 22 tabel
  |--> Return JSON { dumped_at, table1: [...], table2: [...] }

POST /api/admin/restore { data }
  |--> Validasi struktur JSON
  |--> INSERT OR REPLACE per baris
```

### 3.8 Pengaturan Tampilan

```
GET /api/admin/pengaturan-tampilan
PUT /api/admin/pengaturan-tampilan { hero_title, hero_subtitle, logo_url, background_url }
  |--> Upsert pattern (INSERT ... ON CONFLICT(key) DO UPDATE)
```

---

## 4. Modul Wakil Kurikulum

Role: `wakil_kurikulum` — Penjadwalan, kurikulum, kenaikan kelas.

### 4.1 Dashboard WK

```
GET /api/wakil-kurikulum/dashboard
  |--> Statistik: total jadwal, kesiapan guru, progress nilai
```

### 4.2 Penjadwalan — Alur Utama

**A. Referensi & Kesiapan Guru**

```
GET /api/wakil-kurikulum/referensi
  |--> Data semester aktif, kelas, guru, mapel, ruangan

GET /api/wakil-kurikulum/kesiapan?semester_id=
  |--> List guru + hari_aktif + jp_max_per_hari/minggu + mapel/kelas diampu

PUT /api/wakil-kurikulum/kesiapan/:guru_id { hari_aktif, jp_max_per_hari, jp_max_per_minggu }
  |--> Upsert ke tabel guru_mata_pelajaran
```

**B. Manajemen Jadwal (Manual)**

```
POST /api/wakil-kurikulum/jadwal { kelas_id, guru_id, mapel_id, hari, jam_mulai, jam_selesai, ruangan_id }
  |
  |--> cekBentrok(guruId, kelasId, hari, jamMulai, jamSelesai, semesterId)
  |     |--> Guru bentrok? (same guru, same day, overlapping time)
  |     |--> Kelas bentrok? (same class, same day, overlapping time)
  |
  |--> INSERT jadwal_pelajaran (status_validasi = 'draft')

PUT /api/wakil-kurikulum/jadwal/:id
  |--> cekBentrok (exclude current ID)
  |--> UPDATE

DELETE /api/wakil-kurikulum/jadwal/:id
```

**C. Jadwal per Kelas**

```
GET /api/wakil-kurikulum/jadwal-per-kelas?kelas_id=&semester_id=
  |--> Return jadwal untuk satu kelas + info guru & ruangan
```

**D. Auto Generate Jadwal**

```
POST /api/wakil-kurikulum/jadwal/generate
  |
  |--> 1. Hapus semua jadwal draft semester ini
  |--> 2. Ambil semua data kesiapan guru, relasi guru-mapel-kelas
  |--> 3. Load jadwal tervalidasi (tidak diubah)
  |--> 4. Inisialisasi tracker occupancy:
  |     - occupiedKelas: Set<"kelas_id|hari|jam">
  |     - occupiedGuru: Set<"guru_id|hari|jam">
  |     - guruJpCount: Map<guru_id, Map<hari, count>>
  |     - guruMingguCount: Map<guru_id, count>
  |--> 5. Greedy assignment:
  |     for each kelas:
  |       for each mapel dibutuhkan:
  |         cari guru kompatibel (bisa ajar mapel, bisa ajar kelas,
  |               hari aktif, JP max belum terlampaui)
  |         assign ke JP slot pertama yang free
  |--> 6. INSERT assignments + return count
```

**E. Publikasi Jadwal**

```
POST /api/wakil-kurikulum/jadwal/publikasi
  |--> UPDATE jadwal_pelajaran SET status_validasi = 'tervalidasi'
  |     WHERE semester_id = ? AND status_validasi = 'draft'
```

**F. Reset Jadwal**

```
POST /api/wakil-kurikulum/jadwal/reset
  |--> DELETE FROM jadwal_pelajaran WHERE semester_id = ? AND status_validasi = 'draft'
```

### 4.3 Beban Mengajar

```
GET /api/wakil-kurikulum/beban-mengajar?semester_id=
  |--> Per guru: jp_max_per_minggu vs actual JP assigned
```

### 4.4 Bobot Nilai

```
GET /api/wakil-kurikulum/bobot-nilai
POST /api/wakil-kurikulum/bobot-nilai { mapel_id, tahun_ajaran_id, harian_persen, tugas_persen, uts_persen, uas_persen }
  |--> Validasi: total persen harus = 100
PUT /api/wakil-kurikulum/bobot-nilai/:id
```

### 4.5 Monitoring Nilai

```
GET /api/wakil-kurikulum/monitoring-nilai
  |--> 100 nilai terbaru dengan detail siswa/mapel/kelas

GET /api/wakil-kurikulum/status-pengumpulan
  |--> Aggregasi per guru: total input, draft count, validated count
```

### 4.6 Kenaikan Kelas

```
GET /api/wakil-kurikulum/kenaikan-kelas/calon?kelas_id=&tahun_ajaran_id=
  |--> List siswa dengan status 'aktif' di kelas tertentu

POST /api/wakil-kurikulum/kenaikan-kelas/proses { siswa_id, status, ke_kelas_id, ... }
  |
  |--> INSERT kenaikan_kelas
  |--> Jika status = 'lulus':
  |     |--> UPDATE siswa SET status = 'lulus'
  |--> Jika status = 'naik':
  |     |--> UPDATE siswa SET kelas_id = ke_kelas_id
```

### 4.7 Alumni

```
GET /api/wakil-kurikulum/alumni
POST /api/wakil-kurikulum/alumni { siswa_id, tahun_lulus, kontak, catatan }
PUT /api/wakil-kurikulum/alumni/:id
DELETE /api/wakil-kurikulum/alumni/:id
```

### 4.8 Laporan WK

```
GET /api/wakil-kurikulum/laporan/jadwal   -> All jadwal with joins
GET /api/wakil-kurikulum/laporan/absensi  -> 200 absensi records terbaru
GET /api/wakil-kurikulum/laporan/nilai    -> 200 nilai records terbaru
GET /api/wakil-kurikulum/laporan/rapor    -> All rapor records
```

**Alur UI:**
```
WakilKurikulumPage --> DashboardShell
  |--> DashboardPageWK
  |--> PenjadwalanPage: tab Jadwal, Kesiapan, Wali Kelas
  |     |--> Pilih semester -> Lihat/Generate/Validasi jadwal
  |--> AbsensiPageWK: tab Asatidz, Santri, Rekap
  |--> NilaiPageWK: tab Bobot Nilai, Monitoring, Status Pengumpulan
  |--> KenaikanKelasPage: tab Kenaikan Kelas, Alumni
  |--> LaporanPageWK: tab Jadwal, Absensi, Nilai, Rapor
```

---

## 5. Modul Guru Mapel / Wali Kelas

Role: `guru_mapel_wali_kelas` — Input absensi, nilai, pengaduan; wali kelas dapat akses rapor & data siswa.

### 5.1 Cek Status Wali Kelas

```
GET /api/guru/rapor/cek-wali
  |--> Cek apakah user.guru_id terdaftar sebagai wali_kelas_id di tabel kelas
  |--> Response: { isWaliKelas: bool }
```

**Alur UI:**
```
GuruMapelPage init
  |--> cekWaliKelas()
  |--> Jika true: tampilkan menu Rapor + Wali Kelas
  |--> Jika false: sembunyikan menu tsb
```

### 5.2 Dashboard Guru

```
GET /api/guru/dashboard
  |--> Stats: jadwal hari ini, total absensi, total nilai
```

### 5.3 Absensi — Alur Input

```
GET /api/guru/absensi/assignments
  |--> Return mapel+kelas yang diampu guru ini (via guru_mata_pelajaran
  |     atau fallback ke guru_mapel + guru_kelas)

GET /api/guru/absensi/siswa-per-kelas?kelas_id=&mapel_id=&tanggal=&jam=
  |--> List siswa di kelas + status absensi yang sudah ada (untuk prepopulate)

POST /api/guru/absensi { absensi: [{ siswa_id, status, keterangan }, ...] }
  |
  |--> Upsert per siswa:
  |     EXISTS (siswa_id + tanggal + mapel_id + jam) -> UPDATE
  |     NOT EXISTS -> INSERT
  |
  |--> Valid status: hadir, izin, sakit, alpa

GET /api/guru/absensi/riwayat-sesi
  |--> Grouped by tanggal/kelas/mapel
GET /api/guru/absensi/riwayat-sesi/detail?kelas_id=&mapel_id=&tanggal=&jam=
  |--> Per-siswa detail untuk sesi tertentu
```

**Alur UI:**
```
AbsensiPageGuru
  |--> Tab 1 - Input Absensi:
  |     |--> Pilih kelas -> Pilih mapel -> Pilih tanggal & jam
  |     |--> Tampilkan daftar siswa
  |     |--> Set status per siswa (hadir/izin/sakit/alpa)
  |     |--> Submit -> POST massal
  |
  |--> Tab 2 - Riwayat:
  |     |--> Tampilkan sesi-sesi sebelumnya
  |     |--> Klik sesi -> Detail per siswa
  |
  |--> Tab 3 - Assignments:
  |     |--> Tampilkan kelas + mapel yang diampu
```

### 5.4 Nilai — Alur Input

```
GET /api/guru/nilai/assignments
  |--> Mapel + kelas yang diampu

GET /api/guru/nilai/semester-aktif
  |--> Semester info + jenis nilai valid:
  |     Ganjil: ['harian', 'pts1', 'pas']
  |     Genap:  ['harian', 'pts2', 'pat']

GET /api/guru/nilai/siswa-per-kelas?kelas_id=&mapel_id=&jenis=&semester_id=
  |--> List siswa + nilai yang sudah ada

POST /api/guru/nilai/nilai-massal { kelas_id, mapel_id, semester_id, jenis, nilai: [{ siswa_id, nilai }] }
  |--> Upsert per siswa
  |--> Set status_validasi = 'draft'

POST /api/guru/nilai { siswa_id, mapel_id, kelas_id, semester_id, jenis, nilai }
  |--> Single entry

PUT /api/guru/nilai/:id { nilai }
  |--> Hanya bisa edit milik sendiri (diinput_oleh = user.guru_id)

POST /api/guru/nilai/upload-massal
  |--> Upload Excel untuk multiple grade types sekaligus
```

**Alur UI:**
```
NilaiPageGuru
  |--> 1. Pilih kelas
  |--> 2. Pilih mapel
  |--> 3. Pilih jenis nilai (Harian/PTS1/PTS2/PAS/PAT)
  |--> 4. Input nilai:
  |     |--> Manual: form per siswa
  |     |--> Massal: paste nilai
  |     |--> Excel: download template, upload hasil isian
  |--> 5. Submit
  |--> Export nilai (Excel)
```

### 5.5 Rapor (Khusus Wali Kelas)

```
GET /api/guru/rapor/data-wali
  |--> Info kelas wali + daftar siswa + mapel

GET /api/guru/rapor?siswa_id=&semester_id=
  |--> Generate rapor untuk satu siswa:
  |
  |   Algoritma perhitungan:
  |   |--> Tentukan jenis ujian (PAS untuk Ganjil, PAT untuk Genap)
  |   |--> Group nilai by mapel
  |   |--> Per mapel:
  |   |     - nilai_harian: array semua nilai 'harian'
  |   |     - rata_harian: average nilai_harian
  |   |     - nilai_ujian: nilai PAS atau PAT
  |   |     - nilai_akhir: (60% * nilai_ujian) + (40% * rata_harian)
  |   |     - predikat:
  |   |       >= 90 -> A
  |   |       >= 75 -> B
  |   |       >= 60 -> C
  |   |       < 60  -> D
  |
  |--> Response: { siswa, semester, mapel: [{...}], catatan_wali_kelas }

POST /api/guru/rapor/cetak (via admin)
  |--> Tandai dicetak + arsip
```

**Alur UI:**
```
RaporPageGuru (hanya muncul jika wali kelas)
  |--> 1. Pilih siswa
  |--> 2. Generate rapor (client-side PDF via `pdf` package)
  |--> 3. Preview
  |--> 4. Cetak via `printing` package
```

### 5.6 Pengaduan

```
POST /api/guru/pengaduan { siswa_id, kategori, deskripsi, bukti_url }
  |--> INSERT status = 'baru', dilaporkan_oleh = user.guru_id

GET /api/guru/pengaduan?status=
  |--> List pengaduan milik sendiri
```

### 5.7 Wali Kelas — Data Siswa

```
GET /api/guru/data-siswa
  |--> Data siswa lengkap + ringkasan:
  |     - absensi: hadir/izin/sakit/alpa count
  |     - status siswa (berdasarkan pengaduan):
  |       |--> pengaduan_disetujui / total * 100
  |       |--> >= 75% -> 'baik'
  |       |--> >= 50% -> 'cukup'
  |       |--> >= 25% -> 'kurang'
  |       |--> < 25%  -> 'kritis'
  |       |--> Jika 0 pengaduan -> default 'baik'

GET /api/guru/rekap-absensi
GET /api/guru/rekap-nilai

PUT /api/guru/catatan-wali { siswa_id, semester_id, catatan }
  |--> UPDATE nilai_rapor SET catatan_wali_kelas
```

---

## 6. Modul Guru BK

Role: `guru_bk` — Bimbingan konseling, pengaduan, monitoring siswa.

### 6.1 Dashboard BK

```
GET /api/guru-bk/statistik
  |--> Total pengaduan, aktif, selesai, per kategori, total konseling
```

### 6.2 Pengaduan — Alur Tangani

```
GET /api/guru-bk/pengaduan?status=&kategori=
  |--> List SEMUA pengaduan (tidak terfilter oleh reporter)

PUT /api/guru-bk/pengaduan/:id { status, tindak_lanjut }
  |--> Status transition: baru -> diproses -> selesai
  |--> Simpan catatan tindak lanjut
```

**Alur UI:**
```
PengaduanPageBK
  |--> List semua pengaduan (filter by status/kategori)
  |--> Klik detail:
  |     |--> Lihat deskripsi + bukti
  |     |--> Update status (baru -> diproses -> selesai)
  |     |--> Input tindak lanjut
```

### 6.3 Jadwal Konseling — Alur CRUD

```
GET /api/guru-bk/jadwal-konseling/siswa?kelas_id=
  |--> List siswa + jadwal konseling yang sudah ada

POST /api/guru-bk/jadwal-konseling { siswa_id, tanggal, jam, jenis, catatan? }
  |--> INSERT jadwal_konseling (status = 'dijadwalkan')
  |--> Jika catatan disertakan: INSERT konseling langsung

PUT /api/guru-bk/jadwal-konseling/:id { status, ... }
  |--> Update status: dijadwalkan -> selesai/dibatalkan

DELETE /api/guru-bk/jadwal-konseling/:id
```

### 6.4 Konseling — Catatan

```
POST /api/guru-bk/konseling { jadwal_id, siswa_id, catatan, tindak_lanjut }
  |--> Hubungkan dengan jadwal_konseling
GET /api/guru-bk/konseling
PUT /api/guru-bk/konseling/:id
```

### 6.5 Bakat & Minat

```
POST /api/guru-bk/bakat-minat { siswa_id, jenis, deskripsi, catatan_pengembangan }
  |--> Jenis: 'bakat' atau 'minat'
  |--> guru_bk_id = user.guru_id

GET /api/guru-bk/bakat-minat
GET /api/guru-bk/bakat-minat/siswa?kelas_id=
PUT /api/guru-bk/bakat-minat/:id
DELETE /api/guru-bk/bakat-minat/:id
```

### 6.6 Monitoring Akademik

```
GET /api/guru-bk/monitoring/absensi
  |--> Per-siswa: total hadir, izin, sakit, alpa

GET /api/guru-bk/monitoring/pelanggaran
  |--> Per-siswa: jumlah pengaduan kategori 'perilaku'
```

### 6.7 Laporan BK

```
GET /api/guru-bk/bulanan?tahun=&bulan=
  |--> Laporan pengaduan bulanan

GET /api/guru-bk/rekap-kasus
  |--> Per kategori: jumlah pengaduan

GET /api/guru-bk/konseling
  |--> Laporan konseling per bulan

GET /api/guru-bk/bakat-minat
  |--> Statistik by jenis

GET /api/guru-bk/monitoring
  |--> Cross-module: rata-rata nilai, absensi, pengaduan
```

**Alur UI:**
```
GuruBKPage --> DashboardShell
  |--> DashboardPageBK: stat grid
  |--> PengaduanPageBK: List + Filter + Update Status
  |--> KonselingPage:
  |     |--> Tab Jadwal: tambah jadwal konseling
  |     |--> Tab History: riwayat konseling
  |--> BakatMinatPage:
  |     |--> Pilih kelas -> Pilih siswa
  |     |--> Tambah/edit bakat & minat
  |--> MonitoringAkademikPage:
  |     |--> Tab Absensi
  |     |--> Tab Pelanggaran
  |--> LaporanPageBK:
  |     |--> Load semua laporan paralel
```

---

## 7. Modul Kepala Sekolah

Role: `kepala_sekolah` — **Read-only monitoring** semua aspek.

### 7.1 Dashboard KS

```
GET /api/kepala-sekolah/dashboard
  |--> Total siswa, guru, kelas, mapel
  |--> Jadwal per hari
  |--> Absensi recap (by status)
  |--> Nilai distribution
```

### 7.2 Monitoring

Semua endpoint read-only:

```
GET /api/kepala-sekolah/jadwal?kelas_id=
GET /api/kepala-sekolah/absensi?kelas_id=
GET /api/kepala-sekolah/nilai?kelas_id=
GET /api/kepala-sekolah/rapor?kelas_id=&semester_id=
```

### 7.3 BK Overview

```
GET /api/kepala-sekolah/bk
  |--> Konseling per bulan
  |--> Bakat & minat by jenis
  |--> Top 10 siswa bermasalah
```

### 7.4 Laporan

```
GET /api/kepala-sekolah/laporan?jenis=
  |--> jenis: jadwal | absensi | nilai | rapor
```

**Alur UI:**
```
KepalaSekolahPage --> DashboardShell
  |--> DashboardPageKS: stat grid
  |--> LaporanPageKS: 4 tabs (Jadwal, Absensi, Nilai, Rapor)
  |     |--> Filter by kelas + semester
  |     |--> Tampilkan dalam DataTable
  |--> BKPageKS: 3 sections (Konseling, Bakat Minat, Santri Bermasalah)
```

---

## 8. Status Transitions

| Entity | Field | Values | Transitions |
|--------|-------|--------|-------------|
| **Jadwal Pelajaran** | `status_validasi` | `draft`, `tervalidasi` | `draft` → `tervalidasi` (via publikasi WK) |
| **Nilai** | `status_validasi` | `draft`, `tervalidasi` | `draft` → `tervalidasi` (via validasi admin) |
| **Pengaduan** | `status` | `baru`, `diproses`, `selesai` | `baru` → `diproses` → `selesai` (via BK) |
| **Jadwal Konseling** | `status` | `dijadwalkan`, `selesai`, `dibatalkan` | Any to any |
| **Siswa** | `status` | `aktif`, `tidak_aktif`, `pindah`, `lulus` | `aktif` → `lulus` (via kenaikan kelas) |
| **Kenaikan Kelas** | `status` | `naik`, `tidak_naik`, `lulus` | Set at creation |

---

## 9. Entity Relationship

```
tahun_ajaran
  |
  +--< semester
  |      |
  |      +--< jadwal_pelajaran
  |      +--< nilai
  |      +--< nilai_rapor
  |      +--< bobot_nilai
  |      +--< guru_mata_pelajaran
  |
  +--< kelas
  |      |
  |      +--< siswa
  |      |     +--< absensi_siswa
  |      |     +--< nilai
  |      |     +--< pengaduan
  |      |     +--< konseling
  |      |     +--< bakat_minat
  |      |     +--< kenaikan_kelas
  |      |     +--< alumni
  |      |
  |      +--< mapel_kelas >-- mata_pelajaran
  |      +--< guru_kelas >-- guru
  |      +--< jadwal_pelajaran
  |
  +--< tingkat
  +--< jurusan
  +--< ruangan

guru
  |--< users (optional)
  |--< guru_mapel >-- mata_pelajaran
  |--< guru_kelas >-- kelas
  |--< guru_mata_pelajaran
  |--< absensi_guru
  |--< jadwal_pelajaran (as pengajar)
  |--< nilai (as diinput_oleh)
  |--< absensi_siswa (as diinput_oleh)
  |--< pengaduan (as dilaporkan_oleh)
  |--< konseling (as guru_bk_id)
  |--< bakat_minat (as guru_bk_id)
```

---

*Dokumen ini dibuat berdasarkan analisis kode sumber backend (`backend/src/routes/`) dan frontend (`frontend/lib/features/`) per 30 Juli 2026.*
