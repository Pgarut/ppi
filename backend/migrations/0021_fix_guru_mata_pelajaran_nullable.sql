-- ============================================
-- MIGRATION 0021: Fix guru_mata_pelajaran untuk Kesiapan Mengajar
-- ============================================
-- Fix:
--  Tabel guru_mata_pelajaran awalnya dibuat untuk assignment
--  "guru mengajar mapel di kelas" (mata_pelajaran_id & kelas_id NOT NULL).
--  Namun fitur Kesiapan Mengajar menyimpan data per guru + semester
--  (hari_aktif, jp_max) dengan mapel/kelas NULL, sehingga INSERT gagal:
--      NOT NULL constraint failed: guru_mata_pelajaran.mata_pelajaran_id
--  -> Simpan Kesiapan Mengajar selalu error 500.
--
--  Solusi:
--  1. mata_pelajaran_id & kelas_id dijadikan nullable (baris kesiapan
--     diizinkan tanpa mapel/kelas; query JOIN assignment otomatis
--     mengabaikan baris NULL).
--  2. Partial unique index: 1 baris kesiapan per (guru_id, semester_id)
--     hanya untuk baris dengan mapel/kelas NULL, tanpa mengganggu
--     unique assignment yang sudah ada.

PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS guru_mata_pelajaran;

CREATE TABLE guru_mata_pelajaran (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    guru_id             INTEGER NOT NULL REFERENCES guru(id),
    mata_pelajaran_id   INTEGER REFERENCES mata_pelajaran(id),
    kelas_id            INTEGER REFERENCES kelas(id),
    semester_id         INTEGER NOT NULL REFERENCES semester(id),
    hari_aktif          TEXT DEFAULT '[]',          -- JSON array hari aktif (mis. ["Senin","Selasa"])
    jp_max_per_hari     INTEGER DEFAULT 8,          -- batas jam pelajaran per hari
    jp_max_per_minggu   INTEGER DEFAULT 24,         -- batas jam pelajaran per minggu
    UNIQUE (guru_id, mata_pelajaran_id, kelas_id, semester_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_guru_mata_pelajaran_kesiapan
ON guru_mata_pelajaran (guru_id, semester_id)
WHERE mata_pelajaran_id IS NULL AND kelas_id IS NULL;

PRAGMA foreign_keys = ON;