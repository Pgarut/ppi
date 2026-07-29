-- Migration 0004: Perluas guru_mata_pelajaran untuk Kesiapan Mengajar
-- Target: Cloudflare D1 (SQLite)
-- Tambah kolom untuk konfigurasi kesiapan mengajar guru

ALTER TABLE guru_mata_pelajaran ADD COLUMN hari_aktif TEXT DEFAULT '[]';
ALTER TABLE guru_mata_pelajaran ADD COLUMN jp_max_per_hari INTEGER DEFAULT 8;
ALTER TABLE guru_mata_pelajaran ADD COLUMN jp_max_per_minggu INTEGER DEFAULT 24;
