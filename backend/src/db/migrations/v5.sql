-- ============================================================
-- MIGRATION v5 — Modul Dauroh (at-Ta'wid)
-- Target: Cloudflare D1 (SQLite) — Production
-- Tanggal: 2026-08-14
--
-- Deskripsi: Membuat 9 tabel untuk modul Dauroh:
--   1. dauroh_program
--   2. dauroh_musyrifah
--   3. dauroh_jadwal
--   4. dauroh_jadwal_kelas
--   5. dauroh_program_santri
--   6. dauroh_absensi_musyrifah
--   7. dauroh_absensi_santri
--   8. dauroh_surat
--   9. dauroh_nilai
--
-- CARA PAKAI:
--   1. Buat backup dulu!
--   2. Jalankan via wrangler:
--      wrangler d1 execute ppi-db-prod --remote --file=./src/db/migrations/v5.sql
--   3. atau via Cloudflare Dashboard > D1 > Console
-- ============================================================

-- ─────────────────────────────────────────────
-- 1. dauroh_program
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dauroh_program (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    nama_program    TEXT NOT NULL,
    jenis_program   TEXT NOT NULL CHECK (jenis_program IN ('khusus', 'kelas')),
    jenis_dauroh    TEXT NOT NULL CHECK (jenis_dauroh IN ('murojaah', 'tahfidz')),
    skema_penilaian TEXT DEFAULT 'murojaah_tahfidz',
    keterangan      TEXT,
    tahun_ajaran_id INTEGER REFERENCES tahun_ajaran(id),
    is_aktif        INTEGER NOT NULL DEFAULT 1,
    -- Konfigurasi Skema Penilaian
    max_bidang1     INTEGER DEFAULT 40,
    max_bidang2     INTEGER DEFAULT 30,
    max_bidang3     INTEGER DEFAULT 30,
    label_bidang1   TEXT DEFAULT 'Kelancaran Hafalan',
    label_bidang2   TEXT DEFAULT 'Tajwid',
    label_bidang3   TEXT DEFAULT 'Fashohah dan Adab',
    konfigurasi_nilai TEXT,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ─────────────────────────────────────────────
-- 2. dauroh_musyrifah
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- 3. dauroh_jadwal
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- 4. dauroh_jadwal_kelas
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dauroh_jadwal_kelas (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    jadwal_id   INTEGER NOT NULL REFERENCES dauroh_jadwal(id) ON DELETE CASCADE,
    kelas_id    INTEGER NOT NULL REFERENCES kelas(id),
    UNIQUE(jadwal_id, kelas_id)
);

-- ─────────────────────────────────────────────
-- 5. dauroh_program_santri
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dauroh_program_santri (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    program_id  INTEGER NOT NULL REFERENCES dauroh_program(id) ON DELETE CASCADE,
    santri_id   INTEGER NOT NULL REFERENCES siswa(id),
    UNIQUE(program_id, santri_id)
);

-- ─────────────────────────────────────────────
-- 6. dauroh_absensi_musyrifah
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- 7. dauroh_absensi_santri
-- ─────────────────────────────────────────────
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

-- ─────────────────────────────────────────────
-- 8. dauroh_surat (Referensi Al-Quran)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dauroh_surat (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    nomor           INTEGER NOT NULL UNIQUE,
    nama            TEXT NOT NULL,
    nama_arab       TEXT,
    jumlah_ayat     INTEGER NOT NULL,
    juz             INTEGER NOT NULL,
    type            TEXT NOT NULL CHECK(type IN ('makkiyah', 'madaniyah')),
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ─────────────────────────────────────────────
-- 9. dauroh_nilai (Enhanced dengan computed columns)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dauroh_nilai (
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

    -- Computed Columns (SQLite 3.31.0+)
    nilai_bidang1 INTEGER GENERATED ALWAYS AS (
        40 - COALESCE(kelancaran, 0) - COALESCE(ketepatan_ayat, 0) -
        COALESCE(murojaah_sambung, 0) - COALESCE(konsistensi_hafalan, 0)
    ) STORED,

    nilai_bidang2 INTEGER GENERATED ALWAYS AS (
        30 - COALESCE(makhorijul_huruf, 0) - COALESCE(sifatul_huruf, 0) -
        COALESCE(ahkamul_huruf, 0) - COALESCE(ahkamul_madd, 0)
    ) STORED,

    nilai_bidang3 INTEGER GENERATED ALWAYS AS (
        30 - COALESCE(ahkamul_waqfi, 0) - COALESCE(adabut_tilawah, 0) -
        COALESCE(kerapihan_bacaan, 0) - COALESCE(ketepatan_tempo, 0)
    ) STORED,

    total_nilai INTEGER GENERATED ALWAYS AS (
        (40 - COALESCE(kelancaran, 0) - COALESCE(ketepatan_ayat, 0) -
         COALESCE(murojaah_sambung, 0) - COALESCE(konsistensi_hafalan, 0)) +
        (30 - COALESCE(makhorijul_huruf, 0) - COALESCE(sifatul_huruf, 0) -
         COALESCE(ahkamul_huruf, 0) - COALESCE(ahkamul_madd, 0)) +
        (30 - COALESCE(ahkamul_waqfi, 0) - COALESCE(adabut_tilawah, 0) -
         COALESCE(kerapihan_bacaan, 0) - COALESCE(ketepatan_tempo, 0))
    ) STORED,

    -- Audit
    diinput_oleh    INTEGER REFERENCES dauroh_musyrifah(id),
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),

    UNIQUE(program_id, santri_id, surat_nomor, dari_ayat, sampai_ayat)
);

-- ─────────────────────────────────────────────
-- INDEXES untuk performa
-- ─────────────────────────────────────────────
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
CREATE INDEX IF NOT EXISTS idx_dauroh_nilai_status ON dauroh_nilai(status_hafalan);
CREATE INDEX IF NOT EXISTS idx_dauroh_nilai_surat ON dauroh_nilai(surat_nomor);
CREATE INDEX IF NOT EXISTS idx_dauroh_nilai_jadwal ON dauroh_nilai(jadwal_id);
CREATE INDEX IF NOT EXISTS idx_surat_juz ON dauroh_surat(juz);
CREATE INDEX IF NOT EXISTS idx_surat_type ON dauroh_surat(type);

-- ─────────────────────────────────────────────
-- SEED DATA: 114 Surat Al-Quran
-- ─────────────────────────────────────────────
INSERT OR IGNORE INTO dauroh_surat (nomor, nama, nama_arab, jumlah_ayat, juz, type) VALUES
-- Juz 1
(1, 'Al-Fatihah', 'الفاتحة', 7, 1, 'makkiyah'),
(2, 'Al-Baqarah', 'البقرة', 286, 2, 'madaniyah'),
-- Juz 3
(3, 'Ali Imran', 'آل عمران', 200, 3, 'madaniyah'),
(4, 'An Nisa', 'النساء', 176, 4, 'madaniyah'),
-- Juz 4-5
(5, 'Al-Maidah', 'المائدة', 120, 6, 'madaniyah'),
(6, 'Al-Anam', 'الأنعام', 165, 7, 'makkiyah'),
(7, 'Al-Araf', 'الأعراف', 206, 8, 'makkiyah'),
(8, 'Al-Anfal', 'الأنفال', 75, 9, 'madaniyah'),
(9, 'At-Tawbah', 'التوبة', 129, 10, 'madaniyah'),
(10, 'Yunus', 'يونس', 109, 11, 'makkiyah'),
(11, 'Hud', 'هود', 123, 11, 'makkiyah'),
(12, 'Yusuf', 'يوسف', 111, 12, 'makkiyah'),
(13, 'Ar-Ra''d', 'الرعد', 43, 13, 'madaniyah'),
(14, 'Ibrahim', 'إبراهيم', 52, 13, 'makkiyah'),
(15, 'Al-Hijr', 'الحجر', 99, 14, 'makkiyah'),
(16, 'An-Nahl', 'النحل', 128, 14, 'makkiyah'),
(17, 'Al-Isra', 'الإسراء', 111, 15, 'makkiyah'),
(18, 'Al-Kahf', 'الكهف', 110, 15, 'makkiyah'),
(19, 'Maryam', 'مريم', 98, 16, 'makkiyah'),
(20, 'Taha', 'طه', 135, 16, 'makkiyah'),
(21, 'Al-Anbiya', 'الأنبياء', 112, 17, 'makkiyah'),
(22, 'Al-Hajj', 'الحج', 78, 17, 'madaniyah'),
(23, 'Al-Muminun', 'المؤمنون', 118, 18, 'makkiyah'),
(24, 'An-Nur', 'النور', 64, 18, 'madaniyah'),
(25, 'Al-Furqan', 'الفرقان', 77, 18, 'makkiyah'),
(26, 'Ash-Shu''ara', 'الشعراء', 227, 19, 'makkiyah'),
(27, 'An-Naml', 'النمل', 93, 19, 'makkiyah'),
(28, 'Al-Qasas', 'القصص', 88, 20, 'makkiyah'),
(29, 'Al-Ankabut', 'العنكبوت', 69, 20, 'makkiyah'),
(30, 'Ar-Rum', 'الروم', 60, 21, 'makkiyah'),
(31, 'Luqman', 'لقمان', 34, 21, 'makkiyah'),
(32, 'As-Sajdah', 'السجدة', 30, 21, 'makkiyah'),
(33, 'Al-Ahzab', 'الأحزاب', 73, 22, 'madaniyah'),
(34, 'Saba', 'سبأ', 54, 22, 'makkiyah'),
(35, 'Fatir', 'فاطر', 45, 23, 'makkiyah'),
(36, 'Ya-Sin', 'يس', 83, 23, 'makkiyah'),
(37, 'As-Saffat', 'الصافات', 182, 23, 'makkiyah'),
(38, 'Sad', 'ص', 88, 24, 'makkiyah'),
(39, 'Az-Zumar', 'الزمر', 75, 24, 'makkiyah'),
(40, 'Ghafir', 'غافر', 85, 24, 'makkiyah'),
(41, 'Fussilat', 'فصلت', 54, 24, 'makkiyah'),
(42, 'Ash-Shura', 'الشورى', 53, 25, 'makkiyah'),
(43, 'Az-Zukhruf', 'الزخرف', 89, 25, 'makkiyah'),
(44, 'Ad-Dukhan', 'الدخان', 59, 25, 'makkiyah'),
(45, 'Al-Jathiyah', 'الجاثية', 37, 25, 'makkiyah'),
(46, 'Al-Ahqaf', 'الأحقاف', 35, 26, 'makkiyah'),
(47, 'Muhammad', 'محمد', 38, 26, 'madaniyah'),
(48, 'Al-Fath', 'الفتح', 29, 27, 'madaniyah'),
(49, 'Al-Hujurat', 'الحجرات', 18, 28, 'madaniyah'),
(50, 'Qaf', 'ق', 45, 26, 'makkiyah'),
(51, 'Adh-Dhariyat', 'الذاريات', 60, 26, 'makkiyah'),
(52, 'At-Tur', 'الطور', 49, 27, 'makkiyah'),
(53, 'An-Najm', 'النجم', 62, 27, 'makkiyah'),
(54, 'Al-Qamar', 'القمر', 55, 27, 'makkiyah'),
(55, 'Ar-Rahman', 'الرحمن', 78, 27, 'madaniyah'),
(56, 'Al-Waqiah', 'الواقعة', 96, 28, 'makkiyah'),
(57, 'Al-Hadid', 'الحديد', 29, 28, 'madaniyah'),
(58, 'Al-Mujadilah', 'المجادلة', 22, 29, 'madaniyah'),
(59, 'Al-Hashr', 'الحشر', 24, 29, 'madaniyah'),
(60, 'Al-Mumtahanah', 'الممتحنة', 13, 30, 'madaniyah'),
(61, 'As-Saff', 'الصف', 14, 30, 'madaniyah'),
(62, 'Al-Jumu''ah', 'الجمعة', 11, 30, 'madaniyah'),
(63, 'Al-Munafiqun', 'المنافقون', 11, 30, 'madaniyah'),
(64, 'At-Taghabun', 'التغابب', 18, 30, 'madaniyah'),
(65, 'At-Talaq', 'الطلاق', 12, 30, 'madaniyah'),
(66, 'At-Tahrim', 'التحريم', 12, 30, 'madaniyah'),
(67, 'Al-Mulk', 'الملك', 30, 29, 'makkiyah'),
(68, 'Al-Qalam', 'القلم', 52, 28, 'makkiyah'),
(69, 'Al-Haqqah', 'الحاقة', 52, 28, 'makkiyah'),
(70, 'Al-Ma''arij', 'المعارج', 44, 29, 'makkiyah'),
(71, 'Nuh', 'نوح', 28, 29, 'makkiyah'),
(72, 'Al-Jinn', 'الجن', 28, 29, 'makkiyah'),
(73, 'Al-Muzzammil', 'المزمل', 20, 29, 'makkiyah'),
(74, 'Al-Muddaththir', 'المدثر', 56, 30, 'makkiyah'),
(75, 'Al-Qiyamah', 'القيامة', 40, 30, 'makkiyah'),
(76, 'Al-Insan', 'الإنسان', 31, 30, 'madaniyah'),
(77, 'Al-Mursalat', 'المرسلات', 50, 30, 'makkiyah'),
(78, 'An-Naba', 'النبأ', 40, 30, 'makkiyah'),
(79, 'An-Nazi''at', 'النازعات', 46, 30, 'makkiyah'),
(80, 'Abasa', 'عبس', 42, 30, 'makkiyah'),
(81, 'At-Takwir', 'التكوير', 29, 30, 'makkiyah'),
(82, 'Al-Infitar', 'الانفطار', 19, 30, 'makkiyah'),
(83, 'Al-Mutaffifin', 'المطففين', 36, 30, 'makkiyah'),
(84, 'Al-Inshiqaq', 'الانشقاق', 25, 30, 'makkiyah'),
(85, 'Al-Buruj', 'البروج', 22, 30, 'makkiyah'),
(86, 'At-Tariq', 'الطارق', 17, 30, 'makkiyah'),
(87, 'Al-A''la', 'الأعلى', 19, 30, 'makkiyah'),
(88, 'Al-Ghashiyah', 'الغاشية', 26, 30, 'makkiyah'),
(89, 'Al-Fajr', 'الفجر', 30, 30, 'makkiyah'),
(90, 'Al-Balad', 'البلد', 20, 30, 'makkiyah'),
(91, 'Ash-Shams', 'الشمس', 15, 30, 'makkiyah'),
(92, 'Al-Layl', 'الليل', 21, 30, 'makkiyah'),
(93, 'Ad-Duha', 'الضحى', 11, 30, 'makkiyah'),
(94, 'Ash-Sharh', 'الشرح', 8, 30, 'makkiyah'),
(95, 'At-Tin', 'التين', 8, 30, 'makkiyah'),
(96, 'Al-Alaq', 'العلق', 19, 30, 'makkiyah'),
(97, 'Al-Qadr', 'القدر', 5, 30, 'makkiyah'),
(98, 'Al-Bayyinah', 'البينة', 8, 30, 'madaniyah'),
(99, 'Az-Zalzalah', 'الزلزلة', 8, 30, 'madaniyah'),
(100, 'Al-Adiyat', 'العاديات', 11, 30, 'makkiyah'),
(101, 'Al-Qari''ah', 'القارعة', 11, 30, 'makkiyah'),
(102, 'At-Takathur', 'التكاثر', 8, 30, 'makkiyah'),
(103, 'Al-Asr', 'العصر', 3, 30, 'makkiyah'),
(104, 'Al-Humazah', 'الهمزة', 9, 30, 'makkiyah'),
(105, 'Al-Fil', 'الفيل', 5, 30, 'makkiyah'),
(106, 'Quraysh', 'قريش', 4, 30, 'makkiyah'),
(107, 'Al-Ma''un', 'الماعون', 7, 30, 'makkiyah'),
(108, 'Al-Kawthar', 'الكوثر', 3, 30, 'makkiyah'),
(109, 'Al-Kafirun', 'الكافرون', 6, 30, 'makkiyah'),
(110, 'An-Nasr', 'النصر', 3, 30, 'madaniyah'),
(111, 'Al-Masad', 'المسد', 5, 30, 'makkiyah'),
(112, 'Al-Ikhlas', 'الإخلاص', 4, 30, 'makkiyah'),
(113, 'Al-Falaq', 'الفلق', 5, 30, 'makkiyah'),
(114, 'An-Nas', 'الناس', 6, 30, 'makkiyah');

-- ============================================================
-- SELESAI. Verifikasi dengan:
--   SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'dauroh%';
--   SELECT COUNT(*) FROM dauroh_surat;
-- ============================================================
