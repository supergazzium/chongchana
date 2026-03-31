# Payment QR Permission Issue - Root Cause and Solution

## Problem Summary

When implementing the staff payment QR scanning feature, two API endpoints consistently returned **403 Forbidden** errors:

1. `POST /wallet/payment-qr/validate` - Used to validate scanned QR codes
2. `POST /wallet/payment-qr/pay` - Used to process payments after validation

These endpoints need to be **public** (no authentication required) because:
- Staff scan customer QR codes, not their own
- The QR token itself contains authentication (JWT with customer info)
- Adding staff authentication would be redundant and incorrect

## Root Cause Analysis

### The Real Problem: @nuxtjs/auth-next

The issue was caused by **@nuxtjs/auth-next** automatically injecting `Authorization` headers into ALL axios requests, even when we don't want them.

Here's what happens:
```javascript
// This code sends Authorization header automatically:
await this.$axios.post('/wallet/payment-qr/validate', { token })
// Backend receives: Authorization: Bearer <staff-token>
// Backend rejects: 403 Forbidden (staff token invalid for this endpoint)
```

### Why Backend-Only Fixes Didn't Work

We tried multiple backend approaches that **FAILED**:

❌ **routes.json with `auth: false`**
```json
{
  "method": "POST",
  "path": "/wallet/payment-qr/validate",
  "handler": "payment-qr.validatePaymentQR",
  "config": {
    "auth": false  // DOESN'T WORK - Still gets 403
  }
}
```

❌ **Custom policies**
```javascript
// isPublicPaymentQR.js
module.exports = async (ctx, next) => {
  ctx.state.user = null; // DOESN'T WORK - Header already sent
  return await next();
};
```

❌ **Custom middleware**
```javascript
// payment-qr-public middleware
if (publicQRRoutes.includes(ctx.path)) {
  ctx.state.route.config.auth = false; // DOESN'T WORK
}
```

**Why these failed:** The `Authorization` header is sent from the frontend. Backend middleware/policies run AFTER Strapi's authentication layer has already processed the header and rejected it.

## The Working Solution

### Frontend: Create Separate Axios Instance

The ONLY solution that works is to create a **completely separate axios instance** that bypasses @nuxtjs/auth-next entirely.

#### Step 1: Create Plugin (`plugins/axios-public-instance.js`)

```javascript
import axios from 'axios';

export default ({ $config }, inject) => {
  // Create standalone axios instance (not connected to @nuxtjs/auth-next)
  const publicAxios = axios.create({
    baseURL: process.env.NUXT_ENV_BASE_URL || 'http://localhost:7001',
    headers: {
      common: {
        'Content-Type': 'application/json',
      },
    },
  });

  // Interceptor to ensure NO auth headers are ever added
  publicAxios.interceptors.request.use((config) => {
    delete config.headers.Authorization;
    delete config.headers.authorization;
    delete config.headers.common.Authorization;
    delete config.headers.common.authorization;

    console.log('[publicAxios] Request to:', config.url, '- Auth header removed');
    return config;
  });

  // Inject as $publicAxios
  inject('publicAxios', publicAxios);
};
```

#### Step 2: Register Plugin (`nuxt.config.js`)

```javascript
export default {
  plugins: [
    // ... other plugins
    '~/plugins/axios-public-instance.js',
  ],
}
```

#### Step 3: Use in Components

**QR Scanner Page** (`pages/payment/index.vue`):
```javascript
async validateQR(token) {
  try {
    // ✅ Use $publicAxios instead of $axios
    const response = await this.$publicAxios.post(
      "/wallet/payment-qr/validate",
      { token }
    );

    if (response.data && response.data.success && response.data.data) {
      return { success: true, data: response.data.data };
    } else {
      return { success: false, error: response.data?.message || "Invalid QR code" };
    }
  } catch (e) {
    let message = "QR Code ไม่ถูกต้องหรือหมดอายุแล้ว";
    if (e.response && e.response.data) {
      const data = e.response.data;
      if (data.message && typeof data.message === 'object' && data.message.error) {
        message = data.message.error.message || message;
      } else if (typeof data.message === 'string') {
        message = data.message;
      }
    }
    return { success: false, error: String(message) };
  }
}
```

**Confirmation Page** (`pages/payment/confirm.vue`):
```javascript
async onSubmit(e) {
  // ... validation code

  try {
    const payload = {
      nonce: this._paymentData.nonce,
      amount: amount,
      description: this.formData.description,
      metadata: {
        staffId: this.$auth.user.id,
        staffUsername: this.$auth.user.username,
        branch: this.$auth.user.branch,
        timestamp: new Date().toISOString(),
      },
    };

    // ✅ Use $publicAxios instead of $axios
    const response = await this.$publicAxios.post(
      "/wallet/payment-qr/pay",
      payload
    ).then(res => res.data);

    if (response.success && response.data) {
      // Success handling
      this.$router.push("/payment/success");
    }
  } catch (e) {
    // Error handling
  }
}
```

### Backend: Configure Public Routes

Backend changes are still needed to mark these endpoints as public in Strapi.

#### routes.json
```json
{
  "routes": [
    {
      "method": "POST",
      "path": "/wallet/payment-qr/validate",
      "handler": "payment-qr.validatePaymentQR",
      "config": {
        "policies": []
      }
    },
    {
      "method": "POST",
      "path": "/wallet/payment-qr/pay",
      "handler": "payment-qr.processPayment",
      "config": {
        "policies": []
      }
    }
  ]
}
```

## Why This Solution Works

1. **Bypass @nuxtjs/auth-next**: The separate axios instance is created with vanilla `axios`, completely independent of Nuxt's auth module
2. **No Authorization Header**: The interceptor ensures headers are removed at the request level
3. **Backend Sees Clean Request**: Backend receives request without any auth headers, treats it as public
4. **Security Maintained**: QR token itself contains JWT authentication for the customer

## Testing the Fix

1. **Generate QR Code**: Login to admin portal with customer account, generate payment QR
2. **Scan QR Code**: Open staff portal, go to payment page, scan the generated QR
3. **Validate Success**: Should see customer info and balance (no 403 error)
4. **Confirm Payment**: Enter amount, click confirm button
5. **Payment Success**: Should process payment and redirect to success page (no 403 error)

## Common Mistakes to Avoid

❌ **Setting Authorization to undefined**
```javascript
// DOESN'T WORK
await this.$axios.post('/api/public', data, {
  headers: { Authorization: undefined }
});
```

❌ **Trying to configure auth module to skip routes**
```javascript
// DOESN'T WORK
auth: {
  strategies: {
    local: {
      endpoints: {
        // Can't exclude specific routes from getting headers
      }
    }
  }
}
```

✅ **Use separate axios instance**
```javascript
// WORKS
await this.$publicAxios.post('/api/public', data);
```

## Files Modified

**Staff Portal:**
- `plugins/axios-public-instance.js` (NEW) - Public axios instance
- `nuxt.config.js` - Register plugin
- `pages/payment/index.vue` - Use $publicAxios for validate
- `pages/payment/confirm.vue` - Use $publicAxios for pay

**Backend:**
- `api/wallet/config/routes.json` - Empty policies for public routes
- `api/wallet/controllers/payment-qr.js` - Enhanced error logging

## Conclusion

The **only working solution** for bypassing @nuxtjs/auth-next is to create a completely separate axios instance. Backend-only solutions (routes, policies, middleware) cannot fix this because the authentication header is sent from the frontend, and Strapi processes it before any custom code runs.

This pattern should be used for ANY public API endpoint that needs to be called from an authenticated Nuxt app using @nuxtjs/auth-next.
