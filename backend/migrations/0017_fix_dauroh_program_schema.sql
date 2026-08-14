-- ============================================
-- MIGRATION 0017: Perbaiki skema dauroh_program
-- ============================================
-- Fix:
--  1. CHECK jenis_dauroh hanya mengizinkan 'hafalan'/'bacaan'
--     padahal aplikasi & schema.sql memakai 'murojaah'/'tahfidz'
--     -> INSERT program selalu gagal (CHECK constraint violation / 500)
--  2. Pastikan kolom skema_penilaian, max_bidang1/2/3, label_bidang1/2/3,
--     konfigurasi_nilai tersedia (jika migration 0016 belum diterapkan).
--
-- Aman dijalankan baik DB sudah pernah menjalankan 0016 maupun belum.

PRAGMA foreign_keys = OFF;

ALTER TABLE dauroh_program RENAME TO dauroh_program_old;

CREATE TABLE dauroh_program (
    id                 INTEGER PRIMARY KEY AUTOINCREMENT,
    nama_program       TEXT NOT NULL,
    jenis_program      TEXT NOT NULL CHECK (jenis_program IN ('khusus', 'kelas')),
    jenis_dauroh       TEXT NOT NULL CHECK (jenis_dauroh IN ('murojaah', 'tahfidz')),
    skema_penilaian    TEXT DEFAULT 'murojaah_tahfidz',
    keterangan         TEXT,
    tahun_ajaran_id    INTEGER REFERENCES tahun_ajaran(id),
    is_aktif           INTEGER NOT NULL DEFAULT 1,
    max_bidang1        INTEGER DEFAULT 40,
    max_bidang2        INTEGER DEFAULT 30,
    max_bidang3        INTEGER DEFAULT 30,
    label_bidang1      TEXT DEFAULT 'Kelancaran Hafalan',
    label_bidang2      TEXT DEFAULT 'Tajwid',
    label_bidang3      TEXT DEFAULT 'Fashohah dan Adab',
    konfigurasi_nilai  TEXT,
    created_at         TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at         TEXT NOT NULL DEFAULT (datetime('now'))
);

INSERT INTO dauroh_program (
    id, nama_program, jenis_program, jenis_dauroh,
    keterangan, tahun_ajaran_id, is_aktif, created_at, updated_at
)
SELECT
    id,
    nama_program,
    jenis_program,
    CASE jenis_dauroh
        WHEN 'hafalan' THEN 'tahfidz'
        WHEN 'bacaan'  THEN 'murojaah'
        ELSE jenis_dauroh
    END,
    keterangan,
    tahun_ajaran_id,
    is_aktif,
    created_at,
    updated_at
FROM dauroh_program_old;

DROP TABLE dauroh_program_old;

PRAGMA foreign_keys = ON;
