# HISTORIS PERUBAHAN — Sistem Informasi Madrasah PPI

> **Dokumen ini berisi catatan terperinci semua perubahan yang dilakukan pada proyek.**
> **Dibuat untuk menjaga konteks AI (MIMO) agar tidak kehilangan ingatan.**

---

## Daftar Isi

1. [Ringkasan Proyek](#1-ringkasan-proyek)
2. [Fase 1 — Perubahan Kritis](#2-fase-1--perubahan-kritis)
3. [Fase 2 — Kualitas Kode](#3-fase-2--kualitas-kode)
4. [Fase 3 — State Management (Ditunda)](#4-fase-3--state-management-ditunda)
5. [Redesign Penjadwalan](#5-redesign-penjadwalan)
6. [Filter Tingkat & Kelas di Master Data](#6-filter-tingkat--kelas-di-master-data)
7. [Tabel Santri — Kolom Baru & Form](#7-tabel-santri--kolom-baru--form)
8. [Ikon Mata (Show/Hide) Password](#8-ikon-mata-showhide-password)
9. [Fix Dropdown Error saat Edit Santri](#9-fix-dropdown-error-saat-edit-santri)
10. [Fix Refresh Selalu Logout](#10-fix-refresh-salu-logout)
11. [Rencana — Batas Login 2 Perangkat](#11-rencana--batas-login-2-perangkat)
12. [Arsitektur & Konvensi](#12-arsitektur--konvensi)
13. [Status Akhir](#13-status-akhir)

---

## 1. Ringkasan Proyek

| Item | Detail |
|------|--------|
| **Nama** | Sistem Informasi Madrasah PPI (MA/MTs) |
| **Frontend** | Flutter Web (`C:\ppi\frontend`) |
| **Backend** | Cloudflare Workers + TypeScript (`C:\ppi\backend`) |
| **Database** | Cloudflare D1 (SQLite) |
| **Role** | Admin, Kepala Madrasah, Wakil Kurikulum, Guru Mapel/Wali Kelas, Guru BK |
| **Warna Tema** | Hijau (#2E7D32 / AppTheme.primary #10B981), Kuning (#FDD835), Putih |
| **Token Storage** | FlutterSecureStorage (bukan SharedPreferences) |
| **Auth** | Custom JWT via `jose` library (bukan Sanctum/Passport) |

---

## 2. Fase 1 — Perubahan Kritis

**Tanggal:** Awal sesi kerja  
**Tujuan:** Perbaikan keamanan & kompatibilitas

### 2.1 `dart:html` → `universal_html`

**Masalah:** `dart:html` tidak kompatibel dengan platform non-web.

| File | Perubahan |
|------|-----------|
| `pubspec.yaml` | Tambah dependency `universal_html: ^2.2.4` |
| `lib/features/admin/master_data/master_data_page.dart` | `import 'dart:html'` → `import 'package:universal_html/html.dart'` |
| `lib/features/admin/pengaturan/pengaturan_page.dart` | Sama |
| `lib/features/wakil_kurikulum/penjadwalan/penjadwalan_page.dart` | Sama |
| `lib/features/wakil_kurikulum/nilai/nilai_page.dart` | Sama |
| `lib/features/wakil_kurikulum/laporan/laporan_page.dart` | Sama |

### 2.2 `dart:io` di `nilai_page.dart`

**Masalah:** `dart:io` tidak kompatibel dengan web.

| File | Perubahan |
|------|-----------|
| `lib/features/wakil_kurikulum/nilai/nilai_page.dart` | Hapus `import 'dart:io'`, gunakan `XFile.fromData` |

### 2.3 QR Token Centralized

**Masalah:** Token QR Absensi hardcoded di beberapa tempat.

| File | Perubahan |
|------|-----------|
| `lib/config/env.dart` | Tambah `qrAbsensiToken` |
| `lib/features/wakil_kurikulum/penjadwalan/penjadwalan_page.dart` | Gunakan `Env.qrAbsensiToken` |
| `pubspec.yaml` | Hapus `google_fonts` & `path_provider` (tidak terpakai) |

### 2.4 Error Handler Global

**Masalah:** Error tidak ter-log dengan baik.

| File | Perubahan |
|------|-----------|
| `lib/main.dart` | Tambah `FlutterError.onError` + `runZonedGuarded` |

### 2.5 `.gitignore`

**Masalah:** `.env` ter-commit.

| File | Perubahan |
|------|-----------|
| `.gitignore` | Tambah `.env` |

### 2.6 AuthProvider Logout Fix

**Masalah:** `_performLogout` tidak handle error.

| File | Perubahan |
|------|-----------|
| `lib/features/auth/providers/auth_provider.dart` | `_performLogout()` diubah async, tambah try-catch |
| `test/providers/auth_provider_test.dart` | Fix binding init + tambah try-catch |

### 2.7 Test Status

```
98 tests passed ✅
```

---

## 3. Fase 2 — Kualitas Kode

**Tanggal:** Sesi kerja berikutnya  
**Tujuan:** Peningkatan kualitas kode

### 3.1 `avoid_print: true`

| File | Perubahan |
|------|-----------|
| `analysis_options.yaml` | Tambah `avoid_print: true` |

### 3.2 Color Replacement — DITUNDA (Opsi C)

**Alasan:** Dua skema warna berbeda:
- `AppTheme.primary = #10B981` (hijau muda)
- Hardcoded `#2E7D32` (hijau tua — sidebar)

Mengganti semua warna akan mengubah identitas visual. Diputuskan **tidak dilakukan**.

### 3.3 File Splitting — DITUNDA

**Alasan:** Risiko tinggi untuk `master_data_page.dart` (1520 baris), rendah untuk `nilai/rapor`. Tidak dilakukan tanpa analisis mendalam.

### 3.4 Abstract Service — DITUNDA

**Alasan:** Belum ada kebutuhan mendesak. Dilakukan nanti jika ada pattern berulang.

---

## 4. Fase 3 — State Management (Ditunda)

**Alasan:** 30+ file terpengaruh, 64% fitur terdampak. Terlalu besar risikonya tanpa perencanaan matang.

---

## 5. Redesign Penjadwalan

**Tanggal:** Sesi kerja  
**Dokumen desain:** `C:\ppi\frontend\DESAIN_PENJADWALAN.md`  
**Status:** Disetujui user, sudah diimplementasikan

### 5.1 Perubahan Layout

| Sebelum | Sesudah |
|---------|---------|
| 1 tabel full (kolom = hari) | 2 kolom (Panel Kiri + Tabel) |
| Kolom tabel = hari (Sabtu-Minggu) | Kolom tabel = kelas (10A, 10B, ...) |
| Tidak ada panel kiri | Panel kiri (kegiatan tetap + daftar mapel) |
| Tidak ada panel bawah | Panel bawah (keterangan bentrok) |

### 5.2 Komponen Baru

| Komponen | Deskripsi |
|----------|-----------|
| **Toolbar** | Tingkat, Genre Jadwal, Semester, Hari, Reset, Simpan |
| **Panel Kiri** | Kegiatan tetap (Istirahat, Tahfidz, dll) + Daftar Mapel dari Master |
| **Tabel Jadwal** | Kolom = kelas, Baris = JP, Cell = mapel + guru |
| **Panel Bawah** | Auto-detect guru mengajar di 2+ kelas pada jam yang sama |
| **3 Tab** | Jadwal, Kesiapan, Wali Kelas (tetap dipertahankan) |

### 5.3 File yang Diubah

| File | Perubahan |
|------|-----------|
| `lib/features/wakil_kurikulum/penjadwalan/penjadwalan_page.dart` | Full rewrite |

---

## 6. Filter Tingkat & Kelas di Master Data

**Tanggal:** Sesi kerja  
**Status:** Selesai

### 6.1 State Variables

```dart
String? _filterTingkat;
String? _filterKelas;
List<Map<String, dynamic>> _tingkatList = [];
List<Map<String, dynamic>> _kelasList = [];
```

### 6.2 Method `_loadSantriFilters()`

Load data Tingkat & Kelas dari API untuk dropdown filter.

### 6.3 Toolbar Santri (idx == 9)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Tingkat ▾ │ Kelas ▾ │ [Template] [Upload Excel] │ 🔍 Cari... │ [Tambah]  │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 6.4 Filter Logic

- Pilih Tingkat → Kelas dropdown otomatis filter berdasarkan tingkat
- Pilih Kelas → Tabel Santri load data siswa per kelas
- `_load()` dikirim `tingkat_id` dan `kelas_id` sebagai query params

### 6.5 File yang Diubah

| File | Bagian |
|------|--------|
| `lib/features/admin/master_data/master_data_page.dart` | State, `_loadSantriFilters()`, `_load()`, toolbar |

---

## 7. Tabel Santri — Kolom Baru & Form

**Tanggal:** Sesi kerja  
**Status:** Selesai

### 7.1 Kolom Tabel (Sebelum → Sesudah)

| # | Kolom Lama | Kolom Baru | Keterangan |
|---|-----------|-----------|-----------|
| 1 | NIS | NIS | — |
| 2 | NISN | NISN | — |
| 3 | Nama | Nama | — |
| 4 | JK | JK | — |
| 5 | Kelas | Kelas | — |
| 6 | Status | **Nama Ayah** | Baru |
| 7 | — | **Nama Ibu** | Baru |
| 8 | — | **Pekerjaan Ayah** | Baru |
| 9 | — | **Pekerjaan Ibu** | Baru |
| 10 | — | **WhatsApp** | Baru |
| 11 | — | **Username** | Baru (otomatis dari NIS) |
| 12 | — | **Password** | Baru (tersembunyi) |
| 13 | — | **Status** | Pindah dari kolom 6 |
| 14 | ✏️ 🗑️ | ✏️ 🗑️ | Icon Edit & Hapus |

### 7.2 Form Tambah/Edit (4 Section)

```
┌─ Data Pribadi ─────────────────────────────────────┐
│ [NIS] [NISN]                                        │
│ [Nama Santri]                                       │
│ [JK ▾] [Status ▾]                                  │
└─────────────────────────────────────────────────────┘

┌─ Penempatan Kelas ─────────────────────────────────┐
│ [Kelas ▾]                                           │
└─────────────────────────────────────────────────────┘

┌─ Data Orang Tua ───────────────────────────────────┐
│ [Nama Ayah] [Nama Ibu]                             │
│ [Pekerjaan Ayah] [Pekerjaan Ibu]                   │
│ [Nomor WhatsApp]                                    │
└─────────────────────────────────────────────────────┘

┌─ Akun Login ───────────────────────────────────────┐
│ [Username]                                          │
│ [Password (kosongkan jika tidak diubah)]           │
└─────────────────────────────────────────────────────┘
```

### 7.3 Fitur Password

| Aksi | Behavior |
|------|----------|
| **Tambah** | Password wajib diisi |
| **Edit** | Password opsional (kosongkan = tidak diubah) |
| **Tampil di Tabel** | `••••••` (tersembunyi) |

### 7.4 Display Value

```dart
String _displayValue(String col, dynamic val, {int? idx, Map<String, dynamic>? row}) {
  if (val == null) return '-';
  if (col == 'password') return '••••••';
  if (col == 'is_aktif' || col == 'status_aktif') return val == 1 ? 'Ya' : 'Tidak';
  if (col == 'jenis_kelamin') return val == 'L' ? 'Laki-laki' : 'Perempuan';
  if (col == 'kelas_id' && (idx == 5 || idx == 9)) {
    final kelasList = _data[4] ?? [];
    final k = kelasList.cast<Map<String, dynamic>?>().firstWhere(
      (k) => k?['id'] == val, orElse: () => null);
    return k?['nama']?.toString() ?? val.toString();
  }
  return val.toString();
}
```

### 7.5 Save Logic — Skip Password Kosong saat Edit

```dart
} else if (idx == 9 && col == 'password' && edit != null && ctrls[col]!.text.isEmpty) {
  // skip empty password on edit
} else {
  body[col] = ctrls[col]!.text;
}
```

### 7.6 `_ModernField` — Parameter Baru

```dart
class _ModernField extends StatelessWidget {
  // ... existing params ...
  final bool obscureText;
  final TextInputType? keyboardType;
  // ...
}
```

---

## 8. Ikon Mata (Show/Hide) Password

**Tanggal:** Sesi kerja  
**Status:** Selesai

### 8.1 State

```dart
final ValueNotifier<bool> _passwordObscure = ValueNotifier(true);
```

### 8.2 Implementasi

```dart
ValueListenableBuilder<bool>(
  valueListenable: _passwordObscure,
  builder: (_, obscure, __) {
    return TextFormField(
      controller: ctrls['password'],
      obscureText: obscure,
      // ...
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        onPressed: () => _passwordObscure.value = !_passwordObscure.value,
      ),
      // ...
    );
  },
)
```

### 8.3 Reset

```dart
Future<void> _showForm(int idx, {Map<String, dynamic>? edit}) async {
  // ...
  _passwordObscure.value = true; // Selalu mulai tersembunyi
  // ...
}
```

---

## 9. Fix Dropdown Error saat Edit Santri

**Tanggal:** Sesi kerja  
**Status:** Selesai

### 9.1 Error

```
Assertion failed: items==null ||, items.isEmpty||, Value==null||
```

### 9.2 Penyebab

| Masalah | Detail |
|---------|--------|
| `kelasList` kosong | Load async belum selesai saat form dibuka |
| `selectedSiswaKelasId` tidak ditemukan | ID kelas tidak ada di items dropdown |
| Status dari API lowercase | `"aktif"` tidak cocok dengan `"Aktif"` |

### 9.3 Solusi

1. **Load kelas dengan `await`** sebelum dialog muncul
2. **Validasi kelas_id** — cek apakah ID ada di `kelasList`
3. **Normalisasi status** — handle lowercase/spasi dari API

```dart
// Validasi kelas_id
selectedSiswaKelasId = int.tryParse(edit['kelas_id']?.toString() ?? '');
if (selectedSiswaKelasId != null && !kelasList.any((k) => k['id'] == selectedSiswaKelasId)) {
  selectedSiswaKelasId = null;
}

// Normalisasi status
final rawStatus = edit['status']?.toString() ?? '';
if (rawStatus == 'Aktif' || rawStatus.toLowerCase() == 'aktif') {
  selectedSiswaStatus = 'Aktif';
} else if (rawStatus == 'Tidak Aktif' || rawStatus.toLowerCase() == 'tidak_aktif') {
  selectedSiswaStatus = 'Tidak Aktif';
} else if (rawStatus == 'Pindah' || rawStatus.toLowerCase() == 'pindah') {
  selectedSiswaStatus = 'Pindah';
} else {
  selectedSiswaStatus = rawStatus.isNotEmpty ? rawStatus : null;
}
```

4. **`_showForm()` diubah jadi `async`**

---

## 10. Fix Refresh Selalu Logout

**Tanggal:** Sesi kerja  
**Status:** Selesai

### 10.1 Masalah

Token tersimpan di `FlutterSecureStorage`, tapi app selalu mulai di `/login` karena `tryAutoLogin()` tidak pernah dipanggil.

### 10.2 Solusi

| File | Perubahan |
|------|-----------|
| `lib/main.dart` | Panggil `tryAutoLogin()` sebelum `runApp()` |
| `lib/main.dart` | `PpiApp` gunakan `Consumer<AuthProvider>` untuk navigasi otomatis |

### 10.3 Alur Baru

```
App Start
  ↓
tryAutoLogin() → cek token di FlutterSecureStorage
  ↓
  ├── Token valid → AuthStatus.authenticated → Navigasi ke dashboard
  │
  └── Token tidak ada/invalid → AuthStatus.unauthenticated → LoginScreen
```

### 10.4 Kode

```dart
void main() async {
  // ...
  final authProvider = AuthProvider();
  await authProvider.tryAutoLogin(); // ← INI YANG BARU
  // ...
}

// PpiApp.build()
home: Consumer<AuthProvider>(
  builder: (_, auth, __) {
    if (auth.status == AuthStatus.uninitialized || auth.status == AuthStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.status == AuthStatus.authenticated && auth.dashboardRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(auth.dashboardRoute!);
      });
    }
    return const LoginScreen();
  },
),
```

---

## 11. Rencana — Batas Login 2 Perangkat

**Status:** Rencana (belum diimplementasi)  
**Estimasi:** 2.5 - 3 jam

### 11.1 Arsitektur Backend Saat Ini

| Item | Detail |
|------|--------|
| Framework | Cloudflare Workers + TypeScript |
| Database | D1 (SQLite) |
| Auth | Custom JWT (`jose` library) |
| Token Storage | Stateless (tidak ada session table) |
| Access Token Expiry | 8 jam |
| Refresh Token Expiry | 7 hari |
| Logout Endpoint | ❌ Tidak ada |
| Device Tracking | ❌ Tidak ada |
| Session Table | ❌ Tidak ada |

### 11.2 Yang Perlu Dibuat

| # | Komponen | Estimasi |
|---|----------|----------|
| 1 | Migration: tabel `sessions` | 15 menit |
| 2 | Session service: create/validate/revoke | 30 menit |
| 3 | Modifikasi login: capture User-Agent, cek limit | 20 menit |
| 4 | Modifikasi refresh: validasi session aktif | 15 menit |
| 5 | Logout endpoint: hapus session | 15 menit |
| 6 | Update auth middleware: cek session tiap request | 20 menit |
| 7 | Frontend: update logout handler | 10 menit |
| 8 | Testing | 30 menit |
| | **Total** | **~2.5-3 jam** |

### 11.3 Skema Tabel `sessions`

```sql
CREATE TABLE sessions (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     INTEGER NOT NULL REFERENCES users(id),
    user_agent  TEXT,
    token_hash  TEXT NOT NULL,
    is_active   INTEGER NOT NULL DEFAULT 1,
    created_at  TEXT NOT NULL DEFAULT (datetime('now')),
    revoked_at  TEXT
);
```

### 11.4 Alur Login dengan Limit 2 Device

```
1. User login → capture User-Agent
2. Query: COUNT(*) FROM sessions WHERE user_id = ? AND is_active = 1
3. Jika >= 2:
   a. Opsi A: Tolak login → "Login dari perangkat lain terdeteksi"
   b. Opsi B: Revoke session tertua → izinkan login baru
4. Insert session baru ke tabel sessions
5. Return JWT access token + refresh token
```

---

## 12. Arsitektur & Konvensi

### 12.1 Struktur Frontend

```
frontend/lib/
├── main.dart
├── config/
│   ├── env.dart                  (API URL, QR token)
│   └── routes.dart               (route definitions)
├── core/
│   ├── network/api_client.dart   (HTTP + token + auto-refresh)
│   ├── theme/app_theme.dart
│   └── logging/app_logger.dart
├── shared/
│   └── widgets/
│       ├── dashboard_shell.dart
│       └── confirm_dialog.dart
└── features/
    ├── auth/
    │   ├── providers/auth_provider.dart
    │   ├── screens/login_screen.dart
    │   └── widgets/login_form.dart
    ├── admin/
    │   ├── admin_page.dart
    │   ├── dashboard/dashboard_page.dart
    │   ├── master_data/master_data_page.dart  (1700+ baris)
    │   └── pengaturan/pengaturan_page.dart
    ├── wakil_kurikulum/...
    ├── guru_mapel_wali_kelas/...
    ├── guru_bk/...
    └── kepala_sekolah/...
```

### 12.2 Konvensi Kode

| Aspek | Konvensi |
|-------|----------|
| **Naming** | `snake_case` untuk file & variabel |
| **Widget** | `StatefulWidget` dengan `_` prefix untuk private |
| **State** | Provider (`ChangeNotifierProvider`) |
| **API** | `ApiClient.get/post/put/delete` (static methods) |
| **Token** | `FlutterSecureStorage` (bukan SharedPreferences) |
| **Error** | `FlutterError.onError` + `runZonedGuarded` |
| **Lint** | `avoid_print: true` |
| **Warna** | `AppTheme.primary` (#10B981) untuk widget, hardcoded #2E7D32 untuk sidebar |

### 12.3 API Client

```dart
// Token management
static Future<String?> getToken() async => await _storage.read(key: _tokenKey);
static Future<void> saveToken(String token) async => await _storage.write(key: _tokenKey, value: token);
static Future<void> clearTokens() async { /* hapus token + refresh_token */ }

// Auto-refresh on 401
// 1. Coba refresh token via POST /auth/refresh
// 2. Jika berhasil → save new tokens → retry request
// 3. Jika gagal → clearTokens → onSessionExpired
```

### 12.4 Auth Provider

```dart
enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  // Status
  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _user;

  // Auto-login
  Future<void> tryAutoLogin() async { /* cek token → GET /auth/me */ }

  // Login
  Future<void> login(String username, String password) async { /* POST /auth/login */ }

  // Logout
  Future<void> logout() async { /* clear tokens + update state */ }

  // Session expiry (30 menit inactivity)
  // notifyActivity() → reset timer
}
```

---

## 13. Status Akhir

### 13.1 Selesai

| # | Fitur | Tanggal |
|---|-------|---------|
| 1 | Fase 1: universal_html, dart:io, QR token, error handler, .gitignore, await fix | Sesi 1 |
| 2 | Fase 2: avoid_print | Sesi 2 |
| 3 | Redesign Penjadwalan (toolbar, 2 kolom, panel kiri/kanan/bawah) | Sesi 3 |
| 4 | Filter Tingkat & Kelas di Master Data Santri | Sesi 4 |
| 5 | Tabel Santri kolom baru (orang tua, WA, username, password) | Sesi 5 |
| 6 | Ikon mata (show/hide) password | Sesi 5 |
| 7 | Fix dropdown error saat edit Santri | Sesi 5 |
| 8 | Fix refresh selalu logout (tryAutoLogin) | Sesi 5 |

### 13.2 Pending

| # | Fitur | Estimasi | Keterangan |
|---|-------|----------|------------|
| 1 | Batas login 2 perangkat | 2.5-3 jam | Butuh backend changes |
| 2 | Color replacement (Fase 2) | — | Ditunda (Opsi C) |
| 3 | File splitting (Fase 2) | — | Ditunda (risiko tinggi) |
| 4 | Abstract service (Fase 2) | — | Ditunda |
| 5 | State Management (Fase 3) | — | Ditunda (30+ file) |

### 13.3 Test Status

```
98 tests passed ✅
0 analyzer errors ✅
```

---

## 14. Changelog Lengkap (Reverse Chronological)

### Sesi 5 (3 Agustus 2026)
- [x] Tambah kolom Santri: nama_ayah, nama_ibu, pekerjaan_ayah, pekerjaan_ibu, whatsapp, username, password
- [x] Form Santri: 4 section (Data Pribadi, Kelas, Orang Tua, Akun Login)
- [x] Ikon mata show/hide password
- [x] Fix dropdown error (kelas loading async + status normalization)
- [x] Fix refresh selalu logout (tryAutoLogin + Consumer navigation)

### Sesi 4
- [x] Filter Tingkat & Kelas di toolbar Santri
- [x] `_loadSantriFilters()` method
- [x] Filter params di `_load()`

### Sesi 3
- [x] Full rewrite penjadwalan_page.dart
- [x] Toolbar: Tingkat, Genre, Semester, Hari, Reset, Simpan
- [x] Panel Kiri: kegiatan tetap + daftar mapel
- [x] Tabel: kolom = kelas
- [x] Panel Bawah: bentrok detection
- [x] DESAIN_PENJADWALAN.md

### Sesi 2
- [x] `avoid_print: true` di analysis_options.yaml

### Sesi 1
- [x] `dart:html` → `universal_html` (5 file)
- [x] `dart:io` removal dari nilai_page.dart
- [x] QR token centralized ke env.dart
- [x] FlutterError.onError + runZonedGuarded
- [x] `.env` ditambah ke .gitignore
- [x] AuthProvider.logout() try-catch
- [x] auth_provider_test.dart fix

---

## 14. Sesi 7 Agustus 2026

### 14.1 Backend Penjadwalan — Filter Guru

**Masalah:** Endpoint `referensi` dan `kesiapan` di `penjadwalan.ts` mengambil SEMUA guru tanpa filter jabatan. Guru BK, Kepala Sekolah, Wakil Kurikulum muncul di daftar.

**Solusi:** Tambahkan `INNER JOIN guru_mapel gm ON g.id = gm.guru_id` di kedua endpoint.

**File:** `backend/src/routes/wakil_kurikulum/penjadwalan.ts`

### 14.2 Frontend Penjadwalan — Dropdown Multi-Select Hari

**Masalah:** Tab Kesiapan menampilkan hari aktif guru menggunakan `FilterChip` (6 chip). Tampilan penuh.

**Solusi:** Ubah `_HariCheckboxRow` menjadi dropdown multi-select dengan dialog.

**File:** `frontend/lib/features/wakil_kurikulum/penjadwalan/penjadwalan_page.dart`

### 14.3 Admin Settings — Logo & Background URL

**Status:** Tidak ada bug. Sudah berfungsi dengan benar.

**Keputusan:** Pakai Google Drive untuk hosting gambar. R2 akan diaktifkan saat dipublikasi ke beberapa madrasah.

### 14.4 Deploy

- Backend: `https://ppi-backend-production.pgarut77.workers.dev`
- Frontend: `https://8d8da0c1.ppi-frontend-ayg.pages.dev`
- Commit: `e5c3446`

---

*Dokumen ini terakhir diperbarui: 7 Agustus 2026*
*Total perubahan tercatat: 9 sesi kerja*
