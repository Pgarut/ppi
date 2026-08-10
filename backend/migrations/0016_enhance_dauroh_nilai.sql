-- ============================================
-- MIGRATION 0016: Enhance Dauroh Grading System
-- ============================================
-- Fix: D1/libSQL tidak support GENERATED ALWAYS AS...STORED
-- Solusi: kolom biasa + TRIGGER untuk auto-compute

-- ============================================
-- STEP 1: BUAT TABEL DAUROH_SURAT
-- ============================================
CREATE TABLE IF NOT EXISTS dauroh_surat (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nomor INTEGER NOT NULL UNIQUE,
    nama TEXT NOT NULL,
    nama_arab TEXT,
    jumlah_ayat INTEGER NOT NULL,
    juz INTEGER NOT NULL,
    type TEXT NOT NULL CHECK(type IN ('makkiyah', 'madaniyah')),
    created_at TEXT DEFAULT (datetime('now'))
);

-- ============================================
-- STEP 2: BACKUP + REBUILD dauroh_nilai
-- ============================================
CREATE TABLE IF NOT EXISTS dauroh_nilai_backup AS 
SELECT * FROM dauroh_nilai;

ALTER TABLE dauroh_nilai RENAME TO dauroh_nilai_old;

CREATE TABLE dauroh_nilai (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    
    -- Foreign Keys
    program_id INTEGER NOT NULL REFERENCES dauroh_program(id) ON DELETE CASCADE,
    santri_id INTEGER NOT NULL REFERENCES siswa(id) ON DELETE CASCADE,
    jadwal_id INTEGER REFERENCES dauroh_jadwal(id),
    
    -- Metadata Hafalan
    surat_nomor INTEGER REFERENCES dauroh_surat(nomor),
    dari_ayat INTEGER,
    sampai_ayat INTEGER,
    status_hafalan TEXT NOT NULL DEFAULT 'melanjutkan' 
        CHECK(status_hafalan IN ('mengulang', 'melanjutkan', 'selesai')),
    
    -- Bidang 1: Kelancaran Hafalan (Max 40)
    kelancaran INTEGER CHECK(kelancaran BETWEEN 1 AND 5),
    ketepatan_ayat INTEGER CHECK(ketepatan_ayat BETWEEN 1 AND 5),
    murojaah_sambung INTEGER CHECK(murojaah_sambung BETWEEN 1 AND 5),
    konsistensi_hafalan INTEGER CHECK(konsistensi_hafalan BETWEEN 1 AND 5),
    catatan_bidang1 TEXT,
    
    -- Bidang 2: Tajwid (Max 30)
    makhorijul_huruf INTEGER CHECK(makhorijul_huruf BETWEEN 1 AND 5),
    sifatul_huruf INTEGER CHECK(sifatul_huruf BETWEEN 1 AND 5),
    ahkamul_huruf INTEGER CHECK(ahkamul_huruf BETWEEN 1 AND 5),
    ahkamul_madd INTEGER CHECK(ahkamul_madd BETWEEN 1 AND 5),
    catatan_bidang2 TEXT,
    
    -- Bidang 3: Fashohah dan Adab (Max 30)
    ahkamul_waqfi INTEGER CHECK(ahkamul_waqfi BETWEEN 1 AND 5),
    adabut_tilawah INTEGER CHECK(adabut_tilawah BETWEEN 1 AND 5),
    kerapihan_bacaan INTEGER CHECK(kerapihan_bacaan BETWEEN 1 AND 5),
    ketepatan_tempo INTEGER CHECK(ketepatan_tempo BETWEEN 1 AND 5),
    catatan_bidang3 TEXT,
    
    -- Catatan
    catatan_umum TEXT,
    rencana_tindak_lanjut TEXT,
    
    -- Computed (manual columns — updated by trigger)
    nilai_bidang1 INTEGER DEFAULT 0,
    nilai_bidang2 INTEGER DEFAULT 0,
    nilai_bidang3 INTEGER DEFAULT 0,
    total_nilai INTEGER DEFAULT 0,
    
    -- Audit
    diinput_oleh INTEGER REFERENCES dauroh_musyrifah(id),
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    
    -- Constraints
    UNIQUE(program_id, santri_id, surat_nomor, dari_ayat, sampai_ayat)
);

-- ============================================
-- STEP 3: TRIGGER — auto compute nilai
-- ============================================
CREATE TRIGGER IF NOT EXISTS trg_dauroh_nilai_compute_insert
AFTER INSERT ON dauroh_nilai
BEGIN
    UPDATE dauroh_nilai SET
        nilai_bidang1 = 40 - COALESCE(NEW.kelancaran, 0) - COALESCE(NEW.ketepatan_ayat, 0) 
                       - COALESCE(NEW.murojaah_sambung, 0) - COALESCE(NEW.konsistensi_hafalan, 0),
        nilai_bidang2 = 30 - COALESCE(NEW.makhorijul_huruf, 0) - COALESCE(NEW.sifatul_huruf, 0) 
                       - COALESCE(NEW.ahkamul_huruf, 0) - COALESCE(NEW.ahkamul_madd, 0),
        nilai_bidang3 = 30 - COALESCE(NEW.ahkamul_waqfi, 0) - COALESCE(NEW.adabut_tilawah, 0) 
                       - COALESCE(NEW.kerapihan_bacaan, 0) - COALESCE(NEW.ketepatan_tempo, 0),
        total_nilai  = (40 - COALESCE(NEW.kelancaran, 0) - COALESCE(NEW.ketepatan_ayat, 0) 
                       - COALESCE(NEW.murojaah_sambung, 0) - COALESCE(NEW.konsistensi_hafalan, 0))
                     + (30 - COALESCE(NEW.makhorijul_huruf, 0) - COALESCE(NEW.sifatul_huruf, 0) 
                       - COALESCE(NEW.ahkamul_huruf, 0) - COALESCE(NEW.ahkamul_madd, 0))
                     + (30 - COALESCE(NEW.ahkamul_waqfi, 0) - COALESCE(NEW.adabut_tilawah, 0) 
                       - COALESCE(NEW.kerapihan_bacaan, 0) - COALESCE(NEW.ketepatan_tempo, 0))
    WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS trg_dauroh_nilai_compute_update
AFTER UPDATE OF kelancaran, ketepatan_ayat, murojaah_sambung, konsistensi_hafalan,
    makhorijul_huruf, sifatul_huruf, ahkamul_huruf, ahkamul_madd,
    ahkamul_waqfi, adabut_tilawah, kerapihan_bacaan, ketepatan_tempo
ON dauroh_nilai
BEGIN
    UPDATE dauroh_nilai SET
        nilai_bidang1 = 40 - COALESCE(NEW.kelancaran, 0) - COALESCE(NEW.ketepatan_ayat, 0) 
                       - COALESCE(NEW.murojaah_sambung, 0) - COALESCE(NEW.konsistensi_hafalan, 0),
        nilai_bidang2 = 30 - COALESCE(NEW.makhorijul_huruf, 0) - COALESCE(NEW.sifatul_huruf, 0) 
                       - COALESCE(NEW.ahkamul_huruf, 0) - COALESCE(NEW.ahkamul_madd, 0),
        nilai_bidang3 = 30 - COALESCE(NEW.ahkamul_waqfi, 0) - COALESCE(NEW.adabut_tilawah, 0) 
                       - COALESCE(NEW.kerapihan_bacaan, 0) - COALESCE(NEW.ketepatan_tempo, 0),
        total_nilai  = (40 - COALESCE(NEW.kelancaran, 0) - COALESCE(NEW.ketepatan_ayat, 0) 
                       - COALESCE(NEW.murojaah_sambung, 0) - COALESCE(NEW.konsistensi_hafalan, 0))
                     + (30 - COALESCE(NEW.makhorijul_huruf, 0) - COALESCE(NEW.sifatul_huruf, 0) 
                       - COALESCE(NEW.ahkamul_huruf, 0) - COALESCE(NEW.ahkamul_madd, 0))
                     + (30 - COALESCE(NEW.ahkamul_waqfi, 0) - COALESCE(NEW.adabut_tilawah, 0) 
                       - COALESCE(NEW.kerapihan_bacaan, 0) - COALESCE(NEW.ketepatan_tempo, 0)),
        updated_at = datetime('now')
    WHERE id = NEW.id;
END;

-- ============================================
-- STEP 4: MIGRATE DATA LAMA
-- ============================================
INSERT INTO dauroh_nilai (
    program_id, santri_id, 
    status_hafalan, catatan_umum,
    created_at
)
SELECT 
    program_id, santri_id,
    'melanjutkan' as status_hafalan,
    catatan as catatan_umum,
    datetime('now') as created_at
FROM dauroh_nilai_old
WHERE program_id IS NOT NULL 
  AND santri_id IS NOT NULL;

DROP TABLE IF EXISTS dauroh_nilai_old;

-- ============================================
-- STEP 5: UPDATE TABEL DAUROH_PROGRAM
-- ============================================
ALTER TABLE dauroh_program ADD COLUMN skema_penilaian TEXT DEFAULT 'murojaah_tahfidz';
ALTER TABLE dauroh_program ADD COLUMN konfigurasi_nilai TEXT;
ALTER TABLE dauroh_program ADD COLUMN max_bidang1 INTEGER DEFAULT 40;
ALTER TABLE dauroh_program ADD COLUMN max_bidang2 INTEGER DEFAULT 30;
ALTER TABLE dauroh_program ADD COLUMN max_bidang3 INTEGER DEFAULT 30;
ALTER TABLE dauroh_program ADD COLUMN label_bidang1 TEXT DEFAULT 'Kelancaran Hafalan';
ALTER TABLE dauroh_program ADD COLUMN label_bidang2 TEXT DEFAULT 'Tajwid';
ALTER TABLE dauroh_program ADD COLUMN label_bidang3 TEXT DEFAULT 'Fashohah dan Adab';

-- ============================================
-- STEP 6: INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_dauroh_nilai_program ON dauroh_nilai(program_id);
CREATE INDEX IF NOT EXISTS idx_dauroh_nilai_santri ON dauroh_nilai(santri_id);
CREATE INDEX IF NOT EXISTS idx_dauroh_nilai_status ON dauroh_nilai(status_hafalan);
CREATE INDEX IF NOT EXISTS idx_dauroh_nilai_surat ON dauroh_nilai(surat_nomor);
CREATE INDEX IF NOT EXISTS idx_dauroh_nilai_jadwal ON dauroh_nilai(jadwal_id);
CREATE INDEX IF NOT EXISTS idx_surat_juz ON dauroh_surat(juz);
CREATE INDEX IF NOT EXISTS idx_surat_type ON dauroh_surat(type);
