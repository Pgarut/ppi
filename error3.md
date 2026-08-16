backend/src/db/migrations/v6.sql

@ -23,11 +23,14 @@ UPDATE pengaduan SET status = 'diproses' WHERE status = 'ditindaklanjuti';
-- ─────────────────────────────────────────────
-- 2. Rebuild tabel pengaduan dengan CHECK baru
--    (SQLite tidak mendukung ALTER ... DROP CONSTRAINT)
--
--    CATATAN: wrangler d1 execute MENOLAK pernyataan BEGIN
--    TRANSACTION / COMMIT. Karena itu blok transaksi sengaja
--    dihilangkan; setiap pernyataan dieksekusi terpisah oleh
--    wrangler. Pastikan backup DB sebelum menjalankan.
-- ─────────────────────────────────────────────
PRAGMA foreign_keys = OFF;

BEGIN TRANSACTION;

CREATE TABLE pengaduan_new (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id        INTEGER NOT NULL REFERENCES siswa(id),
@@ -51,8 +54,6 @@ CREATE INDEX IF NOT EXISTS idx_pengaduan_siswa     ON pengaduan(siswa_id);
CREATE INDEX IF NOT EXISTS idx_pengaduan_status    ON pengaduan(status);
CREATE INDEX IF NOT EXISTS idx_pengaduan_pelapor   ON pengaduan(dilaporkan_oleh);

COMMIT;

PRAGMA foreign_keys = ON;
