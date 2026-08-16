# 🔍 ANALISIS & RENCANA PERBAIKAN MASALAH LOADING

**Tanggal Analisis:** 12 Agustus 2026  
**Status:** Draft - Menunggu Persetujuan

---

## 📊 HASIL ANALISIS KODE

### 1. Kondisi Saat Ini

| Komponen | Status | Keterangan |
|----------|--------|------------|
| **ApiClient** | ✅ Bagus | Sudah ada token refresh otomatis, TAPI belum ada timeout |
| **AppUtils** | ✅ Bagus | Sudah ada `handleError()`, `showError()`, `showSuccess()` |
| **Error Handling** | ❌ Buruk | 70+ lokasi `catch (_) {}` (silent error) |
| **Loading State** | ⚠️ Variatif | Beberapa pakai `_loading`, beberapa tidak |
| **Timeout API** | ❌ Tidak Ada | Request bisa menggantung selamanya |

---

### 2. statistik Error Handling

```
Total try-catch blocks    : 201 lokasi
Silent error (catch _)    : 70 lokasi  ← PERLU DIPERBAIKI
Proper error handling     : ~131 lokasi
```

---

### 3. Modul yang Terdampak

| Modul | Silent Error | Total Try-Catch | Prioritas |
|-------|--------------|-----------------|-----------|
| Admin | 15 | 45 | 🔴 Tinggi |
| Wakil Kurikulum | 12 | 35 | 🔴 Tinggi |
| Guru Mapel/Wali Kelas | 12 | 38 | 🔴 Tinggi |
| Guru BK | 8 | 25 | 🟡 Sedang |
| Kepala Sekolah | 10 | 30 | 🟡 Sedang |
| Musyrifah | 7 | 18 | 🟡 Sedang |
| Santri | 4 | 12 | 🟢 Rendah |
| Auth | 2 | 5 | 🟢 Rendah |
| **TOTAL** | **70** | **208** | - |

---

## ⚠️ ANALISIS RISIKO

### Risiko 1: Timeout API (CRITICAL)

**Masalah:**  
Saat ini `ApiClient` TIDAK memiliki timeout. Request HTTP menggunakan default timeout dari package `http` yang bisa sangat lama.

**Potensi Error:**
- Request menggantung (hang) jika server lambat
- UI freeze karena menunggu response
- User frustrasi karena tidak ada feedback

**Solusi:**
```dart
// Tambahkan timeout ke semua HTTP methods
static Future<http.Response> _clientWithTimeout() async {
  return http.Client();
}

// Atau set timeout per request
final response = await http.get(uri, headers: headers)
    .timeout(const Duration(seconds: 30));
```

**Risiko Perubahan:**
- 🟡 **Sedang** - Timeout bisa memicu error baru di jaringan lambat
- ✅ **Mitigasi** - Tambahkan retry mechanism untuk network error

---

### Risiko 2: Silent Error (HIGH)

**Masalah:**  
70 lokasi `catch (_) {}` menyembunyikan error, membuat debugging sulit.

**Contoh Masalah:**
```dart
try {
  final data = await service.getData();
  setState(() => _data = data);
} catch (_) {}  // ← ERROR DISIMPAN, USER TIDAK TAHU
```

**Potensi Error:**
- Data tidak muncul tanpa penjelasan
- Bug sulit ditemukan di production
- User tidak tahu harus melakukan apa

**Solusi:**
```dart
try {
  final data = await service.getData();
  setState(() => _data = data);
} catch (e) {
  setState(() => _error = e.toString());
  // Tampilkan error ke user
}
```

**Risiko Perubahan:**
- 🟢 **Rendah** - Hanya menambahkan logging dan error state
- ✅ **Mitigasi** - Error sudah di-handle di ApiClient (throw ApiException)

---

### Risiko 3: Perubahan Flow Loading (MEDIUM)

**Masalah:**  
Setiap halaman punya cara handle loading yang berbeda.

**Variasi yang Ada:**
```dart
// Pola 1: Boolean biasa
bool _loading = true;

// Pola 2: dengan error
bool _loading = true;
String? _error;

// Pola 3: tanpa loading indicator
// (langsung tampilkan data atau empty state)
```

**Potensi Error:**
- 🟡 Loading state tidak konsisten
- 🟡 Beberapa halaman mungkin crash jika error state ditambahkan

**Solusi:**
- Standardisasi pola error handling di semua halaman
- Buat wrapper function yang sudah termasuk loading state

**Risiko Perubahan:**
- 🟡 **Sedang** - Perlu ubah pola di banyak file
- ✅ **Mitigasi** - Test per modul, jangan langsung semua sekaligus

---

### Risiko 4: Breaking Change di Service Layer (LOW)

**Masalah:**  
Service layer sudah return `Map<String, dynamic>`, tidak perlu diubah.

**Analisis:**
```dart
// Service sudah benar
static Future<Map<String, dynamic>> getDashboard() async {
  final res = await ApiClient.get('/admin/dashboard');
  return res['data'] ?? {};
}
```

**Risiko Perubahan:**
- 🟢 **Rendah** - Service layer tidak perlu diubah
- ✅ **Mitigasi** - Cukup perbaiki di layer UI (page)

---

## 📋 RENCANA PERBAIKAN (REVISED)

### Fase 1: Infrastructure (Tanpa Breaking Change)

| No | Tugas | File | Risiko | Estimasi |
|----|-------|------|--------|----------|
| 1.1 | Tambah timeout 30s di ApiClient | `api_client.dart` | 🟡 Sedang | 30 menit |
| 1.2 | Tambah retry untuk network error | `api_client.dart` | 🟡 Sedang | 30 menit |
| 1.3 | Buat `safeApiCall` wrapper | `app_utils.dart` | 🟢 Rendah | 30 menit |
| 1.4 | Test di 1 halaman (dashboard) | `dashboard_page.dart` | 🟢 Rendah | 30 menit |

**Output Fase 1:**
- ✅ ApiClient punya timeout
- ✅ Network error di-retry otomatis
- ✅ Wrapper `safeApiCall` tersedia
- ✅ Test pass di 1 halaman

---

### Fase 2: Batch Fix per Modul (High Priority)

| No | Modul | File | Silent Error | Estimasi |
|----|-------|------|--------------|----------|
| 2.1 | Santri | 7 file | 4 | 1 jam |
| 2.2 | Musyrifah | 6 file | 7 | 1 jam |
| 2.3 | Guru Mapel | 8 file | 12 | 1.5 jam |
| 2.4 | Guru BK | 6 file | 8 | 1 jam |

**Pola Perubahan:**
```dart
// SEBELUM
try {
  _data = await service.getData();
} catch (_) {}

// SESUDAH
try {
  _data = await service.getData();
  setState(() => _loading = false);
} catch (e) {
  setState(() {
    _error = e.toString();
    _loading = false;
  });
}
```

**Risiko per File:**
- 🟢 Rendah - Hanya menambahkan error state
- ⚠️ Pastikan semua `_loading = false` di semua jalur

---

### Fase 3: Batch Fix per Modul (Medium Priority)

| No | Modul | File | Silent Error | Estimasi |
|----|-------|------|--------------|----------|
| 3.1 | Wakil Kurikulum | 7 file | 12 | 1.5 jam |
| 3.2 | Kepala Sekolah | 8 file | 10 | 1.5 jam |
| 3.3 | Admin | 5 file | 15 | 1.5 jam |

---

### Fase 4: Testing & Deploy

| No | Tugas | Estimasi |
|----|-------|----------|
| 4.1 | Flutter analyze penuh | 15 menit |
| 4.2 | Flutter test | 15 menit |
| 4.3 | Manual testing di mobile | 30 menit |
| 4.4 | Commit & Push | 10 menit |
| 4.5 | Deploy ke production | 15 menit |

---

## 🎯 KEPUTUSAN

### Opsi A: Full Fix Sekarang (Direkomendasikan)

**Kelebihan:**
- Semua masalah teratasi sekaligus
- Kode lebih bersih dan maintainable
- Error handling konsisten

**Kekurangan:**
- Butuh waktu 3 hari
- Risiko banyak perubahan sekaligus

---

### Opsi B: Incremental Fix (Lebih Aman)

**Kelebihan:**
- Bisa di-rollback per modul
- Risiko lebih kecil
- Bisa di-test per modul

**Kekurangan:**
- Butuh waktu lebih lama total
- Kode sementara tidak konsisten

---

### Opsi C: Critical Fix Only (Minimum Viable)

**Fokus:**
1. Tambah timeout di ApiClient ✅
2. Fix silent error di dashboard saja ✅
3. Sisanya ditunda

**Waktu:** 1 hari

---

## ❓ PERTANYAAN UNTUK USER

1. **Mana opsi yang dipilih?** (A/B/C)
2. **Apakah perlu skeleton loading?** (Butuh tambahan 2 hari)
3. **Apakah perlu retry mechanism?** (Butuh tambahan 1 hari)

---

**Dibuat oleh:** Buffy  
**Tanggal:** 12 Agustus 2026
