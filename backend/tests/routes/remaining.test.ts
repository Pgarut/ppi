import { describe, it, expect, vi } from 'vitest';
import { handleKonselingBK } from '../../src/routes/guru_bk/konseling';
import { handleMonitoringBK } from '../../src/routes/guru_bk/monitoring';
import { handleJadwalKS } from '../../src/routes/kepala_sekolah/jadwal';
import { handleAbsensiKS } from '../../src/routes/kepala_sekolah/absensi';
import { handleNilaiKS } from '../../src/routes/kepala_sekolah/nilai';
import { handleRaporKS } from '../../src/routes/kepala_sekolah/rapor';
import { handleBKKS } from '../../src/routes/kepala_sekolah/bk';
import { UserPayload } from '../../src/types';

function makeDb() {
  const first = vi.fn();
  const all = vi.fn();
  const run = vi.fn().mockResolvedValue({ meta: { last_row_id: 1, changes: 1 } });
  const bind = vi.fn(() => ({ first, all, run }));
  const stmt = { first, all, run, bind };
  const prepare = vi.fn(() => stmt);
  return { DB: { prepare }, first, all, run, bind, stmt };
}

const bkUser: UserPayload = { sub: 4, username: 'bk', role: 'guru_bk', guru_id: 7 };

function makeUrl(path: string, search = ''): URL {
  return new URL(`http://localhost${path}${search ? '?' + search : ''}`);
}
function makeGet(path: string, search?: string): Request {
  return new Request(makeUrl(path, search), { method: 'GET' });
}
function makePost(path: string, body: unknown): Request {
  return new Request(makeUrl(path), { method: 'POST', body: JSON.stringify(body), headers: { 'Content-Type': 'application/json' } });
}

describe('BK Konseling Routes', () => {
  it('should list jadwal konseling', async () => {
    const db = makeDb();
    db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A', tanggal: '2026-07-27' }] });
    const req = makeGet('/api/guru-bk/jadwal-konseling');
    const res = await handleKonselingBK(req, db, bkUser, ['api', 'guru-bk', 'jadwal-konseling'], makeUrl(''));
    expect(res.status).toBe(200);
  });

  it('should create jadwal konseling', async () => {
    const db = makeDb();
    const req = makePost('/api/guru-bk/jadwal-konseling', { siswa_id: 1, tanggal: '2026-07-28', jam: '09:00', jenis: 'individu' });
    const res = await handleKonselingBK(req, db, bkUser, ['api', 'guru-bk', 'jadwal-konseling'], makeUrl(''));
    expect(res.status).toBe(201);
  });

  it('should list konseling sessions', async () => {
    const db = makeDb();
    db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A', catatan: 'Tes' }] });
    const req = makeGet('/api/guru-bk/konseling');
    const res = await handleKonselingBK(req, db, bkUser, ['api', 'guru-bk', 'konseling'], makeUrl(''));
    expect(res.status).toBe(200);
  });

  it('should list bakat minat', async () => {
    const db = makeDb();
    db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A', jenis: 'Olahraga' }] });
    const req = makeGet('/api/guru-bk/bakat-minat');
    const res = await handleKonselingBK(req, db, bkUser, ['api', 'guru-bk', 'bakat-minat'], makeUrl(''));
    expect(res.status).toBe(200);
  });
});

describe('BK Monitoring Routes', () => {
  it('should return monitoring nilai', async () => {
    const db = makeDb();
    db.all.mockResolvedValue({ results: [{ jenis: 'harian', rata_rata: 80 }] });
    const req = makeGet('/api/guru-bk/monitoring/nilai');
    const res = await handleMonitoringBK(req, db, makeUrl('/api/guru-bk/monitoring/nilai'));
    expect(res.status).toBe(200);
  });

  it('should return monitoring absensi', async () => {
    const db = makeDb();
    db.all.mockResolvedValue({ results: [{ status: 'hadir', jumlah: 20 }] });
    const req = makeGet('/api/guru-bk/monitoring/absensi');
    const res = await handleMonitoringBK(req, db, makeUrl('/api/guru-bk/monitoring/absensi'));
    expect(res.status).toBe(200);
  });

  it('should return monitoring pelanggaran', async () => {
    const db = makeDb();
    db.all.mockResolvedValue({ results: [{ kategori: 'perilaku', jumlah: 3 }] });
    const req = makeGet('/api/guru-bk/monitoring/pelanggaran');
    const res = await handleMonitoringBK(req, db, makeUrl('/api/guru-bk/monitoring/pelanggaran'));
    expect(res.status).toBe(200);
  });
});

describe('Kepala Sekolah View Routes', () => {
  it('should return jadwal', async () => {
    const db = makeDb();
    db.all.mockResolvedValue({ results: [{ id: 1, mapel_nama: 'Matematika' }] });
    const req = makeGet('/api/kepala-sekolah/jadwal');
    const res = await handleJadwalKS(req, db, makeUrl(''));
    expect(res.status).toBe(200);
  });

  it('should return absensi', async () => {
    const db = makeDb();
    db.first.mockResolvedValue({ total: 10 });
    db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A' }] });
    const req = makeGet('/api/kepala-sekolah/absensi');
    const res = await handleAbsensiKS(req, db, makeUrl(''));
    expect(res.status).toBe(200);
  });

  it('should return nilai', async () => {
    const db = makeDb();
    db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A', nilai: 85 }] });
    const req = makeGet('/api/kepala-sekolah/nilai');
    const res = await handleNilaiKS(req, db, makeUrl(''));
    expect(res.status).toBe(200);
  });

  it('should return rapor', async () => {
    const db = makeDb();
    db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A', nilai_akhir: 85 }] });
    const req = makeGet('/api/kepala-sekolah/rapor');
    const res = await handleRaporKS(req, db, makeUrl(''));
    expect(res.status).toBe(200);
  });

  it('should return BK overview', async () => {
    const db = makeDb();
    db.all.mockResolvedValue({ results: [{ kategori: 'perilaku', jumlah: 3 }] });
    const req = makeGet('/api/kepala-sekolah/bk');
    const res = await handleBKKS(req, db, makeUrl(''));
    expect(res.status).toBe(200);
  });
});