-- ============================================================
-- MIGRATION v11 — tabel kegiatan_tetap (dapat dikelola via UI)
-- Target: Cloudflare D1 (SQLite) — Production
-- Tanggal: 2026-08-17
--
-- Deskripsi:
--   Sebelumnya daftar "KEGIATAN TETAP" di-hardcode di kode backend
--   (KEGIATAN_TETAP pada penjadwalan.ts) sehingga Wakil Kurikulum
--   tidak bisa menambah/mengubah kegiatan (mis. Shalat Dzuhur Berjamaah)
--   tanpa deploy ulang. Migration ini membuat tabel kegiatan_tetap
--   + seed data default agar bisa dikelola via UI.
--
-- CARA PAKAI:
--   1. Backup dulu!
--   2. Jalankan via wrangler:
--      wrangler d1 execute ppi-db-prod --remote --file=./src/db/migrations/v11.sql
--      (atau ppi-db untuk lokal)
-- ============================================================

CREATE TABLE IF NOT EXISTS kegiatan_tetap (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    nama    TEXT NOT NULL UNIQUE,
    tipe    TEXT NOT NULL DEFAULT 'kegiatan' CHECK (tipe IN ('kegiatan','istirahat')),
    urutan  INTEGER NOT NULL DEFAULT 0
);

-- Seed default (INSERT OR IGNORE agar tidak menimpa jika sudah ada)
INSERT OR IGNORE INTO kegiatan_tetap (nama, tipe, urutan) VALUES
    ('Istirahat RG',          'istirahat', 1),
    ('Istirahat UG',          'istirahat', 2),
    ('Tahfidz & Tahsin',      'kegiatan',  3),
    ('Murojaah',              'kegiatan',  4),
    ("Ba'at",                 'kegiatan',  5),
    ('Shalat Dzuhur Berjamaah','kegiatan', 6);

-- ============================================================
-- SELESAI. Verifikasi dengan:
--   SELECT * FROM kegiatan_tetap ORDER BY urutan;
-- ============================================================