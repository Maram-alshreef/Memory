require('dotenv').config();

const express = require('express');
const cors = require('cors');
const crypto = require('crypto');

const app = express();

app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const otpStore = new Map();

function normalizeEmail(value) {
  return String(value || '').trim().toLowerCase();
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function generateOtp() {
  return String(crypto.randomInt(100000, 1000000));
}

function hashValue(value) {
  return crypto
    .createHash('sha256')
    .update(String(value))
    .digest('hex');
}

function createResetToken() {
  return crypto.randomBytes(32).toString('hex');
}

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}

function createOtpEmail(otp) {
  return `
    <!DOCTYPE html>
    <html lang="ar" dir="rtl">
      <head>
        <meta charset="UTF-8">
        <title>رمز التحقق</title>
      </head>
      <body style="font-family: Arial, sans-serif; direction: rtl;">
        <h2>My OTP App</h2>
        <p>رمز التحقق الخاص بك هو:</p>

        <div style="
          font-size: 32px;
          font-weight: bold;
          letter-spacing: 8px;
          color: #2563eb;
          margin: 24px 0;
        ">
          ${escapeHtml(otp)}
        </div>

        <p>صلاحية الرمز خمس دقائق.</p>
        <p>إذا لم تطلب إعادة تعيين كلمة المرور، فتجاهل هذه الرسالة.</p>
      </body>
    </html>
  `;
}

async function sendOtpEmail({ email, otp }) {
  const apiKey = process.env.BREVO_API_KEY;
  const senderEmail = process.env.MAIL_FROM;
  const senderName = process.env.MAIL_FROM_NAME || 'My OTP App';

  if (!apiKey) {
    throw new Error('BREVO_API_KEY غير موجود');
  }

  if (!senderEmail) {
    throw new Error('MAIL_FROM غير موجود');
  }

  const response = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: {
      accept: 'application/json',
      'api-key': apiKey,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      sender: {
        name: senderName,
        email: senderEmail,
      },
      to: [
        {
          email,
        },
      ],
      subject: 'رمز التحقق',
      htmlContent: createOtpEmail(otp),
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Brevo API error ${response.status}: ${errorText}`);
  }

  return response.json();
}

app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Backend يعمل',
  });
});

app.post('/auth/send-otp', async (req, res) => {
  try {
    const email = normalizeEmail(req.body.email);

    if (!isValidEmail(email)) {
      return res.status(400).json({
        success: false,
        message: 'البريد الإلكتروني غير صحيح',
      });
    }

    const oldRequest = otpStore.get(email);

    if (
      oldRequest &&
      Date.now() - oldRequest.createdAt < 60 * 1000
    ) {
      return res.status(429).json({
        success: false,
        message: 'انتظر دقيقة قبل طلب رمز جديد',
      });
    }

    const otp = generateOtp();

    await sendOtpEmail({
      email,
      otp,
    });

    otpStore.set(email, {
      otpHash: hashValue(otp),
      createdAt: Date.now(),
      expiresAt: Date.now() + 5 * 60 * 1000,
      attempts: 0,
      verified: false,
      resetToken: null,
      resetTokenExpiresAt: null,
    });

    return res.json({
      success: true,
      message: 'تم إرسال رمز التحقق إلى بريدك الإلكتروني',
    });
  } catch (error) {
    console.error('Brevo send error:', error.message);

    return res.status(500).json({
      success: false,
      message: 'تعذر إرسال رمز التحقق',
    });
  }
});

app.post('/auth/verify-otp', (req, res) => {
  const email = normalizeEmail(req.body.email);
  const otp = String(req.body.otp || '').trim();



  if (!isValidEmail(email) || !/^\d{6}$/.test(otp)) {
    return res.status(400).json({
      success: false,
      message: 'بيانات التحقق غير صحيحة',
    });
  }

  const record = otpStore.get(email);

  if (!record) {
    return res.status(400).json({
      success: false,
      message: 'لا يوجد رمز تحقق نشط',
    });
  }

  if (Date.now() > record.expiresAt) {
    otpStore.delete(email);

    return res.status(400).json({
      success: false,
      message: 'انتهت صلاحية رمز التحقق',
    });
  }

  if (record.attempts >= 5) {
    otpStore.delete(email);

    return res.status(429).json({
      success: false,
      message: 'تم تجاوز عدد المحاولات المسموح بها',
    });
  }

  record.attempts += 1;

  if (hashValue(otp) !== record.otpHash) {
    return res.status(400).json({
      success: false,
      message: 'رمز التحقق غير صحيح',
    });
  }

  const resetToken = createResetToken();

  record.verified = true;
  record.resetToken = resetToken;
  record.resetTokenExpiresAt = Date.now() + 10 * 60 * 1000;

  return res.json({
    success: true,
    message: 'تم التحقق من الرمز بنجاح',
    resetToken,
  });
});

app.post('/auth/reset-password', (req, res) => {
  const email = normalizeEmail(req.body.email);
  const resetToken = String(req.body.resetToken || '').trim();
  const newPassword = String(req.body.newPassword || '');

  if (!isValidEmail(email)) {
    return res.status(400).json({
      success: false,
      message: 'البريد الإلكتروني غير صحيح',
    });
  }

  if (resetToken.length < 20) {
    return res.status(400).json({
      success: false,
      message: 'رمز إعادة التعيين غير صحيح',
    });
  }

  if (newPassword.length < 8) {
    return res.status(400).json({
      success: false,
      message: 'كلمة المرور يجب أن تكون 8 أحرف على الأقل',
    });
  }

  const record = otpStore.get(email);

  if (!record || !record.verified) {
    return res.status(403).json({
      success: false,
      message: 'يجب التحقق من رمز OTP أولًا',
    });
  }

  if (
    !record.resetTokenExpiresAt ||
    Date.now() > record.resetTokenExpiresAt
  ) {
    otpStore.delete(email);

    return res.status(400).json({
      success: false,
      message: 'انتهت صلاحية جلسة إعادة التعيين',
    });
  }

  if (record.resetToken !== resetToken) {
    return res.status(403).json({
      success: false,
      message: 'رمز إعادة التعيين غير صحيح',
    });
  }

  otpStore.delete(email);

  return res.json({
    success: true,
    message: 'تم تغيير كلمة المرور بنجاح',
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Backend يعمل على المنفذ ${PORT}`);
});
