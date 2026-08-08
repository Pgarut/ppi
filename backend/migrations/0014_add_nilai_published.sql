-- Migration 0014: Tambah kolom nilai_published di tabel semester
-- ON/OFF publikasi nilai ke siswa (per semester)

ALTER TABLE semester ADD COLUMN nilai_published INTEGER NOT NULL DEFAULT 0;
