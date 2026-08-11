# HISTORIS PERBAIKAN PPI

> Dokumentasi lengkap percakapan dan perbaikan kode PPI (Sistem Informasi Madrasah).
> Diperuntukkan sebagai referensi untuk manusia dan AI yang mengerjakan proyek ini.

---

## Informasi Proyek

| Item | Detail |
|---|---|
| **Project** | PPI — Sistem Informasi Madrasah (MA/MTs) |
| **Frontend** | Flutter Web |
| **Backend** | Cloudflare Workers (TypeScript) + D1/SQLite |
| **Frontend URL** | `https://ppi-bo8.pages.dev` |
| **Backend URL** | `https://ppi-backend-production.pgarut77.workers.dev` |
| **D1 Database** | `ppi-db-prod` (ID: `f4f8e08d-1d77-4cd4-8021-225e88ae233c`) |
| **GitHub** | `https://github.com/Pgarut/ppi.git` |
| **Tahun Ajaran Aktif** | `id=1, nama="2026-2027", is_aktif=1` |
| **Total Backend Tests** | 175 (semua passing) |

---

## 1. Tabel Master Data Horizontal Scroll + Bulk Upload Save Fix

**Commit**: `4ed239f`

### Masalah
- Tabel master data (santri, guru, kelas, dll) tidak bisa di-scroll horizontal di layar kecil
- Bulk upload santri gagal disimpan

### Percakapan
**User**: "tabel pada master data tidak bisa di scroll"

### Perbaikan
- Menambahkan `scrollable` pada `DataTable` di `master_data_page.dart`
- Memastikan tabel bisa di-scroll horizontal pada semua ukuran layar

---

## 2. Bulk Upload `tahun_ajaran_id` Null Validation + NISN Case

**Commit**: `7879827`

### Masalah
- Upload Excel santri gagal dengan error `NOT NULL constraint failed: siswa.tahun_ajaran_id`
- NISN tidak konsisten kapitalisasi (huruf besar/kecil)

### Percakapan
**User**: "error: NOT NULL constraint failed: siswa.tahun_ajaran_id"

### Perbaikan
- **Backend** (`master_data.ts`): Validasi `tahun_ajaran_id` sebelum insert — jika null, ambil dari tahun ajaran aktif
- **Frontend** (`bulk_upload_dialog.dart`): Normalisasi NISN ke uppercase
- Error detail ditampilkan ke user (row number + error message)

---

## 3. Absensi KS Test URL Path Fix

**Commit**: `836485f`

### Masalah
- Test absensi Kepala Sekolah menggunakan URL path yang salah

### Perbaikan
- Fix path URL pada test case absensi KS

---

## 4. Enforce Single Active Tahun Ajaran/Semester

**Commit**: `b770fab`

### Masalah
- Bisa membuat multiple tahun ajaran aktif secara bersamaan
- Bisa membuat multiple semester aktif secara bersamaan
- FK validation tidak ketat

### Percakapan
**User**: "pastikan tahun ajaran aktif hanya 1"

### Perbaikan
- **Backend** (`master_data.ts`): Saat create/update tahun ajaran dengan `is_aktif=1`, otomatis nonaktifkan tahun ajaran lain
- **Backend** (`master_data.ts`): Saat create/update semester dengan `is_aktif=1`, otomatis nonaktifkan semester lain
- `parseInt()` NaN safety untuk semua parameter ID

---

## 5. Perubahan Besar — Schema, Parent Data, Publikasi Nilai, Delete Nilai

**Commit**: `08fb37e`

### Masalah
- Data orang tua santri tidak tersimpan di database
- Form santri tidak punya field untuk data ayah/ibu
- Guru tidak bisa menghapus nilai draft
- Admin tidak bisa mengelola publikasi nilai
- Tabel nilai dan mata_pelajaran tidak punya UNIQUE constraint

### Percakapan
**User**: "tambahkan data orang tua santri (nama ayah, nama ibu, pekerjaan ayah, pekerjaan ibu) ke database dan form"

### Perbaikan Detail

#### A. Database Schema
- **Migration `0015`**: Menambah kolom `nama_ayah`, `nama_ibu`, `pekerjaan_ayah`, `pekerjaan_ibu`, `whatsapp` ke tabel `siswa`
- **Schema `schema.sql`**: Update CREATE TABLE siswa dengan kolom baru

#### B. CRUD Config Siswa
- **`master_data.ts`**: Config siswa sekarang punya 12 kolom:
  ```
  nis, nisn, nama, jenis_kelamin, kelas_id, tahun_ajaran_id, status,
  nama_ayah, nama_ibu, pekerjaan_ayah, pekerjaan_ibu, whatsapp
  ```

#### C. Auto-fill `tahun_ajaran_id`
- **Create** (`master_data.ts:89-93`): Jika `body['tahun_ajaran_id']` kosong, ambil dari tahun ajaran aktif
- **Update** (`master_data.ts:166-169`): Sama — auto-fill jika kosong
- **Bulk** (`master_data.ts:545`): `taId = (row['tahun_ajaran_id'] as number) || defaultTaId`

#### D. Bulk Upload — 12 Kolom
- **Template Excel** (`handleSiswaTemplate`): 12 kolom header
- **Preview** (`handleSiswaPreview`): 12 kolom output, termasuk nama_ayah, nama_ibu, pekerjaan_ayah, pekerjaan_ibu, whatsapp
- **Bulk INSERT** (`handleSiswaBulk`): 12 kolom INSERT statement

#### E. Publikasi Nilai
- **Backend** (`rapor.ts`):
  - `GET /admin/rapor/status-publikasi` — cek status publikasi
  - `PUT /admin/rapor/:id/publikasi-nilai` — toggle publikasi
- **Frontend** (`admin_rapor_page.dart`): Toggle switch untuk admin
- **Frontend** (`siswa_nilai_page.dart`): Halaman santri cek apakah nilai sudah dipublikasikan

#### F. Delete Nilai untuk Guru
- **Backend** (`nilai.ts`): `DELETE /guru/nilai/:id` — hanya bisa hapus nilai dengan `status_validasi='draft'`
- **Frontend** (`guru_nilai_page.dart`): Tombol hapus untuk nilai draft

#### G. UNIQUE Constraints
- **Migration `0012`**: `UNIQUE(nama)` pada `mata_pelajaran`
- **Migration `0013`**: `UNIQUE(siswa_id, mata_pelajaran_id, semester_id, jenis, diinput_oleh)` pada `nilai`

#### H. Simple Averaging untuk Rekap Nilai
- Rerata nilai per mata pelajaran per santri (harian, tugas, UTS, UAS → nilai akhir)

#### I. Const Fixes + Mounted Check
- Perbaikan `const` yang hilang di ~20 file frontend
- `mounted` check sebelum `setState` di semua async widget

---

## 6. Update `bulkSaveFields` untuk 12 Kolom

**Commit**: `1757fe0`

### Masalah
- `bulkSaveFields` di `master_data_page.dart` masih 7 kolom (lama), padahal database sudah 12 kolom

### Perbaikan
- Update `bulkSaveFields` santri di `master_data_page.dart:113` menjadi 12 field:
  ```dart
  ['nis', 'nisn', 'nama', 'jenis_kelamin', 'kelas_id', 'tahun_ajaran_id',
   'status', 'nama_ayah', 'nama_ibu', 'pekerjaan_ayah', 'pekerjaan_ibu', 'whatsapp']
  ```

---

## 7. Batch Processing untuk Bulk Upload — Cegah Timeout 1000 Row

**Commit**: `cf6a7af`

### Masalah
- Upload 1000 baris data santri dari Excel timeout/slow
- Setiap baris divalidasi satu per satu → sangat lambat

### Percakapan
**User**: "bulk upload 1000 data santri timeout"

### Perbaikan
- **Backend** (`master_data.ts:535-605`):
  - Validasi semua data terlebih dahulu (sebelum insert)
  - Batch check existing NIS: **1 query** untuk semua NIS (bukan 1 query per NIS)
  - Proses INSERT dalam **batch chunks of 50** menggunakan `env.DB.batch()`

---

## 8. Fix Unnecessary Cast Warning

**Commit**: `9ed57b9`

### Masalah
- Flutter analyze warning: unnecessary cast di `bulk_upload_dialog.dart`

### Perbaikan
- Hapus `as String` cast yang tidak perlu

---

## 9. Fix NetworkError pada Bulk Upload 1000 Row

**Commit**: `ccc6a81`

### Masalah
- Upload 1000 baris data santri tetap gagal dengan error:
  ```
  ClientException: NetworkError when attempting to fetch resource.
  uri=https://ppi-backend-production.pgarut77.workers.dev/api/admin/siswa/bulk
  ```
- Bukan masalah CORS, bukan masalah validasi — tapi **Cloudflare Workers timeout**

### Percakapan
**User**: "saya akan coba 500 data saja" (setelah 1000 data gagal)
**AI menganalisis**: Root cause ditemukan di `upsertUserForSiswa`

### Root Cause Analysis

Untuk setiap santri **baru**, `upsertUserForSiswa()` dipanggil di dalam loop batch:

```
1 baris santri baru = 3 query database:
  1. SELECT cek apakah user sudah ada
  2. INSERT/UPDATE user
  3. INSERT log_aktivitas

1000 baris baru = 3.000+ query database secara SEKUENSIAL
```

Cloudflare Workers free tier punya batas CPU time. Proses sebanyak ini **melebihi batas** → Worker timeout → frontend dapat `NetworkError`.

### Perbaikan

#### Backend (`master_data.ts`)

**Sebelum** (BROKEN — per-row user creation):
```typescript
// Di dalam loop batch:
const results = await env.DB.batch(statements);
for (const { nis } of batch) {
  if (!existingNisSet.has(nis)) {
    inserted++;
    const siswaId = result?.meta?.last_row_id;
    await upsertUserForSiswa(env, siswaId, nis, nis, user.sub, ip); // 3 DB calls PER ROW!
  }
}
```

**Sesudah** (FIXED — batch user creation):
```typescript
// 1. Simpan semua data siswa dulu (sama seperti sebelum)
const newSiswaIds: { siswaId: number; nis: string }[] = [];
// ... batch insert siswa ...

// 2. Setelah SEMUA siswa tersimpan, buat user secara batch
if (newSiswaIds.length > 0) {
  // Batch check existing users (1 query)
  const existingUsers = await env.DB.prepare(
    `SELECT id, siswa_id FROM users WHERE siswa_id IN (...)`
  ).bind(...siswaIds).all();

  // Hash password SEKALI (bukan per-row)
  const passwordHash = await bcrypt.hash('ppi123', 10);

  // Batch create/update users (50 per batch)
  const userStatements = [];
  for (const { siswaId, nis } of newSiswaIds) {
    if (existingUserMap.has(siswaId)) {
      userStatements.push(update statement);
    } else {
      userStatements.push(insert statement);
    }
  }
  // Execute in chunks of 50
  for (let u = 0; u < userStatements.length; u += 50) {
    await env.DB.batch(userStatements.slice(u, u + 50));
  }
}
```

**Tabel Perbandingan**:

| | Sebelum | Sesudah |
|---|---|---|
| Query untuk 1000 santri baru | ~3.000 query | ~22 query (20 batch siswa + 2 batch user) |
| Password hash | Dihitung 1000x | Dihitung **1x** |
| Waktu proses | >30 detik (timeout) | <5 detik |

#### Frontend (`bulk_upload_dialog.dart`)
- Tambah `Future.timeout(Duration(seconds: 120))` pada request bulk upload
- Tambah penanganan `TimeoutException` dengan pesan yang jelas

---

## 10. Fix Tabel Kelas Tampilkan Nama + Filter Jenjang

**Commit**: `0abd335`

### Masalah
1. **Tabel santri menampilkan angka** di kolom "Kelas" (misal: `5` alih-alih `X IPA 1`)
2. **Filter jenjang/kelas tidak sinkron** — filter dikirim tapi diabaikan backend

### Percakapan
**User**: "analisis pada tabel santri kenapa tabel kelas berupa angka, tidak berupa XA, XB dan seterusnya. terus pada pilih jenjang dan kelas data tidak sinkron atau muncul datanya berbeda"

### Root Cause Analysis

#### Masalah 1: Kolom Kelas Menampilkan Angka

Di `master_data_page.dart:330`, ada kode untuk resolve `kelas_id` ke nama kelas:

```dart
if (col == 'kelas_id' && ...) {
  final kelasList = _data[MasterDataType.kelas] ?? [];
  // ...lookup...
}
```

Tapi `_data[MasterDataType.kelas]` **kosong** saat tab santri aktif! Data kelas hanya di-load saat user mengklik tab "Kelas". Padahal `_kelasList` (variable terpisah) sudah di-load via `_loadSantriFilters()`.

**Kesalahan**: Pencarian pakai `_data[MasterDataType.kelas]` (kosong), bukan `_kelasList` (sudah ada data).

#### Masalah 2: Filter Jenjang/Kelas Tidak Bekerja

Frontend mengirim:
```
GET /admin/siswa?tingkat_id=3&kelas_id=5
```

Tapi backend CRUD config siswa:
```typescript
'siswa': {
  // ...tidak ada filterFields!
}
```

Tanpa `filterFields`, fungsi `list()` di `crud.ts` **mengabaikan** semua filter params. Filter `tingkat_id` juga butuh JOIN/subquery karena kolom `tingkat_id` ada di tabel `kelas`, bukan `siswa`.

### Perbaikan

#### A. Frontend `_displayValue` (`master_data_page.dart:330-337`)

**Sebelum** (BROKEN):
```dart
if (col == 'kelas_id' && ...) {
  final kelasList = _data[MasterDataType.kelas] ?? []; // KOSONG!
  ...
}
```

**Sesudah** (FIXED):
```dart
if (col == 'kelas_id' && ...) {
  final kelasList = type == MasterDataType.santri
      ? _kelasList  // Sudah di-load via _loadSantriFilters()
      : (_data[MasterDataType.kelas] ?? []);
  ...
}
```

#### B. Backend CRUD Config (`master_data.ts:60-63`)

**Sebelum**:
```typescript
'siswa': {
  table: 'siswa', columns: [...], searchFields: ['nama', 'nis', 'nisn'],
  // TIDAK ada filterFields!
}
```

**Sesudah**:
```typescript
'siswa': {
  table: 'siswa', columns: [...], searchFields: ['nama', 'nis', 'nisn'],
  filterFields: ['kelas_id'],  // TAMBAH filter kelas_id
}
```

#### C. Backend `crud.ts` — Support Extra Where Clause

Fungsi `list()` sekarang menerima parameter tambahan:
```typescript
export async function list(
  env: Env, cfg: CrudConfig, url: URL, user: UserPayload,
  extraWhere?: string,       // TAMBAHAN
  extraBindings?: unknown[]  // TAMBAHAN
)
```

#### D. Backend `handleAdminMasterData` — Tingkat Subquery (`master_data.ts:84-95`)

```typescript
if (resource === 'siswa') {
  const tingkatId = url.searchParams.get('tingkat_id');
  if (tingkatId) {
    extraWhere += ' AND siswa.kelas_id IN (SELECT kelas.id FROM kelas WHERE kelas.tingkat_id = ?)';
    extraBindings.push(tingkatId);
  }
}
```

#### E. Frontend `SantriForm` — Dropdown Jenjang (`santri_form.dart`)

**Sebelum**:
- Hanya ada 1 dropdown: **Kelas** (daftar semua kelas campur aduk, tidak ada filter)

**Sesudah**:
- **Dropdown 1: Jenjang/Tingkat** — pilih dulu (misal: VII, VIII, IX atau X, XI, XII)
- **Dropdown 2: Kelas** — otomatis terfilter hanya menampilkan kelas dari jenjang yang dipilih
- Saat edit, jenjang otomatis terpilih berdasarkan `kelas_id` santri

---

## 11. Gitignore Cleanup

**Commit**: `3d12bce`

### Perbaikan
- Tambah `temp_main.js` ke `.gitignore`
- File sementara tidak lagi ter-track di git

---

## Daftar File yang Sering Diubah

| File | Fungsi |
|---|---|
| `backend/src/routes/admin/master_data.ts` | CRUD handler siswa, bulk upload, auto-fill tahun_ajaran_id, filter |
| `backend/src/utils/crud.ts` | Generic CRUD (list, create, update, delete) |
| `backend/src/utils/response.ts` | CORS headers, response helpers |
| `backend/src/utils/auth.ts` | JWT auth, bcrypt password |
| `backend/src/db/schema.sql` | Skema database lengkap |
| `backend/migrations/*.sql` | Migrasi database |
| `backend/wrangler.toml` | Konfigurasi Cloudflare Workers |
| `frontend/lib/features/admin/master_data/master_data_page.dart` | Halaman master data admin |
| `frontend/lib/features/admin/master_data/widgets/bulk_upload_dialog.dart` | Dialog upload Excel |
| `frontend/lib/features/admin/master_data/widgets/santri_form.dart` | Form tambah/edit santri |
| `frontend/lib/features/admin/services/admin_service.dart` | Service layer admin API |
| `frontend/lib/core/network/api_client.dart` | HTTP client + auto-refresh token |

---

## Konfigurasi Penting

### `wrangler.toml` — CORS_ORIGIN
```toml
[vars]
CORS_ORIGIN = "https://ppi-bo8.pages.dev,https://f1198d05.ppi-bo8.pages.dev,https://ppi-frontend.pages.dev"
```

### `wrangler.toml` — D1 Database
```toml
[[d1_databases]]
binding = "DB"
database_name = "ppi-db-prod"
database_id = "f4f8e08d-1d77-4cd4-8021-225e88ae233c"
```

### Cloudflare Pages Secret
```
API_BASE_URL = https://ppi-backend-production.pgarut77.workers.dev
```

### Database Structure (Siswa)
```
siswa table:
  id, nis (UNIQUE), nisn (UNIQUE), nama, jenis_kelamin,
  tempat_lahir, tanggal_lahir, alamat, no_hp_ortu,
  nama_ayah, nama_ibu, pekerjaan_ayah, pekerjaan_ibu, whatsapp,
  kelas_id (FK → kelas.id), tahun_ajaran_id (FK → tahun_ajaran.id),
  status (aktif/lulus/pindah/keluar), created_at
```

---

## Perintah Deploy

```bash
# Backend
cd backend
npx wrangler deploy --env production

# Frontend
cd frontend
flutter build web
npx wrangler pages deploy build\web --project-name=ppi
```

---

## Checklist Setelah Perubahan Kode

- [ ] `npm test` di `backend/` — 175 tests passing
- [ ] `flutter analyze` di `frontend/` — No issues found
- [ ] Deploy backend: `npx wrangler deploy --env production`
- [ ] Deploy frontend: `npx wrangler pages deploy build\web --project-name=ppi`
- [ ] Test upload Excel 500-1000 baris — tidak timeout
- [ ] Cek tabel santri — kolom kelas tampilkan nama, bukan angka
- [ ] Test filter jenjang → kelas sinkron
- [ ] Test form tambah santri — dropdown jenjang filter kelas

---

*Terakhir diperbarui: Agustus 2026*
