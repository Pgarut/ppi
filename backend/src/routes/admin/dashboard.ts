import { Env } from '../../types';
import { success } from '../../utils/response';

export async function handleDashboard(env: Env): Promise<Response> {
  const [guruResult, siswaResult, kelasResult, absenHariIni, nilaiResult, jadwalResult] = await Promise.all([
    env.DB.prepare('SELECT COUNT(*) as total FROM guru WHERE status_aktif = 1').first<{ total: number }>(),
    env.DB.prepare("SELECT COUNT(*) as total FROM siswa WHERE status = 'aktif'").first<{ total: number }>(),
    env.DB.prepare('SELECT COUNT(*) as total FROM kelas').first<{ total: number }>(),
    env.DB.prepare(
      "SELECT COUNT(*) as total FROM absensi_siswa WHERE tanggal = date('now')"
    ).first<{ total: number }>(),
    env.DB.prepare('SELECT COUNT(*) as total FROM nilai').first<{ total: number }>(),
    env.DB.prepare('SELECT COUNT(*) as total FROM jadwal_pelajaran').first<{ total: number }>(),
  ]);

  const [guruDetail, siswaDetail, absensiDetail, nilaiDetail] = await Promise.all([
    env.DB.prepare(
      "SELECT jabatan, COUNT(*) as count FROM guru WHERE status_aktif = 1 GROUP BY jabatan"
    ).all<{ jabatan: string; count: number }>(),
    env.DB.prepare(
      "SELECT status, COUNT(*) as count FROM siswa GROUP BY status"
    ).all<{ status: string; count: number }>(),
    env.DB.prepare(
      "SELECT status, COUNT(*) as count FROM absensi_siswa WHERE tanggal = date('now') GROUP BY status"
    ).all<{ status: string; count: number }>(),
    env.DB.prepare(
      "SELECT status_validasi, COUNT(*) as count FROM nilai GROUP BY status_validasi"
    ).all<{ status_validasi: string; count: number }>(),
  ]);

  return success({
    ringkasan: {
      guru: guruResult?.total || 0,
      siswa: siswaResult?.total || 0,
      kelas: kelasResult?.total || 0,
      absensi_hari_ini: absenHariIni?.total || 0,
      nilai: nilaiResult?.total || 0,
      jadwal: jadwalResult?.total || 0,
    },
    detail: {
      guru: guruDetail.results.reduce((acc, r) => ({ ...acc, [r.jabatan]: r.count }), {} as Record<string, number>),
      siswa: siswaDetail.results.reduce((acc, r) => ({ ...acc, [r.status]: r.count }), {} as Record<string, number>),
      absensi: absensiDetail.results.reduce((acc, r) => ({ ...acc, [r.status]: r.count }), {} as Record<string, number>),
      nilai: nilaiDetail.results.reduce((acc, r) => ({ ...acc, [r.status_validasi]: r.count }), {} as Record<string, number>),
    },
  });
}
