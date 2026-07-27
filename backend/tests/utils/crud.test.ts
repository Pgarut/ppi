import { describe, it, expect, vi } from 'vitest';
import { list, getById } from '../../src/utils/crud';
import { Env, UserPayload } from '../../src/types';

function makeEnv() {
  const run = vi.fn().mockResolvedValue({ meta: { last_row_id: 1, changes: 1 } });
  const first = vi.fn();
  const all = vi.fn();
  const bind = vi.fn(() => ({ run, all, first }));
  const prepare = vi.fn(() => ({ bind }));
  return { DB: { prepare }, run, all, first, bind } as unknown as Env & typeof bind;
}

const testUser: UserPayload = { sub: 1, username: 'admin', role: 'admin', guru_id: null };
const testConfig = {
  table: 'test_table',
  columns: ['nama', 'kode'],
  label: 'Test',
  searchFields: ['nama'],
  timestamp: true,
};

function makeUrl(path = '/api/admin/test', search = ''): URL {
  return new URL(`http://localhost${path}?${search}`);
}

describe('CRUD utilities', () => {
  describe('list', () => {
    it('should return paginated results', async () => {
      const env = makeEnv();
      env.first.mockResolvedValueOnce({ total: 5 });
      env.all.mockResolvedValue({ results: [{ id: 1, nama: 'Test' }, { id: 2, nama: 'Test 2' }] });

      const res = await list(env, testConfig, makeUrl(), testUser);
      expect(res.status).toBe(200);

      const body = await res.json();
      expect(body.success).toBe(true);
      expect(body.data.items).toHaveLength(2);
      expect(body.data.pagination.total).toBe(5);
      expect(body.data.pagination.page).toBe(1);
      expect(body.data.pagination.total_pages).toBe(1);
    });

    it('should clamp pagination values', async () => {
      const env = makeEnv();
      env.first.mockResolvedValue({ total: 0 });
      env.all.mockResolvedValue({ results: [] });

      const url = makeUrl('/api/admin/test', 'page=0&per_page=999');
      const res = await list(env, testConfig, url, testUser);
      expect(res.status).toBe(200);

      const body = await res.json();
      expect(body.data.pagination.page).toBe(1);
      expect(body.data.pagination.per_page).toBe(100);
    });

    it('should search with LIKE when search param is provided', async () => {
      const env = makeEnv();
      env.first.mockResolvedValue({ total: 1 });
      env.all.mockResolvedValue({ results: [{ id: 1, nama: 'Test' }] });

      const url = makeUrl('/api/admin/test', 'search=test');
      await list(env, testConfig, url, testUser);

      const bindCalls = env.bind.mock.calls;
      expect(bindCalls.some((c: unknown[]) => c[0] === '%test%')).toBe(true);
    });
  });

  describe('getById', () => {
    it('should return 200 with data when found', async () => {
      const env = makeEnv();
      env.first.mockResolvedValue({ id: 1, nama: 'Test' });

      const res = await getById(env, testConfig, 1);
      expect(res.status).toBe(200);

      const body = await res.json();
      expect(body.data).toEqual({ id: 1, nama: 'Test' });
    });

    it('should return 404 when not found', async () => {
      const env = makeEnv();
      env.first.mockResolvedValue(null);

      const res = await getById(env, testConfig, 999);
      expect(res.status).toBe(404);
    });
  });
});
