-- ============================================================
-- Migration 0010: Modul Dauroh
-- Created: 2026-08-06
-- Target: Cloudflare D1 (SQLite)
-- ============================================================

PRAGMA foreign_keys = ON;

-- ============================================================
-- 1. PROGRAM KEGIATAN DAUROH
-- ============================================================

CREATE TABLE IF NOT EXISTS dauroh_program (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    nama_program    TEXT NOT NULL,
    jenis_program   TEXT NOT NULL CHECK (jenis_program IN ('khusus', 'kelas')),
    jenis_dauroh    TEXT NOT NULL CHECK (jenis_dauroh IN ('hafalan', 'bacaan')),
    keterangan      TEXT,
    tahun_ajaran_id INTEGER REFERENCES tahun_ajaran(id),
    is_aktif        INTEGER NOT NULL DEFAULT 1,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- 2. MUSYRIFAH
-- ============================================================

CREATE TABLE IF NOT EXISTS dauroh_musyrifah (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    nipmus              TEXT UNIQUE NOT NULL,
    nama                TEXT NOT NULL,
    jenis_kelamin       TEXT CHECK (jenis_kelamin IN ('L', 'P')),
    status_pendidikan   TEXT CHECK (status_pendidikan IN ('selesai', 'mahasiswa')),
    gelar               TEXT,
    username            TEXT UNIQUE NOT NULL,
    password_hash       TEXT NOT NULL,
    is_aktif            INTEGER NOT NULL DEFAULT 1,
    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- 3. JADWAL DAUROH
-- ============================================================

CREATE TABLE IF NOT EXISTS dauroh_jadwal (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    program_id      INTEGER NOT NULL REFERENCES dauroh_program(id),
    musyrifah_1_id  INTEGER NOT NULL REFERENCES dauroh_musyrifah(id),
    musyrifah_2_id  INTEGER REFERENCES dauroh_musyrifah(id),
    jenjang         TEXT,
    hari            TEXT NOT NULL CHECK (hari IN ('Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu')),
    jam_mulai       TEXT NOT NULL,
    jam_selesai     TEXT NOT NULL,
    is_aktif        INTEGER NOT NULL DEFAULT 1,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- 4. RELASI JADWAL-KELAS
-- ============================================================

CREATE TABLE IF NOT EXISTS dauroh_jadwal_kelas (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    jadwal_id   INTEGER NOT NULL REFERENCES dauroh_jadwal(id) ON DELETE CASCADE,
    kelas_id    INTEGER NOT NULL REFERENCES kelas(id),
    UNIQUE(jadwal_id, kelas_id)
);

-- ============================================================
-- 5. PROGRAM SANTRI (Untuk Program Khusus)
-- ============================================================

CREATE TABLE IF NOT EXISTS dauroh_program_santri (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    program_id  INTEGER NOT NULL REFERENCES dauroh_program(id) ON DELETE CASCADE,
    santri_id   INTEGER NOT NULL REFERENCES siswa(id),
    UNIQUE(program_id, santri_id)
);

-- ============================================================
-- 6. ABSENSI MUSYRIFAH
-- ============================================================

CREATE TABLE IF NOT EXISTS dauroh_absensi_musyrifah (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    musyrifah_id    INTEGER NOT NULL REFERENCES dauroh_musyrifah(id),
    jadwal_id       INTEGER NOT NULL REFERENCES dauroh_jadwal(id),
    tanggal         TEXT NOT NULL,
    waktu_scan      TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'hadir' CHECK (status IN ('hadir', 'izin', 'sakit', 'alpha')),
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(musyrifah_id, jadwal_id, tanggal)
);

-- ============================================================
-- 7. ABSENSI SANTRI
-- ============================================================

CREATE TABLE IF NOT EXISTS dauroh_absensi_santri (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    jadwal_id   INTEGER NOT NULL REFERENCES dauroh_jadwal(id),
    santri_id   INTEGER NOT NULL REFERENCES siswa(id),
    tanggal     TEXT NOT NULL,
    status      TEXT NOT NULL CHECK (status IN ('hadir', 'izin', 'sakit', 'alpha')),
    keterangan  TEXT,
    created_at  TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(jadwal_id, santri_id, tanggal)
);

-- ============================================================
-- 8. NILAI DAUROH
-- ============================================================

CREATE TABLE IF NOT EXISTS dauroh_nilai (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    program_id      INTEGER NOT NULL REFERENCES dauroh_program(id),
    santri_id       INTEGER NOT NULL REFERENCES siswa(id),
    nilai_hafalan   REAL,
    nilai_bacaan    REAL,
    catatan         TEXT,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(program_id, santri_id)
);

-- ============================================================
-- INDEX PENDUKUNG PERFORMA
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_dauroh_program_ta ON dauroh_program(tahun_ajaran_id);
CREATE INDEX IF NOT EXISTS idx_dauroh_jadwal_program ON dauroh_jadwal(program_id);
CREATE INDEX IF NOT EXISTS idx_dauroh_jadwal_musyrifah1 ON dauroh_jadwal(musyrifah_1_id);
CREATE INDEX IF NOT EXISTS idx_dauroh_jadwal_musyrifah2 ON dauroh_jadwal(musyrifah_2_id);
CREATE INDEX IF NOT EXISTS idx_dauroh_jadwal_kelas_jadwal ON dauroh_jadwal_kelas(jadwal_id);
CREATE INDEX IF NOT EXISTS idx_dauroh_jadwal_kelas_kelas ON dauroh_jadwal_kelas(kelas_id);
CREATE INDEX IF NOT EXISTS idx_dauroh_program_santri_program ON dauroh_program_santri(program_id);
CREATE INDEX IF NOT EXISTS idx_dauroh_program_santri_santri ON dauroh_program_santri(santri_id);
CREATE INDEX IF NOT EXISTS idx_dauroh_absensi_musyrifah_musyrifah ON dauroh_absensi_musyrifah(musyrifah_id);
CREATE INDEX IF NOT EXISTS idx_dauroh_absensi_musyrifah_jadwal ON dauroh_absensi_musyrifah(jadwal_id);
CREATE INDEX IF NOT EXISTS idx_dauroh_absensi_musyrifah_tanggal ON dauroh_absensi_musyrifah(tanggal);
CREATE INDEX IF NOT EXISTS idx_dauroh_absensi_santri_jadwal ON dauroh_absensi_santri(jadwal_id);
CREATE INDEX IF NOT EXISTS idx_dauroh_absensi_santri_santri ON dauroh_absensi_santri(santri_id);
CREATE INDEX IF NOT EXISTS idx_dauroh_absensi_santri_tanggal ON dauroh_absensi_santri(tanggal);
CREATE INDEX IF NOT EXISTS idx_dauroh_nilai_program ON dauroh_nilai(program_id);
CREATE INDEX IF NOT EXISTS idx_dauroh_nilai_santri ON dauroh_nilai(santri_id);

-- ============================================================
-- SEED DATA (Opsional)
-- ============================================================

-- Contoh program default (bisa dihapus jika tidak perlu)
-- INSERT OR IGNORE INTO dauroh_program (nama_program, jenis_program, jenis_dauroh, keterangan)
-- VALUES ('Tahfidz Quran', 'kelas', 'hafalan', 'Program hafalan Al-Quran untuk semua kelas');
