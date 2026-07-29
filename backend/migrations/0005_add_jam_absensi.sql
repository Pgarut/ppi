ALTER TABLE absensi_siswa ADD COLUMN jam TEXT;
CREATE INDEX IF NOT EXISTS idx_absensi_siswa_sesi ON absensi_siswa(kelas_id, mata_pelajaran_id, tanggal, jam);
