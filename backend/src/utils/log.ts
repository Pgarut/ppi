import { Env } from '../types';

export async function logAktivitas(env: Env, params: { user_id: number; aksi: string; modul: string; detail: string; ip_address: string }): Promise<void> {
  await env.DB.prepare(
    "INSERT INTO log_aktivitas (user_id, aksi, modul, detail, ip_address) VALUES (?, ?, ?, ?, ?)"
  ).bind(params.user_id, params.aksi, params.modul, params.detail, params.ip_address).run();
}