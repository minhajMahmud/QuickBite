# Resend Email Integration - Quick Setup Card ⚡

## 1️⃣ Get API Key (2 minutes)
- Go to https://resend.com
- Create account / Login
- Generate API key (starts with `re_`)
- Copy the key

## 2️⃣ Add to .env (1 minute)
```env
RESEND_API_KEY=re_your_key_here
RESEND_FROM_EMAIL=noreply@quickbite.com
RESEND_FROM_NAME=QuickBite
FRONTEND_URL=http://localhost:3001
EMAIL_VERIFICATION_URL=http://localhost:3001/verify-email
RESET_PASSWORD_URL=http://localhost:3001/reset-password
```

## 3️⃣ Install & Restart (2 minutes)
```bash
cd backend
npm install
docker-compose restart backend
```

## 4️⃣ Migration Already Applied ✅
Database tables and columns were already created:
- ✅ email_verified
- ✅ password_reset_tokens table
- ✅ email_verification_logs table
- ✅ login_activity table

## 5️⃣ Test the Integration (5 minutes)

### Test Registration & Verification
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "Test123!Pass"
  }'
```

Response includes `token` and `requiresEmailVerification: true`

Check your email for verification link!

### Test Forgot Password
```bash
curl -X POST http://localhost:3000/api/v1/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'
```

Check your email for password reset link!

### Test Login (First Time)
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!Pass"
  }'
```

You'll receive a welcome email on first login!

---

## 📌 API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/v1/auth/register` | Create account + send verification email |
| POST | `/api/v1/auth/login` | Login + send welcome email (first login) |
| POST | `/api/v1/auth/verify-email` | Verify email with token |
| POST | `/api/v1/auth/resend-verification` | Resend verification email |
| POST | `/api/v1/auth/forgot-password` | Request password reset |
| POST | `/api/v1/auth/reset-password` | Reset password with token |

---

## 📧 Emails You'll Receive

1. **Registration:**
   - ✉️ Email Verification (24h link)
   - ✉️ Account Confirmation

2. **Password Recovery:**
   - ✉️ Password Reset Link (1h expiry)

3. **First Login:**
   - ✉️ Welcome Message

---

## ⚙️ Configuration

### Token Expiries
- Email Verification: **24 hours**
- Password Reset: **1 hour**
- JWT Token: **7 days** (configurable)

### Email Sender
- Name: `QuickBite` (configurable in RESEND_FROM_NAME)
- Email: `noreply@quickbite.com` (must match Resend domain)

### Frontend URLs
- Verification: `http://localhost:3001/verify-email?token=...`
- Reset: `http://localhost:3001/reset-password?token=...`

---

## 🔐 Security

✅ **Password Hashing:** Bcrypt (10 salt rounds)
✅ **Token Hashing:** SHA-256 (for reset tokens)
✅ **Token Generation:** 32-byte cryptographic random
✅ **Email Existence:** Not revealed in forgot password field
✅ **Rate Limiting:** Configure in backend if needed

---

## 🐛 Troubleshooting

**Email not working?**
1. Check RESEND_API_KEY in .env
2. View logs: `docker-compose logs backend`
3. Verify Resend domain configuration
4. Check spam/junk folder

**Token expired?**
- Use resend endpoints to get new tokens
- Verification: `/api/v1/auth/resend-verification`
- Password reset: `/api/v1/auth/forgot-password`

**Testing without real email?**
- Use email testing service like Mailinator
- Check Resend dashboard for email logs

---

## 📚 Full Documentation

See [RESEND_EMAIL_INTEGRATION.md](./RESEND_EMAIL_INTEGRATION.md) for:
- Complete API documentation
- Frontend integration examples
- Database schema details
- Email flow diagrams
- Production setup

---

## ✅ Checklist

- [ ] Got Resend API key from https://resend.com
- [ ] Added RESEND_API_KEY to .env
- [ ] Installed dependencies: `npm install`
- [ ] Restarted backend: `docker-compose restart backend`
- [ ] Tested registration endpoint
- [ ] Checked email for verification link
- [ ] Tested forgot password endpoint
- [ ] Tested login and received welcome email
- [ ] Updated frontend with new auth screens
- [ ] Deployed to production 🚀

---

**Created:** March 30, 2026
**Status:** Ready for Production ✅
