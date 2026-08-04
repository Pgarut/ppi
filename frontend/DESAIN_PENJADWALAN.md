# Desain Proposal: Halaman Jadwal Pelajaran (WK)

## Struktur Layout

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  TAB: [ Jadwal ]  [ Kesiapan ]  [ Wali Kelas ]                              │
├─────────────────────────────────────────────────────────────────────────────┤
│ TOOLBAR                                                                     │
│ ┌─────────────────────────────────────────────────────────────────────────┐ │
│ │ Pilih Tingkat ▾  │ Genre Jadwal ▾  │ Semester ▾  │ [Reset] [Simpan]    │ │
│ └─────────────────────────────────────────────────────────────────────────┘ │
├────────────────────────────────┬────────────────────────────────────────────┤
│ PANEL KIRI                     │ PANEL KANAN                               │
│ ┌────────────────────────────┐ │ ┌──────────────────────────────────────┐  │
│ │ [ + Tambah Kegiatan ]      │ │ │ TABEL JADWAL                        │  │
│ │                            │ │ │                                      │  │
│ │ KEGIATAN TETAP:            │ │ │ Waktu  │ 10 A │ 10 B │ 10 C │ ...   │  │
│ │ ☐ Istirahat RG         🗑️ │ │ │ ───────┼──────┼──────┼──────┼─────  │  │
│ │ ☐ Istirahat UG         🗑️ │ │ │ JP 1   │      │      │      │       │  │
│ │ ☐ Tahfidz & Tahsin    🗑️ │ │ │ 07:00- │      │      │      │       │  │
│ │ ☐ Murojaah            🗑️ │ │ │ 07:45  │      │      │      │       │  │
│ │ ☐ Ba'at               🗑️ │ │ │ ───────┼──────┼──────┼──────┼─────  │  │
│ │                            │ │ │ JP 2   │      │      │      │       │  │
│ │ ─────────────────────────  │ │ │ 07:45- │      │      │      │       │  │
│ │                            │ │ │ 08:30  │      │      │      │       │  │
│ │ DAFTAR MAPEL:              │ │ │ ───────┼──────┼──────┼──────┼─────  │  │
│ │ (Otomatis dari Master)     │ │ │  ...   │      │      │      │       │  │
│ │ ┌──────────────────────┐   │ │ │ ───────┼──────┼──────┼──────┼─────  │  │
│ │ │ 📚 Matematika        │   │ │ │ JP 8   │      │      │      │       │  │
│ │ │    Pak Ahmad         │   │ │ │ 12:00- │      │      │      │       │  │
│ │ └──────────────────────┘   │ │ │ 12:45  │      │      │      │       │  │
│ │ ┌──────────────────────┐   │ │ └──────────────────────────────────────┘  │
│ │ │ 📚 Bahasa Arab       │   │ │                                            │
│ │ │    Ustadzah Fatimah  │   │ │                                            │
│ │ └──────────────────────┘   │ │                                            │
│ │ ┌──────────────────────┐   │ │                                            │
│ │ │ 📚 Fiqih             │   │ │                                            │
│ │ │    Ustadz Ibrahim    │   │ │                                            │
│ │ └──────────────────────┘   │ │                                            │
│ │                            │ │                                            │
│ └────────────────────────────┘ │                                            │
├────────────────────────────────┴────────────────────────────────────────────┤
│ PANEL BAWAH: KETERANGAN                                                     │
│ ┌─────────────────────────────────────────────────────────────────────────┐ │
│ │ ⚠️ Keterangan Jam Bentrok (Guru Mengajar di 2+ Kelas):                 │ │
│ │ • Senin JP3: Pak Ahmad (Matematika) mengajar di 10A, 11A, 12B         │ │
│ │ • Selasa JP5: Ust. Fatimah (Bahasa Arab) mengajar di 10C dan 11A      │ │
│ └─────────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Detail Komponen

### 1. Toolbar

| Kontrol | Tipe | Sumber Data | Keterangan |
|---------|------|-------------|------------|
| Pilih Tingkat | Dropdown | API `/referensi` → `tingkat` | Filter kelas berdasarkan tingkat |
| Genre Jadwal | Dropdown | Static: `["Pagi", "Siang", "Full Day"]` | Filter jenis jadwal |
| Semester | Dropdown | API `/referensi` → `semester` | Filter semester aktif |
| Reset | Button | `POST /wakil-kurikulum/jadwal/reset` | Hapus jadwal draft |
| Simpan | Button | `POST /wakil-kurikulum/jadwal/simpan` | Simpan semua perubahan |

### 2. Panel Kiri — Daftar Kegiatan & Mapel

**Kegiatan Tetap (deletable):**
- Istirahat RG (Ruang Guru)
- Istirahat UG (Umum)
- Tahfidz & Tahsin
- Murojaah
- Ba'at

**Daftar Mapel (otomatis dari Master Data Admin):**
- Diambil dari API `/referensi` → `guru_mapel` (guru + mapel yang diampu)
- Setiap item: Nama Mapel + Nama Guru
- **Tidak bisa ditambah** (sudah dari master data)
- Bisa di-drag ke tabel jadwal

**Interaksi:**
- Drag mapel dari panel kiri → drop ke sel tabel
- Klik 🗑️ pada kegiatan tetap untuk hapus

### 3. Panel Kanan — Tabel Jadwal

**Struktur Tabel:**

| Waktu | 10 A | 10 B | 10 C | 10 D | 10 E |
|-------|------|------|------|------|------|
| **JP 1** (07:00-07:45) | Matematika / Pak Ahmad | Bahasa Arab / Ust. Fatimah | - | - | - |
| **JP 2** (07:45-08:30) | - | - | Fiqih / Ust. Ibrahim | - | - |
| **JP 3** (08:30-09:15) | - | - | - | - | - |
| ... | ... | ... | ... | ... | ... |

**Cell Content:**
- Nama Mapel (bold)
- Nama Guru (small, grey)
- Warna: Hijau (tervalidasi) / Orange (draft)

**Interaksi:**
- **Drag & Drop**: Pindah jadwal antar sel
- **Klik sel**: Edit jadwal di sel tersebut
- **Klik "+ Tambah Jam"**: Tambah baris waktu baru

### 4. Panel Bawah — Keterangan Jam Bentrok

**Fungsi:**
- Auto-detect **guru yang mengajar di 2+ kelas pada jam yang sama**
- Guru dapat mengampu beberapa mapel dan beberapa tingkat (10, 11, 12)
- Tampilkan warning jika ada bentrok

**Format:**
```
⚠️ [Hari] [JP]: [Nama Guru] ([Mapel]) mengajar di [Kelas1], [Kelas2] pada jam yang sama
```

**Contoh:**
```
⚠️ Senin JP3: Pak Ahmad (Matematika) mengajar di 10A, 11A, 12B pada jam yang sama
⚠️ Selasa JP5: Ust. Fatimah (Bahasa Arab) mengajar di 10C dan 11A pada jam yang sama
```

---

## Alur Kerja

```
1. User pilih Tingkat → Kelas dropdown ter-update
2. User pilih Semester → Tabel jadwal load
3. User pilih Hari → Tabel filter per hari
4. User drag mapel dari panel kiri → drop ke sel tabel
5. System auto-save & cek bentrok
6. User klik Simpan → Semua perubahan tersimpan
7. User klik Publikasi → Jadwal tampil di Guru
```

---

## API Calls

| Event | Method | Endpoint | Parameter |
|-------|--------|----------|-----------|
| Load referensi | GET | `/referensi` | - (ambil `tingkat`, `kelas`, `semester`, `guru_mapel`) |
| Load JP slots | GET | `/wakil-kurikulum/jp-slots` | - |
| Load jadwal | GET | `/wakil-kurikulum/jadwal-per-kelas` | `kelas_id`, `semester_id` |
| Load guru & mapel | GET | `/referensi` | - (dari `guru_mapel` di referensi) |
| Cek bentrok | POST | `/wakil-kurikulum/jadwal/cek-bentrok` | `body` |
| Simpan jadwal | POST | `/wakil-kurikulum/jadwal/simpan` | `body` |
| Reset jadwal | POST | `/wakil-kurikulum/jadwal/reset` | `semester_id` |
| Publikasi | POST | `/wakil-kurikulum/jadwal/publikasi` | `semester_id` |

---

## Perbedaan dengan Current

| Aspek | Current | Proposal | Alasan |
|-------|---------|----------|--------|
| Tab | 3 (Jadwal, Kesiapan, Wali Kelas) | **Tetap 3** | Pertahankan fitur existing |
| Layout | 1 tabel full | **2 kolom** (Panel Kiri + Tabel) | Sesuai wireframe |
| Kolom Tabel | Hari (Sabtu-Minggu) | **Kelas (10A, 10B, ...)** | Sesuai wireframe |
| Panel Kiri | ❌ Tidak ada | **✅ Ada** | Sesuai wireframe |
| Panel Bawah | ❌ Tidak ada | **✅ Ada** | Sesuai wireframe |
| Drag & Drop | ✅ Ada | **Tetap ada** | Pertahankan fitur |
| Toolbar | 5 buttons | **5 kontrol** | Simplify toolbar |

---

## Estimasi

| Task | Estimasi |
|------|----------|
| Refactor toolbar | 0.5 hari |
| Buat panel kiri | 1 hari |
| Refactor tabel (kolom = kelas) | 1.5 hari |
| Buat panel bawah | 0.5 hari |
| Integrasi drag & drop | 1 hari |
| Testing & fix | 0.5 hari |
| **Total** | **5 hari** |

---

## Status

- [ ] Menunggu approval user
- [ ] Eksekusi
