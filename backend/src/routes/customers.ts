import { Hono } from 'hono';
import { Bindings, JWTPayload } from '../types';
import { authMiddleware } from '../middleware/auth';

const customersApp = new Hono<{ Bindings: Bindings, Variables: { user: JWTPayload } }>();

customersApp.use('*', authMiddleware);

// Middleware to ensure user has a shop context
const requireShopContext = async (c: any, next: any) => {
  const { shopId } = c.get('user');
  if (!shopId) {
    return c.json({ success: false, message: 'No shop context. Please create a shop first.' }, 403);
  }
  await next();
};

customersApp.use('*', requireShopContext);

// Get all customers for the shop
customersApp.get('/', async (c) => {
  const { shopId } = c.get('user');

  try {
    const customers = await c.env.DB.prepare(
      `SELECT * FROM customers WHERE shop_id = ? ORDER BY name ASC`
    ).bind(shopId).all();

    return c.json({ success: true, data: customers.results });
  } catch (error: any) {
    return c.json({ success: false, message: error.message }, 500);
  }
});

// Add a new customer
customersApp.post('/', async (c) => {
  const { shopId } = c.get('user');
  const body = await c.req.json();
  const { name, phone, email, outstanding_balance, address } = body;

  if (!name || !phone) {
    return c.json({ success: false, message: 'Name and phone are required' }, 400);
  }

  const customerId = crypto.randomUUID();

  try {
    await c.env.DB.prepare(
      `INSERT INTO customers (customer_id, shop_id, name, mobile, address, outstanding_balance) 
       VALUES (?, ?, ?, ?, ?, ?)`
    ).bind(customerId, shopId, name, phone, address || '', outstanding_balance || 0).run();

    return c.json({
      success: true,
      message: 'Customer added successfully',
      data: { customer_id: customerId }
    });
  } catch (error: any) {
    return c.json({ success: false, message: error.message }, 500);
  }
});

export default customersApp;
