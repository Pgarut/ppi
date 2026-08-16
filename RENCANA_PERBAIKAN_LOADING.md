# 📋 RENCANA PERBAIKAN MASALAH LOADING

**Tanggal Dibuat:** 12 Agustus 2026  
**Estimasi Selesai:** 14 Agustus 2026  
**Total Durasi:** 3 Hari

---

## 📊 RINGKASAN MASALAH

| No | Masalah | Jumlah | Prioritas |
|----|---------|--------|-----------|
| 1 | Silent Error (`catch (_) {}`) | 190+ lokasi | 🔴 Kritis |
| 2 | Tidak ada Timeout API | 136 endpoint | 🔴 Kritis |
| 3 | Tidak ada Skeleton Loading | 0 file | 🟡 Penting |
| 4 | Error Handling Tidak Konsisten | ~60 file | 🟡 Penting |
| 5 | Tidak ada Retry Mechanism | ~40 file | 🟢 Nice to Have |

---

## 🗓️ JADWAL PERBAIKAN

### **HARI 1: Senin, 12 Agustus 2026**

#### Sesi 1: 09:00 - 10:30 WIB (1.5 jam)
**Buat Utility Error Handling**

| Waktu | Tugas | File | Status |
|-------|-------|------|--------|
| 09:00 - 09:30 | Buat fungsi `safeApiCall` | `lib/shared/widgets/app_utils.dart` | ⬜ |
| 09:30 - 10:00 | Buat fungsi `handleApiError` | `lib/shared/widgets/app_utils.dart` | ⬜ |
| 10:00 - 10:30 | Test utility di satu halaman | `lib/features/santri/dashboard/dashboard_santri_page.dart` | ⬜ |

**Output:**
- [ ] Fungsi `safeApiCall<T>()` tersedia
- [ ] Fungsi `handleApiError()` tersedia
- [ ] Test pass di satu halaman

---

#### Sesi 2: 10:45 - 12:15 WIB (1.5 jam)
**Tambahkan Timeout di ApiClient**

| Waktu | Tugas | File | Status |
|-------|-------|------|--------|
| 10:45 - 11:15 | Tambahkan timeout default | `lib/core/network/api_client.dart` | ⬜ |
| 11:15 - 11:45 | Update semua service calls | `lib/features/*/services/*.dart` | ⬜ |
| 11:45 - 12:15 | Jalankan `flutter analyze` | - | ⬜ |

**Output:**
- [ ] Default timeout 30 detik ditambahkan
- [ ] Semua service calls menggunakan timeout
- [ ] `flutter analyze` pass

---

#### Sesi 3: 13:00 - 15:00 WIB (2 jam)
**Batch Fix: Modul Santri**

| Waktu | Tugas | File | Status |
|-------|-------|------|--------|
| 13:00 - 13:30 | Fix `dashboard_santri_page.dart` | 1 file | ⬜ |
| 13:30 - 14:00 | Fix `jadwal_santri_page.dart` | 1 file | ⬜ |
| 14:00 - 14:30 | Fix `absensi_santri_page.dart` | 1 file | ⬜ |
| 14:30 - 15:00 | Fix `nilai_santri_page.dart` + `materi_santri_page.dart` | 2 file | ⬜ |

**Output:**
- [ ] 5 file santri diperbaiki
- [ ] Error handling konsisten di semua halaman santri
- [ ] `flutter analyze` pass

---

#### Sesi 4: 15:15 - 16:30 WIB (1.25 jam)
**Batch Fix: Modul Musyrifah**

| Waktu | Tugas | File | Status |
|-------|-------|------|--------|
| 15:15 - 15:45 | Fix `dashboard_musyrifah_page.dart` | 1 file | ⬜ |
| 15:45 - 16:00 | Fix `jadwal_dauroh_page.dart` | 1 file | ⬜ |
| 16:00 - 16:15 | Fix `riwayat_absensi_page.dart` | 1 file | ⬜ |
| 16:15 - 16:30 | Fix `nilai_dauroh_page.dart` | 1 file | ⬜ |

**Output:**
- [ ] 4 file musyrifah diperbaiki
- [ ] `flutter analyze` pass

---

### **HARI 2: Selasa, 13 Agustus 2026**

#### Sesi 1: 09:00 - 11:00 WIB (2 jam)
**Batch Fix: Modul Guru (Asatidz)**

| Waktu | Tugas | File | Status |
|-------|-------|------|--------|
| 09:00 - 09:30 | Fix `dashboard_page.dart` | 1 file | ⬜ |
| 09:30 - 10:00 | Fix `jadwal_page.dart` | 1 file | ⬜ |
| 10:00 - 10:30 | Fix `absensi_page.dart` | 1 file | ⬜ |
| 10:30 - 11:00 | Fix `nilai_page.dart` | 1 file | ⬜ |

**Output:**
- [ ] 4 file guru diperbaiki
- [ ] `flutter analyze` pass

---

#### Sesi 2: 11:15 - 12:30 WIB (1.25 jam)
**Batch Fix: Modul Guru (Lanjutan)**

| Waktu | Tugas | File | Status |
|-------|-------|------|--------|
| 11:15 - 11:45 | Fix `rapor_page.dart` | 1 file | ⬜ |
| 11:45 - 12:00 | Fix `pengaduan_page.dart` | 1 file | ⬜ |
| 12:00 - 12:30 | Fix `materi_page.dart` | 1 file | ⬜ |

**Output:**
- [ ] 3 file guru diperbaiki
- [ ] `flutter analyze` pass

---

#### Sesi 3: 13:30 - 15:30 WIB (2 jam)
**Batch Fix: Modul Wakil Kurikulum**

| Waktu | Tugas | File | Status |
|-------|-------|------|--------|
| 13:30 - 14:00 | Fix `penjadwalan_page.dart` | 1 file | ⬜ |
| 14:00 - 14:30 | Fix `nilai_page.dart` | 1 file | ⬜ |
| 14:30 - 15:00 | Fix `absensi_page.dart` | 1 file | ⬜ |
| 15:00 - 15:30 | Fix `kenaikan_kelas_page.dart` | 1 file | ⬜ |

**Output:**
- [ ] 4 file wakil kurikulum diperbaiki
- [ ] `flutter analyze` pass

---

#### Sesi 4: 15:45 - 17:00 WIB (1.25 jam)
**Batch Fix: Modul Wakil Kurikulum (Lanjutan)**

| Waktu | Tugas | File | Status |
|-------|-------|------|--------|
| 15:45 - 16:15 | Fix `laporan_page.dart` + `dauroh_nilai_page.dart` | 2 file | ⬜ |
| 16:15 - 16:45 | Fix `dashboard_page.dart` | 1 file | ⬜ |
| 16:45 - 17:00 | Jalankan `flutter analyze` penuh | - | ⬜ |

**Output:**
- [ ] 3 file wakil kurikulum diperbaiki
- [ ] `flutter analyze` pass

---

### **HARI 3: Rabu, 14 Agustus 2026**

#### Sesi 1: 09:00 - 11:00 WIB (2 jam)
**Batch Fix: Modul Kepala Sekolah**

| Waktu | Tugas | File | Status |
|-------|-------|------|--------|
| 09:00 - 09:20 | Fix `dashboard_page_ks.dart` | 1 file | ⬜ |
| 09:20 - 09:40 | Fix `jadwal_page_ks.dart` | 1 file | ⬜ |
| 09:40 - 10:00 | Fix `nilai_page_ks.dart` | 1 file | ⬜ |
| 10:00 - 10:20 | Fix `rapor_page_ks.dart` | 1 file | ⬜ |
| 10:20 - 10:40 | Fix `bk_page_ks.dart` | 1 file | ⬜ |
| 10:40 - 11:00 | Fix `absensi_page_ks.dart` | 1 file | ⬜ |

**Output:**
- [ ] 6 file kepala sekolah diperbaiki
- [ ] `flutter analyze` pass

---

#### Sesi 2: 11:15 - 12:30 WIB (1.25 jam)
**Batch Fix: Modul Kepala Sekolah (Lanjutan)**

| Waktu | Tugas | File | Status |
|-------|-------|------|--------|
| 11:15 - 11:45 | Fix `laporan_page_ks.dart` | 1 file | ⬜ |
| 11:45 - 12:15 | Fix `dauroh_nilai_page_ks.dart` | 1 file | ⬜ |
| 12:15 - 12:30 | Jalankan `flutter analyze` | - | ⬜ |

**Output:**
- [ ] 2 file kepala sekolah diperbaiki
- [ ] `flutter analyze` pass

---

#### Sesi 3: 13:30 - 15:30 WIB (2 jam)
**Batch Fix: Modul Guru BK**

| Waktu | Tugas | File | Status |
|-------|-------|------|--------|
| 13:30 - 13:50 | Fix `dashboard_page_bk.dart` | 1 file | ⬜ |
| 13:50 - 14:10 | Fix `pengaduan_page_bk.dart` | 1 file | ⬜ |
| 14:10 - 14:30 | Fix `laporan_page_bk.dart` | 1 file | ⬜ |
| 14:30 - 14:50 | Fix `monitoring_akademik_page.dart` | 1 file | ⬜ |
| 14:50 - 15:10 | Fix `bakat_minat_page.dart` | 1 file | ⬜ |
| 15:10 - 15:30 | Fix `konseling_page.dart` | 1 file | ⬜ |

**Output:**
- [ ] 6 file guru BK diperbaiki
- [ ] `flutter analyze` pass

---

#### Sesi 4: 15:45 - 17:00 WIB (1.25 jam)
**Batch Fix: Modul Admin**

| Waktu | Tugas | File | Status |
|-------|-------|------|--------|
| 15:45 - 16:05 | Fix `master_data_page.dart` | 1 file | ⬜ |
| 16:05 - 16:25 | Fix `nilai_page.dart` | 1 file | ⬜ |
| 16:25 - 16:45 | Fix `rapor_page.dart` | 1 file | ⬜ |
| 16:45 - 17:00 | Fix `absensi_page.dart` | 1 file | ⬜ |

**Output:**
- [ ] 4 file admin diperbaiki
- [ ] `flutter analyze` pass

---

#### Sesi 5: 17:00 - 17:30 WIB (0.5 jam)
**Final Testing & Deploy**

| Waktu | Tugas | Status |
|-------|-------|--------|
| 17:00 - 17:10 | Jalankan `flutter analyze` penuh | ⬜ |
| 17:10 - 17:20 | Jalankan `flutter test` | ⬜ |
| 17:20 - 17:30 | Commit & Push | ⬜ |

**Output:**
- [ ] `flutter analyze` pass (0 issues)
- [ ] `flutter test` pass
- [ ] Semua perubahan di-push ke remote

---

## 📈 PROGRESS TRACKER

### Per Modul:
| Modul | Total File | Selesai | Progress |
|-------|------------|---------|----------|
| Santri | 7 | 0 | 0% |
| Musyrifah | 6 | 0 | 0% |
| Guru (Asatidz) | 8 | 0 | 0% |
| Wakil Kurikulum | 7 | 0 | 0% |
| Kepala Sekolah | 8 | 0 | 0% |
| Guru BK | 6 | 0 | 0% |
| Admin | 5 | 0 | 0% |
| **TOTAL** | **47** | **0** | **0%** |

### Per Hari:
| Hari | Target | Selesai | Status |
|------|--------|---------|--------|
| Hari 1 (12 Agustus) | 14 file | 0 file | ⬜ |
| Hari 2 (13 Agustus) | 16 file | 0 file | ⬜ |
| Hari 3 (14 Agustus) | 17 file + testing | 0 file | ⬜ |

---

## 🛠️ TOOLS & SCRIPTS

### Script Batch Fix (contoh):
```bash
# Ganti catch (_) {} dengan error handling
find lib -name "*.dart" -exec sed -i 's/catch (_) {}/catch (e) { debugPrint("Error: \$e"); }/g' {} \;
```

### Command untuk Testing:
```bash
# Analyze
cd frontend && flutter analyze

# Test
cd frontend && flutter test

# Build check
cd frontend && flutter build web --no-tree-shake-icons
```

---

## ✅ CHECKLIST AKHIR

- [ ] Semua `catch (_) {}` diganti dengan error handling
- [ ] Timeout ditambahkan di semua API calls
- [ ] `flutter analyze` pass (0 issues)
- [ ] `flutter test` pass
- [ ] Semua perubahan di-commit
- [ ] Semua perubahan di-push ke remote
- [ ] Deploy berhasil

---

## 📝 CATATAN

1. **Backup:** Selalu backup sebelum perbaikan besar
2. **Commit:** Commit setelah selesai per modul
3. **Test:** Jalankan `flutter analyze` setelah setiap sesi
4. **Dokumentasi:** Update dokumen jika ada perubahan API

---

**Dibuat oleh:** Buffy (AI Assistant)  
**Tanggal:** 12 Agustus 2026  
**Versi:** 1.0
