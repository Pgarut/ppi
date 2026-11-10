import { describe, it, expect } from 'vitest';
import { DatabaseSync } from 'node:sqlite';
import { handleAdminAbsensi } from '../../../src/routes/admin/absensi';
import { handleAdminDauroh } from '../../../src/routes/admin/dauroh';
import { Env, UserPayload } from '../../../src/types';
import { getWaktuAbsensiGuru, getWaktuAbsensiMusyrifah } from '../../../src/utils/absensi_waktu';

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

const adminUser = { sub: 1, username: 'admin', role: 'admin', guru_id: null, siswa_id: null } as UserPayload;

function makeEnv() {
  const db = new DatabaseSync(':memory:');
  db.exec(`
    CREATE TABLE pengaturan (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      key TEXT NOT NULL UNIQUE,
      value TEXT NOT NULL DEFAULT '',
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
    CREATE TABLE log_aktivitas (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      aksi TEXT NOT NULL,
      modul TEXT,
      detail TEXT,
      ip_address TEXT,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    );
    INSERT INTO pengaturan (key, value) VALUES
      ('absensi_jam_masuk_mulai','06:30:00'),
      ('absensi_jam_masuk_selesai','10:00:00'),
      ('absensi_jam_keluar_mulai','11:00:00'),
      ('absensi_jam_keluar_selesai','15:00:00');
  `);
  return { db, env: { DB: new Db(db) } as unknown as Env };
}

function put(env: Env, body: unknown) {
  const url = new URL('https://test.local/api/admin/absensi/pengaturan-waktu');
  return handleAdminAbsensi(
    new Request(url, { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) }),
    env,
    adminUser,
    url,
  );
}

describe('Pengaturan waktu absensi guru (SQLite asli)', () => {
  it('menyimpan 4 nilai dan dapat dibaca kembali', async () => {
    const { db, env } = makeEnv();
    const res = await put(env, {
      jam_masuk_mulai: '06:00',
      jam_masuk_selesai: '09:00',
      jam_keluar_mulai: '12:00',
      jam_keluar_selesai: '16:00',
    });
    expect(res.status).toBe(200);

    const waktu = await getWaktuAbsensiGuru(env);
    expect(waktu).toEqual({
      jam_masuk_mulai: '06:00:00',
      jam_masuk_selesai: '09:00:00',
      jam_keluar_mulai: '12:00:00',
      jam_keluar_selesai: '16:00:00',
    });
    expect(db.prepare('SELECT COUNT(*) AS n FROM pengaturan').get()).toEqual({ n: 4 });
    expect(db.prepare('SELECT COUNT(*) AS n FROM log_aktivitas').get()).toEqual({ n: 1 });
  });

  it('menolak window masuk yang tumpang tindih dengan window keluar', async () => {
    const { env } = makeEnv();
    const res = await put(env, {
      jam_masuk_mulai: '06:00',
      jam_masuk_selesai: '12:00',
      jam_keluar_mulai: '11:00',
      jam_keluar_selesai: '16:00',
    });
    expect(res.status).toBe(400);
    const body = await res.json() as { error: { message: string } };
    expect(body.error.message).toContain('tumpang tindih');
  });

  it('menolak jam keluar yang tidak berurutan', async () => {
    const { env } = makeEnv();
    const res = await put(env, {
      jam_masuk_mulai: '06:30',
      jam_masuk_selesai: '10:00',
      jam_keluar_mulai: '15:00',
      jam_keluar_selesai: '12:00',
    });
    expect(res.status).toBe(400);
  });
});

describe('Pengaturan waktu absensi musyrifah (SQLite asli)', () => {
  const pathParts = ['api', 'admin', 'dauroh', 'pengaturan-waktu'];

  function putMusyrifah(env: Env, body: unknown) {
    const url = new URL('https://test.local/api/admin/dauroh/pengaturan-waktu');
    return handleAdminDauroh(
      new Request(url, { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) }),
      env,
      adminUser,
      pathParts,
      url,
    );
  }

  it('menyimpan 4 nilai musyrifah dan dapat dibaca kembali', async () => {
    const { db, env } = makeEnv();
    const res = await putMusyrifah(env, {
      jam_masuk_mulai: '06:00',
      jam_masuk_selesai: '07:00',
      jam_keluar_mulai: '09:00',
      jam_keluar_selesai: '10:30',
    });
    expect(res.status).toBe(200);

    const waktu = await getWaktuAbsensiMusyrifah(env);
    expect(waktu).toEqual({
      jam_masuk_mulai: '06:00:00',
      jam_masuk_selesai: '07:00:00',
      jam_keluar_mulai: '09:00:00',
      jam_keluar_selesai: '10:30:00',
    });
    // 4 key guru (seed) + 4 key musyrifah
    expect(db.prepare('SELECT COUNT(*) AS n FROM pengaturan').get()).toEqual({ n: 8 });
    expect(db.prepare('SELECT COUNT(*) AS n FROM log_aktivitas').get()).toEqual({ n: 1 });
  });

  it('menimpa nilai lama tanpa membuat key duplikat', async () => {
    const { db, env } = makeEnv();
    await putMusyrifah(env, {
      jam_masuk_mulai: '06:00',
      jam_masuk_selesai: '07:00',
      jam_keluar_mulai: '09:00',
      jam_keluar_selesai: '10:30',
    });
    const res = await putMusyrifah(env, {
      jam_masuk_mulai: '06:15',
      jam_masuk_selesai: '07:15',
      jam_keluar_mulai: '09:15',
      jam_keluar_selesai: '10:45',
    });
    expect(res.status).toBe(200);

    const waktu = await getWaktuAbsensiMusyrifah(env);
    expect(waktu.jam_masuk_mulai).toBe('06:15:00');
    expect(waktu.jam_keluar_selesai).toBe('10:45:00');
    expect(db.prepare('SELECT COUNT(*) AS n FROM pengaturan').get()).toEqual({ n: 8 });
  });

  it('menolak window musyrifah yang tumpang tindih', async () => {
    const { env } = makeEnv();
    const res = await putMusyrifah(env, {
      jam_masuk_mulai: '06:00',
      jam_masuk_selesai: '09:00',
      jam_keluar_mulai: '08:00',
      jam_keluar_selesai: '10:00',
    });
    expect(res.status).toBe(400);
    const body = await res.json() as { error: { message: string } };
    expect(body.error.message).toContain('tumpang tindih');
  });
});
