-- ============================================================
-- MIGRATION v6 — Standarisasi status pengaduan
-- Target: Cloudflare D1 (SQLite) — Production
-- Tanggal: 2026-08-15
--
-- Deskripsi: Kosakata status pengaduan diseragamkan menjadi
--   'baru' -> 'diproses' -> 'selesai'
-- (sebelumnya schema mengizinkan 'ditindaklanjuti' sedangkan
--  backend Guru BK menulis 'diproses').
--
-- CARA PAKAI:
--   1. Buat backup dulu!
--   2. Jalankan via wrangler:
--      wrangler d1 execute ppi-db-prod --remote --file=./src/db/migrations/v6.sql
--   3. atau via Cloudflare Dashboard > D1 > Console
-- ============================================================

-- ─────────────────────────────────────────────
-- 1. Migrasi data lama: 'ditindaklanjuti' -> 'diproses'
-- ─────────────────────────────────────────────
UPDATE pengaduan SET status = 'diproses' WHERE status = 'ditindaklanjuti';

-- ─────────────────────────────────────────────
-- 2. Rebuild tabel pengaduan dengan CHECK baru
--    (SQLite tidak mendukung ALTER ... DROP CONSTRAINT)
-- ─────────────────────────────────────────────
PRAGMA foreign_keys = OFF;

BEGIN TRANSACTION;

CREATE TABLE pengaduan_new (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id        INTEGER NOT NULL REFERENCES siswa(id),
    kategori        TEXT NOT NULL CHECK (kategori IN ('perilaku','kasus')),
    deskripsi       TEXT NOT NULL,
    bukti_url       TEXT,
    dilaporkan_oleh INTEGER NOT NULL REFERENCES guru(id),
    status          TEXT NOT NULL DEFAULT 'baru'
                        CHECK (status IN ('baru','diproses','selesai')),
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

INSERT INTO pengaduan_new (id, siswa_id, kategori, deskripsi, bukti_url, dilaporkan_oleh, status, created_at)
SELECT id, siswa_id, kategori, deskripsi, bukti_url, dilaporkan_oleh, status, created_at FROM pengaduan;

DROP TABLE pengaduan;

ALTER TABLE pengaduan_new RENAME TO pengaduan;

CREATE INDEX IF NOT EXISTS idx_pengaduan_siswa     ON pengaduan(siswa_id);
CREATE INDEX IF NOT EXISTS idx_pengaduan_status    ON pengaduan(status);
CREATE INDEX IF NOT EXISTS idx_pengaduan_pelapor   ON pengaduan(dilaporkan_oleh);

COMMIT;

PRAGMA foreign_keys = ON;

-- ============================================================
-- SELESAI. Verifikasi dengan:
--   SELECT status, COUNT(*) FROM pengaduan GROUP BY status;
--   SELECT sql FROM sqlite_master WHERE name='pengaduan';
-- ============================================================