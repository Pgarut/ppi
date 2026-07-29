import { Env } from '../types';

let _allowedOrigin = '*';

export function setCorsOrigin(origin: string) {
  _allowedOrigin = origin;
}

export function corsHeaders(): Record<string, string> {
  return {
    'Access-Control-Allow-Origin': _allowedOrigin,
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  };
}

export function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders() },
  });
}

export function success(data: unknown, message?: string): Response {
  return json({ success: true, data, message });
}

export function created(data: unknown): Response {
  return json({ success: true, data }, 201);
}

export function error(message: string, status: number, code?: string): Response {
  return json({ success: false, error: { code: code || 'ERROR', message } }, status);
}

export function notFound(entity = 'Data'): Response {
  return error(`${entity} tidak ditemukan`, 404, 'NOT_FOUND');
}

export function badRequest(message: string): Response {
  return error(message, 400, 'BAD_REQUEST');
}

export function unauthorized(): Response {
  return error('Unauthorized', 401, 'UNAUTHORIZED');
}

export function forbidden(): Response {
  return error('Forbidden: insufficient role', 403, 'FORBIDDEN');
}

export function cors(): Response {
  return new Response(null, { status: 204, headers: corsHeaders() });
}

export function resolveCorsOrigin(requestOrigin: string | null, env: Env): string {
  const allowedOriginsRaw = env.CORS_ORIGIN || '*';
  if (allowedOriginsRaw === '*') return '*';

  const allowedOrigins = allowedOriginsRaw.split(',').map((o: string) => o.trim());
  if (!requestOrigin) return allowedOrigins[0] || '*';

  const matched = allowedOrigins.find((o: string) => o === requestOrigin);
  if (matched) return matched;

  // Fallback: return the requesting origin so local/dev origins still work
  return requestOrigin ?? allowedOrigins[0] ?? '*';
}
