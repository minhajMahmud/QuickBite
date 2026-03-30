require('dotenv').config();

module.exports = {
  nodeEnv: process.env.ENV || process.env.NODE_ENV || 'development',
  apiPort: Number(process.env.API_PORT || 3000),
  jwtSecret: process.env.JWT_SECRET || 'replace_me_with_secure_value',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  db: {
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 5432),
    user: process.env.DB_USER || 'quickbite_user',
    password: process.env.DB_PASSWORD || 'quickbite_password_2024',
    database: process.env.DB_NAME || 'quickbite',
  },
  resend: {
    apiKey: process.env.RESEND_API_KEY || '',
    fromEmail: process.env.RESEND_FROM_EMAIL || 'noreply@quickbite.com',
    fromName: process.env.RESEND_FROM_NAME || 'QuickBite',
  },
  frontend: {
    url: process.env.FRONTEND_URL || 'http://localhost:3001',
    emailVerificationUrl: process.env.EMAIL_VERIFICATION_URL || 'http://localhost:3001/verify-email',
    resetPasswordUrl: process.env.RESET_PASSWORD_URL || 'http://localhost:3001/reset-password',
  },
  tokenExpiry: {
    emailVerification: '24h',
    passwordReset: '1h',
  },
};
