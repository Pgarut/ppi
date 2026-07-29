ALTER TABLE nilai RENAME TO nilai_old;

CREATE TABLE nilai (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    siswa_id          INTEGER NOT NULL REFERENCES siswa(id),
    mata_pelajaran_id INTEGER NOT NULL REFERENCES mata_pelajaran(id),
    kelas_id          INTEGER NOT NULL REFERENCES kelas(id),
    semester_id       INTEGER NOT NULL REFERENCES semester(id),
    jenis             TEXT NOT NULL,
    nilai             REAL NOT NULL,
    keterangan        TEXT,
    diinput_oleh      INTEGER NOT NULL REFERENCES guru(id),
    status_validasi   TEXT NOT NULL DEFAULT 'draft' CHECK (status_validasi IN ('draft','tervalidasi')),
    created_at        TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at        TEXT NOT NULL DEFAULT (datetime('now'))
);

INSERT INTO nilai (id, siswa_id, mata_pelajaran_id, kelas_id, semester_id, jenis, nilai, keterangan, diinput_oleh, status_validasi, created_at, updated_at)
SELECT id, siswa_id, mata_pelajaran_id, kelas_id, semester_id,
  CASE
    WHEN jenis = 'uts' THEN 'pts1'
    WHEN jenis = 'uas' THEN 'pas'
    WHEN jenis = 'tugas' THEN 'harian'
    WHEN jenis = 'akhir' THEN 'harian'
    ELSE jenis
  END,
  nilai, keterangan, diinput_oleh, status_validasi, created_at, updated_at
FROM nilai_old;

DROP TABLE nilai_old;

CREATE INDEX IF NOT EXISTS idx_nilai_siswa ON nilai(siswa_id, semester_id);
CREATE INDEX IF NOT EXISTS idx_nilai_siswa_id ON nilai(siswa_id);
CREATE INDEX IF NOT EXISTS idx_nilai_kelas_mapel ON nilai(kelas_id, mata_pelajaran_id);
