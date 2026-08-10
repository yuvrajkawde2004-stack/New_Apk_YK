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
    else if (table === 'suppliers') {
      if (action === 'INSERT') {
        queries.push(c.env.DB.prepare(
          `INSERT INTO suppliers (supplier_id, shop_id, name, phone, address, total_purchased, total_paid, outstanding_due) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
        ).bind(recordId, shopId, data.name, data.phone || '', data.address || '', data.total_purchased || 0, data.total_paid || 0, data.outstanding_due || 0));
      } else if (action === 'UPDATE') {
        queries.push(c.env.DB.prepare(
          `UPDATE suppliers SET name=?, phone=?, address=?, total_purchased=?, total_paid=?, outstanding_due=? WHERE supplier_id=? AND shop_id=?`
        ).bind(data.name, data.phone || '', data.address || '', data.total_purchased || 0, data.total_paid || 0, data.outstanding_due || 0, recordId, shopId));
      } else if (action === 'DELETE') {
        queries.push(c.env.DB.prepare(
          `DELETE FROM suppliers WHERE supplier_id=? AND shop_id=?`
        ).bind(recordId, shopId));
      }
    }
    else if (table === 'purchases') {
      if (action === 'INSERT') {
        queries.push(c.env.DB.prepare(
          `INSERT INTO purchases (purchase_id, shop_id, product_id, product_name, supplier_name, purchase_rate, quantity, total_amount, paid_amount, due_amount, purchase_date, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
        ).bind(recordId, shopId, data.product_id || '', data.product_name || '', data.supplier_name || '', data.purchase_rate || 0, data.quantity || 0, data.total_amount || 0, data.paid_amount || 0, data.due_amount || 0, data.purchase_date || '', data.notes || ''));
      } else if (action === 'DELETE') {
        queries.push(c.env.DB.prepare(`DELETE FROM purchases WHERE purchase_id=? AND shop_id=?`).bind(recordId, shopId));
      }
    }
    else if (table === 'supplier_payments') {
      if (action === 'INSERT') {
        queries.push(c.env.DB.prepare(
          `INSERT INTO supplier_payments (payment_id, shop_id, supplier_name, amount_paid, payment_method, payment_date, notes) VALUES (?, ?, ?, ?, ?, ?, ?)`
        ).bind(recordId, shopId, data.supplier_name, data.amount_paid || 0, data.payment_method || 'Cash', data.payment_date || '', data.notes || ''));
      }
    }
    else if (table === 'customer_payments') {
      if (action === 'INSERT') {
        queries.push(c.env.DB.prepare(
          `INSERT INTO customer_payments (payment_id, shop_id, customer_id, bill_id, amount_paid, payment_method, payment_date) VALUES (?, ?, ?, ?, ?, ?, ?)`
        ).bind(recordId, shopId, data.customer_id, data.bill_id, data.amount_paid || 0, data.payment_method || 'Cash', data.payment_date || ''));
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
