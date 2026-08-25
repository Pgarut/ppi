import { Env } from '../../types';
import { success, error } from '../../utils/response';

// ============================================================
// PUBLIC DISPLAY (Kiosk) - Papan Absensi Asatidz Live
//
// Endpoint publik TANPA login, khusus untuk monitor/TV di pintu
// masuk yang menampilkan QR + daftar hadir secara live.
// Read-only: hanya nama + jam, tanpa data sensitif.
// Dilindungi general rate limit (100 req/menit/IP) di index.ts.
// ============================================================

const WIB_MS = 7 * 60 * 60 * 1000;

export async function handlePublicDisplay(
  request: Request,
  env: Env,
  pathParts: string[]
): Promise<Response> {
  if (request.method !== 'GET') return error('Method tidak didukung', 405);

  const subPath = pathParts.slice(2).join('/'); // /api/public/...

  if (subPath === 'absensi-hari-ini') {
    return getAbsensiHariIni(env);
  }

  return error('Endpoint tidak dikenal', 404);
}

async function getAbsensiHariIni(env: Env): Promise<Response> {
  const today = new Date(Date.now() + WIB_MS).toISOString().split('T')[0];

  const [absensiRows, totalGuruRow] = await Promise.all([
    env.DB.prepare(`
      SELECT g.nama, a.jam_masuk, a.jam_keluar
      FROM absensi_guru a
      JOIN guru g ON a.guru_id = g.id
      WHERE a.tanggal = ? AND a.jam_masuk IS NOT NULL
      ORDER BY a.jam_masuk DESC
    `).bind(today).all<{ nama: string; jam_masuk: string; jam_keluar: string | null }>(),
    env.DB.prepare(
      'SELECT COUNT(*) as total FROM guru WHERE status_aktif = 1'
    ).first<{ total: number }>(),
  ]);

  const items = absensiRows.results;
  const totalAsatidz = totalGuruRow?.total ?? 0;
  const hadir = items.length;
  const sudahKeluar = items.filter((i) => i.jam_keluar !== null).length;

  return success({
    tanggal: today,
    items,
    statistik: {
      total_asatidz: totalAsatidz,
      hadir,
      sudah_keluar: sudahKeluar,
      belum_hadir: Math.max(0, totalAsatidz - hadir),
    },
  });
}
