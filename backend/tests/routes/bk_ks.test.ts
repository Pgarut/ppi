import { describe, it, expect, vi } from 'vitest';
import { handlePengaduanBK } from '../../src/routes/guru_bk/pengaduan';
import { handleLaporanBK } from '../../src/routes/guru_bk/laporan';
import { handleDashboardKS } from '../../src/routes/kepala_sekolah/dashboard';
import { handleLaporanKS } from '../../src/routes/kepala_sekolah/laporan';
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
const ksUser: UserPayload = { sub: 5, username: 'kepsek', role: 'kepala_sekolah', guru_id: null };

function makeUrl(path: string, search = ''): URL {
  return new URL(`http://localhost${path}${search ? '?' + search : ''}`);
}
function makeGet(path: string, search?: string): Request {
  return new Request(makeUrl(path, search), { method: 'GET' });
}
function makePut(path: string, body?: unknown): Request {
  return new Request(makeUrl(path), { method: 'PUT', body: body ? JSON.stringify(body) : undefined, headers: { 'Content-Type': 'application/json' } });
}

describe('Guru BK Routes', () => {
  describe('Pengaduan', () => {
    it('should list all pengaduan', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ total: 3 });
      db.all.mockResolvedValue({ results: [{ id: 1, kategori: 'perilaku', status: 'baru', siswa_nama: 'Siswa A' }] });
      const req = makeGet('/api/guru-bk/pengaduan');
      const res = await handlePengaduanBK(req, db, bkUser, ['api', 'guru-bk', 'pengaduan'], makeUrl(''));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.items).toHaveLength(1);
    });

    it('should filter pengaduan by status', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ total: 1 });
      db.all.mockResolvedValue({ results: [{ id: 1, status: 'baru' }] });
      const req = makeGet('/api/guru-bk/pengaduan?status=baru');
      const res = await handlePengaduanBK(req, db, bkUser, ['api', 'guru-bk', 'pengaduan'], makeUrl('/api/guru-bk/pengaduan', 'status=baru'));
      expect(res.status).toBe(200);
    });

    it('should update status pengaduan with tindak_lanjut', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1 });

      const req = makePut('/api/guru-bk/pengaduan/1', { status: 'diproses', tindak_lanjut: 'Sedang ditangani' });
      const res = await handlePengaduanBK(req, db, bkUser, ['api', 'guru-bk', 'pengaduan', '1'], makeUrl(''));
      expect(res.status).toBe(200);
    });

    it('should reject invalid status', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1 });
      const req = makePut('/api/guru-bk/pengaduan/1', { status: 'invalid' });
      const res = await handlePengaduanBK(req, db, bkUser, ['api', 'guru-bk', 'pengaduan', '1'], makeUrl(''));
      expect(res.status).toBe(400);
    });
  });

  describe('Laporan BK', () => {
    it('should return statistik dashboard', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ total: 10 });
      db.all.mockResolvedValue({ results: [] });
      const req = makeGet('/api/guru-bk/statistik');
      const res = await handleLaporanBK(req, db, bkUser, ['api', 'guru-bk', 'statistik'], makeUrl(''));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data).toHaveProperty('total_pengaduan');
      expect(body.data).toHaveProperty('total_konseling');
    });

    it('should return laporan bulanan', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [{ periode: '2026-07', total: 5 }] });
      const req = makeGet('/api/guru-bk/bulanan?tahun=2026');
      const res = await handleLaporanBK(req, db, bkUser, ['api', 'guru-bk', 'bulanan'], makeUrl('/api/guru-bk/bulanan', 'tahun=2026'));
      expect(res.status).toBe(200);
    });

    it('should return rekap kasus per kategori', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [{ kategori: 'perilaku', total: 5, siswa_terlibat: 3 }] });
      const req = makeGet('/api/guru-bk/rekap-kasus');
      const res = await handleLaporanBK(req, db, bkUser, ['api', 'guru-bk', 'rekap-kasus'], makeUrl(''));
      expect(res.status).toBe(200);
    });
  });
});

describe('Kepala Sekolah Routes', () => {
  describe('Dashboard', () => {
    it('should return statistik sekolah', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ total: 100 });
      db.all.mockResolvedValue({ results: [] });
      const res = await handleDashboardKS(db);
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.statistik).toHaveProperty('total_siswa');
      expect(body.data.statistik).toHaveProperty('total_guru');
      expect(body.data.statistik).toHaveProperty('total_kelas');
      expect(body.data.statistik).toHaveProperty('total_mapel');
      expect(body.data).toHaveProperty('jadwal_per_hari');
      expect(body.data).toHaveProperty('absensi_rekap');
      expect(body.data).toHaveProperty('nilai_distribusi');
    });
  });

  describe('Laporan (5 jenis)', () => {
    const laporanTypes = ['jadwal', 'absensi', 'nilai', 'rapor'];
    laporanTypes.forEach((jenis) => {
      it(`should return laporan ${jenis}`, async () => {
        const db = makeDb();
        db.all.mockResolvedValue({ results: [{ id: 1 }] });
        const url = new URL(`http://localhost/api/kepala-sekolah/laporan?jenis=${jenis}`);
        const req = new Request(url, { method: 'GET' });
        const res = await handleLaporanKS(req, db, url);
        expect(res.status).toBe(200);
        const body = await res.json();
        expect(Array.isArray(body.data)).toBe(true);
      });
    });

    it('should reject unknown laporan type', async () => {
      const db = makeDb();
      const url = new URL('http://localhost/api/kepala-sekolah/laporan?jenis=unknown');
      const req = new Request(url, { method: 'GET' });
      const res = await handleLaporanKS(req, db, url);
      expect(res.status).toBe(400);
    });
  });
});