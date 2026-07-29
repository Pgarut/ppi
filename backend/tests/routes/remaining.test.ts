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
  it('should list jadwal konseling with pagination', async () => {
    const db = makeDb();
    db.first.mockResolvedValue({ total: 1 });
    db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A', tanggal: '2026-07-27' }] });
    const req = makeGet('/api/guru-bk/jadwal-konseling');
    const res = await handleKonselingBK(req, db, bkUser, ['api', 'guru-bk', 'jadwal-konseling'], makeUrl(''));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data.items).toHaveLength(1);
    expect(body.data.pagination).toBeDefined();
  });

  it('should return siswa per kelas', async () => {
    const db = makeDb();
    db.all.mockResolvedValue({ results: [{ id: 1, nis: '123', nama: 'Siswa A', kelas_nama: 'X-A' }] });
    const req = makeGet('/api/guru-bk/jadwal-konseling/siswa?kelas_id=1');
    const res = await handleKonselingBK(req, db, bkUser, ['api', 'guru-bk', 'jadwal-konseling', 'siswa'], makeUrl('/api/guru-bk/jadwal-konseling/siswa', 'kelas_id=1'));
    expect(res.status).toBe(200);
  });

  it('should return history konseling with pagination', async () => {
    const db = makeDb();
    db.first.mockResolvedValue({ total: 2 });
    db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A', catatan: 'Test' }] });
    const req = makeGet('/api/guru-bk/jadwal-konseling/history');
    const res = await handleKonselingBK(req, db, bkUser, ['api', 'guru-bk', 'jadwal-konseling', 'history'], makeUrl(''));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data.items).toHaveLength(1);
  });

  it('should create jadwal konseling with optional catatan', async () => {
    const db = makeDb();
    const req = makePost('/api/guru-bk/jadwal-konseling', { siswa_id: 1, tanggal: '2026-07-28', jam: '09:00', jenis: 'individu', catatan: 'Tes awal' });
    const res = await handleKonselingBK(req, db, bkUser, ['api', 'guru-bk', 'jadwal-konseling'], makeUrl(''));
    expect(res.status).toBe(201);
  });

  it('should reject invalid jenis konseling', async () => {
    const db = makeDb();
    db.run.mockResolvedValue({ meta: { last_row_id: 1, changes: 1 } });
    const req = makePost('/api/guru-bk/jadwal-konseling', { siswa_id: 1, tanggal: '2026-07-28', jenis: 'konsultasi' });
    const res = await handleKonselingBK(req, db, bkUser, ['api', 'guru-bk', 'jadwal-konseling'], makeUrl(''));
    expect(res.status).toBe(400);
  });

  it('should list konseling sessions with pagination', async () => {
    const db = makeDb();
    db.first.mockResolvedValue({ total: 1 });
    db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A', catatan: 'Tes' }] });
    const req = makeGet('/api/guru-bk/konseling');
    const res = await handleKonselingBK(req, db, bkUser, ['api', 'guru-bk', 'konseling'], makeUrl(''));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data.items).toHaveLength(1);
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
  it('should return monitoring absensi per student', async () => {
    const db = makeDb();
    db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A', hadir: 20, izin: 1, sakit: 2, alpa: 0 }] });
    const req = makeGet('/api/guru-bk/monitoring/absensi');
    const res = await handleMonitoringBK(req, db, makeUrl('/api/guru-bk/monitoring/absensi'));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data[0].hadir).toBe(20);
  });

  it('should return monitoring absensi filtered by kelas', async () => {
    const db = makeDb();
    db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A', hadir: 15 }] });
    const req = makeGet('/api/guru-bk/monitoring/absensi?kelas_id=1');
    const res = await handleMonitoringBK(req, db, makeUrl('/api/guru-bk/monitoring/absensi', 'kelas_id=1'));
    expect(res.status).toBe(200);
  });

  it('should return monitoring pelanggaran per student', async () => {
    const db = makeDb();
    db.all.mockResolvedValue({ results: [{ siswa_id: 1, siswa_nama: 'Siswa A', total_pelanggaran: 3, terakhir_dilaporkan: '2026-07-27' }] });
    const req = makeGet('/api/guru-bk/monitoring/pelanggaran');
    const res = await handleMonitoringBK(req, db, makeUrl('/api/guru-bk/monitoring/pelanggaran'));
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.data[0].total_pelanggaran).toBe(3);
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