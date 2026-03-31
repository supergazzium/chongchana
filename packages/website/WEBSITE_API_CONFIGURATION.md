# Website API Configuration & Route Documentation

## Overview
This document outlines all API routes, authentication flows, and security configurations for the Chongjaroen website.

**Last Updated:** March 22, 2026
**Backend URL:** http://localhost:7001 (development)
**Website URL:** http://localhost:8080 (development)

---

## 🔐 Authentication Routes

### 1. User Login
**Endpoint:** `POST /auth/local`
**Authentication:** None (public)
**Request Body:**
```json
{
  "identifier": "user@example.com or phone",
  "password": "password"
}
```
**Response:**
```json
{
  "jwt": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "username": "user@example.com",
    "email": "user@example.com",
    ...
  }
}
```
**Used in:** `/pages/signin.vue`
**Security:** ✅ Brute-force protection recommended (not yet implemented)

### 2. User Registration
**Endpoint:** `POST /api/signup`
**Authentication:** None (public)
**Content-Type:** `multipart/form-data`
**Request Fields:**
- `email` (required)
- `username` (required, auto-set to email)
- `password` (required)
- `firstname` (required)
- `lastname` (required)
- `phone` (required)
- `birthdate` (required, ISO format)
- `gender` (required)

**Response:**
```json
{
  "user": {
    "id": 1,
    "username": "user@example.com",
    ...
  }
}
```
**Used in:** `/pages/signup.vue`
**Security:** ✅ Input validation required

### 3. Get Current User
**Endpoint:** `GET /users/me`
**Authentication:** Required (Bearer token)
**Headers:**
```
Authorization: Bearer {jwt_token}
```
**Response:**
```json
{
  "id": 1,
  "username": "user@example.com",
  "email": "user@example.com",
  ...
}
```
**Used in:** Multiple components via `$auth.fetchUser()`
**Security:** ✅ Protected by JWT authentication

---

## 👤 User Management Routes

### 4. Update User Profile
**Endpoint:** `PUT /users/:id`
**Authentication:** Required (Bearer token)
**Request Body:**
```json
{
  "firstname": "Updated",
  "lastname": "Name",
  ...
}
```
**Used in:** `/plugins/mixins.js` (__updateUser method)
**Security:** ✅ Users can only update their own profile

### 5. Change Profile Image
**Endpoint:** `POST /api/change-profile-image`
**Authentication:** Required (Bearer token)
**Content-Type:** `multipart/form-data`
**Request Fields:**
- `id` (user ID)
- `files` (image file)

**Used in:** `/plugins/mixins.js` (__changeProfileImage method)
**Security:** ✅ File upload validation recommended

### 6. Change Password
**Endpoint:** `POST /api/change-password`
**Authentication:** Required (Bearer token)
**Request Body:**
```json
{
  "currentPassword": "old_password",
  "newPassword": "new_password"
}
```
**Used in:** `/pages/account/password.vue`
**Security:** ✅ Validates current password before update

---

## 🏠 Public Content Routes

### 7. App Initialization Data
**Endpoint:** `GET /api/app-init`
**Authentication:** None (public)
**Response:** Branch information, menus, settings
**Used in:** Website initialization, homepage
**Security:** ✅ Public data only

### 8. Articles
**Endpoint:** `GET /articles`
**Query Parameters:**
- `_sort` (e.g., `published_at:DESC`)
- `_limit` (default: 10)
- `_start` (pagination offset)

**Authentication:** None (public)
**Response:** Array of articles
**Used in:** News section
**Security:** ✅ Public data only

### 9. Events
**Endpoint:** `GET /events`
**Authentication:** None (public)
**Response:** Array of events
**Used in:** Events section
**Security:** ✅ Public data only

---

## 💰 Wallet & Payment Routes

### 10. Get Wallet Balance
**Endpoint:** `GET /api/wallet/balance`
**Authentication:** Required (Bearer token)
**Response:**
```json
{
  "data": {
    "balance": 1000.00,
    "points": 50
  }
}
```
**Security:** ✅ User-specific data

### 11. Get Wallet Transactions
**Endpoint:** `GET /api/wallet/transactions`
**Authentication:** Required (Bearer token)
**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 20)

**Response:**
```json
{
  "data": {
    "transactions": [...],
    "pagination": {...}
  }
}
```
**Security:** ✅ User-specific data

### 12. Create Payment Source (PromptPay/Mobile Banking)
**Endpoint:** `POST /api/wallet/payment/create-source`
**Authentication:** Required (Bearer token)
**Request Body:**
```json
{
  "amount": 1000,
  "currency": "THB",
  "paymentMethod": "promptpay or mobile_banking_scb",
  "returnUri": "chongjaroen://payment-result",
  "platformType": "IOS or ANDROID"
}
```
**Response:**
```json
{
  "data": {
    "chargeId": "chrg_xxx",
    "authorizeUri": "https://...",
    "scannableCode": {
      "type": "qr",
      "image": {...}
    }
  }
}
```
**Security:** ✅ Omise payment gateway integration, server-side tokenization only

### 13. Check Payment Status
**Endpoint:** `GET /api/wallet/payment/status/:chargeId`
**Authentication:** Required (Bearer token)
**Response:**
```json
{
  "data": {
    "chargeId": "chrg_xxx",
    "status": "successful",
    "paid": true,
    "amount": 1000
  }
}
```
**Security:** ✅ User can only check their own charges

### 14. Payment Webhook (Omise)
**Endpoint:** `POST /api/wallet/payment/webhook`
**Authentication:** IP whitelist (Omise servers only)
**Security:** ✅ IP verification, idempotency, duplicate prevention

### 15. Transfer Funds
**Endpoint:** `POST /wallet/transfer`
**Authentication:** Required (Bearer token)
**Request Body:**
```json
{
  "receiverUserId": 123,
  "amount": 100,
  "description": "Transfer",
  "idempotencyKey": "unique-key"
}
```
**Security:**
- ✅ Rate limiting: 10 requests/minute
- ✅ Idempotency: Prevents duplicate transfers
- ✅ Amount limits: ฿1 - ฿50,000
- ✅ Balance validation

### 16. Lookup User for Transfer
**Endpoint:** `POST /wallet/lookup-user`
**Authentication:** Required (Bearer token)
**Request Body:**
```json
{
  "phoneNumber": "0812345678"
}
```
**Security:** ✅ Returns minimal user info, prevents self-transfer

### 17. Get Transfer History
**Endpoint:** `GET /wallet/transfers`
**Authentication:** Required (Bearer token)
**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 20)
- `type` (sent, received, or all)

**Security:** ✅ User-specific data only

---

## 📅 Booking Routes

### 18. Create Booking
**Endpoint:** `POST /api/create-booking`
**Authentication:** Required (Bearer token)
**Request Body:**
```json
{
  "branch": 1,
  "date": "2026-03-25",
  "time": "19:00",
  "guests": 4,
  ...
}
```
**Security:** ✅ User-specific bookings

### 19. Get User Bookings
**Endpoint:** `GET /api/get-bookings`
**Authentication:** Required (Bearer token)
**Security:** ✅ User-specific bookings only

### 20. Cancel Booking
**Endpoint:** `GET /api/cancel-booking?id=:bookingId`
**Authentication:** Required (Bearer token)
**Security:** ✅ User can only cancel their own bookings

---

## 🔒 Security Configurations

### CORS Settings
**File:** `/packages/backend/.env`
```
CORS_ORIGIN=http://localhost:3000,http://localhost:4040,http://localhost:7001,http://localhost:8080
```
**Status:** ✅ Configured for all frontend applications

### Authentication Strategy
- **Type:** JWT (JSON Web Token)
- **Storage:** Client-side (localStorage via @nuxtjs/auth)
- **Expiration:** Configured in Strapi (default: 30 days)
- **Refresh:** Not implemented (tokens expire, user must re-login)

### PCI-DSS Compliance
- ✅ **No server-side card handling** - Card tokenization is client-side only via Omise.js
- ✅ **Deprecated `/api/wallet/payment/create-token`** endpoint
- ✅ **Secure payment flows** using Omise SDK

### SQL Injection Protection
- ✅ **Parameterized queries** - All database queries use `?` placeholders
- ✅ **No string interpolation** in SQL statements
- ✅ **Input validation** on all user inputs

### Admin Route Protection
- ✅ **Role-based access control** (RBAC)
- ✅ **Admin middleware** (`/middlewares/wallet-admin-auth/`)
- ✅ **Route policies** defined in `routes.json`

### Rate Limiting
- ✅ **Transfer endpoints:** 10 requests/minute (database-backed)
- ⚠ **General API:** Not yet implemented (recommended for production)

### Webhook Security
- ✅ **IP Whitelisting** for Omise webhooks
- ✅ **Allowed IPs:** Omise Singapore datacenter (52.77.251.*, 54.254.229.*)
- ✅ **Idempotency checks** prevent duplicate processing

### Sensitive Data Protection
- ✅ **No sensitive data in logs** (removed tokens, QR codes, full nonces)
- ✅ **Password hashing** (bcrypt via Strapi)
- ✅ **Environment variables** for secrets

---

## 🧪 Testing Results

### Manual API Tests (March 22, 2026)

| Endpoint | Method | Auth | Status | Notes |
|----------|--------|------|--------|-------|
| `/api/app-init` | GET | None | ✅ PASS | Returns 6 branches |
| `/articles` | GET | None | ✅ PASS | Public content accessible |
| `/users/me` | GET | Required | ✅ PASS | Returns 400 without auth (correct) |
| CORS headers | OPTIONS | None | ✅ PASS | Origin whitelisting works |

### Security Tests

| Test | Result | Notes |
|------|--------|-------|
| Protected routes without auth | ✅ PASS | Returns 400/401 as expected |
| CORS configuration | ✅ PASS | Website origin allowed |
| SQL injection attempts | ✅ PASS | Parameterized queries prevent injection |
| Admin routes without admin role | ✅ PASS | Middleware blocks non-admin access |

---

## 📝 Configuration Files

### Website Configuration
**File:** `/packages/website/nuxt.config.js`
```javascript
axios: {
  baseURL: process.env.BASE_URL || 'http://localhost:7001'
},
auth: {
  strategies: {
    local: {
      token: {
        property: 'jwt',
        global: false
      },
      endpoints: {
        login: { url: '/auth/local', method: 'post' },
        user: { url: '/users/me', method: 'get' }
      }
    }
  }
}
```

### Website Environment
**File:** `/packages/website/.env`
```bash
BASE_URL=http://localhost:7001
OMISE_PUBLIC_KEY=pkey_test_xxxxx
OMISE_DEFAULT_PAYMENT_METHOD=credit_card
OMISE_OTHER_PAYMENT_METHOD=promptpay,mobile_banking_scb
```

### Backend Environment
**File:** `/packages/backend/.env`
```bash
NODE_PORT=7001
DATABASE_HOST=localhost
DATABASE_NAME=chongjaroen_dev
CORS_ORIGIN=http://localhost:3000,http://localhost:4040,http://localhost:7001,http://localhost:8080
OMISE_SECRET_KEY=skey_xxxxx
OMISE_PUBLIC_KEY=pkey_xxxxx
```

---

## 🚨 Known Issues & Recommendations

### Current Issues
- ⚠ **No general rate limiting** - Recommend implementing for all public endpoints
- ⚠ **No brute-force protection** on login - Recommend adding login attempt tracking
- ⚠ **Token refresh not implemented** - Users must re-login after token expiry

### Recommended Improvements
1. **Add rate limiting middleware** for all API routes (10-100 requests/minute depending on endpoint)
2. **Implement token refresh** mechanism for better UX
3. **Add request logging** for security monitoring
4. **Implement CAPTCHA** on login/signup after failed attempts
5. **Add input sanitization** middleware for all user inputs
6. **Set up monitoring** for failed auth attempts
7. **Implement session management** for better security
8. **Add API versioning** (/api/v1/) for future compatibility

---

## ✅ Deployment Checklist

Before deploying to production:

- [ ] Update `BASE_URL` in website `.env` to production backend URL
- [ ] Update `CORS_ORIGIN` in backend `.env` to production domains only
- [ ] Replace Omise test keys with live keys
- [ ] Enable HTTPS for all endpoints
- [ ] Implement rate limiting on all routes
- [ ] Set up proper logging and monitoring
- [ ] Configure database backups
- [ ] Set JWT expiration to reasonable time (e.g., 7 days)
- [ ] Implement token refresh mechanism
- [ ] Add CAPTCHA to login/signup forms
- [ ] Review and update all RBAC policies
- [ ] Conduct security audit
- [ ] Set up error tracking (Sentry, etc.)
- [ ] Configure CDN for static assets
- [ ] Set up SSL certificates

---

## 📚 Additional Resources

- **Strapi Documentation:** https://strapi.io/documentation
- **Nuxt Auth Module:** https://auth.nuxtjs.org/
- **Omise API Docs:** https://www.omise.co/docs
- **PCI-DSS Compliance:** https://www.pcisecuritystandards.org/

---

**Document maintained by:** Development Team
**For issues or questions:** Contact system administrator
