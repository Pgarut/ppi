#  rencana Wireframe: Halaman Jadwal Pelajaran pada WK 

## Baris Toolbar

| Pilih Tingkat : ▾ 10 | Genre Jadwal ▾ | Semester : ▾ | Reset Jadwal | Simpan / Publikasi |


## Area Konten

### Kolom Kiri — Panel Mata Pelajaran / Kegiatan

```
┌─────────────────────────────┐
│     [+ Tambah]               │
│ * Istirahat RG           🗑️ │
│ * Istirahat UG           🗑️ │
│ * Tahfidz & Tahsin       🗑️ │
│ * Murojaah               🗑️ │
│ * Ba'at                  🗑️ │
│                             │
│ 1. Nama Guru Mapel          │
│    Pelajaran                │
│                             │
│ 1. Nama Guru Mapel          │
│    Pelajaran                │
│                             │
│ 1. Nama Guru Mapel          │
│    Pelajaran                │
│                             │
│ 1. Nama Guru Mapel          │
│    Pelajaran                │
│                             │
│ 1. Nama Guru Mapel          │
│    Pelajaran                │
└─────────────────────────────┘
```

### Kolom Kanan — Tabel Jadwal

| Waktu | 10 A | 10 B | 10 C | 10 D | 10 E |
|---    |---    |---    |--- |---   |---   |
| **+ Tambah / Atur Jam** | | | | | |
|       |       | | | | |
|       |       | | | | |
|       | | | | | |
|       | | | | | |

## Panel Bawah

```
┌───────────────────────────────────────────────────────────┐
│ Keterangan Jam Bentrok .                                   │
│                                                             │
│                                                             │
└───────────────────────────────────────────────────────────┘
```

---

### Catatan struktur
- **Toolbar** (atas): 5 kontrol sejajar — dropdown kelas, dropdown genre jadwal, dropdown semester, tombol reset, tombol simpan/publikasi.
- **Kolom kiri**: daftar kegiatan tetap (bisa dihapus dengan ikon sampah) + daftar input Nama/Guru/Mapel/Pelajaran (5 baris, bisa ditambah dengan tombol `+ Tambah`).
- **Kolom kanan**: tabel utama, baris = waktu/jam, kolom = kelas (10 A–10 E), dengan tombol `+ Tambah / Atur Jam` di baris pertama.
- **Panel bawah**: area "Keterangan Jam Bentrok" — menampilkan info bentrokan jadwal.

## Halaman: Jadwal Pelajaran

### Toolbar
- dropdown: Pilih Tingkat (source: daftar Tingkat) diambil api dari master data admin tetap
- dropdown: Genre Jadwal
- dropdown: Semester
- button: Reset Jadwal (action: reset_jadwal)
- button: Simpan/Publikasi (action: simpan_publikasi_jadwal)

### Panel Kiri: Daftar Kegiatan & Mapel
- list_item: Nama Guru Mapel (action_add: tambah_kegiatan)
- list_item (fixed, deletable): Istirahat RG
- list_item (fixed, deletable): Istirahat UG
- list_item (fixed, deletable): Tahfidz & Tahsin
- list_item (fixed, deletable): Murojaah
- list_item (fixed, deletable): Ba'at
- repeatable_row (x5): { nama_guru, mapel, pelajaran } (action_add: tambah_pelajaran)

### Tabel Jadwal
- table:
  - rows: waktu (jam ke-)
  - columns: kelas (10 A, 10 B, 10 C, 10 D, 10 E)
  - cell_content: mapel yang mengajar pada jam & kelas tsb
  - action: tambah_atur_jam (menambah baris waktu baru)

### Panel Bawah
- info_panel: Keterangan Jam Bentrok (menampilkan konflik jadwal, auto-generated)
