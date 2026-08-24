-- ============================================
-- MIGRATION 0025: JP Slot 40 menit berurutan (tanpa istirahat)
-- ============================================
-- Permintaan Wakil Kurikulum: semua JP dianggap 40 menit, berurutan
-- tanpa slot istirahat di tabel penjadwalan.
--   JP1  07:00-07:40
--   JP2  07:40-08:20
--   JP3  08:20-09:00
--   JP4  09:00-09:40
--   JP5  09:40-10:20
--   JP6  10:20-11:00
--   JP7  11:00-11:40
--   JP8  11:40-12:20
--   JP9  12:20-13:00
--   JP10 13:00-13:40
--   JP11 13:40-14:20
--   JP12 14:20-15:00

-- Jaga agar migration tetap jalan untuk DB baru (chain 0001..0025)
CREATE TABLE IF NOT EXISTS jp_slot (
    kode     TEXT PRIMARY KEY,
    mulai    TEXT NOT NULL,
    selesai  TEXT NOT NULL,
    urutan   INTEGER NOT NULL
);

INSERT OR REPLACE INTO jp_slot (kode, mulai, selesai, urutan, tipe) VALUES
    ('JP1',  '07:00', '07:40', 1,  'pelajaran'),
    ('JP2',  '07:40', '08:20', 2,  'pelajaran'),
    ('JP3',  '08:20', '09:00', 3,  'pelajaran'),
    ('JP4',  '09:00', '09:40', 4,  'pelajaran'),
    ('JP5',  '09:40', '10:20', 5,  'pelajaran'),
    ('JP6',  '10:20', '11:00', 6,  'pelajaran'),
    ('JP7',  '11:00', '11:40', 7,  'pelajaran'),
    ('JP8',  '11:40', '12:20', 8,  'pelajaran'),
    ('JP9',  '12:20', '13:00', 9,  'pelajaran'),
    ('JP10', '13:00', '13:40', 10, 'pelajaran'),
    ('JP11', '13:40', '14:20', 11, 'pelajaran'),
    ('JP12', '14:20', '15:00', 12, 'pelajaran');

-- Sinkronkan jadwal lama (draft) ke waktu slot baru agar tetap tampil di grid.
-- Mapping dari slot lama 45 menit & slot 0023 (dengan istirahat) ke slot baru.
UPDATE jadwal_pelajaran SET jam_mulai = '07:40', jam_selesai = '08:20'
  WHERE jam_mulai = '07:45' AND jam_selesai = '08:30';
UPDATE jadwal_pelajaran SET jam_mulai = '08:20', jam_selesai = '09:00'
  WHERE jam_mulai = '08:30' AND jam_selesai = '09:15';
UPDATE jadwal_pelajaran SET jam_mulai = '09:00', jam_selesai = '09:40'
  WHERE (jam_mulai = '09:30' AND jam_selesai = '10:15')
     OR (jam_mulai = '09:00' AND jam_selesai = '09:20');
UPDATE jadwal_pelajaran SET jam_mulai = '09:40', jam_selesai = '10:20'
  WHERE (jam_mulai = '10:15' AND jam_selesai = '11:00')
     OR (jam_mulai = '09:20' AND jam_selesai = '09:40');
UPDATE jadwal_pelajaran SET jam_mulai = '10:20', jam_selesai = '11:00'
  WHERE (jam_mulai = '11:00' AND jam_selesai = '11:45')
     OR (jam_mulai = '09:40' AND jam_selesai = '10:00');
UPDATE jadwal_pelajaran SET jam_mulai = '11:00', jam_selesai = '11:40'
  WHERE (jam_mulai = '12:30' AND jam_selesai = '13:15')
     OR (jam_mulai = '10:00' AND jam_selesai = '10:40');
UPDATE jadwal_pelajaran SET jam_mulai = '11:40', jam_selesai = '12:20'
  WHERE (jam_mulai = '13:15' AND jam_selesai = '14:00')
     OR (jam_mulai = '10:40' AND jam_selesai = '11:20');
UPDATE jadwal_pelajaran SET jam_mulai = '12:20', jam_selesai = '13:00'
  WHERE jam_mulai = '11:20' AND jam_selesai = '12:00';
UPDATE jadwal_pelajaran SET jam_mulai = '13:00', jam_selesai = '13:40'
  WHERE jam_mulai = '12:00' AND jam_selesai = '12:40';
UPDATE jadwal_pelajaran SET jam_mulai = '13:40', jam_selesai = '14:20'
  WHERE jam_mulai = '12:40' AND jam_selesai = '13:20';
UPDATE jadwal_pelajaran SET jam_mulai = '14:20', jam_selesai = '15:00'
  WHERE jam_mulai = '13:20' AND jam_selesai = '14:00';