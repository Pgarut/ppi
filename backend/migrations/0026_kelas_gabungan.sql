-- ============================================================
-- MIGRATION 0026 — kelas gabungan (combined classes)
-- Salinan logika v12.sql (src/db/migrations/v12.sql) agar
-- diterapkan otomatis oleh CI: wrangler d1 migrations apply
-- Target: Cloudflare D1 (SQLite) — Production
--
-- Deskripsi:
--   Mendukung kelas yang digabung (mis. X-A + X-B diajar bersama
--   oleh satu guru untuk satu mata pelajaran). Sebelumnya setiap
--   kelas dijadwalkan terpisah sehingga jadwal gabungan selalu
--   dianggap BENTROK oleh sistem. Migration ini menambahkan:
--     1. kelas_gabungan            → kelompok kelas gabungan (per semester)
--     2. kelas_gabungan_anggota    → anggota kelas dari tiap kelompok
--     3. kolom gabungan_id         → penanda entri jadwal sebagai
--                                     bagian dari sesi gabungan
--   Data jadwal lama TIDAK diubah (gabungan_id = NULL berarti jadwal
--   normal, tetap berperilaku seperti sebelumnya).
--
-- Verifikasi setelah apply:
--   SELECT name FROM sqlite_master WHERE name IN ('kelas_gabungan','kelas_gabungan_anggota');
--   PRAGMA table_info(jadwal_pelajaran);   -- harus ada kolom gabungan_id
--   SELECT COUNT(*) FROM jadwal_pelajaran; -- jumlah data lama tetap sama
-- ============================================================

-- Kelompok kelas gabungan
CREATE TABLE IF NOT EXISTS kelas_gabungan (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    nama        TEXT NOT NULL,              -- contoh: 'Gabungan X A+B'
    semester_id INTEGER NOT NULL REFERENCES semester(id),
    tingkat_id  INTEGER REFERENCES tingkat(id),
    created_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Anggota kelas dari tiap kelompok
CREATE TABLE IF NOT EXISTS kelas_gabungan_anggota (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    gabungan_id INTEGER NOT NULL REFERENCES kelas_gabungan(id) ON DELETE CASCADE,
    kelas_id    INTEGER NOT NULL REFERENCES kelas(id),
    UNIQUE (gabungan_id, kelas_id)
);

-- Penanda entri jadwal sebagai bagian dari sesi gabungan (NULL = jadwal normal)
ALTER TABLE jadwal_pelajaran ADD COLUMN gabungan_id INTEGER REFERENCES kelas_gabungan(id);

CREATE INDEX IF NOT EXISTS idx_kelas_gabungan_anggota ON kelas_gabungan_anggota(gabungan_id);
CREATE INDEX IF NOT EXISTS idx_jadwal_gabungan ON jadwal_pelajaran(gabungan_id);
