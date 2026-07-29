# Laporan Perubahan Modul Penjadwalan — Wakil Kurikulum

**Tanggal:** 29 Juli 2026
**Proyek:** Sistem Informasi Madrasah (PPI)

---

## 1. Ringkasan Percakapan

### Masalah Awal
- Assertion error `NavigationRail` pada halaman desktop: `!extended || (labelType == null || labelType == NavigationRailLabelType.none) is not true`
- **Penyebab:** `NavigationRail(extended: true)` di `_buildDesktop()` tidak menyetel `labelType`, sehingga mewarisi `NavigationRailLabelType.all` dari tema global (`app_theme.dart:97`)
- **Perbaikan:** Tambah `labelType: NavigationRailLabelType.none` pada `dashboard_shell.dart:173`

### Audit Modul Wakil Kurikulum
- Menemukan 8 modul: Entry Point, Dashboard, Absensi, Penjadwalan, Nilai, Kenaikan Kelas, Laporan, Service
- **5 Critical Issues** teridentifikasi:
  1. Silent catch di semua error handling
  2. Kenaikan Kelas form meminta input ID mentah (tidak pakai dropdown)
  3. Bobot Nilai form kirim `null` tanpa validasi
  4. Reset jadwal backend hapus SEMUA termasuk tervalidasi
  5. Row action buttons overflow di layar sempit

### Fokus: Redesign Penjadwalan
**Konsep baru:** Tab **Distribusi** → **Kesiapan Mengajar Guru**

| Data | Sumber |
|---|---|
| Nama Guru | Admin Master Data (`GET /api/admin/guru`) |
| Hari Mengajar | Checkbox: Sabtu, Minggu, Senin, Selasa, Rabu, Kamis (Jumat libur) |
| JP Maks/Hari | Input manual oleh WK |
| JP Maks/Minggu | Input manual oleh WK |
| Kelas Diampu | Dari Admin `guru_kelas` |
| Mapel Diampu | Dari Admin `guru_mapel` |
| Kapasitas | 🟢 <80%, 🟡 80-99%, 🔴 ≥100% + info |

---

## 2. Database Migration

### File: `backend/migrations/0004_guru_kesiapan.sql`

```sql
-- Migration 0004: Perluas guru_mata_pelajaran untuk Kesiapan Mengajar
-- Target: Cloudflare D1 (SQLite)

ALTER TABLE guru_mata_pelajaran ADD COLUMN hari_aktif TEXT DEFAULT '[]';
ALTER TABLE guru_mata_pelajaran ADD COLUMN jp_max_per_hari INTEGER DEFAULT 8;
ALTER TABLE guru_mata_pelajaran ADD COLUMN jp_max_per_minggu INTEGER DEFAULT 24;
```

### Kolom Baru di `guru_mata_pelajaran`

| Kolom | Tipe | Default | Fungsi |
|---|---|---|---|
| `hari_aktif` | `TEXT` | `'[]'` | JSON array hari aktif guru |
| `jp_max_per_hari` | `INTEGER` | `8` | Maksimal JP per hari |
| `jp_max_per_minggu` | `INTEGER` | `24` | Maksimal JP per minggu |

---

## 3. Perubahan Backend

### 3.1 File: `backend/src/routes/wakil_kurikulum/penjadwalan.ts`

**Rewrit全长 (673 baris).** Perubahan utama:

#### Hari Kerja Baru
```typescript
const HARI = ['Sabtu', 'Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis'];
// Jumat libur — tidak ada dalam daftar
```

#### API Kesiapan Mengajar (3 endpoint baru)
| Method | Endpoint | Fungsi |
|---|---|---|
| `GET` | `/api/wakil-kurikulum/kesiapan?semester_id=` | Daftar semua guru + konfigurasi kesiapan |
| `PUT` | `/api/wakil-kurikulum/kesiapan/:guru_id` | Upsert kesiapan per guru |
| `PUT` | `/api/wakil-kurikulum/kesiapan` | Batch upsert |

#### API Wali Kelas (1 endpoint baru)
| Method | Endpoint | Fungsi |
|---|---|---|
| `GET` | `/api/wakil-kurikulum/wali-kelas` | Daftar guru wali kelas (dari Admin) |

#### Jadwal CRUD — Perubahan
- **POST**: Validasi hari terhadap `HARI` baru
- **PUT**: Conflict detection sebelum update (sebelumnya tidak ada)
- **POST /jadwal/cek-bentrok**: Endpoint baru untuk cek bentrok frontend
- **POST /jadwal/simpan**: Endpoint baru untuk simpan batch dengan conflict check

#### Fungsi `cekBentrok` (baru)
```typescript
async function cekBentrok(env, guruId, kelasId, hari, jamMulai, jamSelesai, semesterId, excludeId?)
// Mengembalikan string error atau null
// Cek: guru bentrok + kelas bentrok
```

#### Generate Jadwal — Diperbarui
Sekarang menggunakan:
1. `guru_mata_pelajaran` (kesiapan) — hari aktif, JP max
2. `guru_kelas` — kelas diampu (dari Admin)
3. `guru_mapel` — mapel diampu (dari Admin)
4. `mapel_kelas` — mapel per kelas (dari Admin)
5. `jadwal_pelajaran` tervalidasi — jangan diubah
6. Tracker: `occupiedKelas`, `occupiedGuru`, `guruJpCount`, `guruMingguCount`

#### Reset — Perbaikan Bug
```typescript
// SEBELUM (SALAH): menghapus SEMUA termasuk tervalidasi
DELETE FROM jadwal_pelajaran WHERE semester_id = ?

// SESUDAH (BENAR): hanya draft
DELETE FROM jadwal_pelajaran WHERE semester_id = ? AND status_validasi = 'draft'
```

### 3.2 File: `backend/src/index.ts`

**Routing — tambah path baru:**
```typescript
// SEBELUM
if (subPath.startsWith('jp-slots') || subPath.startsWith('referensi') || ...)

// SESUDAH
if (subPath.startsWith('kesiapan') || subPath.startsWith('jp-slots') || subPath.startsWith('referensi') || subPath.startsWith('jadwal') || subPath.startsWith('jadwal-per-kelas') || subPath.startsWith('beban') || subPath.startsWith('jadwal-guru') || subPath.startsWith('jadwal-kelas') || subPath.startsWith('wali-kelas')) {
```

### 3.3 File: `backend/tests/routes/wakil_kurikulum.test.ts`

- Hapus test `distribusi-mengajar`
- Tambah test `kesiapan` (list + update)
- Update test `generate` (mock baru: kesiapan, guru_mapel, guru_kelas, mapel_kelas)
- Update test `beban-mengajar` (param `semester_id`)

**Hasil: 168 tests passed ✅**

---

## 4. Perubahan Frontend

### 4.1 File: `frontend/lib/features/wakil_kurikulum/services/wakil_kurikulum_service.dart`

**Method dihapus:**
- `getDistribusiMengajar()` — diganti
- `createDistribusi()` — diganti
- `deleteDistribusi()` — diganti

**Method baru:**
```dart
static Future<List<dynamic>> getKesiapan(int semesterId)
static Future<void> updateKesiapan(int guruId, Map<String, dynamic> body)
static Future<Map<String, dynamic>> batchUpdateKesiapan(Map<String, dynamic> body)

static Future<List<dynamic>> getWaliKelas()

static Future<Map<String, dynamic>> simpanJadwal(List<Map<String, dynamic>> jadwal)
static Future<Map<String, dynamic>> cekBentrok(Map<String, dynamic> data)
```

### 4.2 File: `frontend/lib/features/wakil_kurikulum/penjadwalan/penjadwalan_page.dart`

**Rewrit全长 (860+ baris).** Perubahan utama:

#### Tab Baru
| Index | Label | Fungsi |
|---|---|---|
| 0 | **Jadwal** | Timetable + Generate + Simpan + Drag-Drop |
| 1 | **Kesiapan** | Konfigurasi kesiapan guru (ganti Distribusi) |
| 2 | **Wali Kelas** | Daftar wali kelas dari Admin (ganti Beban) |

#### Tab Kesiapan
- Data tabel: Guru, NIP, Hari Aktif (checkbox), JP/Hari, JP/Minggu, Kelas Diampu, Mapel Diampu, Kapasitas
- Indikator: 🟢 <80%, 🟡 80-99%, 🔴 ≥100% + info kelebihan
- Tombol **Simpan Semua** (batch upsert)
- Filter semester

#### Tab Jadwal — Fitur Baru
- Tombol **Simpan** — batch simpan dengan conflict check
- Tombol **Generate** — confirm label "Generate"
- Tombol **Publikasi** — confirm label "Publikasi"
- Tombol **Reset** — hanya hapus draft, tervalidasi aman
- Form tambah jadwal: cek bentrok sebelum submit via `cekBentrok` API
- Hari dropdown: Sabtu, Minggu, Senin, Selasa, Rabu, Kamis

#### Tab Wali Kelas
- Daftar guru wali kelas dari Admin
- Menampilkan: nama, NIP, kelas binaan, jumlah santri
- Indikator: ✅ hijau (sudah punya kelas), ⚪ abu (belum ditugaskan)
- Tombol Refresh

### 4.3 File: `frontend/lib/shared/widgets/confirm_dialog.dart`

**Tambah parameter:**
```dart
Future<bool> showConfirmDialog(BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Ya, Hapus',  // ← baru
})
```

### 4.4 File: `frontend/lib/shared/widgets/dashboard_shell.dart`

**Perbaikan NavigationRail assertion error:**
```dart
// SEBELUM (line 171-172)
NavigationRail(
  extended: true,
  // ❌ labelType tidak diset → warisi NavigationRailLabelType.all dari tema

// SESUDAH (line 171-173)
NavigationRail(
  extended: true,
  labelType: NavigationRailLabelType.none,  // ✅ eksplisit
```

---

## 5. Alur Data Baru

```
┌─────────────────────────────────────────────────────────────────────────┐
│ ADMIN MASTER DATA                                                        │
│  - guru_mapel  → "guru bisa ngajar mapel apa"                          │
│  - guru_kelas  → "guru bisa ngajar di kelas mana"                      │
│  - mapel_kelas → "mapel diajarkan di kelas mana"                       │
└───────────────────────────┬─────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ TAB: KESIAPAN MENGAJAR GURU                                             │
│  (Data per-guru per-semester di guru_mata_pelajaran)                    │
│  - Hari aktif: checkbox (Sabtu-Minggu-Senin-Selasa-Rabu-Kamis)         │
│  - JP max/hari & JP max/minggu: input manual WK                        │
│  - Kapasitas: 🟢🟡🔴 otomatis                                           │
└───────────────────────────┬─────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ GENERATE JADWAL OTOMATIS                                                 │
│  Algoritma greedy + constraint:                                         │
│  ✅ Hari aktif guru                                                     │
│  ✅ Kelas dalam guru_kelas                                              │
│  ✅ Mapel dalam guru_mapel                                              │
│  ✅ Mapel dalam mapel_kelas (untuk kelas tertentu)                      │
│  ✅ JP/hari ≤ jp_max_per_hari                                           │
│  ✅ JP/minggu ≤ jp_max_per_minggu                                       │
│  ✅ Guru tidak bentrok (guru × hari × jam)                              │
│  ✅ Kelas tidak bentrok (kelas × hari × jam)                            │
└───────────────────────────┬─────────────────────────────────────────────┘
                            │ Draft
                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ TAB: JADWAL — TIMETABLE                                                  │
│  - Drag & drop antar slot                                               │
│  - Cek bentrok via API /jadwal/cek-bentrok                              │
│  - Tombol SIMPAN → simpan batch via /jadwal/simpan                      │
│  - Tombol PUBLIKASI → draft → tervalidasi                               │
│  - 🔴 Merah jika bentrok + info                                         │
└───────────────────────────┬─────────────────────────────────────────────┘
                            │ Publikasi
                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ JADWAL TERVALIDASI — Diakses role lain                                  │
│  - Guru Mapel: lihat jadwal saya                                        │
│  - Kepala Sekolah: monitoring jadwal                                    │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ TAB: WALI KELAS (read-only dari Admin)                                  │
│  Tampilkan semua guru dengan jabatan 'wali_kelas'                       │
│  - Nama, NIP, Kelas binaan, Jumlah santri                              │
│  - Indikator: ✅ sudah punya kelas / ⚪ belum ditugaskan                │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Status Pengujian

| Lapisan | Hasil |
|---|---|
| Backend | ✅ 168 test passed (vitest) |
| Frontend | ✅ flutter analyze — 0 error (hanya info/warning pre-existing) |

---

## 7. Catatan Penting

1. **Migration harus dijalankan** sebelum deploy: `wrangler d1 execute ppi-db --file=backend/migrations/0004_guru_kesiapan.sql`
2. **Data existing** di `guru_mata_pelajaran` (old distribusi) tetap ada dan tidak dihapus
3. **Generate baru** hanya membaca row dengan `hari_aktif != '[]'` (kesiapan yang sudah diisi)
4. **WK tidak bisa akses Admin API** — semua data Admin (wali kelas, guru_kelas, dll) di-proxy via endpoint WK
5. **Jumat libur** — tidak ada dalam HARI, tidak bisa dipilih untuk jadwal

Langkah selanjutnya sesuai rencana:
1. Jalankan migration ke D1 production: wrangler d1 execute ppi-db --file=backend/migrations/0004_guru_kesiapan.sql
2. Deploy backend (Cloudflare Workers) + build frontend
3. Monitor edge cases data existing
Mau lanjut deploy sekarang? Atau ada yang perlu direview/diubah dulu?
