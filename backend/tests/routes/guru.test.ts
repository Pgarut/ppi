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
      const req = makeGet('/api/guru/absensi/siswa-per-kelas?kelas_id=1');
      const res = await handleAbsensiGuru(req, db, guruUser, ['api', 'guru', 'absensi', 'siswa-per-kelas'], makeUrl('/api/guru/absensi/siswa-per-kelas', 'kelas_id=1'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.siswa).toHaveLength(1);
    });
  });

  describe('Nilai', () => {
    it('should return assignments for nilai dropdown', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1, nama: 'Semester 1' });
      db.all.mockResolvedValue({ results: [{ mata_pelajaran_id: 1, mapel_nama: 'Matematika', kelas_id: 1, kelas_nama: '7A' }] });
      const req = makeGet('/api/guru/nilai/assignments');
      const res = await handleNilaiGuru(req, db, guruUser, ['api', 'guru', 'nilai', 'assignments'], makeUrl('/api/guru/nilai/assignments'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data).toHaveLength(1);
    });

    it('should return active semester with jenis list', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1, nama: 'Semester 1' });
      const req = makeGet('/api/guru/nilai/semester-aktif');
      const res = await handleNilaiGuru(req, db, guruUser, ['api', 'guru', 'nilai', 'semester-aktif'], makeUrl('/api/guru/nilai/semester-aktif'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.jenis_list).toEqual(['harian', 'pts1', 'pas']);
    });

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
      db.first.mockResolvedValueOnce({ nama: 'Semester 1' });
      const req = makePost('/api/guru/nilai', { siswa_id: 1, mata_pelajaran_id: 1, kelas_id: 1, semester_id: 1, jenis: 'harian', nilai: 85 });
      const res = await handleNilaiGuru(req, db, guruUser, ['api', 'guru', 'nilai'], makeUrl(''));
      expect(res.status).toBe(201);
    });

    it('should reject invalid jenis nilai for semester', async () => {
      const db = makeDb();
      db.first.mockResolvedValueOnce({ nama: 'Semester 1' });
      const req = makePost('/api/guru/nilai', { siswa_id: 1, mata_pelajaran_id: 1, kelas_id: 1, semester_id: 1, jenis: 'pts2', nilai: 85 });
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
      const req = makeGet('/api/guru/nilai/siswa-per-kelas?kelas_id=1&mata_pelajaran_id=1&semester_id=1');
      const res = await handleNilaiGuru(req, db, guruUser, ['api', 'guru', 'nilai', 'siswa-per-kelas'], makeUrl('/api/guru/nilai/siswa-per-kelas', 'kelas_id=1&mata_pelajaran_id=1&semester_id=1'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.siswa).toHaveLength(1);
    });

    it('should input nilai massal', async () => {
      const db = makeDb();
      db.first
        .mockResolvedValueOnce({ nama: 'Semester 1' })
        .mockResolvedValueOnce(null);
      const req = makePost('/api/guru/nilai/nilai-massal', { kelas_id: 1, mata_pelajaran_id: 1, semester_id: 1, jenis: 'harian', entries: [{ siswa_id: 1, nilai: 85 }, { siswa_id: 2, nilai: 90 }] });
      const res = await handleNilaiGuru(req, db, guruUser, ['api', 'guru', 'nilai', 'nilai-massal'], makeUrl(''));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.inserted).toBe(2);
    });
  });

  describe('Rapor', () => {
    it('should reject non-wali-kelas user', async () => {
      const db = makeDb();
      db.first.mockResolvedValue(null);
      const req = makeGet('/api/guru/rapor');
      const res = await handleRaporGuru(req, db, guruUser, ['api', 'guru', 'rapor'], makeUrl(''));
      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error.message).toContain('Hanya wali kelas');
    });

    it('should check wali kelas status', async () => {
      const db = makeDb();
      db.first.mockResolvedValue({ id: 1, nama: '7A' });
      const req = makeGet('/api/guru/rapor/cek-wali');
      const res = await handleRaporGuru(req, db, guruUser, ['api', 'guru', 'rapor', 'cek-wali'], makeUrl('/api/guru/rapor/cek-wali'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.is_wali_kelas).toBe(true);
    });

    it('should get rapor when wali kelas (aggregate from nilai)', async () => {
      const db = makeDb();
      db.first
        .mockResolvedValueOnce({ id: 1, nama: '7A' })             // getWaliKelas
        .mockResolvedValueOnce({ id: 1, nis: '123', nisn: null, nama: 'Siswa A', kelas_id: 1 }) // siswa
        .mockResolvedValueOnce({ id: 1, nama: 'Semester 1', tahun_ajaran_id: 1 }) // semester
        .mockResolvedValueOnce(null);                              // catatan wali (null)
      db.all
        .mockResolvedValueOnce({ results: [] })                    // bobot_nilai (kosong → default 40/30/30)
        .mockResolvedValueOnce({
          results: [
            { mata_pelajaran_id: 1, mapel_nama: 'Matematika', mapel_kode: 'MTK', jenis: 'harian', nilai: 80 },
            { mata_pelajaran_id: 1, mapel_nama: 'Matematika', mapel_kode: 'MTK', jenis: 'harian', nilai: 90 },
            { mata_pelajaran_id: 1, mapel_nama: 'Matematika', mapel_kode: 'MTK', jenis: 'pas', nilai: 85 },
            { mata_pelajaran_id: 2, mapel_nama: 'IPA', mapel_kode: 'IPA', jenis: 'harian', nilai: 78 },
            { mata_pelajaran_id: 2, mapel_nama: 'IPA', mapel_kode: 'IPA', jenis: 'pas', nilai: 82 },
          ],
        });
      const req = makeGet('/api/guru/rapor?siswa_id=1&semester_id=1');
      const res = await handleRaporGuru(req, db, guruUser, ['api', 'guru', 'rapor'], makeUrl('/api/guru/rapor', 'siswa_id=1&semester_id=1'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data.siswa).toBeDefined();
      expect(body.data.semester).toBeDefined();
      expect(body.data.mapel).toHaveLength(2);
      // Bobot default: harian+tugas=40, uts=30, uas=30 (tidak ada PTS di data test)
      // Matematika: harian [80,90] → rata 85, pas=85, akhir=(85*40+85*30)/70=85
      expect(body.data.mapel[0].nilai_akhir).toBe(85);
      // IPA: harian [78] → rata 78, pas=82, akhir=(78*40+82*30)/70=79.7
      expect(body.data.mapel[1].nilai_akhir).toBe(79.7);
    });

    it('should reject rapor without siswa_id or semester_id', async () => {
      const db = makeDb();
      db.first
        .mockResolvedValueOnce({ id: 1, nama: '7A' });             // getWaliKelas
      const req = makeGet('/api/guru/rapor');
      const res = await handleRaporGuru(req, db, guruUser, ['api', 'guru', 'rapor'], makeUrl(''));
      expect(res.status).toBe(400);
    });

    it('should return semester list', async () => {
      const db = makeDb();
      db.all.mockResolvedValue({
        results: [
          { id: 1, nama: 'Semester 1', tahun_ajaran: '2025/2026' },
          { id: 2, nama: 'Semester 2', tahun_ajaran: '2025/2026' },
        ],
      });
      const req = makeGet('/api/guru/rapor/semester');
      const res = await handleRaporGuru(req, db, guruUser, ['api', 'guru', 'rapor', 'semester'], makeUrl('/api/guru/rapor/semester'));
      expect(res.status).toBe(200);
      const body = await res.json();
      expect(body.data).toHaveLength(2);
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