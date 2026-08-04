import { Env, UserPayload } from '../../types';
import { success, error } from '../../utils/response';

export async function handleProfil(env: Env, user: UserPayload): Promise<Response> {
  const { results } = await env.DB.prepare(
    `SELECT s.*, k.nama as kelas_nama, t.nama as tingkat_nama,
            ta.nama as tahun_ajaran_nama
     FROM siswa s
     LEFT JOIN kelas k ON s.kelas_id = k.id
     LEFT JOIN tingkat t ON k.tingkat_id = t.id
     LEFT JOIN tahun_ajaran ta ON k.tahun_ajaran_id = ta.id
     WHERE s.id = ?`
  ).bind(user.siswa_id).all();

  if (results.length === 0) {
    return error('Data siswa tidak ditemukan', 404);
  }

  const siswa = results[0] as any;
  return success({
    id: siswa.id,
    nis: siswa.nis,
    nisn: siswa.nisn,
    nama: siswa.nama,
    jenis_kelamin: siswa.jenis_kelamin,
    tempat_lahir: siswa.tempat_lahir,
    tanggal_lahir: siswa.tanggal_lahir,
    alamat: siswa.alamat,
    no_hp_ortu: siswa.no_hp_ortu,
    status: siswa.status,
    kelas: {
      id: siswa.kelas_id,
      nama: siswa.kelas_nama,
      tingkat: siswa.tingkat_nama,
    },
    tahun_ajaran: siswa.tahun_ajaran_nama,
  });
}
