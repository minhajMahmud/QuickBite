# Customer Dashboard - Testing & Verification Guide

## 🧪 Testing the Dashboard

### Prerequisites
1. ✅ Backend running: `docker-compose up -d postgres pgadmin backend`
2. ✅ Flutter app running: `flutter run -d chrome --web-port=3003`
3. ✅ Logged in with valid user account

### Test Scenarios

## 1️⃣ User Stats Display Test

**Steps:**
1. Navigate to customer dashboard
2. Verify welcome message shows correct user name
3. Check KPI cards display:
   - Total Orders count
   - Total Spent amount
   - Loyalty Points
   - Saved Addresses
4. Verify all values are > 0 (if user has orders)

**Expected Output:**
```
Welcome back, [User Name]! 👋
Here's your account summary

[Total Orders Card]  [Total Spent Card]
[Loyalty Points]     [Saved Addresses]
```

**Validation via Backend:**
```bash
# Check user data
curl -X GET http://localhost:3000/api/v1/users/me \
  -H "Authorization: Bearer [TOKEN]"

# Check orders
curl -X GET http://localhost:3000/api/v1/orders \
  -H "Authorization: Bearer [TOKEN]"
```

---

## 2️⃣ Recent Orders Display Test

**Steps:**
1. On dashboard, scroll to "Recent Orders" section
2. Verify order cards show:
   - Restaurant name
   - Order date and time
   - Total amount ($)
   - Status badge (Delivered/Pending/Cancelled)
3. Click "View All →" to navigate to order history
4. Verify max 5 recent orders shown

**Expected Output:**
```
Recent Orders

[Restaurant Name] - $45.50          Feb 15, 2026 • 6:30 PM
[Delivered ✓] status badge

[Restaurant Name] - $32.00          Feb 14, 2026 • 5:15 PM
[Preparing...] status badge
```

**Database Verification:**
```bash
# Connect to PostgreSQL
docker exec -it quickbite_postgres psql -U quickbite_user -d quickbite

# Check user's orders
SELECT id, restaurant_name, total_amount, status, created_at 
FROM public.orders 
WHERE user_id = 'current-user-id' 
ORDER BY created_at DESC 
LIMIT 5;

# Check total spent
SELECT SUM(total_amount) FROM public.orders WHERE user_id = 'user-id';
```

---

## 3️⃣ Loading State Test

**Steps:**
1. Open dashboard
2. Network tab should show API calls
3. Verify loading spinner appears briefly
4. Data loads and displays after 1-2 seconds

**Verification:**
```bash
# Monitor backend logs
docker logs -f quickbite_backend | grep -i "GET /api/v1"
```

Expected logs:
```
📊 Fetching user stats from http://localhost:3000/api/v1/users/me
✅ User stats received: {...}
📋 Fetching recent orders from http://localhost:3000/api/v1/orders
✅ Orders received: [...]
```

---

## 4️⃣ Error Handling Test

**Steps:**
1. Stop backend: `docker-compose down backend`
2. Try loading dashboard
3. Verify error message displays
4. Click "Retry" button
5. Restart backend: `docker-compose up -d backend`
6. Verify data loads on retry

**Expected Error Display:**
```
❌ Error Loading Dashboard
Connection refused: Connection attempt to http://localhost:3000
[Retry Button]
```

---

## 5️⃣ Refresh Functionality Test

**Steps:**
1. Dashboard loads with data
2. Create new order in app
3. Pull down on dashboard (refresh gesture)
4. Verify "Recent Orders" updates with new order
5. Click refresh button in AppBar
6. Verify data re-fetches

**Verification:**
```bash
# Check latest order
curl -X GET http://localhost:3000/api/v1/orders \
  -H "Authorization: Bearer [TOKEN]" | jq '.[0]'
```

---

## 6️⃣ Status Badge Colors Test

**Test Cases:**
| Status | Expected Color | Badge Text |
|--------|---|---|
| delivered | Green | Delivered ✓ |
| pending | Orange | Preparing... |
| cancelled | Red | Cancelled |

**Verification:**
```bash
# Create order with different status
docker exec quickbite_postgres psql -U quickbite_user -d quickbite \
  -c "UPDATE public.orders SET status='pending' WHERE id='order-xyz';"

# Refresh dashboard and verify badge color
```

---

## 7️⃣ Responsive Design Test

**Mobile (< 600px):**
1. Open in Chrome DevTools - Mobile view
2. KPI cards in 2xN grid
3. Verify text readable
4. Verify spacing comfortable

**Tablet (600px - 900px):**
1. Resize window to ~600px
2. KPI cards in 2xN grid
3. Verify layout maintains

**Desktop (> 900px):**
1. Maximize window
2. KPI cards in 4x1 grid
3. All content visible without scrolling initially

---

## 8️⃣ Navigation Test

**Steps:**
1. From dashboard, click menu items:
   - "Order History" → `/dashboard/orders`
   - "Favorites" → `/dashboard/favorites`
   - "Addresses" → `/dashboard/addresses`
   - "Notifications" → `/dashboard/notifications`
   - "Settings" → `/dashboard/settings`
2. Verify page navigation works

**Note:** Other dashboard pages may need to be implemented

---

## 9️⃣ Data Accuracy Test

**Test Case 1: Order Count**
```bash
# In database
SELECT COUNT(*) FROM public.orders WHERE user_id = 'user-id';

# Compare with dashboard "Total Orders" card value
```

**Test Case 2: Total Spent Amount**
```bash
# In database
SELECT SUM(total_amount) FROM public.orders WHERE user_id = 'user-id';

# Compare with dashboard "Total Spent" card value
```

**Test Case 3: Date Formatting**
```bash
# Database stores date as ISO string
SELECT created_at FROM public.orders WHERE user_id = 'user-id' LIMIT 1;
# Example: 2026-03-31T10:30:00Z

# Dashboard should format as: Mar 31, 2026 • 10:30 AM
```

---

## 🔟 Performance Test

**Metrics:**
1. Dashboard load time < 3 seconds
2. Refresh time < 2 seconds
3. No jank or stuttering during scroll
4. Network requests batched efficiently

**Verification:**
```bash
# Monitor in Chrome DevTools
1. Open Network tab
2. Filter for XHR requests
3. Check request size and response time

Expected:
- GET /users/me - ~200-500ms
- GET /orders - ~200-500ms
- Total time < 1 second for both
```

---

## 📊 Testing with Real Data

### Scenario 1: New User (No Orders)
1. Create new user account
2. Navigate to dashboard
3. Verify:
   - Welcome shows correct name
   - All KPI values are 0
   - "Recent Orders" shows empty state
   - "No orders yet" + "Start Ordering" button shown

### Scenario 2: User with Multiple Orders
1. Use existing user with orders
2. Verify:
   - Total Orders > 0
   - Total Spent calculated correctly
   - All 5 recent orders display
   - Status badges show correctly

### Scenario 3: Order Status Updates
1. Place new order
2. Dashboard shows "Pending" status
3. Update order status: `UPDATE orders SET status='delivered' WHERE id='...';`
4. Refresh dashboard
5. Status changes to "Delivered ✓"

---

## 🔍 Backend API Response Validation

### /api/v1/users/me Response
```json
{
  "id": "user-123",
  "name": "Ahmed Hassan",
  "email": "ahmed@example.com",
  "phone": "01700000000",
  "loyaltyPoints": 2540,
  "savedAddresses": 3,
  "createdAt": "2026-01-15T08:00:00Z",
  "updatedAt": "2026-03-31T12:00:00Z"
}
```

**Validation:**
```bash
curl -X GET http://localhost:3000/api/v1/users/me \
  -H "Authorization: Bearer [YOUR_TOKEN]" \
  -H "Content-Type: application/json" | jq '.'
```

### /api/v1/orders Response
```json
[
  {
    "id": "order-1",
    "userId": "user-123",
    "restaurantId": "rest-1",
    "restaurantName": "Pizza Palace",
    "items": [
      {
        "itemId": "item-1",
        "name": "Margherita Pizza",
        "quantity": 1,
        "price": 15.00
      }
    ],
    "totalAmount": 45.50,
    "deliveryFee": 2.00,
    "status": "delivered",
    "createdAt": "2026-02-15T18:30:00Z",
    "updatedAt": "2026-02-15T19:15:00Z"
  }
]
```

**Validation:**
```bash
curl -X GET http://localhost:3000/api/v1/orders \
  -H "Authorization: Bearer [YOUR_TOKEN]" \
  -H "Content-Type: application/json" | jq '.'
```

---

## ✅ Checklist

- [ ] Backend is running and responsive
- [ ] User is authenticated (valid token)
- [ ] Dashboard loads without errors
- [ ] User stats display correct values
- [ ] Recent orders show formatted correctly
- [ ] Status badges show with correct colors
- [ ] Refresh functionality works
- [ ] Error states handle gracefully
- [ ] Pull-to-refresh works
- [ ] Navigation to menu items works
- [ ] Responsive design works on all screens
- [ ] Data matches database values
- [ ] Performance is acceptable
- [ ] All dates/times formatted correctly

---

## 🚨 Common Issues & Solutions

### Issue 1: "Connection refused" error
**Solution:**
```bash
# Check backend status
docker ps | grep backend

# If not running:
docker-compose up -d backend

# Check logs:
docker logs quickbite_backend | tail -20
```

### Issue 2: Dashboard shows 0 for all stats
**Solution:**
```bash
# Verify user has orders
docker exec quickbite_postgres psql -U quickbite_user -d quickbite \
  -c "SELECT COUNT(*) FROM public.orders WHERE user_id = '...'"

# If 0, create test data or place a new order
```

### Issue 3: Incorrect total spent calculation
**Solution:**
```bash
# Check order amounts in database
docker exec quickbite_postgres psql -U quickbite_user -d quickbite \
  -c "SELECT id, total_amount FROM public.orders WHERE user_id = '...'"

# Verify API calculates SUM correctly
# Check DashboardApiService._calculateTotalSpent() implementation
```

### Issue 4: Status badges showing wrong colors
**Solution:**
Check _OrderCard._getStatusColor() method in customer_dashboard_screen.dart
Ensure status values match expected enum values exactly

---

## 📈 Performance Benchmarks

**Target Metrics:**
- Page load: < 2 seconds
- API response: < 500ms
- UI render: < 100ms
- Memory usage: < 50MB

**Monitoring:**
```bash
# In Chrome DevTools - Performance tab:
1. Press F12
2. Go to Performance tab
3. Record page load
4. Check for Performance Issues
```

---

## 🎯 Success Criteria

✅ Dashboard loads real data from backend
✅ All KPI values match database
✅ Recent orders display with correct formatting
✅ Status badges render with proper colors
✅ User is greeted by name
✅ Refresh functionality works
✅ Error states handled gracefully
✅ Responsive on all screen sizes
✅ No console errors or warnings
✅ Performance acceptable
