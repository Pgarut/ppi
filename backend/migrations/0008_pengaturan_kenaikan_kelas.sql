-- Migration 0008: Tambah tabel pengaturan_kenaikan_kelas
-- Tanggal: 2026-07-30

-- Tabel konfigurasi kenaikan kelas per tahun ajaran
CREATE TABLE IF NOT EXISTS pengaturan_kenaikan_kelas (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    tahun_ajaran_id     INTEGER NOT NULL REFERENCES tahun_ajaran(id),
    min_absensi_persen  REAL NOT NULL DEFAULT 75,
    min_nilai_akhir     REAL NOT NULL DEFAULT 60,
    created_at          TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at          TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE (tahun_ajaran_id)
);
