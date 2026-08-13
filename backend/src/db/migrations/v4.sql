-- ============================================================
-- MIGRATION v4 — Tambah tabel guru_mapel_kelas
-- Target: Cloudflare D1 (SQLite) — Production
-- Tanggal: 2026-08-12
--
-- CARA PAKAI:
--   1. Buat backup dulu!
--   2. Jalankan per baris via Cloudflare Dashboard > D1 > Console
--   3. atau via wrangler: wrangler d1 execute ppi-db --remote --file=./src/db/migrations/v4.sql
-- ============================================================

-- ─────────────────────────────────────────────
-- 1. Buat tabel guru_mapel_kelas
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS guru_mapel_kelas (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    guru_id           INTEGER NOT NULL REFERENCES guru(id) ON DELETE CASCADE,
    mata_pelajaran_id INTEGER NOT NULL REFERENCES mata_pelajaran(id) ON DELETE CASCADE,
    kelas_id          INTEGER NOT NULL REFERENCES kelas(id) ON DELETE CASCADE,
    created_at        TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(guru_id, mata_pelajaran_id, kelas_id)
);

-- ─────────────────────────────────────────────
-- 2. Buat indexes untuk performa
-- ─────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_gmk_guru       ON guru_mapel_kelas(guru_id);
CREATE INDEX IF NOT EXISTS idx_gmk_mapel      ON guru_mapel_kelas(mata_pelajaran_id);
CREATE INDEX IF NOT EXISTS idx_gmk_kelas      ON guru_mapel_kelas(kelas_id);
CREATE INDEX IF NOT EXISTS idx_gmk_guru_mapel ON guru_mapel_kelas(guru_id, mata_pelajaran_id);
CREATE INDEX IF NOT EXISTS idx_gmk_guru_kelas ON guru_mapel_kelas(guru_id, kelas_id);

-- ─────────────────────────────────────────────
-- 3. Migrasi data lama (guru_mapel × guru_kelas)
--    Hanya untuk kombinasi yang valid di mapel_kelas
-- ─────────────────────────────────────────────
INSERT OR IGNORE INTO guru_mapel_kelas (guru_id, mata_pelajaran_id, kelas_id)
SELECT DISTINCT gm.guru_id, gm.mata_pelajaran_id, gk.kelas_id
FROM guru_mapel gm
INNER JOIN guru_kelas gk ON gm.guru_id = gk.guru_id
INNER JOIN mapel_kelas mk ON gm.mata_pelajaran_id = mk.mata_pelajaran_id
                          AND gk.kelas_id = mk.kelas_id;

-- ─────────────────────────────────────────────
-- SELESAI. Verifikasi dengan:
--   SELECT COUNT(*) FROM guru_mapel_kelas;
--   SELECT g.nama, mp.nama AS mapel, k.nama AS kelas
--   FROM guru_mapel_kelas gmk
--   JOIN guru g ON gmk.guru_id = g.id
--   JOIN mata_pelajaran mp ON gmk.mata_pelajaran_id = mp.id
--   JOIN kelas k ON gmk.kelas_id = k.id
--   ORDER BY g.nama, mp.nama, k.nama;
-- ============================================================
