-- ============================================================
-- MIGRATION v3 — Tambah kolom, tabel, indexes
-- Target: Cloudflare D1 (SQLite) — Production
-- Tanggal: 2026-08-04
--
-- CARA PAKAI:
--   1. Buat backup dulu!
--   2. Jalankan per baris via Cloudflare Dashboard > D1 > Console
--   3. atau via wrangler: wrangler d1 execute ppi-db --remote --file=./src/db/migrations/v3.sql
-- ============================================================

-- ─────────────────────────────────────────────
-- 1. Tambah kolom ke guru_mata_pelajaran
-- ─────────────────────────────────────────────
ALTER TABLE guru_mata_pelajaran ADD COLUMN hari_aktif TEXT DEFAULT '[]';
ALTER TABLE guru_mata_pelajaran ADD COLUMN jp_max_per_hari INTEGER DEFAULT 8;
ALTER TABLE guru_mata_pelajaran ADD COLUMN jp_max_per_minggu INTEGER DEFAULT 24;

-- ─────────────────────────────────────────────
-- 2. Tambah kolom jam ke absensi_siswa
-- ─────────────────────────────────────────────
ALTER TABLE absensi_siswa ADD COLUMN jam TEXT;

-- ─────────────────────────────────────────────
-- 3. Tambah kolom link_youtube ke materi
-- ─────────────────────────────────────────────
-- Hanya jalankan jika tabel materi sudah ada
-- ALTER TABLE materi ADD COLUMN link_youtube TEXT;

-- ─────────────────────────────────────────────
-- 4. Buat tabel materi (jika belum ada)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS materi (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    guru_id             INTEGER NOT NULL REFERENCES guru(id),
    mata_pelajaran_id   INTEGER NOT NULL REFERENCES mata_pelajaran(id),
    kelas_id            INTEGER NOT NULL REFERENCES kelas(id),
    judul               TEXT NOT NULL,
    deskripsi           TEXT,
    link_url            TEXT NOT NULL,
    link_youtube         TEXT,
    pertemuan           TEXT,
    is_aktif            INTEGER NOT NULL DEFAULT 1,
    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ─────────────────────────────────────────────
-- 5. Tambah indexes untuk performa
-- ─────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_nilai_diinput    ON nilai(diinput_oleh);
CREATE INDEX IF NOT EXISTS idx_absensi_kelas_tgl ON absensi_siswa(kelas_id, tanggal);
CREATE INDEX IF NOT EXISTS idx_jadwal_guru      ON jadwal_pelajaran(guru_id, semester_id);
CREATE INDEX IF NOT EXISTS idx_jadwal_hari      ON jadwal_pelajaran(hari, guru_id);
CREATE INDEX IF NOT EXISTS idx_materi_guru      ON materi(guru_id);
CREATE INDEX IF NOT EXISTS idx_materi_kelas     ON materi(kelas_id, is_aktif);
CREATE INDEX IF NOT EXISTS idx_pengaduan_pelapor ON pengaduan(dilaporkan_oleh);
CREATE INDEX IF NOT EXISTS idx_pengaduan_status  ON pengaduan(status);

-- ============================================================
-- SELESAI. Verifikasi dengan:
--   SELECT * FROM pragma_table_info('guru_mata_pelajaran');
--   SELECT * FROM pragma_table_info('absensi_siswa');
--   SELECT name FROM sqlite_master WHERE type='table' AND name='materi';
-- ============================================================
