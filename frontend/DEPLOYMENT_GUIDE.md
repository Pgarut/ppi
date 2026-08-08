# 📱 Panduan Deploy Sistem Informasi Madrasah PPI

## 🎯 Opsi Deploy

### 1. PWA (Progressive Web App) ⭐ REKOMENDASI
Bisa di-install langsung dari browser di Android & PC

### 2. Android APK/AAB
Untuk distribusi via Play Store atau install manual

### 3. Desktop App (Windows/Mac/Linux)
Untuk penggunaan di komputer

---

## 🌐 Opsi 1: PWA (Progressive Web App)

### Kelebihan:
- ✅ Bisa di-install dari browser tanpa Play Store
- ✅ Update otomatis
- ✅ Ukuran kecil (< 1MB)
- ✅ Bisa offline (dengan cache)
- ✅ Support Android, iOS, Windows, Mac, Linux

### Langkah Deploy:

#### 1. Build Web
```bash
# Build untuk production
flutter build web --release --dart-define=API_BASE_URL=https://api.ppi-madrasah.com

# Atau dengan base href jika di subfolder
flutter build web --release --base-href=/ppi/ --dart-define=API_BASE_URL=https://api.ppi-madrasah.com
```

#### 2. Deploy ke Hosting
Hasil build ada di `build/web/`

**Opsi Hosting:**
- **Vercel** (Gratis): https://vercel.com
- **Netlify** (Gratis): https://netlify.com
- **Firebase Hosting** (Gratis): https://firebase.google.com
- **GitHub Pages** (Gratis): https://pages.github.com

#### 3. Install di Android (dari browser)
1. Buka aplikasi Chrome
2. Kunjungi URL website PPI
3. Klik menu ⋮ (titik tiga)
4. Pilih "Install app" atau "Tambahkan ke layar utama"
5. Klik "Install"

#### 4. Install di PC (dari browser)
1. Buka Chrome/Edge
2. Kunjungi URL website PPI
3. Klik ikon install di address bar (atau menu ⋮ → Install)
4. Aplikasi akan terinstall sebagai aplikasi desktop

---

## 📱 Opsi 2: Android APK

### Kelebihan:
- ✅ Akses penuh ke fitur Android
- ✅ Bisa publish di Play Store
- ✅ Performa lebih baik dari PWA
- ✅ Bisa offline tanpa browser

### Langkah Build:

#### 1. Setup Android Project
```bash
# Buka project di Android Studio
flutter create --platforms android .
```

#### 2. Build APK
```bash
# Build APK (untuk install manual)
flutter build apk --release --dart-define=API_BASE_URL=https://api.ppi-madrasah.com

# Build AAB (untuk Play Store)
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.ppi-madrasah.com
```

#### 3. Install APK
- APK ada di: `build/app/outputs/flutter-apk/app-release.apk`
- Transfer ke HP dan install
- Aktifkan "Sumber tidak dikenal" jika perlu

#### 4. Publish ke Play Store
1. Buat akun Google Play Developer ($25 sekali)
2. Upload AAB ke Play Console
3. Isi deskripsi, screenshot, dll
4. Submit untuk review

---

## 💻 Opsi 3: Desktop App

### Windows
```bash
# Build untuk Windows
flutter build windows --release --dart-define=API_BASE_URL=https://api.ppi-madrasah.com

# Output di: build/windows/x64/runner/Release/
```

### macOS
```bash
# Build untuk macOS
flutter build macos --release --dart-define=API_BASE_URL=https://api.ppi-madrasah.com

# Output di: build/macos/Build/Products/Release/
```

### Linux
```bash
# Build untuk Linux
flutter build linux --release --dart-define=API_BASE_URL=https://api.ppi-madrasah.com

# Output di: build/linux/x64/release/bundle/
```

---

## 🔧 Konfigurasi API

### Environment Variables
```bash
# Development
API_BASE_URL=http://localhost:8787

# Production
API_BASE_URL=https://api.ppi-madrasah.com
```

### Build Command
```bash
# Dengan API URL
flutter build web --dart-define=API_BASE_URL=https://api.ppi-madrasah.com

# Dengan .env file
flutter build web --dart-define-from-file=.env
```

---

## 📋 Checklist Deploy

### PWA
- [ ] Update manifest.json (nama, ikon, warna)
- [ ] Tambahkan service worker untuk offline
- [ ] Build web dengan release mode
- [ ] Deploy ke hosting
- [ ] Test install di Android
- [ ] Test install di PC

### Android
- [ ] Setup Android project
- [ ] Build APK/AAB
- [ ] Test di device Android
- [ ] Publish ke Play Store (opsional)

### Desktop
- [ ] Build untuk Windows/Mac/Linux
- [ ] Test di masing-masing OS
- [ ] Buat installer (opsional)

---

## 🚀 Rekomendasi Deploy

### Untuk Madrasah:
1. **Primary: PWA** → Deploy ke Vercel/Netlify (gratis)
2. **Secondary: Android APK** → Share APK langsung ke guru/siswa
3. **Optional: Desktop** → Untuk admin yang pakai PC

### URL Contoh:
- PWA: `https://ppi-madrasah.vercel.app`
- API: `https://api.ppi-madrasah.com`

---

## 📞 Bantuan

Jika ada masalah:
1. Cek console browser (F12) untuk error
2. Pastikan API server berjalan
3. Test di browser lain
4. Clear cache jika perlu
