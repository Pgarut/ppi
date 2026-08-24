 Catatan Perubahan & Rencana Sistem

**Tanggal**: 22 Agustus 2026

---

## Bagian 1: Daftar Belum Deploy & Push

### 1.1 Master Data - Tabel Santri (Admin)

**Status**: ✅ Selesai, belum commit/push

| File | Perubahan |
|------|-----------|
| `backend/src/routes/admin/master_data.ts` | Filter status + hapus users saat hapus siswa |
| `frontend/lib/features/admin/master_data/master_data_page.dart` | Kolom tabel + filter status + perPage |
| `frontend/lib/features/admin/master_data/widgets/santri_form.dart` | Opsi status "pindah" |

**Detail:**
- Kolom tabel: Tambah `nisn` dan `whatsapp`
- Filter status: Dropdown (Semua/Aktif/Lulus/Keluar/Pindah)
- Hapus siswa: Ikut hapus record di tabel `users` (fix orphaned)
- Status pindah: Ditambahkan di form edit
- Per-page: `100` → `20`

---

### 1.2 Wakil Kurikulum - Kenaikan Kelas

**Status**: ✅ Selesai, belum commit/push

| File | Perubahan |
|------|-----------|
| `backend/src/routes/wakil_kurikulum/kenaikan-kelas.ts` | Transaction batch + filter absensi + pagination + endpoint alumni/calon |
| `frontend/lib/features/wakil_kurikulum/kenaikan-kelas/kenaikan-kelas-page.dart` | Loading + konfirmasi + pagination + search + dropdown + error handling + step indicator |
| `frontend/lib/features/wakil_kurikulum/services/wakil-kurikulum-service.dart` | Pagination + getCalonAlumni() |

**Detail Backend:**
- Transaction batch: Semua INSERT/UPDATE dibungkus `DB.batch()` (atomic)
- Filter absensi: Query absensi filter by `tahun_ajaran_id`
- Pagination history: GET `/kenaikan-kelas` support `page`, `per_page`, `search`
- Pagination alumni: GET `/alumni` support `page`, `per_page`, `search`
- Endpoint alumni/calon: GET `/alumni/calon` untuk list siswa XII belum alumni

**Detail Frontend:**
- Loading state: Tombol submit disable saat loading + spinner
- Konfirmasi dialog: AlertDialog sebelum proses batch
- Pagination + Search: Kedua tab (history & alumni) punya search bar + pagination
- Alumni dropdown: Form tambah alumni pakai dropdown siswa XII
- Error handling: SnackBar untuk semua error
- Step indicator dinamis: 3 step untuk kelas XII, 4 step untuk lainnya

---

### 1.3 Hasil Analisis

- ✅ Flutter analyze: 0 errors (hanya warnings/info)
- ✅ TypeScript compile: No errors

---

## Bagian 2: Rencana Perancangan Sistem 1 & Sistem 2

### 2.1 Arsitektur Umum

┌─────────────────────────────────────────────────────────────┐
│                      SISTEM 1 (PPI)                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   ADMIN     │  │ KURIKULUM   │  │  SANTRI PAGE        │ │
│  │  ─────────  │  │  ─────────  │  │  (Idarat al-        │ │
│  │ Data Santri │  │ Kenaikan    │  │   Madfu'at)         │ │
│  │ Data Kelas  │  │ Kelas       │  │                     │ │
│  └─────────────┘  └─────────────┘  │ Melihat data        │ │
│                                     │ pembayaran dari     │ │
│                                     │ Sistem 2            │ │
│                                     └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                    API Key (X-API-Key)
                              │
┌─────────────────────────────┼───────────────────────────────┐
│                             ▼                               │
│                      SISTEM 2 (Pihak Kedua)                │
│              (Aplikasi Web / Responsive Tablet)             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  • Input jenis pembayaran (sesuai kebutuhan)               │
│  • Input pembayaran per santri                              │
│  • Kelola status (*, *, **)                               │
│  • Kirim notifikasi ke santri                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘

### 2.2 Sumber Data

| Modul (Sistem 1) | Data yang Disediakan |
|------------------|---------------------|
| **Admin** | Data Santri + Data Kelas |
| **Kurikulum** | Kenaikan Kelas |
| **Santri Page** | Melihat data pembayaran dari Sistem 2 |

### 2.3 Peran

| Aktor | Aksi |
|-------|------|
| **Pihak Kedua (Sistem 2)** | Input jenis pembayaran, input pembayaran per santri, kirim notifikasi ke santri |
| **Admin (Sistem 1)** | Hanya **melihat** data pembayaran di modul Idarat al-Madfu'at |
| **Santri** | Menerima notifikasi pembayaran |

### 2.4 Status Pembayaran

| Kode | Status | Keterangan |
|------|--------|------------|
| `*` | Telah Lunas | Pembayaran selesai |
| `**` | Sedang dalam Proses | Pembayaran sedang diproses |
| `***` | Belum melakukan Pembayaran | Belum bayar |

---

## Bagian 3: Alur API Key

### 3.1 Flow Komunikasi

┌─────────────────────────────────────────────────────────────┐
│                      SISTEM 1 (PPI)                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Database                                            │   │
│  │  ┌───────────────────────────────────────────────┐  │   │
│  │  │  api_keys                                      │  │   │
│  │  │  ───────────────────────────────────────────  │  │   │
│  │  │  id | nama_pihak | api_key_hash | is_aktif   │  │   │
│  │  │   1 | Toko Maju  | $2a$10$abc...  | true     │  │   │
│  │  └───────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
│                          │                                  │
│                    API Endpoints                            │
│              /api/v1/santri                                │
│              /api/v1/kelas                                 │
│              /api/v1/kenaikan-kelas                        │
│              /api/v1/pembayaran (POST)                     │
│                          │                                  │
└──────────────────────────┼──────────────────────────────────┘
                           │
                    API Key Header
              X-API-Key: abc123def456...
                           │
┌──────────────────────────┼──────────────────────────────────┐
│                          ▼                                  │
│                      SISTEM 2 (Pihak Kedua)                │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Aplikasi Web/Tablet                                 │   │
│  │                                                      │   │
│  │  1. GET data santri      → /api/v1/santri            │   │
│  │  2. GET data kelas       → /api/v1/kelas             │   │
│  │  3. GET kenaikan kelas   → /api/v1/kenaikan-kelas    │   │
│  │  4. POST pembayaran      → /api/v1/pembayaran        │   │
│  │  5. POST notifikasi      → /api/v1/notifikasi        │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘

### 3.2 Alur Request - Ambil Data

Sistem 2                          Sistem 1
   │                                 │
   │  GET /api/v1/santri             │
   │  Header:                        │
   │    X-API-Key: abc123def456      │
   │                                 │
   │  ─────────────────────────────> │
   │                                 │
   │                    ┌────────────┴────────────┐
   │                    │  Validasi API Key        │
   │                    │  1. Cari di table        │
   │                    │  2. Check is_aktif       │
   │                    │  3. Verify hash          │
   │                    └────────────┬────────────┘
   │                                 │
   │  <───────────────────────────── │
   │  Response: { data: ... }      │

### 3.3 Alur Request - Kirim Data

Sistem 2                          Sistem 1
   │                                 │
   │  POST /api/v1/pembayaran        │
   │  Header:                        │
   │    X-API-Key: abc123def456      │
   │  Body:                          │
   │    { santri_id, jenis, jumlah } │
   │                                 │
   │  ─────────────────────────────> │
   │                                 │
   │                    ┌────────────┴────────────┐
   │                    │  Validasi + Simpan       │
   │                    │  1. Validasi API Key     │
   │                    │  2. Simpan ke tabel      │
   │                    │  3. Kirim notif ke       │
   │                    │     santri               │
   │                    └────────────┬────────────┘
   │                                 │
   │  <───────────────────────────── │
   │  Response: { success: true }    │

### 3.4 Alur Sinkronisasi

#### Polling (Sistem 2 fetch berkala)
Sistem 1 (PPI)                Sistem 2 (Pihak Kedua)
      │                              │
      │  GET /api/v1/santri          │
      │ <─────────────────────────  │
      │                              │
      │  Sistem 2 fetch ulang        │
      │  data terbaru                │

#### Webhook (Sistem 1 push saat data berubah)
Sistem 1 (PPI)                Sistem 2 (Pihak Kedua)
      │                              │
      │  POST /webhook/kenaikan      │
      │  { siswa_id, kelas_baru }    │
      │ ─────────────────────────>  │
      │                              │
      │              Update data siswa

---

## Bagian 4: Desain API Key

### 4.2 API Endpoints (Admin)

| Method | Endpoint              | Function                    |
|--------|------------------------|------------------------------|
| POST   | /admin/api-keys        | Generate API Key baru       |
| GET    | /admin/api-keys        | List semua API Key          |
| PUT    | /admin/api-keys/:id    | Update (aktif/nonaktif)     |
| DELETE | /admin/api-keys/:id    | Hapus API Key                |

### 4.3 Validation Middleware

```javascript
async function validateApiKey(request: Request, env: Env): Promise<boolean> {
  const apiKey = request.headers.get('X-API-Key');
  if (!apiKey) return false;

  const key = await env.DB.prepare(
    'SELECT id FROM api_keys WHERE api_key = ? AND is_aktif = 1'
  ).bind(apiKey).first();

  return key !== null;
}
```

### 4.4 Admin Interface

- Halaman untuk generate API Key
- Tampilkan API Key sekali saja (setelah generate)
- Toggle aktif/nonaktif API Key

---

## Bagian 5: Rencana Perancangan API Key (Belum Beres)

### 5.1 Yang Sudah Direncanakan

| Komponen                | Status         | Keterangan                  |
|--------------------------|----------------|------------------------------|
| Database table api_keys  | ✅ Direncanakan | Schema sudah dibuat         |
| Validation Middleware    | ✅ Direncanakan | Logic sudah dipahami        |
| Admin Endpoints          | ✅ Direncanakan | CRUD sudah direncanakan     |

### 5.2 Yang Belum Direncanakan

| Komponen                          | Status  | Yang Perlu Dikerjakan                  |
|------------------------------------|---------|------------------------------------------|
| UI Admin API Keys                  | ❌ Belum | Halaman untuk manage API Key            |
| API Key Generation Logic           | ❌ Belum | Generate + hash + tampilkan sekali      |
| Permissions System                 | ❌ Belum | read, write, readwrite                  |
| Rate Limiting                      | ❌ Belum | Batasi request per API Key              |
| Logging                            | ❌ Belum | Catat semua request dari Sistem 2       |
| Webhook System                     | ❌ Belum | Push notification ke Sistem 2           |
| Database Table jenis_pembayaran    | ❌ Belum | Jenis pembayaran dari Sistem 2           |
| Database Table pembayaran          | ❌ Belum | Data pembayaran per santri               |
| Database Table notifikasi          | ❌ Belum | Notifikasi ke santri                     |
| Frontend Idarat al-Madfu'at        | ❌ Belum | Admin view untuk lihat pembayaran        |

### 5.3 Pertanyaan Belum Terjawab

| No | Pertanyaan                          | Opsi                                    |
|----|--------------------------------------|-------------------------------------------|
| 1  | Siapa yang generate API Key?         | Admin PPI / Pihak Kedua minta            |
| 2  | Permissions API Key?                 | read / write / readwrite                |
| 3  | UI manage API Key di mana?           | Master Data / Pengaturan                |
| 4  | Rate limit berapa?                   | 100/hari / 1000/hari / Unlimited        |
| 5  | Webhook retry jika gagal?            | 3x retry / manual retry                 |
| 6  | Notifikasi ke santri pakai apa?      | Push / SMS / WhatsApp                    |

---

## Ringkasan Status

| Item                    | Status                            |
|---------------------------|------------------------------------|
| Master Data Santri        | ✅ Selesai, belum push            |
| Kenaikan Kelas             | ✅ Selesai, belum push            |
| API Key System             | ⚠️ Direncanakan, belum dikerjakan |
| Sistem 1 ↔ Sistem 2        | ⚠️ Direncanakan, belum dikerjakan |
| Idarat al-Madfu'at          | ❌ Belum dikerjakan                |