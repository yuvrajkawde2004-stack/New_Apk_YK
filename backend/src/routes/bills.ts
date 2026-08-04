import { Hono } from 'hono';
import { Bindings, JWTPayload } from '../types';
import { authMiddleware } from '../middleware/auth';

const billsApp = new Hono<{ Bindings: Bindings, Variables: { user: JWTPayload } }>();

billsApp.use('*', authMiddleware);

const requireShopContext = async (c: any, next: any) => {
  const { shopId } = c.get('user');
  if (!shopId) return c.json({ success: false, message: 'No shop context' }, 403);
  await next();
};
billsApp.use('*', requireShopContext);

// Create a new bill (transaction)
billsApp.post('/', async (c) => {
  const { shopId } = c.get('user');
  const body = await c.req.json();
  const { customer_id, bill_number, subtotal, discount, grand_total, payment_method, payment_status, amount_paid, items } = body;

  if (!items || !Array.isArray(items) || items.length === 0) {
    return c.json({ success: false, message: 'Bill items are required' }, 400);
  }

  const billId = crypto.randomUUID();
  const queries = [];

  // 1. Insert the Bill
  queries.push(
    c.env.DB.prepare(
      `INSERT INTO bills (bill_id, shop_id, customer_id, bill_number, subtotal, discount, grand_total, payment_method, payment_status, amount_paid)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    ).bind(billId, shopId, customer_id || null, bill_number || `INV-\${Date.now()}`, subtotal || 0, discount || 0, grand_total || 0, payment_method || 'Cash', payment_status || 'paid', amount_paid || grand_total)
  );

  // 2. Insert Bill Items and decrease stock
  for (const item of items) {
    const itemId = crypto.randomUUID();
    queries.push(
      c.env.DB.prepare(
        `INSERT INTO bill_items (item_id, bill_id, product_id, quantity, price, total) VALUES (?, ?, ?, ?, ?, ?)`
      ).bind(itemId, billId, item.product_id, item.quantity, item.price, item.total)
    );

    // Decrease stock
    queries.push(
      c.env.DB.prepare(
        `UPDATE products SET stock = stock - ? WHERE product_id = ? AND shop_id = ?`
      ).bind(item.quantity, item.product_id, shopId)
    );
  }

  // 3. Update customer outstanding balance if unpaid/partial
  if (customer_id && (payment_status === 'unpaid' || payment_status === 'partial')) {
    const pendingAmount = grand_total - amount_paid;
    if (pendingAmount > 0) {
      queries.push(
        c.env.DB.prepare(
          `UPDATE customers SET outstanding_balance = outstanding_balance + ? WHERE customer_id = ? AND shop_id = ?`
        ).bind(pendingAmount, customer_id, shopId)
      );
    }
  }

  try {
    // Execute all queries in a batch transaction
    await c.env.DB.batch(queries);

    return c.json({
      success: true,
      message: 'Bill created successfully',
      data: { bill_id: billId }
    });
  } catch (error: any) {
    return c.json({ success: false, message: error.message }, 500);
  }
});

export default billsApp;
