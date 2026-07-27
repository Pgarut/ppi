import { describe, it, expect, vi } from 'vitest';
import { handleAbsensiGuru } from '../../src/routes/guru_mapel_wali_kelas/absensi';
import { handleNilaiGuru } from '../../src/routes/guru_mapel_wali_kelas/nilai';
import { handleRaporGuru } from '../../src/routes/guru_mapel_wali_kelas/rapor';
import { handlePengaduan } from '../../src/routes/guru_mapel_wali_kelas/pengaduan';
import { handleWaliKelas } from '../../src/routes/guru_mapel_wali_kelas/wali_kelas';
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

const guruUser: UserPayload = { sub: 3, username: 'guru', role: 'guru_mapel_wali_kelas', guru_id: 5 };

function makeUrl(path: string, search = ''): URL {
  return new URL(`http://localhost${path}${search ? '?' + search : ''}`);
}
function makeGet(path: string, search?: string): Request {
  return new Request(makeUrl(path, search), { method: 'GET' });
}
function makePost(path: string, body: unknown): Request {
  return new Request(makeUrl(path), { method: 'POST', body: JSON.stringify(body), headers: { 'Content-Type': 'application/json' } });
}
function makePut(path: string, body: unknown): Request {
  return new Request(makeUrl(path), { method: 'PUT', body: JSON.stringify(body), headers: { 'Content-Type': 'application/json' } });
}

describe('Guru Mapel / Wali Kelas Routes', () => {
  describe('Absensi', () => {
    it('should list riwayat absensi guru', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ total: 5 });
      db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A', status: 'hadir' }] });
      const req = makeGet('/api/guru/absensi');
      const res = await handleAbsensiGuru(req, db, guruUser, ['api', 'guru', 'absensi'], makeUrl(''));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.items).toHaveLength(1);
    });

    it('should input absensi massal', async () => {
      const db = makeDb();
      db.first.mockResolvedValue(null);
      const req = makePost('/api/guru/absensi', { kelas_id: 1, tanggal: '2026-07-27', entries: [{ siswa_id: 1, status: 'hadir' }, { siswa_id: 2, status: 'sakit' }] });
      const res = await handleAbsensiGuru(req, db, guruUser, ['api', 'guru', 'absensi'], makeUrl(''));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.inserted).toBe(2);
    });

    it('should upsert existing absensi', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1 });
      const req = makePost('/api/guru/absensi', { kelas_id: 1, tanggal: '2026-07-27', entries: [{ siswa_id: 1, status: 'alfa' }] });
      const res = await handleAbsensiGuru(req, db, guruUser, ['api', 'guru', 'absensi'], makeUrl(''));
      expect(res.status).toBe(200);
    });

    it('should get siswa per kelas for absensi form', async () => {
      const db = makeDb();
      db.all
        .mockResolvedValueOnce({ results: [{ id: 1, nis: '123', nama: 'Siswa A' }] })
        .mockResolvedValueOnce({ results: [] });
      const req = makeGet('/api/guru/siswa-per-kelas?kelas_id=1');
      const res = await handleAbsensiGuru(req, db, guruUser, ['api', 'guru', 'siswa-per-kelas'], makeUrl('/api/guru/siswa-per-kelas', 'kelas_id=1'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.siswa).toHaveLength(1);
    });
  });

  describe('Nilai', () => {
    it('should list nilai guru', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ total: 3 });
      db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A', nilai: 85 }] });
      const req = makeGet('/api/guru/nilai');
      const res = await handleNilaiGuru(req, db, guruUser, ['api', 'guru', 'nilai'], makeUrl(''));
      expect(res.status).toBe(200);
    });

    it('should input nilai', async () => {
      const db = makeDb();
      const req = makePost('/api/guru/nilai', { siswa_id: 1, mata_pelajaran_id: 1, kelas_id: 1, semester_id: 1, jenis: 'harian', nilai: 85 });
      const res = await handleNilaiGuru(req, db, guruUser, ['api', 'guru', 'nilai'], makeUrl(''));
      expect(res.status).toBe(201);
    });

    it('should reject invalid jenis nilai', async () => {
      const db = makeDb();
      const req = makePost('/api/guru/nilai', { siswa_id: 1, mata_pelajaran_id: 1, kelas_id: 1, semester_id: 1, jenis: 'invalid', nilai: 85 });
      const res = await handleNilaiGuru(req, db, guruUser, ['api', 'guru', 'nilai'], makeUrl(''));
      expect(res.status).toBe(400);
    });

    it('should update own nilai', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1, diinput_oleh: 5 });
      const req = makePut('/api/guru/nilai/1', { nilai: 90 });
      const res = await handleNilaiGuru(req, db, guruUser, ['api', 'guru', 'nilai', '1'], makeUrl(''));
      expect(res.status).toBe(200);
    });

    it('should reject update of other teacher nilai', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1, diinput_oleh: 99 });
      const req = makePut('/api/guru/nilai/1', { nilai: 90 });
      const res = await handleNilaiGuru(req, db, guruUser, ['api', 'guru', 'nilai', '1'], makeUrl(''));
      expect(res.status).toBe(400);
    });

    it('should get siswa per kelas for nilai form', async () => {
      const db = makeDb();
      db.all
        .mockResolvedValueOnce({ results: [{ id: 1, nis: '123', nama: 'Siswa A' }] })
        .mockResolvedValueOnce({ results: [] });
      const req = makeGet('/api/guru/siswa-per-kelas?kelas_id=1&mata_pelajaran_id=1&semester_id=1');
      const res = await handleNilaiGuru(req, db, guruUser, ['api', 'guru', 'siswa-per-kelas'], makeUrl('/api/guru/siswa-per-kelas', 'kelas_id=1&mata_pelajaran_id=1&semester_id=1'));
      expect(res.status).toBe(200);
    });

    it('should input nilai massal', async () => {
      const db = makeDb();
      db.first.mockResolvedValue(null);
      const req = makePost('/api/guru/nilai-massal', { kelas_id: 1, mata_pelajaran_id: 1, semester_id: 1, jenis: 'harian', entries: [{ siswa_id: 1, nilai: 85 }, { siswa_id: 2, nilai: 90 }] });
      const res = await handleNilaiGuru(req, db, guruUser, ['api', 'guru', 'nilai-massal'], makeUrl(''));
      expect(res.status).toBe(200);
    });
  });

  describe('Rapor', () => {
    it('should get rapor', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A', nilai_akhir: 85 }] });
      const req = makeGet('/api/guru/rapor?siswa_id=1');
      const res = await handleRaporGuru(req, db, guruUser, ['api', 'guru', 'rapor'], makeUrl('/api/guru/rapor', 'siswa_id=1'));
      expect(res.status).toBe(200);
    });

    it('should create rapor', async () => {
      const db = makeDb();
      db.first.mockResolvedValue(null);
      const req = makePost('/api/guru/rapor', { siswa_id: 1, kelas_id: 1, semester_id: 1, mata_pelajaran_id: 1, nilai_akhir: 85, predikat: 'A' });
      const res = await handleRaporGuru(req, db, guruUser, ['api', 'guru', 'rapor'], makeUrl(''));
      expect(res.status).toBe(201);
    });

    it('should update existing rapor', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1 });
      const req = makePost('/api/guru/rapor', { siswa_id: 1, kelas_id: 1, semester_id: 1, mata_pelajaran_id: 1, nilai_akhir: 90 });
      const res = await handleRaporGuru(req, db, guruUser, ['api', 'guru', 'rapor'], makeUrl(''));
      expect(res.status).toBe(200);
    });
  });

  describe('Pengaduan', () => {
    it('should list own pengaduan', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ total: 2 });
      db.all.mockResolvedValue({ results: [{ id: 1, kategori: 'perilaku', status: 'baru' }] });
      const req = makeGet('/api/guru/pengaduan');
      const res = await handlePengaduan(req, db, guruUser, ['api', 'guru', 'pengaduan'], makeUrl(''));
      expect(res.status).toBe(200);
    });

    it('should create pengaduan', async () => {
      const db = makeDb();
      const req = makePost('/api/guru/pengaduan', { siswa_id: 1, kategori: 'perilaku', deskripsi: 'Terlambat' });
      const res = await handlePengaduan(req, db, guruUser, ['api', 'guru', 'pengaduan'], makeUrl(''));
      expect(res.status).toBe(201);
    });

    it('should reject invalid kategori', async () => {
      const db = makeDb();
      const req = makePost('/api/guru/pengaduan', { siswa_id: 1, kategori: 'invalid', deskripsi: 'Test' });
      const res = await handlePengaduan(req, db, guruUser, ['api', 'guru', 'pengaduan'], makeUrl(''));
      expect(res.status).toBe(400);
    });
  });

  describe('Wali Kelas', () => {
    it('should return wali kelas info when user is wali kelas', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1, nama: 'X-A' });
      db.all.mockResolvedValue({ results: [{ id: 1, nama: 'Siswa A' }] });
      const req = makeGet('/api/guru/data-siswa');
      const res = await handleWaliKelas(req, db, guruUser, ['api', 'guru', 'data-siswa'], makeUrl(''));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.kelas.nama).toBe('X-A');
      expect(body.data.siswa).toHaveLength(1);
    });

    it('should handle non-wali kelas user gracefully', async () => {
      const db = makeDb();
      db.first.mockResolvedValue(null);
      const req = makeGet('/api/guru/data-siswa');
      const nonWaliUser: UserPayload = { ...guruUser, sub: 6 };
      const res = await handleWaliKelas(req, db, nonWaliUser, ['api', 'guru', 'data-siswa'], makeUrl(''));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.wali_kelas).toBeNull();
    });

    it('should return rekap absensi wali kelas', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1, nama: 'X-A' });
      db.all.mockResolvedValue({ results: [{ status: 'hadir', jumlah: 20 }] });
      const req = makeGet('/api/guru/rekap-absensi');
      const res = await handleWaliKelas(req, db, guruUser, ['api', 'guru', 'rekap-absensi'], makeUrl(''));
      expect(res.status).toBe(200);
    });

    it('should update catatan wali kelas', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1, nama: 'X-A' });
      const req = makePut('/api/guru/catatan-wali', { siswa_id: 1, semester_id: 1, catatan: 'Baik' });
      const res = await handleWaliKelas(req, db, guruUser, ['api', 'guru', 'catatan-wali'], makeUrl(''));
      expect(res.status).toBe(200);
    });
  });
});