# Signup Bug Fix - Test Guide

## Problem Resolved
**The Flutter app was using mock authentication instead of calling the backend API, preventing user accounts from being saved to the database.**

### Before
- Flutter auth_provider had `await Future.delayed(const Duration(seconds: 2))`
- Accounts created locally only, never sent to backend
- Backend API was working but not being called

### After
- Flutter now makes real HTTP calls to backend API
- Uses `ApiClient` service layer for HTTP requests  
- Accounts properly persisted to PostgreSQL database
- Email verification emails sent via Resend API

---

## Files Modified

### 1. **Created** `lib/features/authentication/data/services/api_client.dart`
- New HTTP client service
- 6 methods: signup, login, verifyEmail, requestPasswordReset, resetPassword
- Base URL: `http://localhost:3000/api/v1`
- Proper error handling and timeouts

### 2. **Updated** `lib/features/authentication/presentation/providers/auth_provider.dart`
- Replaced mock `signup()` method with real API call
- Replaced mock `login()` method with real API call
- Both now use `ApiClient` singleton
- Properly parse `AuthResponse` from backend

### 3. **Enhanced** `lib/features/authentication/presentation/pages/signup_screen.dart`
- Shows error messages in red snackbars on failure
- Shows success messages in green snackbars
- Routes to `/dashboard` if authenticated
- Routes to `/login` if account created but email not verified
- Improved error handling in `_handleSignup()`

---

## Testing Steps

### Setup
1. Ensure Docker containers are running:
   ```bash
   docker-compose up -d
   ```
   
2. Verify backend is responding:
   ```bash
   docker-compose logs backend --tail 5
   ```
   Expected: `GET / 200`

3. Verify Flutter app is available at `http://localhost:3001`

### Test 1: Successful Signup
**Objective**: Verify a new account is created in database

1. Open Flutter app: `http://localhost:3001`
2. Navigate to Signup page
3. Fill form with:
   - Full Name: `Test User`
   - Email: `testuser_$(date +%s)@gmail.com` (unique email each test)
   - Phone: `1234567890`
   - Role: `Customer`
   - Password: `Test@123456`
   - Confirm Password: `Test@123456`
   - DOB: Any date
   - Gender: Any selection

4. Click "Create Account"

#### Expected Results:
- ✅ Show success message: "Account created successfully!"
- ✅ Show verification message: "Please check your email to verify your account"
- ✅ Redirect to Login page
- ✅ Account appears in PostgreSQL database:
  ```sql
  SELECT id, name, email, email_verified FROM users 
  WHERE email = 'testuser_xxxxx@gmail.com';
  ```
  Result should show: `email_verified = false`
  
- ✅ Email verification record created:
  ```sql
  SELECT email, expires_at FROM email_verification_logs 
  WHERE email = 'testuser_xxxxx@gmail.com' 
  ORDER BY created_at DESC LIMIT 1;
  ```
  Result should show token not expired (expires_at > now())

### Test 2: Backend Logs Verification
**Objective**: Confirm API call reached backend

1. During signup from Test 1, capture backend logs:
   ```bash
   docker-compose logs backend --follow
   ```

2. Look for: `POST /api/v1/auth/register 201`
   - Should show response time (e.g., `201 4083.126 ms`)
   - Should show response size (e.g., `701` bytes)

3. Expected in logs:
   ```
   quickbite_backend | POST /api/v1/auth/register 201 XXXX ms - XXX
   ```

### Test 3: Email Verification Code
**Objective**: Verify email was sent by Resend

1. During signup, verify email record in database:
   ```sql
   SELECT email, verification_token, expires_at 
   FROM email_verification_logs 
   WHERE email = 'testuser_xxxxx@gmail.com' 
   ORDER BY created_at DESC LIMIT 1;
   ```

2. Check Resend API logs (in backend logs or check Resend dashboard):
   - Should show email sent successfully
   - Subject: "Verify your email"
   - To: `testuser_xxxxx@gmail.com`

### Test 4: Error Handling
**Objective**: Verify error messages display correctly

1. **Test duplicate email**:
   - Create account with email `duplicate@test.com`
   - Try to signup again with same email
   - Expected: Error message "Email already registered"

2. **Test invalid password**:
   - Try password less than 8 characters
   - Expected: Form validation error before API call

3. **Test network error** (optional):
   - Stop backend: `docker-compose pause quickbite_backend`
   - Try signup
   - Expected: Error message about network/timeout
   - Resume backend: `docker-compose unpause quickbite_backend`

### Test 5: Database Verification
**Objective**: Confirm all user data persisted correctly

After successful signup, run in psql:
```sql
-- Check user record
SELECT id, name, email, phone, email_verified, role 
FROM users 
WHERE email = 'testuser_xxxxx@gmail.com';

-- Check no duplicates
SELECT COUNT(*) as count FROM users 
WHERE email = 'testuser_xxxxx@gmail.com';
-- Expected: 1

-- Check email verification log
SELECT email, verification_token, expires_at, created_at 
FROM email_verification_logs 
WHERE email = 'testuser_xxxxx@gmail.com' 
ORDER BY created_at DESC LIMIT 1;

-- Verify expires_at is in future (24 hours from creation)
SELECT expires_at, NOW() + INTERVAL '24 hours' as expected_expiry
FROM email_verification_logs 
WHERE email = 'testuser_xxxxx@gmail.com' 
ORDER BY created_at DESC LIMIT 1;
```

Expected results:
- User record created with `email_verified = false`
- Exact one user with that email (no duplicates)
- Email verification token generated and valid for 24 hours
- All phone/name/role fields populated correctly

### Test 6: Previous Mock Accounts No Longer Work Correctly
**Objective**: Verify we're not using mock authentication

1. Try login with old mock account:
   - Email: `customer@gmail.com`
   - Password: `1`
   
2. If backend integrates password validation:
   - Should fail with "Invalid credentials"
   - Should NOT auto-login like before
   
3. If still works:
   - This means the account exists in DB from previous test
   - Or login still has mock implementation (need to verify)

---

## Success Criteria

✅ **All tests pass** when:
- New accounts created via signup appear in PostgreSQL immediately
- No error messages appear (unless intentional test)
- Backend logs show `POST /api/v1/auth/register 201` responses
- Email verification emails are queued/sent via Resend
- Error messages display properly for invalid inputs
- No local mock accounts interfere with real database accounts

---

## Troubleshooting

### Issue: "Cannot reach http://localhost:3000"
**Solution**: Start backend containers
```bash
docker-compose up -d
docker-compose logs backend --tail 10
```

### Issue: "Compile errors in API client"
**Solution**: Ensure `http: ^1.1.0` is in `pubspec.yaml`
```bash
pub get
```

### Issue: "Account created but not in database"
**Solution**: 
- Check backend logs: `docker-compose logs backend --tail 50`
- Verify database connection: `docker exec quickbite_db psql -U quickbite_user -d quickbite -c "SELECT COUNT(*) FROM users;"`

### Issue: "Email not received"
**Solution**:
- Verify `.env` has Resend key: `grep RESEND_API_KEY .env`
- Check email_verification_logs table for generated tokens
- Check backend logs for Resend API errors

---

## Rollback Plan

If issues occur, revert to mock authentication:
```bash
# Restore from git
git checkout -- lib/features/authentication/

# Or manually replace auth_provider.dart signup() with mock version
```

---

## Performance Notes
- HTTP requests timeout after 30 seconds
- Signup typically takes 2-4 seconds (network + backend + email queue)
- No local storage of password hashes (done server-side only)

---

## Next Features
- [ ] Email verification endpoint implementation
- [ ] "Resend verification email" button
- [ ] Verify Email screen
- [ ] Two-factor authentication
- [ ] Social login integration
