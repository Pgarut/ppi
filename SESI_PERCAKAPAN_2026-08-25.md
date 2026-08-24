# Sesi Percakapan — Debugging & Deployment PPI Madrasah

> **Tanggal:** 25 Agustus 2026
> **Project:** PPI (Sistem Informasi MA Persis Garut)
> **Stack:** Flutter Web (frontend) + Cloudflare Workers/D1 (backend) + Cloudflare Pages

---

## Ringkasan Masalah yang Ditangani

| # | Masalah | Status |
|---|---------|--------|
| 1 | Error CORS di `error.md` | ✅ Teranalisa (backend mati) |
| 2 | Judul login selalu "Sistem Informasi MA Persis Garut", seharusnya "MA PERSIS GARUT" | ✅ Selesai |
| 3 | Setelah push/commit hasil deploy tetap menampilkan judul lama | ✅ Selesai (fix CI) |
| 4 | Banner "Refresh/Update" muncul terus di browser & PWA; saran instal PWA harusnya hanya di browser | ✅ Selesai |

---

## 1. Analisis `error.md` — Error CORS

**Isi error:** Permintaan cross-origin ke `http://localhost:8787/api/auth/me` dan `/api/pengaturan-tampilan` ditolak dengan `Kode status: (null)`.

**Kesimpulan:** Bukan salah konfigurasi CORS, tapi **backend lokal sedang tidak berjalan**.

**Bukti:**
- `Kode status: (null)` + "Permintaan CORS tidak berhasil" = koneksi gagal total (server tidak merespons), bukan header CORS salah.
- `Test-NetConnection localhost -Port 8787` → `False` (port tidak listening).
- Konfigurasi CORS backend sudah benar:
  - `CORS_ORIGIN = "*"` di `backend/wrangler.toml`
  - Preflight `OPTIONS` ditangani di `backend/src/index.ts:52`
  - `corsHeaders()` menempel di semua response (`backend/src/utils/response.ts`)
- `backend/backend.log` membuktikan sebelumnya normal (`200 OK`, preflight `204`).

**Solusi:** Jalankan ulang backend → `.\run.ps1` atau `cd backend; npm run dev`.

---

## 2 & 3. Judul Login Tidak Berubah Menjadi "MA PERSIS GARUT"

### Alur data judul login
```
DB tabel pengaturan → GET /api/pengaturan-tampilan → login_screen.dart
```

### Temuan berlapis

1. **Error ditelan diam-diam** — `frontend/lib/features/auth/screens/login_screen.dart:54`:
   ```dart
   } catch (_) {}   // gagal fetch = tanpa log, default tetap tampil
   ```
   Fallback hardcode di baris 24: `'Sistem Informasi\nMA Persis Garut'`.

2. **Data D1 lokal ≠ produksi** — database lokal berisi `hero_title = "Sistem Informasi Madrasah"`, sedangkan produksi benar:
   ```json
   GET https://ppi-backend-production.pgarut77.workers.dev/api/pengaturan-tampilan
   → hero_title: "MA PERSIS GARUT"  ✓
   ```
   Pengaturan dilakukan langsung online; database lokal & produksi **terpisah by design**.

3. **Bukti utama (bedah build live):** `main.dart.js` di `https://ppi-bo8.pages.dev` mengandung `localhost:8787` dan **tidak memuat URL API produksi sama sekali** → build dikompilasi tanpa `--dart-define=API_BASE_URL` → setiap browser pengunjung memanggil *localhost miliknya sendiri* → gagal → tampil teks hardcode.

### Akar masalah CI
`.github/workflows/deploy.yml:141` semula:
```yaml
--dart-define=API_BASE_URL=${{ vars.API_BASE_URL || 'https://ppi-backend-production.pgarut77.workers.dev' }}
```
Repo variable GitHub `API_BASE_URL` ternyata ter-set nilai salah (diduga `localhost:8787`) sehingga **menimpa fallback**.

### Perbaikan yang dieksekusi
- **Hardcode** URL produksi di `deploy.yml` (commit `b32d8db`):
  ```yaml
  --dart-define=API_BASE_URL=https://ppi-backend-production.pgarut77.workers.dev
  ```
- Build manual + deploy manual via `npx wrangler pages deploy build/web --project-name=ppi --branch main`.
- Verifikasi live: JS memuat URL produksi ✓, `localhost:8787` hilang ✓.

### Fakta penting infrastruktur
| Item | Nilai |
|------|-------|
| Project Pages | bernama **`ppi`**, domain **`ppi-bo8.pages.dev`** (subdomain lama tetap dipakai) |
| Backend produksi | `https://ppi-backend-production.pgarut77.workers.dev` |
| CORS produksi | `https://ppi-bo8.pages.dev, https://f1198d05.ppi-bo8.pages.dev` |

### Catatan tambahan (belum dikerjakan)
- Nilai tersimpan ada spasi ekor `"MA PERSIS GARUT "` → sebaiknya di-trim saat PUT di `pengaturan_tampilan.ts:29`.
- `background_url` berupa link Google Drive `/view?...` → tidak bisa langsung dipakai `NetworkImage`; gunakan format thumbnail `https://drive.google.com/thumbnail?id=...`.
- Judul juga di-hardcode di beberapa tempat: `splash_screen.dart:37`, `dashboard_shell.dart:405`, admin `dashboard_page.dart:387`, `dashboard_musyrifah_page.dart:113`, `tentang_page.dart:26`.

---

## 4. Banner Refresh Selalu Muncul & Saran Instal PWA

**File:** `frontend/web/index.html`

### Penyebab
1. **Banner "🔄 Update Tersedia / Refresh Sekarang"** muncul tiap Service Worker mendeteksi versi baru. Karena deployment sangat sering (12+ dalam beberapa jam), hampir setiap buka app ketemu versi baru. Throttle lama hanya pakai `sessionStorage` (per sesi tab) → tiap buka ulang PWA prompt muncul lagi.
2. **Banner "📲 Instal Aplikasi"** dipicu `beforeinstallprompt` tanpa pengecekan apakah sudah berjalan standalone.
3. Bug CSS: `width:calc(100%-32px)` (tanpa spasi) → deklarasi lebar tidak valid.

### Perbaikan yang dieksekusi
1. Tambah fungsi deteksi standalone dan gate banner instal:
   ```js
   function isStandalonePWA() {
     return window.matchMedia('(display-mode: standalone)').matches
         || window.matchMedia('(display-mode: fullscreen)').matches
         || window.matchMedia('(display-mode: minimal-ui)').matches
         || window.navigator.standalone === true;
   }
   ```
   → banner instal hanya muncul di browser, tidak di PWA.
2. Throttle banner update jadi **maksimal 1x per 3 hari** via `localStorage` key `sw_update_prompted_at`.
3. Fix CSS `calc(100% - 32px)`.

Build sukses + deploy + verifikasi live OK.

---

## Commit yang Dibuat

| Commit | Pesan |
|--------|-------|
| `b32d8db` | `fix(ci): hardcode production API_BASE_URL agar build web tidak fallback ke localhost` |

**Belum di-commit saat sesi berakhir:**
- `frontend/web/index.html` (perbaikan banner PWA) ← perlu commit
- Beberapa file lain milik user di working tree (migrasi, schema, dsb.) — tidak disentuh

---

## Perintah Berguna

```powershell
# Jalankan backend + frontend lokal
.\run.ps1

# Build web produksi (WAJIB dengan dart-define!)
cd frontend
flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL=https://ppi-backend-production.pgarut77.workers.dev

# Deploy frontend ke Cloudflare Pages
npx wrangler pages deploy build/web --project-name=ppi --branch main

# Deploy backend produksi
cd backend
npx wrangler deploy --env production

# Query D1 lokal / remote
npx wrangler d1 execute ppi-db-prod --local --command "SELECT ..."
npx wrangler d1 execute ppi-db-prod --remote --command "SELECT ..."

# Jalankan Flutter dev mengarah ke API produksi
flutter run -d chrome --dart-define=API_BASE_URL=https://ppi-backend-production.pgarut77.workers.dev
```

## Rekomendasi Lanjutan
1. Commit perubahan `index.html` agar CI konsisten dengan build live.
2. Cek/hapus repo variable GitHub `API_BASE_URL` (Settings → Secrets and variables → Actions) jika masih berisi localhost.
3. Trim nilai `hero_title`/`hero_subtitle` saat disimpan.
4. Ganti `background_url` ke format URL gambar langsung (bukan halaman `/view` Google Drive).
