-- Migration 0002: Add mapel_kelas pivot table for many-to-many subject-class association
-- Target: Cloudflare D1 (SQLite)
-- The old mata_pelajaran.kelas_id column (from migration v1) is left in place.

CREATE TABLE IF NOT EXISTS mapel_kelas (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    mata_pelajaran_id INTEGER NOT NULL REFERENCES mata_pelajaran(id) ON DELETE CASCADE,
    kelas_id          INTEGER NOT NULL REFERENCES kelas(id) ON DELETE CASCADE,
    UNIQUE(mata_pelajaran_id, kelas_id)
);

CREATE TABLE IF NOT EXISTS guru_mapel (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    guru_id           INTEGER NOT NULL REFERENCES guru(id) ON DELETE CASCADE,
    mata_pelajaran_id INTEGER NOT NULL REFERENCES mata_pelajaran(id) ON DELETE CASCADE,
    UNIQUE(guru_id, mata_pelajaran_id)
);

CREATE TABLE IF NOT EXISTS guru_kelas (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    guru_id  INTEGER NOT NULL REFERENCES guru(id) ON DELETE CASCADE,
    kelas_id INTEGER NOT NULL REFERENCES kelas(id) ON DELETE CASCADE,
    UNIQUE(guru_id, kelas_id)
);
