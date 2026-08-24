-- ============================================================
-- API Keys for Sistem 2 (Pihak Kedua) Integration
-- ============================================================

CREATE TABLE api_keys (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    nama_pihak      TEXT NOT NULL,                    -- nama pihak ketiga (mis. "Bank BRI", "Toko Maju")
    api_key_hash    TEXT NOT NULL,                    -- bcrypt hash dari api_key
    permissions     TEXT NOT NULL DEFAULT 'read',     -- 'read', 'write', 'readwrite'
    rate_limit      INTEGER NOT NULL DEFAULT 1000,    -- request per hari
    is_aktif        INTEGER NOT NULL DEFAULT 1,       -- 1 = aktif, 0 = nonaktif
    last_used_at    TEXT,                             -- timestamp terakhir digunakan
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Index untuk lookup cepat
CREATE INDEX idx_api_keys_is_aktif ON api_keys(is_aktif);
CREATE INDEX idx_api_keys_nama_pihak ON api_keys(nama_pihak);

-- Rate limit tracking per API Key per hari
CREATE TABLE api_key_rate_limits (
    api_key_id      INTEGER NOT NULL REFERENCES api_keys(id) ON DELETE CASCADE,
    date            TEXT NOT NULL,                    -- YYYY-MM-DD
    count           INTEGER NOT NULL DEFAULT 0,
    window_start    INTEGER NOT NULL,                 -- epoch ms
    updated_at      TEXT NOT NULL DEFAULT (datetime('now')),
    PRIMARY KEY (api_key_id, date)
);

-- ============================================================
-- Tabel Pembayaran (dipush oleh Sistem 2 via API Key)
-- ============================================================

CREATE TABLE pembayaran (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    santri_id           INTEGER NOT NULL REFERENCES siswa(id) ON DELETE CASCADE,
    jenis_pembayaran_id INTEGER NOT NULL REFERENCES jenis_pembayaran(id),
    jumlah              REAL NOT NULL,                -- nominal pembayaran
    status              TEXT NOT NULL DEFAULT '***'   -- '*' = Lunas, '**' = Proses, '***' = Belum Bayar
                          CHECK (status IN ('*', '**', '***')),
    tanggal_bayar       TEXT,                         -- tanggal pembayaran (jika sudah bayar)
    bukti_url           TEXT,                         -- URL bukti transfer (opsional)
    catatan             TEXT,
    api_key_id          INTEGER REFERENCES api_keys(id), -- tracking pihak yang input
    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_pembayaran_santri ON pembayaran(santri_id);
CREATE INDEX idx_pembayaran_status ON pembayaran(status);
CREATE INDEX idx_pembayaran_jenis ON pembayaran(jenis_pembayaran_id);
CREATE INDEX idx_pembayaran_tanggal ON pembayaran(tanggal_bayar);
CREATE INDEX idx_pembayaran_api_key ON pembayaran(api_key_id);

-- ============================================================
-- Tabel Jenis Pembayaran (Master data, dikelola Admin)
-- ============================================================

CREATE TABLE jenis_pembayaran (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    nama        TEXT NOT NULL UNIQUE,         -- contoh: "SPP Bulanan", "Dauroh", "Seragam"
    kode        TEXT UNIQUE,                  -- kode singkat: "SPP", "DAUROH", "SERAGAM"
    deskripsi   TEXT,
    is_aktif    INTEGER NOT NULL DEFAULT 1,
    created_at  TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

-- ============================================================
-- Tabel Notifikasi (dipush oleh Sistem 2 via API Key)
-- ============================================================

CREATE TABLE notifikasi (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    santri_id       INTEGER NOT NULL REFERENCES siswa(id) ON DELETE CASCADE,
    judul           TEXT NOT NULL,
    pesan           TEXT NOT NULL,
    tipe            TEXT NOT NULL DEFAULT 'info'  -- 'info', 'warning', 'success', 'error'
                      CHECK (tipe IN ('info', 'warning', 'success', 'error')),
    is_read         INTEGER NOT NULL DEFAULT 0,   -- 0 = belum dibaca, 1 = sudah dibaca
    api_key_id      INTEGER REFERENCES api_keys(id),
    created_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX idx_notifikasi_santri ON notifikasi(santri_id);
CREATE INDEX idx_notifikasi_is_read ON notifikasi(is_read);
CREATE INDEX idx_notifikasi_created ON notifikasi(created_at);