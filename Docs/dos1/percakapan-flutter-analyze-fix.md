# Percakapan — Fix Flutter Analyze (Error & Warning)

**Tanggal**: 29 Juli 2026  
**Role**: Guru BK, Guru Mapel/Wali Kelas  
**Fokus**: Memperbaiki error dan warning dari `flutter analyze`

---

## Ringkasan

Setelah menjalankan `flutter analyze` pada proyek Flutter frontend, ditemukan:
- **9 errors** (🔴)
- **2 warnings** (🟡)
- 302 info-level issues (tidak diperbaiki)

Semua error dan warning berhasil diperbaiki tanpa mengubah alur kerja, tampilan, atau fungsionalitas aplikasi.

---

## Daftar Error & Perbaikan

### 1. `konseling_page.dart:160` — `bool` di-assign ke `String?`
**Error**: `invalid_assignment` — A value of type `bool` can't be assigned to a variable of type `String?`

**Penyebab**: `ChoiceChip.onSelected` memberikan parameter `bool`, tapi kode meng-assign-nya ke variabel `String?`:
```dart
onSelected: (v) => setDialogState(() => hari = v),
```

**Perbaikan**: Gunakan loop variable `h` (dari `hariList.map((h) => ...)`) bukan parameter `v`:
```dart
onSelected: (v) => setDialogState(() => hari = h),
```

---

### 2. `pengaduan_page_bk.dart:322` — Kurang koma
**Error**: `expected_token` — Expected to find `,`

**Penyebab**: String literal tidak diakhiri koma:
```dart
Text(
  '${_totalPages > 1 ? "Hal $_page/" : ""}...'
  style: TextStyle(...),  // ← kurang koma setelah string
),
```

**Perbaikan**: Tambah koma setelah string:
```dart
Text(
  '${_totalPages > 1 ? "Hal $_page/" : ""}...',
  style: TextStyle(...),
),
```

---

### 3. `absensi_page.dart:60,69` — `const` constructor tidak ada
**Error**: `const_with_non_const` — The constructor being called isn't a const constructor

**Penyebab**: `const _InputAbsensiPage()` dan `const _RiwayatAbsensiPage()` dipanggil tapi class-nya tidak punya `const` constructor.

**Perbaikan**: Tambah `const` constructor:
```dart
class _InputAbsensiPage extends StatefulWidget {
  const _InputAbsensiPage();
  // ...
}
```

---

### 4. `rapor_page.dart:113,246,287,303` — `const_eval_type_bool_num_string`
**Error**: In constant expressions, operands of this operator must be of type 'bool', 'num', 'String' or 'null'

**Penyebab**: Empat konstanta expression mengandung tipe yang tidak bisa dievaluasi:
- `const Text('Rapor Santri', style: TextStyle(color: Colors.white))` — `Colors.white` (MaterialColor) tidak bisa dipakai di `const TextStyle`
- `const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)` — `pw.FontWeight.bold` memicu operator `==` di internal TextStyle
- `const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)` — sama
- `const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)` — sama

**Perbaikan**: Hapus `const` dari keempat widget tersebut:
```dart
// Sebelum:
const Text('Rapor Santri', style: TextStyle(...))

// Sesudah:
Text('Rapor Santri', style: TextStyle(...))
```

---

### 5. `wali_kelas_page.dart:663` — Parameter `rows` tidak dikenal
**Error**: `undefined_named_parameter` — The named parameter 'rows' isn't defined

**Penyebab**: `pw.Table.fromTextArray()` menggunakan parameter `rows` yang tidak valid — parameter yang benar adalah `data`.

**Perbaikan**: Ganti `rows:` menjadi `data:`:
```dart
// Sebelum:
pw.Table.fromTextArray(
  rows: siswa.asMap().entries.map(...).toList(),
)

// Sesudah:
pw.Table.fromTextArray(
  data: siswa.asMap().entries.map(...).toList(),
)
```

---

### 6. `wali_kelas_page.dart:562` — Variable `anchor` tidak dipakai (warning)
**Warning**: `unused_local_variable`

**Perbaikan**: Hapus `final anchor = `, gunakan cascade langsung:
```dart
// Sebelum:
final anchor = html.AnchorElement(href: url)
  ..target = '_blank'
  ..download = '...'
  ..click();

// Sesudah:
html.AnchorElement(href: url)
  ..target = '_blank'
  ..download = '...'
  ..click();
```

---

### 7. `bakat_minat_page.dart:530` — Variable `anchor` tidak dipakai (warning)
**Warning**: `unused_local_variable`

**Perbaikan**: Sama dengan #6, hapus `final anchor = `.

---

## Hasil Akhir

```
flutter analyze → 0 errors, 0 warnings, 302 infos
```

Semua **9 errors** dan **2 warnings** berhasil diperbaiki.  
Info-level issues (302) tidak disentuh untuk menghindari perubahan yang tidak perlu.

---

## File yang Diubah

| File | Perubahan |
|------|-----------|
| `frontend/lib/features/guru_bk/konseling/konseling_page.dart` | Fix ChoiceChip `hari = v` → `hari = h` |
| `frontend/lib/features/guru_bk/pengaduan/pengaduan_page_bk.dart` | Tambah koma setelah string |
| `frontend/lib/features/guru_mapel_wali_kelas/absensi/absensi_page.dart` | Tambah `const` constructor |
| `frontend/lib/features/guru_mapel_wali_kelas/rapor/rapor_page.dart` | Hapus `const` dari 4 widget |
| `frontend/lib/features/guru_mapel_wali_kelas/wali_kelas/wali_kelas_page.dart` | `rows:` → `data:`, hapus `anchor` |
| `frontend/lib/features/guru_bk/bakat_minat/bakat_minat_page.dart` | Hapus `anchor` variable |

---

*Dokumen ini disalin dari percakapan dengan Buffy (Freebuff AI Agent)*
