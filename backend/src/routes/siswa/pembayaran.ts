import { Env, UserPayload } from '../../types';
import { success, error } from '../../utils/response';

function formatPeriodeLabel(periode: string | null): string {
  if (!periode) return '-';
  try {
    const [year, month] = periode.split('-');
    const monthNames = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    const monthNum = parseInt(month, 10);
    return `${monthNames[monthNum] || month} ${year}`;
  } catch {
    return periode;
  }
}

export async function handleSiswaPembayaran(
  env: Env,
  user: UserPayload,
  url: URL
): Promise<Response> {
  const siswaId = user.siswa_id;
  if (!siswaId) return error('Data santri tidak ditemukan', 404);

  // Get all payments for this santri, ordered by jenis + periode desc
  const rows = await env.DB.prepare(`
    SELECT 
      p.id, p.santri_id, p.jenis_pembayaran_id, p.periode, p.jumlah, p.status, 
      p.tanggal_bayar, p.bukti_url, p.catatan, p.created_at, p.updated_at,
      jp.nama as jenis_nama, jp.kode as jenis_kode
    FROM pembayaran p
    JOIN jenis_pembayaran jp ON p.jenis_pembayaran_id = jp.id
    WHERE p.santri_id = ?
    ORDER BY jp.nama ASC, p.periode DESC
  `).bind(siswaId).all();

  // Group by jenis_pembayaran
  const groupedMap = new Map<number, {
    jenis_pembayaran_id: number;
    jenis_nama: string;
    jenis_kode: string;
    periods: Array<{
      id: number;
      periode: string | null;
      label: string;
      jumlah: number;
      status: string;
      status_label: string;
      tanggal_bayar: string | null;
      bukti_url: string | null;
      catatan: string | null;
      created_at: string | null;
    }>;
  }>();

  for (const row of rows.results) {
    const r = row as any;
    const jenisId = r.jenis_pembayaran_id;

    if (!groupedMap.has(jenisId)) {
      groupedMap.set(jenisId, {
        jenis_pembayaran_id: jenisId,
        jenis_nama: r.jenis_nama,
        jenis_kode: r.jenis_kode,
        periods: []
      });
    }

    const group = groupedMap.get(jenisId)!;
    group.periods.push({
      id: r.id,
      periode: r.periode,
      label: formatPeriodeLabel(r.periode),
      jumlah: r.jumlah,
      status: r.status,
      status_label: r.status === '*' ? 'Lunas' : r.status === '**' ? 'Proses' : 'Belum Bayar',
      tanggal_bayar: r.tanggal_bayar,
      bukti_url: r.bukti_url,
      catatan: r.catatan,
      created_at: r.created_at,
    });
  }

  const grouped = Array.from(groupedMap.values());

  return success({ grouped });
}