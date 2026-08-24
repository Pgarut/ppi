-- ============================================================
-- Add periode column to pembayaran table
-- Format: 'YYYY-MM' (e.g., '2024-07' for Juli 2024)
-- ============================================================

ALTER TABLE pembayaran ADD COLUMN periode TEXT;

-- Index untuk query grouped by jenis + periode
CREATE INDEX idx_pembayaran_jenis_periode ON pembayaran(jenis_pembayaran_id, periode);
CREATE INDEX idx_pembayaran_santri_jenis_periode ON pembayaran(santri_id, jenis_pembayaran_id, periode);

-- Update existing records: set periode from tanggal_bayar or created_at
UPDATE pembayaran 
SET periode = substr(coalesce(tanggal_bayar, created_at), 1, 7)
WHERE periode IS NULL;