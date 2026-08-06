-- ============================================================
-- Migration 0012: Update tingkat jenjang CHECK constraint
-- 'MA' → 'MA/MLN', constraint: ('MTs', 'MA/MLN')
-- ============================================================

PRAGMA foreign_keys = OFF;
PRAGMA defer_foreign_keys = ON;

-- 1. Create new table with new CHECK constraint
CREATE TABLE tingkat_new (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    nama       TEXT NOT NULL UNIQUE,
    jenjang    TEXT NOT NULL CHECK (jenjang IN ('MTs', 'MA/MLN')),
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 2. Copy data, convert 'MA' → 'MA/MLN' during insert
INSERT INTO tingkat_new (id, nama, jenjang, created_at, updated_at)
SELECT id, nama,
       CASE WHEN jenjang = 'MA' THEN 'MA/MLN' ELSE jenjang END,
       created_at, updated_at
FROM tingkat;

-- 3. Drop old table
DROP TABLE IF EXISTS tingkat;

-- 4. Rename new table
ALTER TABLE tingkat_new RENAME TO tingkat;

-- 5. Recreate indexes
CREATE UNIQUE INDEX IF NOT EXISTS idx_tingkat_nama ON tingkat(nama);

PRAGMA defer_foreign_keys = OFF;
PRAGMA foreign_keys = ON;
