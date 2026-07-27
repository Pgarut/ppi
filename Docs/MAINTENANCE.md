# Maintenance Guide — PPI Madrasah

## 1. Backup Database

### Manual via Dashboard
1. Login sebagai Admin
2. Buka **Pengaturan → Backup Database**
3. Klik **Download Backup** → simpan file JSON

### Manual via Wrangler CLI (Production)
```bash
# Export semua data
npx wrangler d1 execute ppi-db-prod --env production \
  --command="SELECT 'backup_' || strftime('%Y%m%d_%H%M%S','now') as backup_time"

npx wrangler d1 export ppi-db-prod --env production \
  --output=./backups/ppi_$(date +%Y%m%d_%H%M%S).sql
```

### Restore
```bash
npx wrangler d1 execute ppi-db-prod --env production \
  --file=./backups/ppi_20260727_120000.sql
```

**Jadwal Backup yang Direkomendasikan:**
| Frekuensi | Isi |
|-----------|-----|
| Harian (otomatis via GH Actions) | Backup full database |
| Mingguan (manual) | Download via dashboard + simpan di drive eksternal |
| Bulanan | Backup + archive ke cloud storage |
| Akhir Semester | Backup + simpan sebagai arsip permanen |
| Akhir Tahun | Backup final sebelum kenaikan kelas |

---

## 2. Monitoring

### Health Check Endpoint
```bash
curl https://api.ppi-madrasah.com/health
# Response: { "status": "ok", "timestamp": "..." }
```

### Logs (Cloudflare Workers)
```bash
# Tail logs production
npx wrangler tail --env production

# Filter error logs
npx wrangler tail --env production --status error
```

### Metrics
- **Workers Dashboard:** https://dash.cloudflare.com → Workers & Pages → ppi-api
- **D1 Dashboard:** Cloudflare Dashboard → D1 → ppi-db-prod (kueri, storage, latency)
- **Pages Dashboard:** Cloudflare Pages → ppi-frontend (build status, bandwidth)

---

## 3. Deployment

### Backend
```bash
# Production
cd backend
npx wrangler deploy --env production

# Rollback (jika error)
npx wrangler rollback --env production
# atau deploy versi sebelumnya via Dashboard
```

### Frontend
```bash
cd frontend
flutter build web --release --dart-define=API_BASE_URL=https://api.ppi-madrasah.com
# Upload folder build/web/ ke Cloudflare Pages
```

### Migrasi Database
```bash
# Buat migration baru
npx wrangler d1 migrations create ppi-db-prod nama_migration

# Apply migration
npx wrangler d1 migrations apply ppi-db-prod --env production
```

---

## 4. Error Recovery

### Aplikasi Error 500
1. Cek logs: `npx wrangler tail --env production --status error`
2. Cek binding D1 sudah benar di wrangler.toml
3. Rollback deployment ke versi sebelumnya
4. Jika tidak bisa → nonaktifkan maintenance mode di Cloudflare

### Data Corrupt
1. Hentikan akses user (nonaktifkan sementara)
2. Restore dari backup terakhir
3. Verifikasi integritas data
4. Buka akses kembali

### Lupa Password Admin
Jalankan di database:
```sql
-- Reset password admin ke 'admin123'
UPDATE users SET password_hash = '$2a$10$hhytufYSv9wApOYj1SI4muVIWBQN1L.3txdpxnzB07e7ky/mDz8We'
WHERE username = 'admin';
```

---

## 5. Performance Optimization

### Database
- Pantau ukuran D1 database (max 2GB per database)
- Hapus data lama: log aktivitas > 1 tahun, backup > 3 bulan
- Index sudah dibuat di migration — jangan drop

### Cache
- Gunakan CF Cache untuk asset statis (otomatis di Pages)
- API response bisa di-cache di sisi client (localStorage untuk master data statis)

### Limit
| Resource | Limit | Notes |
|----------|-------|-------|
| D1 read rows/sec | 25000 | Per query row scan |
| D1 write rows/sec | 5000 | Per batch insert |
| Worker CPU | 30ms | Per request |
| Worker memory | 128MB | Total |
| Pages bandwidth | 1GB/hari | Free plan |

---

## 6. Security Checklist

- [ ] Password default sudah diganti semua user
- [ ] JWT_SECRET & JWT_REFRESH_SECRET sudah diset via `wrangler secret put`
- [ ] Cloudflare API Token dengan minimal scope yang diperlukan
- [ ] WAF rule diaktifkan (Block common attacks)
- [ ] Rate limiting diaktifkan
- [ ] HTTPS enforced (otomatis via Cloudflare)
- [ ] Backup database dienkripsi
- [ ] Audit log diaktifkan & dipantau

---

## 7. Annual Cycle

| Bulan | Aktivitas |
|-------|-----------|
| Juni | Backup akhir TA, proses kenaikan/kelulusan, archive data |
| Juli | Setup TA baru, input siswa baru, generate jadwal baru |
| Agustus-Desember | Operasional semester ganjil |
| Desember | Backup akhir semester, rapor semester ganjil |
| Januari | Setup semester genap |
| Januari-Mei | Operasional semester genap |
| Juni | Backup akhir TA, archive, loop lagi |
