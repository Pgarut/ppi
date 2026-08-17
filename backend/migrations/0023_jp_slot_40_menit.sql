-- ============================================
-- MIGRATION 0023: JP Slot 40 menit + istirahat 20 menit
-- ============================================
-- Fix: jadwal lama memakai slot 45 menit dan tidak ada slot istirahat
--  yang bisa ditempati kegiatan 'Istirahat RG' / 'Istirahat UG'.
-- Skema baru (12 slot):
--   JP1-JP3   : pelajaran 07:00-09:00 (40 mnt)
--   JP4       : istirahat RG 09:00-09:20 (20 mnt)
--   JP5       : pelajaran 09:20-09:40 (jembatan, kompromi flat slot)
--   JP6       : istirahat UG 09:40-10:00 (20 mnt)
--   JP7-JP9   : pelajaran 10:00-12:00
--   JP10      : istirahat/shalat 12:00-12:40
--   JP11-JP12 : pelajaran 12:40-14:00
-- Tambah kolom tipe ('pelajaran'/'istirahat') agar auto-generate
--  tidak mengisi jam pelajaran ke slot istirahat.

-- Jaga agar migration tetap jalan untuk DB baru (chain 0001..0023)
CREATE TABLE IF NOT EXISTS jp_slot (
    kode     TEXT PRIMARY KEY,
    mulai    TEXT NOT NULL,
    selesai  TEXT NOT NULL,
    urutan   INTEGER NOT NULL
);

ALTER TABLE jp_slot ADD COLUMN tipe TEXT NOT NULL DEFAULT 'pelajaran';

INSERT OR REPLACE INTO jp_slot (kode, mulai, selesai, urutan, tipe) VALUES
    ('JP1',  '07:00', '07:40', 1,  'pelajaran'),
    ('JP2',  '07:40', '08:20', 2,  'pelajaran'),
    ('JP3',  '08:20', '09:00', 3,  'pelajaran'),
    ('JP4',  '09:00', '09:20', 4,  'istirahat'),
    ('JP5',  '09:20', '09:40', 5,  'pelajaran'),
    ('JP6',  '09:40', '10:00', 6,  'istirahat'),
    ('JP7',  '10:00', '10:40', 7,  'pelajaran'),
    ('JP8',  '10:40', '11:20', 8,  'pelajaran'),
    ('JP9',  '11:20', '12:00', 9,  'pelajaran'),
    ('JP10', '12:00', '12:40', 10, 'istirahat'),
    ('JP11', '12:40', '13:20', 11, 'pelajaran'),
    ('JP12', '13:20', '14:00', 12, 'pelajaran');

-- Sinkronkan jadwal lama (draft) ke waktu slot baru agar tetap tampil di grid.
-- JP1 (07:00-07:40) tidak berubah. Old JP4 (09:30-10:15) dialihkan ke istirahat
--  bila entri istirahat, atau ke slot jembatan JP5 bila pelajaran.
UPDATE jadwal_pelajaran SET jam_mulai = '07:40', jam_selesai = '08:20'
  WHERE jam_mulai = '07:45' AND jam_selesai = '08:30';
UPDATE jadwal_pelajaran SET jam_mulai = '08:20', jam_selesai = '09:00'
  WHERE jam_mulai = '08:30' AND jam_selesai = '09:15';
UPDATE jadwal_pelajaran SET jam_mulai = '09:00', jam_selesai = '09:20'
  WHERE jam_mulai = '09:30' AND jam_selesai = '10:15' AND is_istirahat = 1;
UPDATE jadwal_pelajaran SET jam_mulai = '09:20', jam_selesai = '09:40'
  WHERE jam_mulai = '09:30' AND jam_selesai = '10:15' AND is_istirahat != 1;
UPDATE jadwal_pelajaran SET jam_mulai = '10:00', jam_selesai = '10:40'
  WHERE jam_mulai = '10:15' AND jam_selesai = '11:00';
UPDATE jadwal_pelajaran SET jam_mulai = '10:40', jam_selesai = '11:20'
  WHERE jam_mulai = '11:00' AND jam_selesai = '11:45';
UPDATE jadwal_pelajaran SET jam_mulai = '12:40', jam_selesai = '13:20'
  WHERE jam_mulai = '12:30' AND jam_selesai = '13:15';
UPDATE jadwal_pelajaran SET jam_mulai = '13:20', jam_selesai = '14:00'
  WHERE jam_mulai = '13:15' AND jam_selesai = '14:00';