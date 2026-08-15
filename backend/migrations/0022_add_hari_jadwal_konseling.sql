-- ============================================
-- MIGRATION 0022: Tambah kolom hari di jadwal_konseling
-- ============================================
-- Fix: form jadwal konseling punya pemilih "Hari", tapi hari
--  tidak pernah dikirim & tidak tersimpan di DB.
--  -> tambah kolom hari (nullable, karena tanggal juga mencatat hari).

ALTER TABLE jadwal_konseling ADD COLUMN hari TEXT;