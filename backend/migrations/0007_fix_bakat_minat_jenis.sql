-- Migration 0007: Fix bakat_minat.jenis CHECK constraint
-- Target: Cloudflare D1 (SQLite)
--
-- SQLite tidak mendukung ALTER COLUMN, jadi kita rebuild tabel.
-- Perubahan: jenis CHECK dari ('akademik','olahraga','seni','keagamaan','organisasi','lainnya')
--            menjadi ('bakat','minat')

-- 1. Pindahkan data ke tabel temporary
ALTER TABLE bakat_minat RENAME TO bakat_minat_old;

-- 2. Buat tabel baru dengan constraint yang benar
CREATE TABLE IF NOT EXISTS bakat_minat (
    id                      INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id                INTEGER NOT NULL REFERENCES siswa(id),
    jenis                   TEXT NOT NULL CHECK (jenis IN ('bakat','minat')),
    deskripsi               TEXT,
    catatan_pengembangan    TEXT,
    guru_bk_id              INTEGER NOT NULL REFERENCES guru(id),
    created_at              TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at              TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 3. Salin data dari tabel lama (kolom yang sama)
INSERT INTO bakat_minat (id, siswa_id, jenis, deskripsi, catatan_pengembangan, guru_bk_id, created_at, updated_at)
SELECT id, siswa_id, jenis, deskripsi, catatan_pengembangan, guru_bk_id, created_at, updated_at
FROM bakat_minat_old;

-- 4. Hapus tabel lama
DROP TABLE IF EXISTS bakat_minat_old;

-- 5. Update seed data jika ada
-- (Tidak ada seed data bakat_minat di seed.sql, jadi tidak perlu update)
