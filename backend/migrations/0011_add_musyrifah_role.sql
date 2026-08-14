-- ============================================================
-- Migration 0011: Add musyrifah role to users table
-- SQLite/D1 does not support ALTER TABLE for CHECK constraints.
-- Workaround: recreate users table with updated CHECK constraint.
-- ============================================================

-- Kolom siswa_id dibutuhkan oleh rebuild di bawah, tapi tidak dibuat
-- di 0001_initial.sql. Tambahkan dulu agar migration ini reproducible
-- dari DB kosong (DB yang sudah ter-apply tidak akan menjalankan ulang).
ALTER TABLE users ADD COLUMN siswa_id INTEGER REFERENCES siswa(id);

PRAGMA foreign_keys = OFF;

-- 1. Create new table with updated CHECK constraint
CREATE TABLE users_new (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    username        TEXT NOT NULL UNIQUE,
    password_hash   TEXT NOT NULL,
    role            TEXT NOT NULL CHECK (role IN (
                        'admin',
                        'kepala_sekolah',
                        'wakil_kurikulum',
                        'guru_mapel_wali_kelas',
                        'guru_bk',
                        'siswa',
                        'musyrifah'
                    )),
    guru_id         INTEGER REFERENCES guru(id),
    siswa_id        INTEGER REFERENCES siswa(id),
    is_active       INTEGER NOT NULL DEFAULT 1,
    last_login_at   TEXT,
    created_at      TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT NOT NULL DEFAULT (datetime('now'))
);

-- 2. Copy existing data
INSERT INTO users_new (id, username, password_hash, role, guru_id, siswa_id, is_active, last_login_at, created_at, updated_at)
SELECT id, username, password_hash, role, guru_id, siswa_id, is_active, last_login_at, created_at, updated_at
FROM users;

-- 3. Drop old table
DROP TABLE users;

-- 4. Rename new table
ALTER TABLE users_new RENAME TO users;

-- 5. Recreate indexes
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_guru_id ON users(guru_id);
CREATE INDEX IF NOT EXISTS idx_users_siswa_id ON users(siswa_id);

PRAGMA foreign_keys = ON;
