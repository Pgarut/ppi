import { vi } from 'vitest';

vi.stubEnv('JWT_SECRET', 'test-secret-key-min-32-chars-for-hs256!!!');
