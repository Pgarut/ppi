-- ============================================
-- MIGRATION 0020: Perbaiki FK yang menunjuk tabel lama
-- ============================================
-- Fix:
--  Migrasi 0017 me-rename dauroh_program -> dauroh_program_old lalu drop.
--  Akibatnya SQLite menulis ulang FK di tabel lain yang mereferensikan
--  dauroh_program menjadi dauroh_program_old, sehingga INSERT ke
--  dauroh_jadwal / dauroh_program_santri gagal:
--      no such table: main.dauroh_program_old: SQLITE_ERROR
--
--  Solusi: drop & recreate kedua tabel (kosong) dengan FK yang benar
--  menunjuk ke dauroh_program.

PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS dauroh_program_santri;
DROP TABLE IF EXISTS dauroh_jadwal;

CREATE TABLE dauroh_jadwal (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    program_id      INTEGER NOT NULL REFERENCES dauroh_program(id),
    musyrifah_1_id  INTEGER NOT NULL REFERENCES dauroh_musyrifah(id),
    musyrifah_2_id  INTEGER REFERENCES dauroh_musyrifah(id),
    jenjang         TEXT,
    hari            TEXT NOT NULL CHECK (hari IN ('Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu')),
    jam_mulai       TEXT NOT NULL,
    jam_selesai     TEXT NOT NULL,
    is_aktif        INTEGER NOT NULL DEFAULT 1,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE dauroh_program_santri (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    program_id  INTEGER NOT NULL REFERENCES dauroh_program(id) ON DELETE CASCADE,
    santri_id   INTEGER NOT NULL REFERENCES siswa(id),
    UNIQUE(program_id, santri_id)
);

PRAGMA foreign_keys = ON;