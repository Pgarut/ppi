import { Env } from '../../types';
import { success } from '../../utils/response';

export async function handleDashboardKS(env: Env): Promise<Response> {
  const [totalSiswa, totalGuru, totalKelas, totalMapel,
    jadwalPerHari, absensiRekap, nilaiDistribusi] = await Promise.all([
    env.DB.prepare("SELECT COUNT(*) as total FROM siswa WHERE status = 'aktif'").first<{ total: number }>(),
    env.DB.prepare('SELECT COUNT(*) as total FROM guru WHERE status_aktif = 1').first<{ total: number }>(),
    env.DB.prepare('SELECT COUNT(*) as total FROM kelas').first<{ total: number }>(),
    env.DB.prepare('SELECT COUNT(*) as total FROM mata_pelajaran').first<{ total: number }>(),

    env.DB.prepare(
      `SELECT hari, COUNT(*) as jumlah FROM jadwal_pelajaran
       WHERE status_validasi = 'tervalidasi'
       GROUP BY hari ORDER BY CASE hari
         WHEN 'Sabtu' THEN 1 WHEN 'Minggu' THEN 2 WHEN 'Senin' THEN 3
         WHEN 'Selasa' THEN 4 WHEN 'Rabu' THEN 5 WHEN 'Kamis' THEN 6
         ELSE 7 END`
    ).all<{ hari: string; jumlah: number }>(),

    env.DB.prepare(
      'SELECT status, COUNT(*) as jumlah FROM absensi_siswa GROUP BY status'
    ).all<{ status: string; jumlah: number }>(),

    env.DB.prepare(
      'SELECT jenis, COUNT(*) as jumlah, ROUND(AVG(nilai), 2) as rata_rata FROM nilai GROUP BY jenis'
    ).all<{ jenis: string; jumlah: number; rata_rata: number }>(),
  ]);

  return success({
    statistik: {
      total_siswa: totalSiswa?.total || 0,
      total_guru: totalGuru?.total || 0,
      total_kelas: totalKelas?.total || 0,
      total_mapel: totalMapel?.total || 0,
    },
    jadwal_per_hari: jadwalPerHari.results,
    absensi_rekap: absensiRekap.results,
    nilai_distribusi: nilaiDistribusi.results,
  });
}
