import { describe, it, expect, beforeAll } from 'vitest';
import { generateToken, verifyToken, authMiddleware } from '../../src/middleware/auth';
import { Env, UserPayload } from '../../src/types';

const testEnv = {
  JWT_SECRET: 'test-secret-key-min-32-chars-for-hs256!!!',
  JWT_EXPIRES_IN: '1h',
  DB: {} as any,
} satisfies Env;

const testUser: UserPayload = {
  sub: 1,
  username: 'admin',
  role: 'admin',
  guru_id: null,
};

describe('auth middleware', () => {
  describe('generateToken', () => {
    it('should generate a valid JWT string', async () => {
      const token = await generateToken(testUser, testEnv);
      expect(token).toBeTruthy();
      expect(typeof token).toBe('string');
      expect(token.split('.')).toHaveLength(3);
    });

    it('should generate different tokens for different payloads', async () => {
      const token1 = await generateToken(testUser, testEnv);
      const token2 = await generateToken(
        { ...testUser, sub: 2, username: 'guru' },
        testEnv,
      );
      expect(token1).not.toBe(token2);
    });
  });

  describe('verifyToken', () => {
    it('should verify a valid token and return payload', async () => {
      const token = await generateToken(testUser, testEnv);
      const payload = await verifyToken(token, testEnv);
      expect(payload).not.toBeNull();
      expect(payload!.sub).toBe(1);
      expect(payload!.username).toBe('admin');
      expect(payload!.role).toBe('admin');
    });

    it('should return null for an invalid token', async () => {
      const payload = await verifyToken('invalid.token.here', testEnv);
      expect(payload).toBeNull();
    });

    it('should return null for a token signed with different secret', async () => {
      const token = await generateToken(testUser, testEnv);
      const wrongEnv = { ...testEnv, JWT_SECRET: 'different-secret-key-not-the-same-one!!' };
      const payload = await verifyToken(token, wrongEnv);
      expect(payload).toBeNull();
    });

    it('should return null for expired token', async () => {
      const expiredEnv = { ...testEnv, JWT_EXPIRES_IN: '0s' };
      const token = await generateToken(testUser, expiredEnv);
      await new Promise((r) => setTimeout(r, 100));
      const payload = await verifyToken(token, expiredEnv);
      expect(payload).toBeNull();
    });
  });

  describe('authMiddleware', () => {
    it('should return null when no Authorization header', async () => {
      const request = new Request('http://localhost');
      const user = await authMiddleware(request, testEnv);
      expect(user).toBeNull();
    });

    it('should return null when header is not Bearer', async () => {
      const request = new Request('http://localhost', {
        headers: { Authorization: 'Basic token123' },
      });
      const user = await authMiddleware(request, testEnv);
      expect(user).toBeNull();
    });

    it('should return null for invalid Bearer token', async () => {
      const request = new Request('http://localhost', {
        headers: { Authorization: 'Bearer invalid-token' },
      });
      const user = await authMiddleware(request, testEnv);
      expect(user).toBeNull();
    });

    it('should return payload for valid Bearer token', async () => {
      const token = await generateToken(testUser, testEnv);
      const request = new Request('http://localhost', {
        headers: { Authorization: `Bearer ${token}` },
      });
      const user = await authMiddleware(request, testEnv);
      expect(user).not.toBeNull();
      expect(user!.username).toBe('admin');
    });
  });
});
