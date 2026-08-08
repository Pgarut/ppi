-- Migration 0015: Tambah kolom data orang tua di tabel siswa
-- nama_ayah, nama_ibu, pekerjaan_ayah, pekerjaan_ibu, whatsapp

ALTER TABLE siswa ADD COLUMN nama_ayah TEXT;
ALTER TABLE siswa ADD COLUMN nama_ibu TEXT;
ALTER TABLE siswa ADD COLUMN pekerjaan_ayah TEXT;
ALTER TABLE siswa ADD COLUMN pekerjaan_ibu TEXT;
ALTER TABLE siswa ADD COLUMN whatsapp TEXT;
