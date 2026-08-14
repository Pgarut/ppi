-- ============================================
-- MIGRATION 0019: Koreksi rumus nilai dauroh
-- ============================================
-- Prod memakai arsitektur GENERATED COLUMN (schema.sql), bukan trigger (0016).
-- Bug: rumus 40 - sum membuat nilai sempurna = 36, padahal label UI "Max 40/30/30"
-- dan frontend menghitung 44/34/34 - sum.
-- Rumus benar: (max + 4) - sum -> nilai_bidang1 = 44 - sum, bidang2/3 = 34 - sum.
-- Strategi: rebuild tabel dengan generated column ber-rumus yang dikoreksi.

PRAGMA foreign_keys = OFF;

-- Bersihkan trigger lama (jika ada dari migration 0016)
DROP TRIGGER IF EXISTS trg_dauroh_nilai_compute_insert;
DROP TRIGGER IF EXISTS trg_dauroh_nilai_compute_update;

ALTER TABLE dauroh_nilai RENAME TO dauroh_nilai_old;

CREATE TABLE dauroh_nilai (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Foreign Keys
    program_id      INTEGER NOT NULL REFERENCES dauroh_program(id) ON DELETE CASCADE,
    santri_id       INTEGER NOT NULL REFERENCES siswa(id) ON DELETE CASCADE,
    jadwal_id       INTEGER REFERENCES dauroh_jadwal(id),

    -- Metadata Hafalan
    surat_nomor     INTEGER REFERENCES dauroh_surat(nomor),
    dari_ayat       INTEGER,
    sampai_ayat     INTEGER,
    status_hafalan  TEXT NOT NULL DEFAULT 'melanjutkan'
                        CHECK(status_hafalan IN ('mengulang', 'melanjutkan', 'selesai')),

    -- Bidang 1: Kelancaran Hafalan (Max 40)
    kelancaran          INTEGER CHECK(kelancaran BETWEEN 1 AND 5),
    ketepatan_ayat      INTEGER CHECK(ketepatan_ayat BETWEEN 1 AND 5),
    murojaah_sambung    INTEGER CHECK(murojaah_sambung BETWEEN 1 AND 5),
    konsistensi_hafalan INTEGER CHECK(konsistensi_hafalan BETWEEN 1 AND 5),
    catatan_bidang1     TEXT,

    -- Bidang 2: Tajwid (Max 30)
    makhorijul_huruf    INTEGER CHECK(makhorijul_huruf BETWEEN 1 AND 5),
    sifatul_huruf       INTEGER CHECK(sifatul_huruf BETWEEN 1 AND 5),
    ahkamul_huruf       INTEGER CHECK(ahkamul_huruf BETWEEN 1 AND 5),
    ahkamul_madd        INTEGER CHECK(ahkamul_madd BETWEEN 1 AND 5),
    catatan_bidang2     TEXT,

    -- Bidang 3: Fashohah dan Adab (Max 30)
    ahkamul_waqfi       INTEGER CHECK(ahkamul_waqfi BETWEEN 1 AND 5),
    adabut_tilawah      INTEGER CHECK(adabut_tilawah BETWEEN 1 AND 5),
    kerapihan_bacaan    INTEGER CHECK(kerapihan_bacaan BETWEEN 1 AND 5),
    ketepatan_tempo     INTEGER CHECK(ketepatan_tempo BETWEEN 1 AND 5),
    catatan_bidang3     TEXT,

    -- Catatan
    catatan_umum        TEXT,
    rencana_tindak_lanjut TEXT,

    -- Computed Columns (rumus dikoreksi: sempurna = 40/30/30)
    nilai_bidang1 INTEGER GENERATED ALWAYS AS (
        44 - COALESCE(kelancaran, 0) - COALESCE(ketepatan_ayat, 0) -
        COALESCE(murojaah_sambung, 0) - COALESCE(konsistensi_hafalan, 0)
    ) STORED,

    nilai_bidang2 INTEGER GENERATED ALWAYS AS (
        34 - COALESCE(makhorijul_huruf, 0) - COALESCE(sifatul_huruf, 0) -
        COALESCE(ahkamul_huruf, 0) - COALESCE(ahkamul_madd, 0)
    ) STORED,

    nilai_bidang3 INTEGER GENERATED ALWAYS AS (
        34 - COALESCE(ahkamul_waqfi, 0) - COALESCE(adabut_tilawah, 0) -
        COALESCE(kerapihan_bacaan, 0) - COALESCE(ketepatan_tempo, 0)
    ) STORED,

    total_nilai INTEGER GENERATED ALWAYS AS (
        (44 - COALESCE(kelancaran, 0) - COALESCE(ketepatan_ayat, 0) -
         COALESCE(murojaah_sambung, 0) - COALESCE(konsistensi_hafalan, 0)) +
        (34 - COALESCE(makhorijul_huruf, 0) - COALESCE(sifatul_huruf, 0) -
         COALESCE(ahkamul_huruf, 0) - COALESCE(ahkamul_madd, 0)) +
        (34 - COALESCE(ahkamul_waqfi, 0) - COALESCE(adabut_tilawah, 0) -
         COALESCE(kerapihan_bacaan, 0) - COALESCE(ketepatan_tempo, 0))
    ) STORED,

    -- Audit
    diinput_oleh    INTEGER REFERENCES dauroh_musyrifah(id),
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),

    UNIQUE(program_id, santri_id, surat_nomor, dari_ayat, sampai_ayat)
);

INSERT INTO dauroh_nilai (
    program_id, santri_id, jadwal_id, surat_nomor, dari_ayat, sampai_ayat, status_hafalan,
    kelancaran, ketepatan_ayat, murojaah_sambung, konsistensi_hafalan, catatan_bidang1,
    makhorijul_huruf, sifatul_huruf, ahkamul_huruf, ahkamul_madd, catatan_bidang2,
    ahkamul_waqfi, adabut_tilawah, kerapihan_bacaan, ketepatan_tempo, catatan_bidang3,
    catatan_umum, rencana_tindak_lanjut, diinput_oleh, created_at, updated_at
)
SELECT
    program_id, santri_id, jadwal_id, surat_nomor, dari_ayat, sampai_ayat, status_hafalan,
    kelancaran, ketepatan_ayat, murojaah_sambung, konsistensi_hafalan, catatan_bidang1,
    makhorijul_huruf, sifatul_huruf, ahkamul_huruf, ahkamul_madd, catatan_bidang2,
    ahkamul_waqfi, adabut_tilawah, kerapihan_bacaan, ketepatan_tempo, catatan_bidang3,
    catatan_umum, rencana_tindak_lanjut, diinput_oleh, created_at, updated_at
FROM dauroh_nilai_old;

DROP TABLE dauroh_nilai_old;

CREATE INDEX IF NOT EXISTS idx_dauroh_nilai_program ON dauroh_nilai(program_id);
CREATE INDEX IF NOT EXISTS idx_dauroh_nilai_santri ON dauroh_nilai(santri_id);
CREATE INDEX IF NOT EXISTS idx_dauroh_nilai_status ON dauroh_nilai(status_hafalan);
CREATE INDEX IF NOT EXISTS idx_dauroh_nilai_surat ON dauroh_nilai(surat_nomor);
CREATE INDEX IF NOT EXISTS idx_dauroh_nilai_jadwal ON dauroh_nilai(jadwal_id);

PRAGMA foreign_keys = ON;