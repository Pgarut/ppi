-- ============================================================
-- MIGRATION v7 — Tabel catatan_wali_kelas
-- Target: Cloudflare D1 (SQLite) — Production
-- Tanggal: 2026-08-15
--
-- Deskripsi: Menyediakan tempat penyimpanan catatan wali kelas
-- per (siswa, semester). Sebelumnya catatan hanya di-UPDATE ke
-- tabel nilai_rapor yang tidak pernah di-INSERT sehingga fitur
-- tidak berfungsi (0 baris terpengaruh).
--
-- CARA PAKAI:
--   1. Buat backup dulu!
--   2. Jalankan via wrangler:
--      wrangler d1 execute ppi-db-prod --remote --file=./src/db/migrations/v7.sql
--   3. atau via Cloudflare Dashboard > D1 > Console
-- ============================================================

CREATE TABLE IF NOT EXISTS catatan_wali_kelas (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id    INTEGER NOT NULL REFERENCES siswa(id) ON DELETE CASCADE,
    semester_id INTEGER NOT NULL REFERENCES semester(id),
    catatan     TEXT NOT NULL DEFAULT '',
    updated_at  TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(siswa_id, semester_id)
);

CREATE INDEX IF NOT EXISTS idx_catatan_wali_siswa    ON catatan_wali_kelas(siswa_id);
CREATE INDEX IF NOT EXISTS idx_catatan_wali_semester ON catatan_wali_kelas(semester_id);

-- ============================================================
-- SELESAI. Verifikasi dengan:
--   SELECT name FROM sqlite_master WHERE name='catatan_wali_kelas';
-- ============================================================