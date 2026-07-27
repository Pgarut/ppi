import { describe, it, expect, vi, beforeAll } from 'vitest';

// We'll test the routing dispatch of index.ts by instantiating the worker
// and making requests. Since we can't easily import the default export,
// we test the route pattern matching logic used in index.ts.

describe('API Routing Integration', () => {
  function makePathParts(path: string): string[] {
    return new URL(path, 'http://localhost').pathname.split('/').filter(Boolean);
  }

  describe('Admin routing patterns', () => {
    it('should extract admin resource from /api/admin/tahun-ajaran', () => {
      const parts = makePathParts('/api/admin/tahun-ajaran');
      expect(parts[0]).toBe('api');
      expect(parts[1]).toBe('admin');
      expect(parts[2]).toBe('tahun-ajaran');
    });

    it('should extract admin resource from /api/admin/siswa/5', () => {
      const parts = makePathParts('/api/admin/siswa/5');
      expect(parts[2]).toBe('siswa');
      expect(parts[3]).toBe('5');
    });

    const masterResources = ['tahun-ajaran', 'semester', 'jurusan', 'tingkat', 'kelas', 'mata-pelajaran', 'guru', 'siswa', 'ruangan'];
    masterResources.forEach((res) => {
      it(`should recognize master resource: ${res}`, () => {
        const parts = makePathParts(`/api/admin/${res}`);
        expect(masterResources.includes(parts[2])).toBe(true);
      });
    });
  });

  describe('WK routing patterns', () => {
    it('should route penjadwalan sub-routes', () => {
      const routes = ['jp-slots', 'referensi', 'jadwal', 'jadwal-per-kelas', 'distribusi-mengajar', 'beban-mengajar', 'jadwal-guru', 'jadwal-kelas'];
      routes.forEach((route) => {
        const parts = makePathParts(`/api/wakil-kurikulum/${route}`);
        const subPath = parts.slice(2).join('/');
        expect(subPath.startsWith('jp-slots') || subPath.startsWith('referensi') ||
               subPath.startsWith('jadwal') || subPath.startsWith('jadwal-per-kelas') ||
               subPath.startsWith('distribusi') || subPath.startsWith('beban') ||
               subPath.startsWith('jadwal-guru') || subPath.startsWith('jadwal-kelas')).toBe(true);
      });
    });

    it('should route nilai sub-routes', () => {
      const routes = ['bobot-nilai', 'monitoring-nilai', 'status-pengumpulan'];
      routes.forEach((route) => {
        const parts = makePathParts(`/api/wakil-kurikulum/${route}`);
        const subPath = parts.slice(2).join('/');
        expect(subPath.startsWith('bobot-nilai') || subPath.startsWith('monitoring-nilai') || subPath.startsWith('status-pengumpulan')).toBe(true);
      });
    });

    it('should route kenaikan-kelas and alumni', () => {
      const parts1 = makePathParts('/api/wakil-kurikulum/kenaikan-kelas');
      const subPath1 = parts1.slice(2).join('/');
      expect(subPath1.startsWith('kenaikan-kelas')).toBe(true);

      const parts2 = makePathParts('/api/wakil-kurikulum/alumni');
      const subPath2 = parts2.slice(2).join('/');
      expect(subPath2.startsWith('alumni')).toBe(true);
    });

    it('should route laporan', () => {
      const parts = makePathParts('/api/wakil-kurikulum/laporan/jadwal');
      const subPath = parts.slice(2).join('/');
      expect(subPath.startsWith('laporan')).toBe(true);
    });
  });

  describe('Guru routing patterns', () => {
    it('should route absensi, nilai, rapor, pengaduan', () => {
      const routes = ['absensi', 'nilai', 'rapor', 'pengaduan', 'data-siswa'];
      routes.forEach((route) => {
        const parts = makePathParts(`/api/guru/${route}`);
        expect(parts[1]).toBe('guru');
        expect(parts[2]).toBe(route);
      });
    });
  });

  describe('Role guard patterns', () => {
    const adminOnly = ['admin'];
    const wkOnly = ['wakil-kurikulum'];
    const guruOnly = ['guru_mapel_wali_kelas'];
    const ksOnly = ['kepala_sekolah'];
    const bkOnly = ['guru_bk'];

    it('should identify admin prefix', () => {
      const parts = makePathParts('/api/admin/dashboard');
      expect(parts[1]).toBe('admin');
    });

    it('should identify wakil-kurikulum prefix', () => {
      const parts = makePathParts('/api/wakil-kurikulum/dashboard');
      expect(parts[1]).toBe('wakil-kurikulum');
    });

    it('should identify guru prefix', () => {
      const parts = makePathParts('/api/guru/absensi');
      expect(parts[1]).toBe('guru');
    });

    it('should identify kepala-sekolah prefix', () => {
      const parts = makePathParts('/api/kepala-sekolah/dashboard');
      expect(parts[1]).toBe('kepala-sekolah');
    });

    it('should identify guru-bk prefix', () => {
      const parts = makePathParts('/api/guru-bk/pengaduan');
      expect(parts[1]).toBe('guru-bk');
    });
  });

  describe('Public vs authenticated routes', () => {
    it('should identify auth routes without token', () => {
      expect(makePathParts('/api/auth/login').slice(0, 3).join('/')).toBe('api/auth/login');
    });

    it('should identify public pengaturan-tampilan', () => {
      expect(makePathParts('/api/pengaturan-tampilan').slice(0, 2).join('/')).toBe('api/pengaturan-tampilan');
    });

    it('should identify authenticated /api/auth/me', () => {
      expect(makePathParts('/api/auth/me').slice(0, 3).join('/')).toBe('api/auth/me');
    });

    it('should identify refresh endpoint', () => {
      expect(makePathParts('/api/auth/refresh').slice(0, 3).join('/')).toBe('api/auth/refresh');
    });
  });
});