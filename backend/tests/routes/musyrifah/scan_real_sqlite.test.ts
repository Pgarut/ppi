import { describe, it, expect, vi, afterEach } from 'vitest';
import { DatabaseSync } from 'node:sqlite';
import { handleMusyrifahRoutes } from '../../../src/routes/musyrifah/index';
import { Env, UserPayload } from '../../../src/types';

class Stmt {
  constructor(private db: DatabaseSync, private sql: string, private params: unknown[] = []) {}
  bind(...p: unknown[]) { return new Stmt(this.db, this.sql, p); }
  async first<T>(): Promise<T | null> { return (this.db.prepare(this.sql).get(...this.params) as T | undefined) ?? null; }
  async all<T>(): Promise<{ results: T[] }> { return { results: this.db.prepare(this.sql).all(...this.params) as T[] }; }
  async run() { const r = this.db.prepare(this.sql).run(...this.params); return { meta: { last_row_id: Number(r.lastInsertRowid), changes: Number(r.changes) } }; }
}
class Db {
  constructor(private db: DatabaseSync) {}
  prepare(sql: string) { return new Stmt(this.db, sql); }
  async batch(st: Stmt[]) { return Promise.all(st.map((s) => s.run())); }
}

const user = { sub: 1, username: 'musyrifah1', role: 'musyrifah', guru_id: null, siswa_id: null } as UserPayload;

function makeEnv() {
  const db = new DatabaseSync(':memory:');
  db.exec(`
    CREATE TABLE pengaturan (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      key TEXT NOT NULL UNIQUE,
      value TEXT NOT NULL DEFAULT '',
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
    CREATE TABLE dauroh_musyrifah (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nipmus TEXT,
      nama TEXT NOT NULL,
      username TEXT NOT NULL UNIQUE
    );
    CREATE TABLE dauroh_program (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nama_program TEXT NOT NULL
    );
    CREATE TABLE dauroh_jadwal (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      program_id INTEGER NOT NULL,
      musyrifah_1_id INTEGER NOT NULL,
      musyrifah_2_id INTEGER,
      hari TEXT NOT NULL,
      jam_mulai TEXT NOT NULL,
      jam_selesai TEXT NOT NULL,
      is_aktif INTEGER NOT NULL DEFAULT 1
    );
    CREATE TABLE dauroh_absensi_musyrifah (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      musyrifah_id INTEGER NOT NULL,
      jadwal_id INTEGER NOT NULL,
      tanggal TEXT NOT NULL,
      waktu_scan TEXT NOT NULL,
      waktu_masuk TEXT,
      waktu_keluar TEXT,
      status TEXT NOT NULL DEFAULT 'hadir',
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      UNIQUE(musyrifah_id, jadwal_id, tanggal)
    );

    INSERT INTO pengaturan (key, value) VALUES
      ('dauroh_jam_masuk_mulai','06:30:00'),
      ('dauroh_jam_masuk_selesai','10:00:00'),
      ('dauroh_jam_keluar_mulai','11:00:00'),
      ('dauroh_jam_keluar_selesai','15:00:00');
    INSERT INTO dauroh_musyrifah (id, nipmus, nama, username)
      VALUES (1, 'M001', 'Musyrifah Satu', 'musyrifah1');
    INSERT INTO dauroh_program (id, nama_program) VALUES (1, 'Tahfidz');
    INSERT INTO dauroh_jadwal (id, program_id, musyrifah_1_id, hari, jam_mulai, jam_selesai, is_aktif)
      VALUES (1, 1, 1, 'Senin', '07:30', '09:00', 1);
  `);
  const env = { DB: new Db(db), QR_DAUROH_TOKEN: 'TEST_DAUROH' } as unknown as Env;
  return { db, env };
}

function scan(env: Env, body: unknown) {
  const url = new URL('https://test.local/api/musyrifah/absensi/scan');
  return handleMusyrifahRoutes(
    new Request(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    }),
    env,
    user,
    ['api', 'musyrifah', 'absensi', 'scan'],
    url,
  );
}

/** Senin, 5 Januari 2026, jam HH:MM WIB. */
function at(time: string) {
  vi.useFakeTimers();
  vi.setSystemTime(new Date(`2026-01-05T${time}:00+07:00`));
}

afterEach(() => {
  vi.useRealTimers();
});

const validToken = 'TEST_DAUROH';

describe('Scan absensi musyrifah (SQLite asli)', () => {
  it('mencatat absen masuk pada window masuk', async () => {
    const { db, env } = makeEnv();
    at('08:00');

    const res = await scan(env, { token: validToken });
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { action: string; message: string } };
    expect(body.data.action).toBe('absen_masuk');

    const row = db.prepare('SELECT waktu_masuk, waktu_keluar FROM dauroh_absensi_musyrifah').get() as Record<string, unknown>;
    expect(row).toMatchObject({ waktu_masuk: '08:00:00', waktu_keluar: null });
  });

  it('menolak scan masuk kedua dan menyebutkan jam masuk yang tercatat', async () => {
    const { db, env } = makeEnv();
    at('08:00');
    await scan(env, { token: validToken });

    at('08:05');
    const res = await scan(env, { token: validToken });
    expect(res.status).toBe(400);
    const body = await res.json() as { error: { message: string } };
    expect(body.error.message).toContain('Jam masuk sudah tercatat pukul 08:00');

    const count = db.prepare('SELECT COUNT(*) AS n FROM dauroh_absensi_musyrifah').get() as { n: number };
    expect(count.n).toBe(1);
  });

  it('mencatat absen keluar setelah absen masuk', async () => {
    const { db, env } = makeEnv();
    at('08:00');
    await scan(env, { token: validToken });

    at('11:30');
    const res = await scan(env, { token: validToken });
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { action: string } };
    expect(body.data.action).toBe('absen_keluar');

    const row = db.prepare('SELECT waktu_masuk, waktu_keluar FROM dauroh_absensi_musyrifah').get() as Record<string, unknown>;
    expect(row).toMatchObject({ waktu_masuk: '08:00:00', waktu_keluar: '11:30:00' });
  });

  it('menolak scan keluar tanpa absen masuk', async () => {
    const { env } = makeEnv();
    at('11:30');

    const res = await scan(env, { token: validToken });
    expect(res.status).toBe(400);
    const body = await res.json() as { error: { message: string } };
    expect(body.error.message).toContain('Belum ada absen masuk');
  });

  it('menolak scan di luar window jam absensi', async () => {
    const { env } = makeEnv();
    at('16:00');

    const res = await scan(env, { token: validToken });
    expect(res.status).toBe(400);
    const body = await res.json() as { error: { message: string } };
    expect(body.error.message).toContain('Di luar jam absensi');
  });

  it('menolak token QR yang salah', async () => {
    const { env } = makeEnv();
    at('08:00');

    const res = await scan(env, { token: 'SALAH' });
    expect(res.status).toBe(400);
  });

  it('menolak body JSON yang tidak valid tanpa error 500', async () => {
    const { env } = makeEnv();
    at('08:00');
    const url = new URL('https://test.local/api/musyrifah/absensi/scan');

    const res = await handleMusyrifahRoutes(
      new Request(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{bukan json' }),
      env,
      user,
      ['api', 'musyrifah', 'absensi', 'scan'],
      url,
    );
    expect(res.status).toBe(400);
  });

  it('meminta pilih jadwal bila ada lebih dari satu jadwal hari ini', async () => {
    const { db, env } = makeEnv();
    db.exec(`
      INSERT INTO dauroh_program (id, nama_program) VALUES (2, 'Tahsin');
      INSERT INTO dauroh_jadwal (id, program_id, musyrifah_1_id, hari, jam_mulai, jam_selesai, is_aktif)
        VALUES (2, 2, 1, 'Senin', '09:30', '10:30', 1);
    `);
    at('08:00');

    const res = await scan(env, { token: validToken });
    expect(res.status).toBe(200);
    const body = await res.json() as { data: { action: string; jadwal: { id: number }[] } };
    expect(body.data.action).toBe('pilih_jadwal');
    expect(body.data.jadwal).toHaveLength(2);

    const res2 = await scan(env, { token: validToken, jadwal_id: 2 });
    expect(res2.status).toBe(200);
    const body2 = await res2.json() as { data: { action: string } };
    expect(body2.data.action).toBe('absen_masuk');

    const row = db.prepare('SELECT jadwal_id FROM dauroh_absensi_musyrifah').get() as { jadwal_id: number };
    expect(row.jadwal_id).toBe(2);
  });

  it('menolak jadwal_id yang bukan jadwal musyrifah', async () => {
    const { env } = makeEnv();
    at('08:00');

    const res = await scan(env, { token: validToken, jadwal_id: 999 });
    expect(res.status).toBe(400);
    const body = await res.json() as { error: { message: string } };
    expect(body.error.message).toContain('bukan jadwal Anda');
  });

  it('mengisi jam masuk pada baris koreksi admin yang masih kosong', async () => {
    const { db, env } = makeEnv();
    db.exec(`
      INSERT INTO dauroh_absensi_musyrifah (musyrifah_id, jadwal_id, tanggal, waktu_scan, waktu_masuk, status)
        VALUES (1, 1, '2026-01-05', '07:00:00', NULL, 'hadir');
    `);
    at('08:10');

    const res = await scan(env, { token: validToken });
    expect(res.status).toBe(200);

    const row = db.prepare('SELECT waktu_masuk FROM dauroh_absensi_musyrifah').get() as Record<string, unknown>;
    expect(row.waktu_masuk).toBe('08:10:00');
  });

  it('tidak menimpa status izin/sakit/alpha yang diisi admin', async () => {
    const { db, env } = makeEnv();
    db.exec(`
      INSERT INTO dauroh_absensi_musyrifah (musyrifah_id, jadwal_id, tanggal, waktu_scan, waktu_masuk, status)
        VALUES (1, 1, '2026-01-05', '07:00:00', NULL, 'izin');
    `);
    at('08:10');

    const res = await scan(env, { token: validToken });
    expect(res.status).toBe(400);
    const body = await res.json() as { error: { message: string } };
    expect(body.error.message).toContain('izin');

    const row = db.prepare('SELECT waktu_masuk, status FROM dauroh_absensi_musyrifah').get() as Record<string, unknown>;
    expect(row).toMatchObject({ waktu_masuk: null, status: 'izin' });
  });
});
