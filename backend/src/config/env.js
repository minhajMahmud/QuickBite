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
};
