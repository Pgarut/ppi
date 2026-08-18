-- ============================================================
-- MIGRATION 0024: Materi berbasis TINGKAT (bukan per kelas)
-- ============================================================
-- Perubahan model:
--   Sebelum : materi terikat ke 1 kelas spesifik (kelas_id NOT NULL)
--   Sesudah : materi terikat ke 1 TINGKAT (tingkat_id), berlaku untuk
--             semua kelas dalam tingkat tsb (X, XI, XII).
--
-- 1. kelas_id dijadikan nullable (materi baru menyimpan tingkat_id).
-- 2. tingkat_id ditambahkan, di-backfill dari kelas_id yang sudah ada.
-- 3. Index baru untuk filter santri per tingkat.
--
-- Compatible dengan production schema (no created_at/updated_at di
-- sebagian tabel? materi tetap memakai created_at/updated_at).

PRAGMA foreign_keys = OFF;
PRAGMA defer_foreign_keys = ON;

-- 1. Buat tabel baru
CREATE TABLE materi_new (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    guru_id             INTEGER NOT NULL REFERENCES guru(id),
    mata_pelajaran_id   INTEGER NOT NULL REFERENCES mata_pelajaran(id),
    kelas_id            INTEGER REFERENCES kelas(id),
    tingkat_id          INTEGER REFERENCES tingkat(id),
    judul               TEXT NOT NULL,
    deskripsi           TEXT,
    link_url            TEXT NOT NULL,
    link_youtube        TEXT,
    pertemuan           TEXT,
    is_aktif            INTEGER NOT NULL DEFAULT 1,
    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 2. Salin data lama, isi tingkat_id dari kelas
INSERT INTO materi_new (id, guru_id, mata_pelajaran_id, kelas_id, tingkat_id,
                        judul, deskripsi, link_url, link_youtube, pertemuan,
                        is_aktif, created_at, updated_at)
SELECT m.id, m.guru_id, m.mata_pelajaran_id, m.kelas_id, k.tingkat_id,
       m.judul, m.deskripsi, m.link_url, m.link_youtube, m.pertemuan,
       m.is_aktif, m.created_at, m.updated_at
FROM materi m
LEFT JOIN kelas k ON m.kelas_id = k.id;

-- 3. Ganti tabel lama
DROP TABLE IF EXISTS materi;
ALTER TABLE materi_new RENAME TO materi;

-- 4. Recreate indexes + index tingkat
CREATE INDEX IF NOT EXISTS idx_materi_guru          ON materi(guru_id);
CREATE INDEX IF NOT EXISTS idx_materi_kelas         ON materi(kelas_id, is_aktif);
CREATE INDEX IF NOT EXISTS idx_materi_tingkat       ON materi(tingkat_id);

PRAGMA defer_foreign_keys = OFF;
PRAGMA foreign_keys = ON;
