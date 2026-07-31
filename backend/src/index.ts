import { Hono } from 'hono';
import { cors } from 'hono/cors';

type Bindings = {
  DB: D1Database;
};

const app = new Hono<{ Bindings: Bindings }>();

// Enable CORS for frontend requests
app.use('*', cors());

// Basic health check
app.get('/', (c) => c.text('RetailFlow Cloudflare Backend API is running!'));

// ==========================================
// AUTHENTICATION & OTP
// ==========================================

// Send OTP
app.post('/api/auth/send-otp', async (c) => {
  const body = await c.req.json();
  const { identifier } = body; // Mobile or Email

  if (!identifier) {
    return c.json({ error: 'Identifier is required' }, 400);
  }

  // Generate a random 4-digit OTP
  const otpCode = Math.floor(1000 + Math.random() * 9000).toString();
  
  // Set expiration to 30 seconds from now
  const expiresAt = new Date(Date.now() + 30 * 1000).toISOString();
  const id = crypto.randomUUID();

  // Save to database
  await c.env.DB.prepare(
    `INSERT INTO otps (id, identifier, otp_code, expires_at) VALUES (?, ?, ?, ?)`
  ).bind(id, identifier, otpCode, expiresAt).run();

  // In production, integrate SMS/Email provider here
  // console.log(`Sending OTP ${otpCode} to ${identifier}`);

  return c.json({ success: true, message: 'OTP sent successfully (valid for 30s)', debug_otp: otpCode });
});

// Verify OTP
app.post('/api/auth/verify-otp', async (c) => {
  const body = await c.req.json();
  const { identifier, otpCode } = body;

  // Find the OTP
  const result = await c.env.DB.prepare(
    `SELECT * FROM otps WHERE identifier = ? AND otp_code = ? ORDER BY created_at DESC LIMIT 1`
  ).bind(identifier, otpCode).first();

  if (!result) {
    return c.json({ error: 'Invalid OTP' }, 400);
  }

  // Check if expired
  const now = new Date();
  const expiresAt = new Date(result.expires_at as string);
  
  if (now > expiresAt) {
    return c.json({ error: 'OTP has expired (exceeded 30 seconds)' }, 400);
  }

  // OTP is valid. Now check if user exists.
  let user = await c.env.DB.prepare(
    `SELECT * FROM users WHERE mobile = ? OR email = ?`
  ).bind(identifier, identifier).first();

  if (!user) {
    // Create new user with a unique user_id
    const userId = crypto.randomUUID();
    await c.env.DB.prepare(
      `INSERT INTO users (user_id, mobile) VALUES (?, ?)`
    ).bind(userId, identifier).run();

    user = { user_id: userId, mobile: identifier };
  }

  // Generate a basic session token (In production, use JWT)
  const token = btoa(JSON.stringify({ userId: user.user_id, identifier }));

  // Delete the used OTP
  await c.env.DB.prepare(`DELETE FROM otps WHERE id = ?`).bind(result.id).run();

  return c.json({ 
    success: true, 
    token, 
    user,
    message: 'Login successful' 
  });
});

export default app;
