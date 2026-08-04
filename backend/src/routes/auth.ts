import { Hono } from 'hono';
import { sign } from 'hono/jwt';
import { Bindings, JWTPayload } from '../types';

const authApp = new Hono<{ Bindings: Bindings }>();

// 1. Send OTP
authApp.post('/send-otp', async (c) => {
  try {
    const body = await c.req.json();
    const { target, type } = body; // target is email/mobile, type is 'mobile' or 'gmail'

    if (!target) {
      return c.json({ success: false, message: 'Target is required' }, 400);
    }

    const otpCode = Math.floor(1000 + Math.random() * 9000).toString();
    const expiresAt = new Date(Date.now() + 30 * 1000).toISOString(); // 30 seconds
    const id = crypto.randomUUID();

    await c.env.DB.prepare(
      `INSERT INTO otps (id, identifier, otp_code, expires_at) VALUES (?, ?, ?, ?)`
    ).bind(id, target, otpCode, expiresAt).run();

    // Integrate Twilio SMS API
    console.log(`[SIMULATED] Sending OTP ${otpCode} to ${target}`);

    try {
      const twilioAccountSid = 'AC5efee9d5d92f22fb650348a6b5b0bf15';
      const twilioApiKey = 'SK93278bfc2244cf138bacffd66dc9a041';
      const twilioApiSecret = 'QfDv9qDKAHHDEbYXagC29xJBYQb3rzfT';
      const twilioFromNumber: string = '+17372212163'; // User's Twilio Trial Number

      if (twilioFromNumber !== 'TWILIO_NUMBER_PLACEHOLDER') {
        const twilioUrl = `https://api.twilio.com/2010-04-01/Accounts/${twilioAccountSid}/Messages.json`;

        let toPhone = target;
        if (!toPhone.startsWith('+')) {
          toPhone = '+91' + toPhone; // Default to India if no country code
        }

        const formData = new URLSearchParams();
        formData.append('To', toPhone);
        formData.append('From', twilioFromNumber);
        formData.append('Body', `Your RetailFlow login OTP is: ${otpCode}`);

        const authHeader = 'Basic ' + btoa(`${twilioApiKey}:${twilioApiSecret}`);

        const twilioResponse = await fetch(twilioUrl, {
          method: 'POST',
          headers: {
            'Authorization': authHeader,
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          body: formData.toString()
        });

        if (!twilioResponse.ok) {
          const errText = await twilioResponse.text();
          console.error('Twilio Error:', errText);
          // For trial accounts, Twilio blocks custom SMS to India. We just log the error and continue.
        } else {
          console.log('Twilio SMS sent successfully');
        }
      }
    } catch (err: any) {
      console.error('Failed to send SMS via Twilio', err);
    }

    return c.json({
      success: true,
      message: `OTP sent successfully to ${target} (valid for 30s)`,
      debug_otp: otpCode
    });
  } catch (error: any) {
    return c.json({ success: false, message: error.message }, 500);
  }
});

// 2. Verify OTP
authApp.post('/verify-otp', async (c) => {
  try {
    const body = await c.req.json();
    const { target, code } = body;

    const result = await c.env.DB.prepare(
      `SELECT * FROM otps WHERE identifier = ? AND otp_code = ? ORDER BY created_at DESC LIMIT 1`
    ).bind(target, code).first();

    if (!result) {
      return c.json({ success: false, message: 'Invalid OTP' }, 400);
    }

    const now = new Date();
    const expiresAt = new Date(result.expires_at as string);
    if (now > expiresAt) {
      return c.json({ success: false, message: 'OTP has expired (exceeded 30 seconds)' }, 400);
    }

    // OTP is valid. Find or create user.
    let user = await c.env.DB.prepare(
      `SELECT * FROM users WHERE mobile = ? OR email = ?`
    ).bind(target, target).first();

    if (!user) {
      const userId = crypto.randomUUID();
      const isEmail = target.includes('@');

      await c.env.DB.prepare(
        `INSERT INTO users (user_id, ${isEmail ? 'email' : 'mobile'}) VALUES (?, ?)`
      ).bind(userId, target).run();

      user = { user_id: userId, mobile: !isEmail ? target : null, email: isEmail ? target : null };
    }

    // Check if user owns a shop, get the first shop ID as default
    const shop = await c.env.DB.prepare(
      `SELECT shop_id FROM shops WHERE owner_id = ? LIMIT 1`
    ).bind(user.user_id).first();

    const shopId = shop ? shop.shop_id : undefined;

    // Generate JWT
    const payload: JWTPayload = {
      userId: user.user_id as string,
      shopId: shopId as string | undefined,
      exp: Math.floor(Date.now() / 1000) + 60 * 60 * 24 * 30, // 30 days expiration
    };

    const token = await sign(payload, c.env.JWT_SECRET || 'fallback-secret-key-for-dev', 'HS256');

    // Delete used OTP
    await c.env.DB.prepare(`DELETE FROM otps WHERE id = ?`).bind(result.id).run();

    return c.json({
      success: true,
      token,
      user,
      message: 'Login successful'
    });
  } catch (error: any) {
    return c.json({ success: false, message: error.message }, 500);
  }
});

export default authApp;
