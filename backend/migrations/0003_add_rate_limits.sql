-- Migration 0003: Add rate_limits table for cross-instance rate limiting
-- Target: Cloudflare D1 (SQLite)

CREATE TABLE IF NOT EXISTS rate_limits (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    key         TEXT NOT NULL UNIQUE,        -- e.g. "rl:192.168.1.1" or "bf:192.168.1.1:admin"
    type        TEXT NOT NULL CHECK (type IN ('general','bruteforce')),
    count       INTEGER NOT NULL DEFAULT 0,
    window_start INTEGER NOT NULL,           -- Unix timestamp ms
    lock_until  INTEGER NOT NULL DEFAULT 0,  -- Unix timestamp ms (0 = not locked)
    last_attempt INTEGER NOT NULL DEFAULT 0, -- Unix timestamp ms
    created_at  TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at  TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_rate_limits_key ON rate_limits(key);
CREATE INDEX IF NOT EXISTS idx_rate_limits_type ON rate_limits(type);

-- Cleanup job: hapus data rate limit yang sudah expired (lebih dari 1 jam)
-- Dijalankan via aplikasi secara periodik
