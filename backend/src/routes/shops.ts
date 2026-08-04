import { Hono } from 'hono';
import { Bindings, JWTPayload } from '../types';
import { authMiddleware } from '../middleware/auth';

const shopsApp = new Hono<{ Bindings: Bindings, Variables: { user: JWTPayload } }>();

shopsApp.use('*', authMiddleware);

// Get shops for the current user
shopsApp.get('/', async (c) => {
  const { userId } = c.get('user');

  try {
    const shops = await c.env.DB.prepare(
      `SELECT s.shop_id, s.shop_name, s.address, s.created_at, su.role 
       FROM shops s 
       JOIN shop_users su ON s.shop_id = su.shop_id 
       WHERE su.user_id = ?`
    ).bind(userId).all();

    return c.json({ success: true, data: shops.results });
  } catch (error: any) {
    return c.json({ success: false, message: error.message }, 500);
  }
});

// Create a new shop
shopsApp.post('/', async (c) => {
  const { userId } = c.get('user');
  const body = await c.req.json();
  const { shop_name, address } = body;

  if (!shop_name) {
    return c.json({ success: false, message: 'Shop name is required' }, 400);
  }

  const shopId = crypto.randomUUID();

  try {
    // We use a batch query because D1 doesn't support interactive transactions yet
    await c.env.DB.batch([
      c.env.DB.prepare(
        `INSERT INTO shops (shop_id, owner_id, shop_name, address) VALUES (?, ?, ?, ?)`
      ).bind(shopId, userId, shop_name, address || ''),
      c.env.DB.prepare(
        `INSERT INTO shop_users (id, shop_id, user_id, role) VALUES (?, ?, ?, ?)`
      ).bind(crypto.randomUUID(), shopId, userId, 'owner')
    ]);

    return c.json({
      success: true,
      message: 'Shop created successfully',
      data: { shop_id: shopId, shop_name, address }
    });
  } catch (error: any) {
    return c.json({ success: false, message: error.message }, 500);
  }
});

export default shopsApp;
