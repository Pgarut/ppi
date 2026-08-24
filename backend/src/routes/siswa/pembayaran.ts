import { Env, UserPayload } from '../../types';
import { success, error } from '../../utils/response';

export async function handleSiswaPembayaran(
  env: Env,
  user: UserPayload,
  url: URL
): Promise<Response> {
  const siswaId = user.siswa_id;
  if (!siswaId) return error('Data santri tidak ditemukan', 404);

  const page = Math.max(1, parseInt(url.searchParams.get('page') || '1'));
  const perPage = Math.min(100, Math.max(1, parseInt(url.searchParams.get('per_page') || '20')));
  const offset = (page - 1) * perPage;
  const status = url.searchParams.get('status');

  let whereClause = 'WHERE p.santri_id = ?';
  const params: (string | number)[] = [siswaId];

  if (status) {
    whereClause += ' AND p.status = ?';
    params.push(status);
  }

  const countResult = await env.DB.prepare(
    `SELECT COUNT(*) as total FROM pembayaran p ${whereClause}`
  ).bind(...params).first<{ total: number }>();

  const total = countResult?.total || 0;

  const rows = await env.DB.prepare(
    `SELECT p.id, p.santri_id, p.jenis_pembayaran_id, p.jumlah, p.status, p.tanggal_bayar,
            p.bukti_url, p.catatan, p.created_at, p.updated_at,
            jp.nama as jenis_nama, jp.kode as jenis_kode
     FROM pembayaran p
     JOIN jenis_pembayaran jp ON p.jenis_pembayaran_id = jp.id
     ${whereClause}
     ORDER BY p.created_at DESC LIMIT ? OFFSET ?`
  ).bind(...params, perPage, offset).all();

  const items = rows.results.map((r: any) => ({
    ...r,
    status_label: r.status === '*' ? 'Lunas' : r.status === '**' ? 'Proses' : 'Belum Bayar',
  }));

  return success({
    items,
    pagination: { page, per_page: perPage, total, total_pages: Math.ceil(total / perPage) },
  });
}