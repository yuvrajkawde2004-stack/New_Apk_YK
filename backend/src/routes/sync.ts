import { Hono } from 'hono';
import { Bindings, JWTPayload } from '../types';
import { authMiddleware } from '../middleware/auth';

const syncApp = new Hono<{ Bindings: Bindings, Variables: { user: JWTPayload } }>();

syncApp.use('*', authMiddleware);

const requireShopContext = async (c: any, next: any) => {
  const { shopId } = c.get('user');
  if (!shopId) return c.json({ success: false, message: 'No shop context' }, 403);
  await next();
};
syncApp.use('*', requireShopContext);

// Batch Sync API (Offline-First Sync Up)
syncApp.post('/', async (c) => {
  const { shopId } = c.get('user');
  const body = await c.req.json();
  const logs = body.logs;

  if (!logs || !Array.isArray(logs)) {
    return c.json({ success: false, message: 'Invalid sync logs format' }, 400);
  }

  const queries = [];

  for (const log of logs) {
    const data = typeof log.data_json === 'string' ? JSON.parse(log.data_json) : log.data_json;
    const action = log.action.toUpperCase();
    const table = log.table_name;
    const recordId = log.record_id;

    if (table === 'products') {
      if (action === 'INSERT') {
        queries.push(c.env.DB.prepare(
          `INSERT INTO products (product_id, shop_id, product_name, category, purchase_rate, quantity, supplier_name, low_stock_limit) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
        ).bind(recordId, shopId, data.product_name, data.category, data.purchase_rate, data.quantity, data.supplier_name, data.low_stock_limit));
      } else if (action === 'UPDATE') {
        queries.push(c.env.DB.prepare(
          `UPDATE products SET product_name=?, category=?, purchase_rate=?, quantity=?, supplier_name=?, low_stock_limit=? WHERE product_id=? AND shop_id=?`
        ).bind(data.product_name, data.category, data.purchase_rate, data.quantity, data.supplier_name, data.low_stock_limit, recordId, shopId));
      } else if (action === 'DELETE') {
        queries.push(c.env.DB.prepare(
          `DELETE FROM products WHERE product_id=? AND shop_id=?`
        ).bind(recordId, shopId));
      }
    } 
    else if (table === 'customers') {
      if (action === 'INSERT') {
        queries.push(c.env.DB.prepare(
          `INSERT INTO customers (customer_id, shop_id, name, phone, outstanding_balance) VALUES (?, ?, ?, ?, ?)`
        ).bind(recordId, shopId, data.name, data.phone, data.outstanding_balance || 0));
      } else if (action === 'UPDATE') {
        queries.push(c.env.DB.prepare(
          `UPDATE customers SET name=?, phone=?, outstanding_balance=? WHERE customer_id=? AND shop_id=?`
        ).bind(data.name, data.phone, data.outstanding_balance || 0, recordId, shopId));
      } else if (action === 'DELETE') {
        queries.push(c.env.DB.prepare(
          `DELETE FROM customers WHERE customer_id=? AND shop_id=?`
        ).bind(recordId, shopId));
      }
    }
    else if (table === 'bills') {
       if (action === 'INSERT') {
         const bill = data.bill;
         queries.push(c.env.DB.prepare(
          `INSERT INTO bills (bill_id, shop_id, customer_id, bill_number, subtotal, discount, grand_total, payment_method, payment_status, amount_paid) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
         ).bind(recordId, shopId, bill.customer_id || null, bill.bill_number || `INV-${Date.now()}`, bill.subtotal || 0, bill.discount || 0, bill.grand_total || 0, bill.payment_method || 'Cash', bill.payment_status || 'paid', bill.amount_paid || bill.grand_total));
         
         if (data.items && Array.isArray(data.items)) {
           for (const item of data.items) {
             queries.push(c.env.DB.prepare(
               `INSERT INTO bill_items (item_id, bill_id, product_id, quantity, price, total) VALUES (?, ?, ?, ?, ?, ?)`
             ).bind(crypto.randomUUID(), recordId, item.product_id, item.quantity, item.price, item.total));
           }
         }
       }
    }
  }

  try {
    if (queries.length > 0) {
      await c.env.DB.batch(queries);
    }
    return c.json({ success: true, message: 'Sync applied successfully', processed: logs.length });
  } catch (error: any) {
    return c.json({ success: false, message: error.message }, 500);
  }
});

export default syncApp;
