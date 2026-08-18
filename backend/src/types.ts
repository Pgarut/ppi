export interface Env {
  DB: D1Database;
  JWT_SECRET: string;
  JWT_EXPIRES_IN?: string;
  JWT_REFRESH_SECRET?: string;
  CORS_ORIGIN?: string;
  QR_DAUROH_TOKEN?: string;
  QR_ABSENSI_TOKEN?: string;
  JAM_MASUK_MULAI?: string;
  JAM_MASUK_SELESAI?: string;
  JAM_KELUAR_MULAI?: string;
  JAM_KELUAR_SELESAI?: string;
  DAUROH_JAM_MASUK_MULAI?: string;
  DAUROH_JAM_MASUK_SELESAI?: string;
  DAUROH_JAM_KELUAR_MULAI?: string;
  DAUROH_JAM_KELUAR_SELESAI?: string;
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
  | 'siswa'
  | 'musyrifah';

export interface AuthenticatedRequest extends Request {
  user?: UserPayload;
}
