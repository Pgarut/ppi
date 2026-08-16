import { describe, it, expect, vi } from 'vitest';
import { handlePenjadwalan } from '../../src/routes/wakil_kurikulum/penjadwalan';
import { handleNilaiWK } from '../../src/routes/wakil_kurikulum/nilai';
import { handleAbsensiWK } from '../../src/routes/wakil_kurikulum/absensi';
import { handleKenaikanKelas } from '../../src/routes/wakil_kurikulum/kenaikan_kelas';
import { handleLaporanWK } from '../../src/routes/wakil_kurikulum/laporan';
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

const wkUser: UserPayload = { sub: 2, username: 'wakil', role: 'wakil_kurikulum', guru_id: null };

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
function makeDelete(path: string): Request {
  return new Request(makeUrl(path), { method: 'DELETE' });
}

describe('Wakil Kurikulum Routes', () => {
  describe('Penjadwalan', () => {
    it('should return JP slots', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [] });
      const req = makeGet('/api/wakil-kurikulum/jp-slots');
      const res = await handlePenjadwalan(req, db, wkUser, ['api', 'wakil-kurikulum', 'jp-slots'], makeUrl(''));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(Array.isArray(body.data)).toBe(true);
      expect(body.data.length).toBe(8);
      expect(body.data[0]).toHaveProperty('kode');
    });

    it('should return referensi dropdown data', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [{ id: 1, nama: 'X-A' }] });
      const req = makeGet('/api/wakil-kurikulum/referensi');
      const res = await handlePenjadwalan(req, db, wkUser, ['api', 'wakil-kurikulum', 'referensi'], makeUrl(''));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.kelas).toBeDefined();
      expect(body.data.guru).toBeDefined();
      expect(body.data.mapel).toBeDefined();
    });

    it('should generate jadwal', async () => {
      const db = makeDb();
      // Kesiapan guru
      db.all
        .mockResolvedValueOnce({ results: [{ guru_id: 1, hari_aktif: '["Sabtu","Minggu","Senin","Selasa","Rabu","Kamis"]', jp_max_per_hari: 8, jp_max_per_minggu: 24, guru_nama: 'Guru A' }] })
        // guru_mapel
        .mockResolvedValueOnce({ results: [{ guru_id: 1, mata_pelajaran_id: 1 }] })
        // guru_kelas
        .mockResolvedValueOnce({ results: [{ guru_id: 1, kelas_id: 1 }] })
        // mapel_kelas
        .mockResolvedValueOnce({ results: [{ mata_pelajaran_id: 1, kelas_id: 1 }] })
        // existing validated
        .mockResolvedValueOnce({ results: [] });
      db.run.mockResolvedValue({ meta: { changes: 1 } });
      const req = makePost('/api/wakil-kurikulum/jadwal/generate', { semester_id: 1 });
      const res = await handlePenjadwalan(req, db, wkUser, ['api', 'wakil-kurikulum', 'jadwal', 'generate'], makeUrl(''));
      expect(res.status).toBe(200);
    });

    it('should reset jadwal', async () => {
      const db = makeDb();
      db.run.mockResolvedValue({ meta: { changes: 5 } });
      const req = makePost('/api/wakil-kurikulum/jadwal/reset', { semester_id: 1 });
      const res = await handlePenjadwalan(req, db, wkUser, ['api', 'wakil-kurikulum', 'jadwal', 'reset'], makeUrl(''));
      expect(res.status).toBe(200);
    });

    it('should publish jadwal', async () => {
      const db = makeDb();
      db.run.mockResolvedValue({ meta: { changes: 10 } });
      const req = makePost('/api/wakil-kurikulum/jadwal/publikasi', { semester_id: 1 });
      const res = await handlePenjadwalan(req, db, wkUser, ['api', 'wakil-kurikulum', 'jadwal', 'publikasi'], makeUrl(''));
      expect(res.status).toBe(200);
    });

    it('should get jadwal per kelas', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [{ id: 1, mapel_nama: 'Matematika', hari: 'Senin' }] });
      const req = makeGet('/api/wakil-kurikulum/jadwal-per-kelas?kelas_id=1&semester_id=1');
      const res = await handlePenjadwalan(req, db, wkUser, ['api', 'wakil-kurikulum', 'jadwal-per-kelas'], makeUrl('/api/wakil-kurikulum/jadwal-per-kelas', 'kelas_id=1&semester_id=1'));
      expect(res.status).toBe(200);
    });

    it('should create jadwal', async () => {
      const db = makeDb();
      // validasiGuruMapelKelas: cek guru_mapel_kelas (spesifik)
      db.first.mockResolvedValueOnce({ guru_id: 1, mata_pelajaran_id: 1, kelas_id: 1 });
      // cekBentrok: guru tidak bentrok
      db.first.mockResolvedValueOnce(null);
      // cekBentrok: kelas tidak bentrok
      db.first.mockResolvedValueOnce(null);
      db.run.mockResolvedValue({ meta: { last_row_id: 1 } });
      const req = makePost('/api/wakil-kurikulum/jadwal', { kelas_id: 1, mata_pelajaran_id: 1, guru_id: 1, hari: 'Senin', jam_mulai: '07:00', jam_selesai: '07:45', semester_id: 1 });
      const res = await handlePenjadwalan(req, db, wkUser, ['api', 'wakil-kurikulum', 'jadwal'], makeUrl(''));
      expect(res.status).toBe(201);
    });

    it('should reject bentrok jadwal', async () => {
      const db = makeDb();
      // validasiGuruMapelKelas: cek guru_mapel_kelas (spesifik) - lolos
      db.first.mockResolvedValueOnce({ guru_id: 1, mata_pelajaran_id: 1, kelas_id: 1 });
      // cekBentrok: guru bentrok
      db.first.mockResolvedValueOnce({ kelas_id: 2, kelas_nama: 'X-B' });
      const req = makePost('/api/wakil-kurikulum/jadwal', { kelas_id: 1, mata_pelajaran_id: 1, guru_id: 1, hari: 'Senin', jam_mulai: '07:00', jam_selesai: '07:45', semester_id: 1 });
      const res = await handlePenjadwalan(req, db, wkUser, ['api', 'wakil-kurikulum', 'jadwal'], makeUrl(''));
      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error.message).toContain('BENTROK');
    });

    it('should delete jadwal', async () => {
      const db = makeDb();
      const req = makeDelete('/api/wakil-kurikulum/jadwal/1');
      const res = await handlePenjadwalan(req, db, wkUser, ['api', 'wakil-kurikulum', 'jadwal', '1'], makeUrl(''));
      expect(res.status).toBe(200);
    });

    it('should list kesiapan guru', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [{ id: 1, nama: 'Guru A', nip: '123', hari_aktif: '[]', jp_max_per_hari: 8, jp_max_per_minggu: 24, kelas_diampu: '[]', mapel_diampu: '[]' }] });
      const req = makeGet('/api/wakil-kurikulum/kesiapan?semester_id=1');
      const res = await handlePenjadwalan(req, db, wkUser, ['api', 'wakil-kurikulum', 'kesiapan'], makeUrl('/api/wakil-kurikulum/kesiapan', 'semester_id=1'));
      expect(res.status).toBe(200);
    });

    it('should update kesiapan guru', async () => {
      const db = makeDb();
      db.first.mockResolvedValue(null);
      const req = makePut('/api/wakil-kurikulum/kesiapan/1', { semester_id: 1, hari_aktif: ['Sabtu', 'Senin'], jp_max_per_hari: 8, jp_max_per_minggu: 24 });
      const res = await handlePenjadwalan(req, db, wkUser, ['api', 'wakil-kurikulum', 'kesiapan', '1'], makeUrl(''));
      expect(res.status).toBe(200);
    });

    it('should return beban mengajar', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [{ id: 1, nama: 'Guru A', hari_aktif: '["Sabtu","Senin"]', jp_max_per_hari: 8, jp_max_per_minggu: 24, jp_terisi: 3 }] });
      const req = makeGet('/api/wakil-kurikulum/beban-mengajar?semester_id=1');
      const res = await handlePenjadwalan(req, db, wkUser, ['api', 'wakil-kurikulum', 'beban-mengajar'], makeUrl('/api/wakil-kurikulum/beban-mengajar', 'semester_id=1'));
      expect(res.status).toBe(200);
    });
  });

  describe('Nilai (Bobot & Monitoring)', () => {
    it('should list bobot nilai', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [{ id: 1, harian_persen: 20, uts_persen: 30 }] });
      const req = makeGet('/api/wakil-kurikulum/bobot-nilai');
      const res = await handleNilaiWK(req, db, wkUser, ['api', 'wakil-kurikulum', 'bobot-nilai'], makeUrl(''));
      expect(res.status).toBe(200);
    });

    it('should create bobot nilai with valid total 100%', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1 }); // FK check
      const req = makePost('/api/wakil-kurikulum/bobot-nilai', { tahun_ajaran_id: 1, harian_persen: 20, tugas_persen: 20, uts_persen: 30, uas_persen: 30 });
      const res = await handleNilaiWK(req, db, wkUser, ['api', 'wakil-kurikulum', 'bobot-nilai'], makeUrl(''));
      expect(res.status).toBe(201);
    });

    it('should reject bobot nilai not 100%', async () => {
      const db = makeDb();
      const req = makePost('/api/wakil-kurikulum/bobot-nilai', { tahun_ajaran_id: 1, harian_persen: 10, tugas_persen: 10, uts_persen: 10, uas_persen: 10 });
      const res = await handleNilaiWK(req, db, wkUser, ['api', 'wakil-kurikulum', 'bobot-nilai'], makeUrl(''));
      expect(res.status).toBe(400);
    });

    it('should get monitoring nilai', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A', nilai: 85 }] });
      const req = makeGet('/api/wakil-kurikulum/monitoring-nilai');
      const res = await handleNilaiWK(req, db, wkUser, ['api', 'wakil-kurikulum', 'monitoring-nilai'], makeUrl(''));
      expect(res.status).toBe(200);
    });

    it('should get status pengumpulan', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [{ guru_id: 1, guru_nama: 'Guru A', total_input: 50 }] });
      const req = makeGet('/api/wakil-kurikulum/status-pengumpulan');
      const res = await handleNilaiWK(req, db, wkUser, ['api', 'wakil-kurikulum', 'status-pengumpulan'], makeUrl(''));
      expect(res.status).toBe(200);
    });
  });

  describe('Absensi Monitoring', () => {
    it('should list absensi', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ total: 3 });
      db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A' }] });
      const req = makeGet('/api/wakil-kurikulum/absensi');
      const res = await handleAbsensiWK(req, db, makeUrl('/api/wakil-kurikulum/absensi'));
      expect(res.status).toBe(200);
    });
  });

  describe('Kenaikan Kelas & Alumni', () => {
    it('should list kenaikan kelas', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Siswa A', status: 'naik' }] });
      const req = makeGet('/api/wakil-kurikulum/kenaikan-kelas');
      const res = await handleKenaikanKelas(req, db, wkUser, ['api', 'wakil-kurikulum', 'kenaikan-kelas'], makeUrl(''));
      expect(res.status).toBe(200);
    });

    it('should get calon kenaikan', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [{ id: 1, nis: '123', nama: 'Siswa A' }] });
      const req = makeGet('/api/wakil-kurikulum/kenaikan-kelas/calon?kelas_id=1&tahun_ajaran_id=1');
      const res = await handleKenaikanKelas(req, db, wkUser, ['api', 'wakil-kurikulum', 'kenaikan-kelas', 'calon'], makeUrl('/api/wakil-kurikulum/kenaikan-kelas/calon', 'kelas_id=1&tahun_ajaran_id=1'));
      expect(res.status).toBe(200);
    });

    it('should proses kenaikan kelas', async () => {
      const db = makeDb();
      // 1. FK check tahun_ajaran → exists
      // 2. existing process check → none
      db.first
        .mockResolvedValueOnce({ id: 1 })   // taExist FK check
        .mockResolvedValueOnce(null)          // existingProcess check
        .mockResolvedValueOnce({ tahun_ajaran_id: 1 }); // kelasTujuan
      const req = makePost('/api/wakil-kurikulum/kenaikan-kelas/proses', { siswa_id: 1, dari_kelas_id: 1, ke_kelas_id: 2, status: 'naik', tahun_ajaran_id: 1 });
      const res = await handleKenaikanKelas(req, db, wkUser, ['api', 'wakil-kurikulum', 'kenaikan-kelas', 'proses'], makeUrl(''));
      expect(res.status).toBe(201);
    });

    it('should reject invalid status kenaikan', async () => {
      const db = makeDb();
      const req = makePost('/api/wakil-kurikulum/kenaikan-kelas/proses', { siswa_id: 1, dari_kelas_id: 1, status: 'invalid', tahun_ajaran_id: 1 });
      const res = await handleKenaikanKelas(req, db, wkUser, ['api', 'wakil-kurikulum', 'kenaikan-kelas', 'proses'], makeUrl(''));
      expect(res.status).toBe(400);
    });

    it('should list alumni', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({ results: [{ id: 1, siswa_nama: 'Alumni A', tahun_lulus: 2026 }] });
      const req = makeGet('/api/wakil-kurikulum/alumni');
      const res = await handleKenaikanKelas(req, db, wkUser, ['api', 'wakil-kurikulum', 'alumni'], makeUrl(''));
      expect(res.status).toBe(200);
    });

    it('should create alumni', async () => {
      const db = makeDb();
      const req = makePost('/api/wakil-kurikulum/alumni', { siswa_id: 1, tahun_lulus: 2026 });
      const res = await handleKenaikanKelas(req, db, wkUser, ['api', 'wakil-kurikulum', 'alumni'], makeUrl(''));
      expect(res.status).toBe(201);
    });
  });

  describe('Laporan (4 jenis)', () => {
    ['jadwal', 'absensi', 'nilai', 'rapor'].forEach((jenis) => {
      it(`should return laporan ${jenis}`, async () => {
        const db = makeDb();
        db.all.mockResolvedValue({ results: [{ id: 1 }] });
        const req = makeGet(`/api/wakil-kurikulum/laporan/${jenis}`);
        const res = await handleLaporanWK(req, db, wkUser, ['api', 'wakil-kurikulum', 'laporan', jenis], makeUrl(''));
        expect(res.status).toBe(200);
        const body = await res.json();
        expect(Array.isArray(body.data)).toBe(true);
      });
    });

    it('should reject unknown laporan type', async () => {
      const db = makeDb();
      const req = makeGet('/api/wakil-kurikulum/laporan/unknown');
      const res = await handleLaporanWK(req, db, wkUser, ['api', 'wakil-kurikulum', 'laporan', 'unknown'], makeUrl(''));
      expect(res.status).toBe(400);
    });
  });
});