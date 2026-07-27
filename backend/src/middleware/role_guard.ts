import { Role, UserPayload } from '../types';

export function roleGuard(
  user: UserPayload | null,
  allowedRoles: Role[]
): { allowed: boolean; reason?: string } {
  if (!user) {
    return { allowed: false, reason: 'Unauthorized' };
  }

  if (!allowedRoles.includes(user.role)) {
    return { allowed: false, reason: 'Forbidden: insufficient role' };
  }

  return { allowed: true };
}
