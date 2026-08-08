-- Migration 0013: Tambah UNIQUE constraint pada tabel nilai
-- UNIQUE: siswa_id + mata_pelajaran_id + semester_id + jenis + diinput_oleh
-- SQLite tidak support ALTER TABLE ADD UNIQUE, jadi harus buat tabel baru

-- 1. Buat tabel baru dengan UNIQUE constraint
CREATE TABLE nilai_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id INTEGER NOT NULL REFERENCES siswa(id),
    mata_pelajaran_id INTEGER NOT NULL REFERENCES mata_pelajaran(id),
    kelas_id INTEGER NOT NULL REFERENCES kelas(id),
    semester_id INTEGER NOT NULL REFERENCES semester(id),
    jenis TEXT NOT NULL CHECK (jenis IN ('harian','tugas','uts','uas','akhir','pts1','pas','pts2','pat')),
    nilai REAL NOT NULL,
    keterangan TEXT,
    diinput_oleh INTEGER NOT NULL REFERENCES guru(id),
    status_validasi TEXT NOT NULL DEFAULT 'draft' CHECK (status_validasi IN ('draft','tervalidasi')),
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(siswa_id, mata_pelajaran_id, semester_id, jenis, diinput_oleh)
);

-- 2. Copy data dari tabel lama
INSERT INTO nilai_new (id, siswa_id, mata_pelajaran_id, kelas_id, semester_id, jenis, nilai, keterangan, diinput_oleh, status_validasi, created_at, updated_at)
SELECT id, siswa_id, mata_pelajaran_id, kelas_id, semester_id, jenis, nilai, keterangan, diinput_oleh, status_validasi, created_at, updated_at
FROM nilai;

-- 3. Drop tabel lama
DROP TABLE nilai;

-- 4. Rename tabel baru
ALTER TABLE nilai_new RENAME TO nilai;

-- 5. Recreate indexes
CREATE INDEX IF NOT EXISTS idx_nilai_siswa ON nilai(siswa_id, semester_id);
CREATE INDEX IF NOT EXISTS idx_nilai_diinput ON nilai(diinput_oleh);
CREATE INDEX IF NOT EXISTS idx_nilai_mapel ON nilai(mata_pelajaran_id);
CREATE INDEX IF NOT EXISTS idx_nilai_semester ON nilai(semester_id);
