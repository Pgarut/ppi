-- ============================================
-- MIGRATION 0018: Absensi masuk/keluar musyrifah
-- ============================================
-- Alur baru: scan pertama = absensi MASUK, scan kedua = absensi KELUAR.
-- QR tetap dicetak sekali (token statis).

ALTER TABLE dauroh_absensi_musyrifah ADD COLUMN waktu_masuk TEXT;
ALTER TABLE dauroh_absensi_musyrifah ADD COLUMN waktu_keluar TEXT;

-- Backfill: data lama (1 scan/hari) dianggap sebagai waktu masuk
UPDATE dauroh_absensi_musyrifah SET waktu_masuk = waktu_scan WHERE waktu_masuk IS NULL;