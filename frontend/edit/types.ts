export interface Env {
  DB: D1Database;
  JWT_SECRET: string;
  JWT_EXPIRES_IN?: string;
  JWT_REFRESH_SECRET?: string;
  CORS_ORIGIN?: string;
}

export interface UserPayload {
  sub: number;
  username: string;
  role: Role;
  guru_id: number | null;
  siswa_id: number | null;
}

export type Role =
  | 'admin'
  | 'kepala_sekolah'
  | 'wakil_kurikulum'
  | 'guru_mapel_wali_kelas'
  | 'guru_bk'
  | 'siswa';

export interface AuthenticatedRequest extends Request {
  user?: UserPayload;
}
