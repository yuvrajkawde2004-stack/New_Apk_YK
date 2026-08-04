/**
 * Cloudflare Worker Backend API for Manisha Collection Retail Management System
 * Integrates Cloudflare D1 (SQLite) and Cloudflare R2 (PDF/Image Storage)
 */

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const path = url.pathname;
    const method = request.method;

    // CORS Headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Content-Type': 'application/json',
    };

    if (method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    try {
      // 1. Health check
      if (path === '/' || path === '/api/health') {
        return new Response(
          JSON.stringify({ status: 'ok', service: 'Cloudflare Workers Backend API (D1 + R2)' }),
          { headers: corsHeaders }
        );
      }

      // 2. Auth: Send OTP
      if (path === '/api/auth/send-otp' && method === 'POST') {
        const body = await request.json();
        const { target, type } = body; // target = phone/email, type = 'mobile' | 'gmail'

        const code = Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit OTP
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString(); // 5 mins

        await env.DB.prepare(
          'INSERT INTO otps (target, code, expires_at) VALUES (?, ?, ?)'
        ).bind(target, code, expiresAt).run();

        return new Response(
          JSON.stringify({ success: true, message: `OTP sent to ${target}`, code: code }),
          { headers: corsHeaders }
        );
      }

      // 3. Auth: Verify OTP
      if (path === '/api/auth/verify-otp' && method === 'POST') {
        const body = await request.json();
        const { target, code } = body;

        const record = await env.DB.prepare(
          'SELECT * FROM otps WHERE target = ? AND code = ? ORDER BY created_at DESC LIMIT 1'
        ).bind(target, code).first();

        if (!record) {
          return new Response(
            JSON.stringify({ success: false, message: 'Invalid OTP' }),
            { status: 400, headers: corsHeaders }
          );
        }

        // Register user if not existing
        await env.DB.prepare(
          'INSERT OR IGNORE INTO users (target, auth_type) VALUES (?, ?)'
        ).bind(target, target.includes('@') ? 'gmail' : 'mobile').run();

        return new Response(
          JSON.stringify({ success: true, message: 'Auth successful', token: `token_${Date.now()}` }),
          { headers: corsHeaders }
        );
      }

      // 4. Customers API
      if (path === '/api/customers' && method === 'GET') {
        const { results } = await env.DB.prepare('SELECT * FROM customers ORDER BY id DESC').all();
        return new Response(JSON.stringify({ success: true, data: results }), { headers: corsHeaders });
      }

      if (path === '/api/customers' && method === 'POST') {
        const body = await request.json();
        const { name, phone, email, outstanding_balance, notes } = body;

        const res = await env.DB.prepare(
          'INSERT INTO customers (name, phone, email, outstanding_balance, notes) VALUES (?, ?, ?, ?, ?)'
        ).bind(name, phone || '', email || '', outstanding_balance || 0, notes || '').run();

        return new Response(
          JSON.stringify({ success: true, id: res.meta.last_row_id }),
          { headers: corsHeaders }
        );
      }

      // 5. Products API
      if (path === '/api/products' && method === 'GET') {
        const { results } = await env.DB.prepare('SELECT * FROM products ORDER BY id DESC').all();
        return new Response(JSON.stringify({ success: true, data: results }), { headers: corsHeaders });
      }

      if (path === '/api/products' && method === 'POST') {
        const body = await request.json();
        const { name, category, price, stock, sku } = body;

        const res = await env.DB.prepare(
          'INSERT INTO products (name, category, price, stock, sku) VALUES (?, ?, ?, ?, ?)'
        ).bind(name, category, price, stock || 0, sku || `SKU-${Date.now()}`).run();

        return new Response(
          JSON.stringify({ success: true, id: res.meta.last_row_id }),
          { headers: corsHeaders }
        );
      }

      // 6. Bills API
      if (path === '/api/bills' && method === 'GET') {
        const { results } = await env.DB.prepare('SELECT * FROM bills ORDER BY id DESC').all();
        return new Response(JSON.stringify({ success: true, data: results }), { headers: corsHeaders });
      }

      // 7. Cloudflare R2 Upload Backup (Images / PDF Invoices)
      if (path === '/api/backup/upload-r2' && method === 'POST') {
        const formData = await request.formData();
        const file = formData.get('file');
        const filename = formData.get('filename') || `backup_${Date.now()}.pdf`;

        if (!file) {
          return new Response(
            JSON.stringify({ success: false, message: 'No file provided' }),
            { status: 400, headers: corsHeaders }
          );
        }

        await env.STORAGE.put(filename, file.stream(), {
          httpMetadata: { contentType: file.type || 'application/pdf' },
        });

        const publicUrl = `https://r2.manishacollection.com/${filename}`;
        return new Response(
          JSON.stringify({ success: true, file_url: publicUrl }),
          { headers: corsHeaders }
        );
      }

      return new Response(
        JSON.stringify({ error: 'Endpoint Not Found' }),
        { status: 404, headers: corsHeaders }
      );
    } catch (err) {
      return new Response(
        JSON.stringify({ success: false, error: err.message }),
        { status: 500, headers: corsHeaders }
      );
    }
  },
};
