```js
require('dotenv').config();

const crypto = require('crypto');
const express = require('express');
const cors = require('cors');
const { Resend } = require('resend');

const app = express();
const port = Number(process.env.PORT || 3000);

const otpTtlMinutes = Number(process.env.OTP_TTL_MINUTES || 5);
const otpTtlMs = otpTtlMinutes * 60 * 1000;

const otpStore = new Map();

// Resend
const resend = new Resend(process.env.RESEND_API_KEY);

app.use(cors());
app.use(express.json());

function normalizeEmail(value) {
  return String(value || '').trim().toLowerCase();
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function hashCode(code) {
  return crypto.createHash('sha256').update(code).digest('hex');
}

function createCode() {
  return String(crypto.randomInt(100000, 1000000));
}

app.get('/', (_req, res) => {
  res.json({
    ok: true,
    message: 'Memora OTP server is running',
  });
});

app.get('/health', (_req, res) => {
  res.json({
    ok: true,
    message: 'Memora OTP server is working',
  });
});

app.post('/otp/request', async (req, res) => {
  const email = normalizeEmail(req.body.email);

  console.log('OTP request received:', email);

  if (!isValidEmail(email)) {
    return res.status(400).json({
      ok: false,
      message: 'البريد الإلكتروني غير صحيح',
    });
  }

  const code = createCode();
  const expiresAt = Date.now() + otpTtlMs;

  otpStore.set(email, {
    codeHash: hashCode(code),
    expiresAt,
  });

  try {
    console.log('Sending OTP using Resend...');

    const { data, error } = await resend.emails.send({
      from: 'Memora <onboarding@resend.dev>',
      to: [email],
      subject: 'رمز استعادة كلمة المرور - Memora',
      text: `رمز التحقق الخاص بك هو: ${code}\n\nالرمز صالح لمدة ${otpTtlMinutes} دقائق. لا تشاركه مع أي شخص.`,
      html: `
        <div dir="rtl" style="font-family:Arial,sans-serif;line-height:1.8">
          <h2>استعادة كلمة المرور - Memora</h2>

          <p>رمز التحقق الخاص بك هو:</p>

          <h1 style="letter-spacing:8px;color:#2E7D6E">
            ${code}
          </h1>

          <p>
            الرمز صالح لمدة ${otpTtlMinutes} دقائق.
          </p>

          <p>
            لا تشارك هذا الرمز مع أي شخص.
          </p>
        </div>
      `,
    });

    if (error) {
      throw new Error(error.message || 'Resend email error');
    }

    console.log('OTP email sent successfully');
    console.log('Resend email ID:', data?.id);

    return res.json({
      ok: true,
      message: 'تم إرسال رمز التحقق إلى البريد الإلكتروني',
    });
  } catch (error) {
    otpStore.delete(email);

    console.error('OTP email error:', error);

    return res.status(500).json({
      ok: false,
      message: 'تعذر إرسال رمز التحقق، حاول مرة أخرى',
    });
  }
});

app.post('/otp/verify', (req, res) => {
  const email = normalizeEmail(req.body.email);
  const code = String(req.body.code || '').trim();

  const record = otpStore.get(email);

  if (!record || Date.now() > record.expiresAt) {
    otpStore.delete(email);

    return res.status(400).json({
      ok: false,
      message: 'رمز التحقق منتهي أو غير موجود',
    });
  }

  if (!/^\d{6}$/.test(code) || hashCode(code) !== record.codeHash) {
    return res.status(400).json({
      ok: false,
      message: 'رمز التحقق غير صحيح',
    });
  }

  otpStore.delete(email);

  return res.json({
    ok: true,
    message: 'تم التحقق من الرمز بنجاح',
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Memora OTP server listening on port ${port}`);
});

setInterval(() => {
  const now = Date.now();

  for (const [email, record] of otpStore.entries()) {
    if (record.expiresAt <= now) {
      otpStore.delete(email);
    }
  }
}, 60 * 1000).unref();
```
