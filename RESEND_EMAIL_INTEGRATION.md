# QuickBite Resend Email Integration Guide 📧

## Overview

QuickBite now integrates **Resend** for reliable email notifications across authentication flows:
- ✅ **Email Verification** on account creation
- ✅ **Account Confirmation** emails
- ✅ **Forgot Password** with secure reset links
- ✅ **First-Time Login** welcome emails
- ✅ **Resend Verification** email functionality

---

## 📋 Setup Instructions

### Step 1: Get Your Resend API Key

1. Visit [Resend.com](https://resend.com)
2. Sign up / Log in to your account
3. Go to **API Keys** section
4. Create a new API key
5. Copy your API key (starts with `re_`)

### Step 2: Configure Environment Variables

Update [.env](.env) with your Resend credentials:

```env
# Resend Email Configuration
RESEND_API_KEY=re_your_api_key_here_replace_with_actual_key
RESEND_FROM_EMAIL=noreply@quickbite.com
RESEND_FROM_NAME=QuickBite

# Frontend URLs (for email links)
FRONTEND_URL=http://localhost:3001
EMAIL_VERIFICATION_URL=http://localhost:3001/verify-email
RESET_PASSWORD_URL=http://localhost:3001/reset-password
```

### Step 3: Install Dependencies

```bash
cd backend
npm install
```

This will install the `resend` package (already added to package.json).

### Step 4: Apply Database Migration

The migration has already been applied, which adds:
- `email_verified` column to users
- `email_verification_token` fields
- `password_reset_tokens` table
- `email_verification_logs` table
- `login_activity` table

To manually apply the migration:
```bash
docker exec -i quickbite_postgres psql -U quickbite_user -d quickbite < migrations/001_add_email_verification.sql
```

### Step 5: Restart Backend Service

```bash
docker-compose restart backend
```

---

## 🔐 API Endpoints

### 1. Register New User (with Email Verification)

**Endpoint:** `POST /api/v1/auth/register`

**Request:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "SecurePassword123!",
  "role": "customer"  // optional, defaults to "customer"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Account created! Please verify your email to continue.",
  "token": "eyJhbGc...",
  "requiresEmailVerification": true,
  "user": {
    "id": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "role": "customer",
    "emailVerified": false,
    "firstLogin": true
  }
}
```

**Emails Sent:**
1. **Verification Email** - Link to confirm email address (24-hour expiry)
2. **Account Confirmation** - Welcome email with getting started info

---

### 2. Verify Email Address

**Endpoint:** `POST /api/v1/auth/verify-email`

**Request:**
```json
{
  "email": "john@example.com",
  "token": "token_from_email_link"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Email verified successfully! You can now use all features."
}
```

---

### 3. Resend Verification Email

**Endpoint:** `POST /api/v1/auth/resend-verification`

Use this if user didn't receive the verification email.

**Request:**
```json
{
  "email": "john@example.com"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Verification email sent successfully"
}
```

---

### 4. Request Password Reset

**Endpoint:** `POST /api/v1/auth/forgot-password`

**Request:**
```json
{
  "email": "john@example.com"
}
```

**Response:**
```json
{
  "success": true,
  "message": "If that email address is in our system, we will send a password reset link"
}
```

**Emails Sent:**
- **Password Reset Email** - Secure link to reset password (1-hour expiry)

---

### 5. Reset Password with Token

**Endpoint:** `POST /api/v1/auth/reset-password`

**Request:**
```json
{
  "email": "john@example.com",
  "token": "reset_token_from_email",
  "newPassword": "NewSecurePassword123!"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Password reset successfully! You can now login with your new password."
}
```

---

### 6. Login User

**Endpoint:** `POST /api/v1/auth/login`

**Request:**
```json
{
  "email": "john@example.com",
  "password": "SecurePassword123!"
}
```

**Response:**
```json
{
  "success": true,
  "token": "eyJhbGc...",
  "isFirstLogin": true,
  "user": {
    "id": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "emailVerified": true,
    "firstLogin": false
  }
}
```

**Emails Sent (on first login):**
- **First Login Welcome Email** - Features and getting started guide

---

## 📧 Email Templates

### 1. Verification Email
- Header: Purple gradient background
- Content: Welcome message + verification button
- Token expiry: 24 hours
- Action: Click link to verify

### 2. Account Confirmation Email
- Header: Green gradient background  
- Content: Profile setup guide, next steps
- Immediate send: On registration

### 3. Password Reset Email
- Header: Pink/Red gradient background
- Content: Security notice + reset link
- Token expiry: 1 hour
- Warning: Informs user to contact support if not requested

### 4. First Login Welcome Email
- Header: Purple gradient background
- Content: Feature grid (Browse, Delivery, Coupons, Tracking)
- Action: "Start Ordering Now" button
- Personalized: Sent on first successful login

---

## 🔒 Security Features

### Token Management
- **Email Verification Tokens**: 32-byte random, 24-hour expiry
- **Password Reset Tokens**: Hashed with SHA-256, 1-hour expiry
- **Token Storage**: Only hashes stored in database, never plain tokens

### Password Security
- Bcrypt hashing with salt rounds = 10
- Password reset clears old tokens
- Last password change tracked

### First Login Tracking
- `first_login` flag tracks new users
- Email sent only on first successful login
- Flag cleared after first login

### Email Verification Process
- Non-verified users see message: "Please verify your email"
- Verification required for Restaurant/Delivery roles
- Customers can use app but with email verification banner

---

## 🚀 Testing the Integration

### Using cURL

```bash
# 1. Register user
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "TestPass123!",
    "role": "customer"
  }'

# 2. Request password reset
curl -X POST http://localhost:3000/api/v1/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com"
  }'

# 3. Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPass123!"
  }'
```

### Using Postman

1. Import the API endpoints
2. Set environment variable: `BASE_URL=http://localhost:3000`
3. Register a test user
4. Check your email for verification link
5. Verify email or request password reset

---

## 🐛 Troubleshooting

### Email Not Sending

**Problem:** "Failed to send verification email"

**Solutions:**
1. Verify `RESEND_API_KEY` is correct in .env
2. Check Docker backend container logs: `docker-compose logs backend`
3. Ensure `RESEND_FROM_EMAIL` matches your Resend domain
4. For production: Verify Resend domain is configured

```bash
docker-compose logs backend | grep -i "resend\|email"
```

### Token Expired

**Email verification token:** 24 hours
- Use `/api/v1/auth/resend-verification` to get new token

**Password reset token:** 1 hour
- Request new reset email via `/api/v1/auth/forgot-password`

### Email Verification Issues

**Problem:** User can't verify email

**Check database:**
```bash
# Connect to database
docker exec -it quickbite_postgres psql -U quickbite_user -d quickbite

# Check user status
SELECT id, email, email_verified, email_verification_token_expires_at 
FROM users 
WHERE email = 'user@example.com';
```

---

## 📊 Database Schema

### users table additions:
```sql
email_verified BOOLEAN DEFAULT FALSE
email_verification_token VARCHAR(500)
email_verification_token_expires_at TIMESTAMP
first_login BOOLEAN DEFAULT TRUE
last_password_change TIMESTAMP
password_reset_token VARCHAR(500)  -- Stored as hash
password_reset_token_expires_at TIMESTAMP
```

### New tables:
- `password_reset_tokens` - Track password reset requests
- `email_verification_logs` - Log verification attempts
- `login_activity` - Track login events and first login flag

---

## 🔄 Email Flow Diagrams

### Registration Flow
```
User > /auth/register
           ↓
    Create user (email_verified=false)
           ↓
    Generate 24h verification token
           ↓
    Send verification email + confirmation email
           ↓
    Return JWT token
           ↓
User clicks email link or uses token
           ↓
    /auth/verify-email
           ↓
    Set email_verified=true
           ↓
    User can now use full features
```

### Password Reset Flow
```
User > /auth/forgot-password
           ↓
    Generate 1h reset token
           ↓
    Hash and store token
           ↓
    Send reset email with token
           ↓
    Return success message
           ↓
User clicks email link
           ↓
    /auth/reset-password (with email, token, newPassword)
           ↓
    Verify token validity
           ↓
    Hash new password
           ↓
    Clear reset token
           ↓
    User can login with new password
```

### First Login Flow
```
User > /auth/login (first_login=true)
           ↓
    Verify credentials
           ↓
    Check first_login flag
           ↓
    IF first_login=true:
       - Send welcome email
       - Set first_login=false
           ↓
    Generate JWT token
           ↓
    Return token + isFirstLogin=true
           ↓
Frontend can show getting started guide
```

---

## 📝 Frontend Integration Example

### React Implementation

```javascript
// Registration with email verification
async function handleRegister(name, email, password) {
  const response = await fetch('http://localhost:3000/api/v1/auth/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name, email, password })
  });
  
  const data = await response.json();
  
  if (data.requiresEmailVerification) {
    // Show verification screen
    showVerificationScreen(email);
  }
  
  // Store token
  localStorage.setItem('token', data.token);
}

// Verify email with token from URL
async function handleEmailVerification(email, token) {
  const response = await fetch('http://localhost:3000/api/v1/auth/verify-email', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, token })
  });
  
  const data = await response.json();
  
  if (data.success) {
    // Redirect to dashboard
    window.location.href = '/dashboard';
  }
}

// Forgot password flow
async function handleForgotPassword(email) {
  const response = await fetch('http://localhost:3000/api/v1/auth/forgot-password', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email })
  });
  
  // Always show success message (don't reveal email existence)
  showMessage('Check your email for reset instructions');
}

// Reset password with token
async function handleResetPassword(email, token, newPassword) {
  const response = await fetch('http://localhost:3000/api/v1/auth/reset-password', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, token, newPassword })
  });
  
  const data = await response.json();
  
  if (data.success) {
    showMessage('Password reset! Redirecting to login...');
    setTimeout(() => window.location.href = '/login', 2000);
  }
}
```

---

## 🎯 Next Steps

1. **Add Frontend Routes:**
   - `/verify-email?token=...` - Email verification page
   - `/reset-password?token=...` - Password reset page
   - `/login` - Enhanced with forgot password link

2. **Add Email Preferences:**
   - User can manage email notification preferences
   - Unsubscribe links in emails

3. **Add 2FA Support:**
   - Optional two-factor authentication via email codes

4. **Monitor Email Metrics:**
   - Track delivery rates
   - Monitor bounce/complaint rates via Resend dashboard

---

## 📞 Support

For issues with:
- **Resend API:** Check [Resend docs](https://resend.com/docs)
- **QuickBite Backend:** Check backend logs: `docker-compose logs backend`
- **Database:** Connect via pgAdmin at http://localhost:5050

---

**Last Updated:** March 30, 2026
