import { Hono } from 'hono';
import { Bindings, JWTPayload } from '../types';
import { authMiddleware } from '../middleware/auth';

const usersApp = new Hono<{ Bindings: Bindings, Variables: { user: JWTPayload } }>();

usersApp.use('*', authMiddleware);

// Get current user profile
usersApp.get('/me', async (c) => {
  const { userId } = c.get('user');

  try {
    const user = await c.env.DB.prepare(
      `SELECT user_id, mobile, email, name, created_at, status FROM users WHERE user_id = ?`
    ).bind(userId).first();

    if (!user) {
      return c.json({ success: false, message: 'User not found' }, 404);
    }

    return c.json({ success: true, data: user });
  } catch (error: any) {
    return c.json({ success: false, message: error.message }, 500);
  }
});

// Update user profile
usersApp.put('/me', async (c) => {
  const { userId } = c.get('user');
  const body = await c.req.json();

  try {
    const { name, email } = body;

    const updates = [];
    const values = [];

    if (name !== undefined) {
      updates.push('name = ?');
      values.push(name);
    }

    if (email !== undefined) {
      updates.push('email = ?');
      values.push(email);
    }

    if (updates.length === 0) {
      return c.json({ success: false, message: 'No fields to update' }, 400);
    }

    values.push(userId);
    const updateQuery = `UPDATE users SET ${updates.join(', ')} WHERE user_id = ?`;

    await c.env.DB.prepare(updateQuery).bind(...values).run();

    return c.json({ success: true, message: 'Profile updated successfully' });
  } catch (error: any) {
    return c.json({ success: false, message: error.message }, 500);
  }
});

export default usersApp;
