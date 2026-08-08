# 📱 Analisis QR Absensi Musyrifah Dauroh
## Sistem Informasi Madrasah PPI

---

## 🔄 Konsep Absensi Dauroh

### Prinsip Utama:
1. **QR Code DICETAK & DITEMPEL** di lokasi kegiatan (Aula/Ruang Dauroh)
2. **Musyrifah SCAN QR** dengan mobile device (seperti guru scan absensi)
3. **Data masuk ke Monitoring Absensi**: NIP, Nama, Hari, Jam
4. **Santri TIDAK perlu QR** - absensi santri dilihat dari rekap

---

## 📋 Alur Lengkap

### FASE 1: Admin Cetak QR Code

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  🖨️ Admin Cetak QR Code Dauroh                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  QR Code (Token Statis): PPI_DAUROH_QR_2026                                │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                      │   │
│  │              ┌─────────────────────────────┐                         │   │
│  │              │                             │                         │   │
│  │              │      QR CODE DAUROH         │                         │   │
│  │              │                             │                         │   │
│  │              │   Token: PPI_DAUROH_QR_2026 │                         │   │
│  │              │                             │                         │   │
│  │              └─────────────────────────────┘                         │   │
│  │                                                                      │   │
│  │  📍 Ditempel di: Aula / Ruang Dauroh / Lokasi Kegiatan             │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  ✅ QR Code ini STATIS (sama selalu) - Cukup dicetak 1x                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### FASE 2: Musyrifah Scan QR (Saat Mulai Dauroh)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  👩‍🏫 Dashboard Musyrifah (Mobile)                                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Selamat Pagi, Siti Aminah                                                  │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  📅 Jadwal Hari Ini                                                 │   │
│  │                                                                      │   │
│  │  08:00 - 10:00  Tahfidz Juz 30 (X MIPA 1, X MIPA 2)               │   │
│  │                  Status: ⏳ Belum Absen                              │   │
│  │                                                                      │   │
│  │  [ 📷 Scan QR Absensi ]  ← KLIK TOMBOL INI                         │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  Setelah klik "Scan QR":                                                    │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                      │   │
│  │                   ┌─────────────────────┐                            │   │
│  │                   │                     │                            │   │
│  │                   │   [ KAMERA VIEW ]   │                            │   │
│  │                   │                     │                            │   │
│  │                   │   Arahkan ke QR     │                            │   │
│  │                   │   Code di Lokasi    │                            │   │
│  │                   │                     │                            │   │
│  │                   └─────────────────────┘                            │   │
│  │                                                                      │   │
│  │  Status: Menunggu scan...                                            │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

### FASE 3: Data Masuk ke Monitoring Absensi

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  ✅ Scan Berhasil!                                                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                                                                      │   │
│  │  ✅ Absensi Berhasil!                                                │   │
│  │                                                                      │   │
│  │  NIP    : MUS001                                                    │   │
│  │  Nama   : Siti Aminah                                               │   │
│  │  Hari   : Rabu                                                      │   │
│  │  Jam    : 08:05 WIB                                                 │   │
│  │                                                                      │   │
│  │  ═══════════════════════════════════════════════════════════════   │   │
│  │                                                                      │   │
│  │  Data sudah tercatat di Monitoring Absensi!                         │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 📊 Monitoring Absensi (Tampilan Admin)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  📊 Monitoring Absensi Dauroh                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Filter: Program [  Semua  ▼]  Tanggal [  06/08/2026  ]                    │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ No │ NIP      │ Nama           │ Hari    │ Jam     │ Status        │   │
│  ├────┼──────────┼────────────────┼─────────┼─────────┼───────────────│   │
│  │ 1  │ MUS001   │ Siti Aminah    │ Rabu    │ 08:05   │ ✅ Hadir      │   │
│  │ 2  │ MUS002   │ Abdul Rahman   │ Rabu    │ 08:10   │ ✅ Hadir      │   │
│  │ 3  │ MUS003   │ Fatimah Zahra  │ Rabu    │ 08:02   │ ✅ Hadir      │   │
│  │ 4  │ MUS004   │ Hasan Basri    │ Rabu    │    -    │ ❌ Alpha      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│  Rekap: Hadir: 3 | Alpha: 1 | Total Musyrifah: 4                           │
│                                                                             │
│                                         [ 📄 Export Excel ] [ 🖨️ Print ]    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔌 API Endpoints

### Scan QR (Musyrifah):
```
POST /api/dauroh/absensi/scan
Body: {
  "token": "PPI_DAUROH_QR_2026",
  "jadwal_id": 123,
  "tanggal": "2026-08-06"
}
Response: {
  "success": true,
  "message": "Absensi berhasil",
  "data": {
    "nip": "MUS001",
    "nama": "Siti Aminah",
    "hari": "Rabu",
    "jam": "08:05:30",
    "status": "hadir"
  }
}
```

### Get Monitoring Absensi:
```
GET /api/dauroh/monitoring/absensi?tanggal=2026-08-06
Response: {
  "data": [
    {
      "nip": "MUS001",
      "nama": "Siti Aminah",
      "hari": "Rabu",
      "jam": "08:05",
      "status": "hadir"
    },
    {
      "nip": "MUS002",
      "nama": "Abdul Rahman",
      "hari": "Rabu",
      "jam": "08:10",
      "status": "hadir"
    }
  ],
  "rekap": {
    "hadir": 3,
    "alpha": 1,
    "total": 4
  }
}
```

---

## 🗄️ Database Schema

### Tabel Absensi Musyrifah (Updated):
```sql
CREATE TABLE dauroh_absensi_musyrifah (
  id SERIAL PRIMARY KEY,
  musyrifah_id INTEGER NOT NULL REFERENCES dauroh_musyrifah(id),
  jadwal_id INTEGER NOT NULL REFERENCES dauroh_jadwal(id),
  tanggal DATE NOT NULL,
  waktu_scan TIME NOT NULL,
  status VARCHAR(10) DEFAULT 'hadir',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(musyrifah_id, jadwal_id, tanggal)
);
```

---

## 📁 Struktur File

```
lib/features/admin/dauroh/monitoring/
├── absensi_musyrifah_page.dart    ← Monitoring Absensi Musyrifah
└── widgets/
    └── absensi_table_widget.dart  ← Tabel absensi

lib/features/musyrifah/absensi/
├── scan_qr_page.dart              ← Halaman Scan QR
└── widgets/
    └── qr_scanner_widget.dart     ← Widget kamera scanner
```

---

## ✅ Ringkasan Alur

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              ALUR SEDERHANA                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. Admin cetak QR Code → Tempel di lokasi kegiatan                       │
│                                                                             │
│  2. Musyrifah datang → Buka HP → Scan QR yang ditempel                    │
│                                                                             │
│  3. Data otomatis masuk ke Monitoring:                                     │
│     ├── NIP Musyrifah                                                      │
│     ├── Nama Musyrifah                                                     │
│     ├── Hari (Senin, Selasa, dst)                                          │
│     └── Jam (08:05, 13:10, dst)                                            │
│                                                                             │
│  4. Admin lihat di Monitoring Absensi → Daftar lengkap                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## ✅ Checklist Implementasi

### Admin:
- [ ] Buat QR Code (cetak) untuk lokasi kegiatan
- [ ] Halaman Monitoring Absensi Musyrifah
- [ ] Tabel: NIP, Nama, Hari, Jam, Status
- [ ] Filter tanggal & program
- [ ] Export Excel & Print

### Musyrifah:
- [ ] Tombol "Scan QR" di dashboard
- [ ] Halaman Scanner (kamera)
- [ ] Konfirmasi setelah scan berhasil

### Backend:
- [ ] Endpoint scan QR
- [ ] Endpoint monitoring absensi
- [ ] Validasi token QR

---

**Mau saya bantu implementasi mulai dari mana?**
