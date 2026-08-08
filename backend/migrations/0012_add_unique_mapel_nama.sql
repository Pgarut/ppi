-- Migration 0012: Tambah UNIQUE constraint pada mata_pelajaran.nama
-- SQLite tidak support ALTER TABLE ADD UNIQUE, jadi harus buat tabel baru

-- 1. Buat tabel baru dengan UNIQUE pada nama
CREATE TABLE mata_pelajaran_new (
    id   INTEGER PRIMARY KEY AUTOINCREMENT,
    nama TEXT NOT NULL UNIQUE,
    kode TEXT UNIQUE
);

-- 2. Copy data dari tabel lama
INSERT INTO mata_pelajaran_new (id, nama, kode) SELECT id, nama, kode FROM mata_pelajaran;

-- 3. Drop tabel lama
DROP TABLE mata_pelajaran;

-- 4. Rename tabel baru
ALTER TABLE mata_pelajaran_new RENAME TO mata_pelajaran;

-- 5. Recreate indexes
CREATE INDEX IF NOT EXISTS idx_mata_pelajaran_nama ON mata_pelajaran(nama);
