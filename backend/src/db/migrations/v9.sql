-- ============================================================
-- MIGRATION v9 — tabel jp_slot (jam pelajaran yang dapat diatur manual)
-- Target: Cloudflare D1 (SQLite) — Production
-- Tanggal: 2026-08-16
--
-- Deskripsi:
--   Sebelumnya waktu JP1–JP8 di-hardcode di kode backend sehingga
--   kolom "Waktu" pada tabel Jadwal tidak bisa diubah manual dan
--   bisa tidak konsisten dengan jam_mulai/jam_selesai entri jadwal.
--   Migration ini menambahkan tabel jp_slot + data default.
--
-- CARA PAKAI:
--   1. Backup dulu!
--   2. Jalankan via wrangler:
--      wrangler d1 execute ppi-db-prod --remote --file=./src/db/migrations/v9.sql
--      (atau ppi-db untuk lokal)
-- ============================================================

CREATE TABLE IF NOT EXISTS jp_slot (
    kode     TEXT PRIMARY KEY,          -- 'JP1'..'JP8'
    mulai    TEXT NOT NULL,             -- format 'HH:MM'
    selesai  TEXT NOT NULL,             -- format 'HH:MM'
    urutan   INTEGER NOT NULL
);

-- Seed default (INSERT OR IGNORE agar tidak menimpa jika sudah ada)
INSERT OR IGNORE INTO jp_slot (kode, mulai, selesai, urutan) VALUES
    ('JP1', '07:00', '07:45', 1),
    ('JP2', '07:45', '08:30', 2),
    ('JP3', '08:30', '09:15', 3),
    ('JP4', '09:30', '10:15', 4),
    ('JP5', '10:15', '11:00', 5),
    ('JP6', '11:00', '11:45', 6),
    ('JP7', '12:30', '13:15', 7),
    ('JP8', '13:15', '14:00', 8);

-- ============================================================
-- SELESAI. Verifikasi dengan:
--   SELECT * FROM jp_slot ORDER BY urutan;
-- ============================================================