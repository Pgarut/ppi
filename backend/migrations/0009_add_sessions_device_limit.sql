-- ============================================================
-- Migration 0009: Tabel Sessions untuk Device Limiting
-- Batasi login maksimal 2 perangkat per user
-- ============================================================

CREATE TABLE IF NOT EXISTS sessions (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_agent  TEXT,
    token_hash  TEXT NOT NULL,
    is_active   INTEGER NOT NULL DEFAULT 1,
    created_at  TEXT NOT NULL DEFAULT (datetime('now')),
    last_active TEXT NOT NULL DEFAULT (datetime('now')),
    revoked_at  TEXT
);

-- Index untuk query cepat: cari session aktif per user
CREATE INDEX IF NOT EXISTS idx_sessions_user_active
    ON sessions(user_id, is_active);

-- Index untuk cleanup session lama
CREATE INDEX IF NOT EXISTS idx_sessions_created
    ON sessions(created_at);
