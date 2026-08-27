-- Migration 0029: Tabel publikasi nilai per mata pelajaran
-- Admin dapat mengontrol publikasi nilai per-mapel per-semester

CREATE TABLE IF NOT EXISTS publikasi_nilai_mapel (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    semester_id       INTEGER NOT NULL REFERENCES semester(id),
    mata_pelajaran_id INTEGER NOT NULL REFERENCES mata_pelajaran(id),
    is_published      INTEGER NOT NULL DEFAULT 0,
    created_at        TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at        TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(semester_id, mata_pelajaran_id)
);
