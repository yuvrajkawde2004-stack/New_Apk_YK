import { Context, Next } from 'hono';
import { verify } from 'hono/jwt';
import { Bindings, JWTPayload } from '../types';

export const authMiddleware = async (c: Context<{ Bindings: Bindings, Variables: { user: JWTPayload } }>, next: Next) => {
  const authHeader = c.req.header('Authorization');

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ error: 'Unauthorized: Missing or invalid token' }, 401);
  }

  const token = authHeader.split(' ')[1];

  try {
    const payload = await verify(token, c.env.JWT_SECRET || 'fallback-secret-key-for-dev', 'HS256') as JWTPayload;

    // Attach user payload to context
    c.set('user', payload);

    await next();
  } catch (err) {
    return c.json({ error: 'Unauthorized: Token expired or invalid' }, 401);
  }
};
