import { jwtVerify, SignJWT } from 'jose';
import { Env, UserPayload } from '../types';
import { hashToken, validateSession } from './session';

const getSecretKey = (env: Env) => new TextEncoder().encode(env.JWT_SECRET);
const getRefreshSecret = (env: Env) => {
  const refreshSecret = env.JWT_REFRESH_SECRET || env.JWT_SECRET + '_refresh';
  return new TextEncoder().encode(refreshSecret);
};

export async function generateToken(
  payload: UserPayload,
  env: Env
): Promise<string> {
  const expiresIn = env.JWT_EXPIRES_IN || '8h';

  return new SignJWT({ ...payload } as unknown as Record<string, unknown>)
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(expiresIn)
    .sign(getSecretKey(env));
}

export async function verifyToken(
  token: string,
  env: Env
): Promise<UserPayload | null> {
  try {
    const { payload } = await jwtVerify(token, getSecretKey(env));
    return payload as unknown as UserPayload;
  } catch {
    return null;
  }
}

export async function generateRefreshToken(
  userId: number,
  env: Env
): Promise<string> {
  return new SignJWT({ sub: userId, type: 'refresh' } as unknown as Record<string, unknown>)
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('7d')
    .sign(getRefreshSecret(env));
}

export async function verifyRefreshToken(
  token: string,
  env: Env
): Promise<{ sub: number } | null> {
  try {
    const { payload } = await jwtVerify(token, getRefreshSecret(env));
    if (payload.type !== 'refresh') return null;
    return { sub: Number(payload.sub) };
  } catch {
    return null;
  }
}

export async function authMiddleware(
  request: Request,
  env: Env
): Promise<UserPayload | null> {
  const authHeader = request.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }

  const token = authHeader.slice(7);
  const user = await verifyToken(token, env);
  if (!user) return null;

  // Validasi session aktif (opsional: Uncomment jika ingin cek session di setiap request)
  // const tokenHash = await hashToken(token);
  // const isValid = await validateSession(tokenHash, env);
  // if (!isValid) return null;

  return user;
}
