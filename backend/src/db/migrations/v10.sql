-- ============================================================
-- MIGRATION v10 — perbaiki CHECK constraint hari pada jadwal_pelajaran
-- Target: Cloudflare D1 (SQLite) — Production
-- Tanggal: 2026-08-16
--
-- Deskripsi:
--   CHECK constraint hari sebelumnya hanya mengizinkan
--   ('Senin','Selasa','Rabu','Kamis','Jumat','Sabtu') sehingga
--   penyimpanan jadwal pada hari 'Minggu' selalu ditolak oleh
--   backend (aplikasi memakai hari Sabtu-Minggu-Senin-Selasa-Rabu-Kamis).
--   Migration ini membuat ulang tabel dengan CHECK yang benar.
--
-- CARA PAKAI:
--   1. Backup dulu!
--   2. Jalankan via wrangler:
--      wrangler d1 execute ppi-db-prod --remote --file=./src/db/migrations/v10.sql
--      (atau ppi-db untuk lokal)
-- ============================================================

PRAGMA foreign_keys = OFF;

CREATE TABLE jadwal_pelajaran_new (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    kelas_id            INTEGER NOT NULL REFERENCES kelas(id),
    mata_pelajaran_id   INTEGER REFERENCES mata_pelajaran(id),
    guru_id             INTEGER REFERENCES guru(id),
    ruangan_id          INTEGER REFERENCES ruangan(id),
    nama_kegiatan       TEXT,
    is_istirahat        INTEGER NOT NULL DEFAULT 0,
    hari                TEXT NOT NULL CHECK (hari IN (
                            'Sabtu','Minggu','Senin','Selasa','Rabu','Kamis'
                        )),
    jam_mulai           TEXT NOT NULL,   -- format 'HH:MM'
    jam_selesai         TEXT NOT NULL,
    semester_id         INTEGER NOT NULL REFERENCES semester(id),
    status_validasi     TEXT NOT NULL DEFAULT 'draft'
                            CHECK (status_validasi IN ('draft','tervalidasi'))
);

INSERT INTO jadwal_pelajaran_new (id, kelas_id, mata_pelajaran_id, guru_id, ruangan_id, nama_kegiatan, is_istirahat, hari, jam_mulai, jam_selesai, semester_id, status_validasi)
    SELECT id, kelas_id, mata_pelajaran_id, guru_id, ruangan_id, nama_kegiatan, is_istirahat, hari, jam_mulai, jam_selesai, semester_id, status_validasi
    FROM jadwal_pelajaran;

DROP TABLE jadwal_pelajaran;

ALTER TABLE jadwal_pelajaran_new RENAME TO jadwal_pelajaran;

CREATE INDEX IF NOT EXISTS idx_jadwal_kelas ON jadwal_pelajaran(kelas_id, semester_id);
CREATE INDEX IF NOT EXISTS idx_jadwal_guru  ON jadwal_pelajaran(guru_id, semester_id);
CREATE INDEX IF NOT EXISTS idx_jadwal_hari  ON jadwal_pelajaran(hari, guru_id);

PRAGMA foreign_keys = ON;

-- ============================================================
-- SELESAI. Verifikasi dengan:
--   SELECT sql FROM sqlite_master WHERE name='jadwal_pelajaran';
-- ============================================================