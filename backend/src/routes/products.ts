import { Hono } from 'hono';
import { Bindings, JWTPayload } from '../types';
import { authMiddleware } from '../middleware/auth';

const productsApp = new Hono<{ Bindings: Bindings, Variables: { user: JWTPayload } }>();

productsApp.use('*', authMiddleware);

const requireShopContext = async (c: any, next: any) => {
  const { shopId } = c.get('user');
  if (!shopId) return c.json({ success: false, message: 'No shop context' }, 403);
  await next();
};
productsApp.use('*', requireShopContext);

// Get all products for the shop
productsApp.get('/', async (c) => {
  const { shopId } = c.get('user');

  try {
    const products = await c.env.DB.prepare(
      `SELECT * FROM products WHERE shop_id = ? ORDER BY name ASC`
    ).bind(shopId).all();

    return c.json({ success: true, data: products.results });
  } catch (error: any) {
    return c.json({ success: false, message: error.message }, 500);
  }
});

// Add a new product
productsApp.post('/', async (c) => {
  const { shopId } = c.get('user');
  const body = await c.req.json();
  const { name, category, purchase_price, selling_price, stock, image_url } = body;

  if (!name) {
    return c.json({ success: false, message: 'Product name is required' }, 400);
  }

  const productId = crypto.randomUUID();

  try {
    await c.env.DB.prepare(
      `INSERT INTO products (product_id, shop_id, name, category, purchase_price, selling_price, stock, image_url) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
    ).bind(productId, shopId, name, category || '', purchase_price || 0, selling_price || 0, stock || 0, image_url || '').run();

    return c.json({
      success: true,
      message: 'Product added successfully',
      data: { product_id: productId }
    });
  } catch (error: any) {
    return c.json({ success: false, message: error.message }, 500);
  }
});

export default productsApp;
