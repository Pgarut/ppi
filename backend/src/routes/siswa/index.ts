import { Env, UserPayload } from '../../types';
import { error } from '../../utils/response';
import { handleProfil } from './profil';
import { handleJadwal } from './jadwal';
import { handleAbsensi } from './absensi';
import { handleNilai } from './nilai';
import { handleMateri } from './materi';

export async function handleSiswaRoutes(
  request: Request,
  env: Env,
  user: UserPayload,
  pathParts: string[],
  url: URL
): Promise<Response> {
  const method = request.method;
  const sub = pathParts[2] ?? '';

  if (sub === 'profil' && method === 'GET') {
    return handleProfil(env, user);
  }

  if (sub === 'jadwal' && method === 'GET') {
    return handleJadwal(env, user, url);
  }

  if (sub === 'absensi' && method === 'GET') {
    return handleAbsensi(env, user, url);
  }

  if (sub === 'nilai' && method === 'GET') {
    return handleNilai(env, user, url);
  }

  if (sub === 'materi' && method === 'GET') {
    return handleMateri(env, user, url);
  }

  return error('Endpoint tidak ditemukan', 404);
}
