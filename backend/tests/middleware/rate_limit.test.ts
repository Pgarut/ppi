import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
  generalRateLimit,
  bruteForceCheck,
  bruteForceRecordFailure,
  bruteForceRecordSuccess,
} from '../../src/middleware/rate_limit';

const mockEnv = { DB: { prepare: vi.fn(() => ({ bind: vi.fn(() => ({ run: vi.fn() })) })) } };

function makeRequest(url = 'http://localhost/api/test', ip = '127.0.0.1'): Request {
  return new Request(url, {
    headers: { 'CF-Connecting-IP': ip },
  });
}

describe('rate_limit middleware', () => {
  describe('generalRateLimit', () => {
    it('should return null for first request', async () => {
      const result = await generalRateLimit(makeRequest(), mockEnv as any);
      expect(result).toBeNull();
    });

    it('should allow requests under the limit', async () => {
      for (let i = 0; i < 99; i++) {
        const result = await generalRateLimit(makeRequest(), mockEnv as any);
        expect(result).toBeNull();
      }
    });

    it('should block requests over 100 per minute', async () => {
      const ip = '10.0.0.1';
      for (let i = 0; i < 100; i++) {
        await generalRateLimit(makeRequest('http://localhost/api/test', ip), mockEnv as any);
      }
      const blocked = await generalRateLimit(makeRequest('http://localhost/api/test', ip), mockEnv as any);
      expect(blocked).not.toBeNull();
      expect(blocked!.status).toBe(429);
      const body = await blocked!.json();
      expect(body.error.code).toBe('RATE_LIMITED');
      expect(blocked!.headers.get('Retry-After')).toBeTruthy();
    });

    it('should allow requests from different IPs independently', async () => {
      for (let i = 0; i < 101; i++) {
        await generalRateLimit(makeRequest('http://localhost/api/test', '192.168.1.1'), mockEnv as any);
      }
      const otherIp = await generalRateLimit(makeRequest('http://localhost/api/test', '192.168.1.2'), mockEnv as any);
      expect(otherIp).toBeNull();
    });
  });

  describe('bruteForceCheck', () => {
    it('should return null when no prior failures', async () => {
      const result = await bruteForceCheck('admin', makeRequest(), mockEnv as any);
      expect(result).toBeNull();
    });

    it('should block after 5 failed attempts', async () => {
      const username = 'testuser';
      const request = makeRequest('http://localhost/api/auth/login', '10.0.0.2');

      for (let i = 0; i < 5; i++) {
        await bruteForceRecordFailure(username, request, mockEnv as any);
      }

      const blocked = await bruteForceCheck(username, request, mockEnv as any);
      expect(blocked).not.toBeNull();
      expect(blocked!.status).toBe(429);
      const body = await blocked!.json();
      expect(body.error.code).toBe('ACCOUNT_LOCKED');
      expect(blocked!.headers.get('Retry-After')).toBeTruthy();
    });

    it('should not block different usernames from same IP', async () => {
      const ip = '10.0.0.3';
      const req1 = makeRequest('http://localhost', ip);

      for (let i = 0; i < 5; i++) {
        await bruteForceRecordFailure('locked_user', req1, mockEnv as any);
      }

      const result = await bruteForceCheck('other_user', req1, mockEnv as any);
      expect(result).toBeNull();
    });

    it('should not block same username from different IP', async () => {
      const username = 'shared_user';

      for (let i = 0; i < 5; i++) {
        await bruteForceRecordFailure(
          username,
          makeRequest('http://localhost', `10.0.0.${i + 10}`),
          mockEnv as any,
        );
      }

      const result = await bruteForceCheck(
        username,
        makeRequest('http://localhost', '10.0.0.99'),
        mockEnv as any,
      );
      expect(result).toBeNull();
    });
  });

  describe('bruteForceRecordSuccess', () => {
    it('should reset failure counter after successful login', async () => {
      const username = 'reset_test';
      const request = makeRequest('http://localhost/api/auth/login', '10.0.0.4');

      for (let i = 0; i < 5; i++) {
        await bruteForceRecordFailure(username, request, mockEnv as any);
      }

      await bruteForceRecordSuccess(username);

      const result = await bruteForceCheck(username, request, mockEnv as any);
      expect(result).toBeNull();
    });
  });
});
