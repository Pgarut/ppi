import { describe, it, expect } from 'vitest';
import { json, success, created, error, notFound, badRequest, unauthorized, forbidden, cors } from '../../src/utils/response';

describe('response utilities', () => {
  describe('json', () => {
    it('should return Response with JSON body and default status 200', async () => {
      const res = json({ foo: 'bar' });
      expect(res.status).toBe(200);
      expect(res.headers.get('Content-Type')).toBe('application/json');
      const body = await res.json();
      expect(body).toEqual({ foo: 'bar' });
    });

    it('should return Response with custom status', async () => {
      const res = json({ error: 'bad' }, 400);
      expect(res.status).toBe(400);
    });

    it('should include CORS headers', () => {
      const res = json({});
      expect(res.headers.get('Access-Control-Allow-Origin')).toBe('*');
      expect(res.headers.get('Access-Control-Allow-Methods')).toBe('GET, POST, PUT, DELETE, OPTIONS');
      expect(res.headers.get('Access-Control-Allow-Headers')).toBe('Content-Type, Authorization');
    });
  });

  describe('success', () => {
    it('should return 200 with success:true and data', async () => {
      const res = success({ id: 1 });
      const body = await res.json();
      expect(body).toEqual({ success: true, data: { id: 1 }, message: undefined });
    });

    it('should include optional message', async () => {
      const res = success({ id: 1 }, 'Created');
      const body = await res.json();
      expect(body.message).toBe('Created');
    });
  });

  describe('created', () => {
    it('should return 201 with success:true', async () => {
      const res = created({ id: 1 });
      expect(res.status).toBe(201);
      const body = await res.json();
      expect(body).toEqual({ success: true, data: { id: 1 } });
    });
  });

  describe('error', () => {
    it('should return error response with default code', async () => {
      const res = error('Something went wrong', 500);
      expect(res.status).toBe(500);
      const body = await res.json();
      expect(body).toEqual({
        success: false,
        error: { code: 'ERROR', message: 'Something went wrong' },
      });
    });

    it('should return error with custom code', async () => {
      const res = error('Not found', 404, 'NOT_FOUND');
      const body = await res.json();
      expect(body.error.code).toBe('NOT_FOUND');
    });
  });

  describe('notFound', () => {
    it('should return 404 with default message', async () => {
      const res = notFound();
      expect(res.status).toBe(404);
      const body = await res.json();
      expect(body.error.message).toBe('Data tidak ditemukan');
    });

    it('should return 404 with custom entity name', async () => {
      const res = notFound('User');
      const body = await res.json();
      expect(body.error.message).toBe('User tidak ditemukan');
    });
  });

  describe('badRequest', () => {
    it('should return 400 with given message', async () => {
      const res = badRequest('Invalid input');
      expect(res.status).toBe(400);
      const body = await res.json();
      expect(body.error.message).toBe('Invalid input');
    });
  });

  describe('unauthorized', () => {
    it('should return 401', async () => {
      const res = unauthorized();
      expect(res.status).toBe(401);
      const body = await res.json();
      expect(body.error.code).toBe('UNAUTHORIZED');
    });
  });

  describe('forbidden', () => {
    it('should return 403', async () => {
      const res = forbidden();
      expect(res.status).toBe(403);
      const body = await res.json();
      expect(body.error.code).toBe('FORBIDDEN');
    });
  });

  describe('cors', () => {
    it('should return 204 with CORS headers', () => {
      const res = cors();
      expect(res.status).toBe(204);
      expect(res.headers.get('Access-Control-Allow-Origin')).toBe('*');
    });
  });
});
