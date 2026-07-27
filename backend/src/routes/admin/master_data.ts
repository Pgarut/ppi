import { Env, UserPayload } from '../../types';
import { CrudConfig, list, getById, create, update, remove } from '../../utils/crud';
import { json, badRequest } from '../../utils/response';

const configs: Record<string, CrudConfig> = {
  'tahun-ajaran': { table: 'tahun_ajaran', columns: ['nama', 'tanggal_mulai', 'tanggal_selesai', 'is_aktif'], label: 'Tahun Ajaran', searchFields: ['nama'], timestamp: true },
  'semester': { table: 'semester', columns: ['tahun_ajaran_id', 'nama', 'is_aktif'], label: 'Semester', searchFields: ['nama'], timestamp: true },
  'jurusan': { table: 'jurusan', columns: ['nama', 'kode'], label: 'Jurusan', searchFields: ['nama', 'kode'], timestamp: true },
  'tingkat': { table: 'tingkat', columns: ['nama', 'jenjang'], label: 'Tingkat', searchFields: ['nama'], timestamp: true },
  'kelas': { table: 'kelas', columns: ['nama', 'tingkat_id', 'jurusan_id', 'wali_kelas_id', 'ruangan_id', 'tahun_ajaran_id'], label: 'Kelas', searchFields: ['nama'], timestamp: true },
  'mata-pelajaran': { table: 'mata_pelajaran', columns: ['nama', 'kode', 'jenjang'], label: 'Mata Pelajaran', searchFields: ['nama', 'kode'], timestamp: true },
  'guru': { table: 'guru', columns: ['nip', 'nama', 'jenis_kelamin', 'no_hp', 'email', 'jabatan', 'status_aktif'], label: 'Guru', searchFields: ['nama', 'nip', 'email'], filterFields: ['jabatan'], timestamp: true },
  'siswa': { table: 'siswa', columns: ['nis', 'nisn', 'nama', 'jenis_kelamin', 'tempat_lahir', 'tanggal_lahir', 'alamat', 'no_hp_ortu', 'kelas_id', 'tahun_ajaran_id', 'status'], label: 'Siswa', searchFields: ['nama', 'nis', 'nisn'], timestamp: true },
  'ruangan': { table: 'ruangan', columns: ['nama', 'kapasitas'], label: 'Ruangan', searchFields: ['nama'], timestamp: true },
};

export async function handleAdminMasterData(request: Request, env: Env, user: UserPayload, pathParts: string[], url: URL): Promise<Response> {
  const ip = request.headers.get('CF-Connecting-IP') || 'unknown';

  if (pathParts.length < 3) return badRequest('Resource tidak valid');

  const resource = pathParts[2];

  // /api/admin/kelas?search=... atau /api/admin/kelas/5
  const isList = pathParts.length === 3 && request.method === 'GET' && !url.searchParams.has('id');
  const isById = pathParts.length === 4 && request.method === 'GET';
  const isCreate = pathParts.length === 3 && request.method === 'POST';
  const isUpdate = pathParts.length === 4 && request.method === 'PUT';
  const isDelete = pathParts.length === 4 && request.method === 'DELETE';

  const cfg = configs[resource];
  if (!cfg) return badRequest(`Resource '${resource}' tidak dikenal`);

  try {
    if (isList) return list(env, cfg, url, user);
    if (isById) return getById(env, cfg, parseInt(pathParts[3]));
    if (isCreate) {
      const body = await request.json() as Record<string, unknown>;
      return create(env, cfg, body, user, ip);
    }
    if (isUpdate) {
      const body = await request.json() as Record<string, unknown>;
      return update(env, cfg, parseInt(pathParts[3]), body, user, ip);
    }
    if (isDelete) return remove(env, cfg, parseInt(pathParts[3]), user, ip);
  } catch (e) {
    return badRequest(e instanceof Error ? e.message : 'Invalid request');
  }

  return badRequest('Method tidak didukung');
}
