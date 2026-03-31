# Omise API Issue Report

**Date:** March 20, 2026
**Account Email:** admin@chongjaroen.com
**Account ID:** account_5tuer3rednk8r6sft74
**Issue:** Authentication failure when creating payment sources (PromptPay)

---

## Problem Summary

Our application can successfully authenticate with Omise API and retrieve account information, but receives `authentication_failure` errors when attempting to create payment sources (specifically PromptPay sources). This prevents us from implementing wallet top-up functionality in our application.

---

## API Credentials Being Used

- **Secret Key:** `skey_672xp2hgkg0pd5tu5kn`
- **Public Key:** `pkey_5tuer3rmwoxiudi0d04`
- **Environment:** Test Mode
- **API Version:** 2019-05-29
- **SDK:** omise-node (Node.js)

---

## Test Results

We have systematically tested different Omise API endpoints to isolate the issue:

### ✅ Working Endpoints

#### 1. Account API (GET /account)
```
Status: SUCCESS
Response:
{
  "email": "admin@chongjaroen.com",
  "id": "account_5tuer3rednk8r6sft74",
  "object": "account"
}
```
**Conclusion:** Basic authentication works correctly.

---

### ❌ Failing Endpoints

#### 2. Capability API (GET /capability)
```
Status: FAILED
Error Response:
{
  "object": "error",
  "location": "https://www.omise.co/api-errors#authentication-failure",
  "code": "authentication_failure",
  "message": "authentication failed"
}
```

#### 3. Source Creation API (POST /sources)
**Request:**
```javascript
{
  type: 'promptpay',
  amount: 30000,  // 300 THB
  currency: 'THB'
}
```

**Error Response:**
```json
{
  "object": "error",
  "location": "https://www.omise.co/api-errors#authentication-failure",
  "code": "authentication_failure",
  "message": "authentication failed"
}
```

---

## Technical Evidence

### 1. Test Script Output
```
============================================================
OMISE API CREDENTIALS TEST
============================================================

[STEP 1] Checking environment variables:
OMISE_SECRET_KEY: skey_672xp2hgkg... (24 chars)
OMISE_PUBLIC_KEY: pkey_5tuer3rmwo... (24 chars)
Full SECRET_KEY: skey_672xp2hgkg0pd5tu5kn
Full PUBLIC_KEY: pkey_5tuer3rmwoxiudi0d04

[STEP 2] Testing Account API (GET /account):
✓ SUCCESS: Account API works!
Account Email: admin@chongjaroen.com
Account ID: account_5tuer3rednk8r6sft74
Account Object: account

[STEP 3] Testing Capability API (GET /capability):
✗ FAILED: Capability API failed
Error: authentication failed

[STEP 4] Testing PromptPay Source Creation:
✗ FAILED: PromptPay Source creation failed
Error: authentication failed
Error code: authentication_failure

============================================================
TEST SUMMARY
============================================================
Account API: ✓ PASSED
Capability API: ✗ FAILED
PromptPay Source: ✗ FAILED
============================================================
```

### 2. Application Backend Logs
```
[2026-03-20T13:05:56.007Z] info [Payment] Creating PromptPay source with: {
  "secretKey":"skey_672xp2hgkg...",
  "amount":30000,
  "currency":"THB"
}

[2026-03-20T13:05:56.258Z] error [Payment] createPromptPaySource error: {
  "object":"error",
  "location":"https://www.omise.co/api-errors#authentication-failure",
  "code":"authentication_failure",
  "message":"authentication failed"
}
```

### 3. Code Implementation
```javascript
const omise = require('omise')({
  secretKey: process.env.OMISE_SECRET_KEY,
  omiseVersion: '2019-05-29',
});

// This works ✓
const account = await omise.account.retrieve();

// This fails ✗
const source = await omise.sources.create({
  type: 'promptpay',
  amount: 30000,
  currency: 'THB',
});
```

---

## Expected Behavior

According to Omise documentation, creating a PromptPay source should return:
```json
{
  "object": "source",
  "id": "src_test_xxxxx",
  "type": "promptpay",
  "flow": "offline",
  "amount": 30000,
  "currency": "THB",
  "scannable_code": {
    "type": "qr",
    "image": {
      "download_uri": "https://...",
      ...
    }
  },
  ...
}
```

---

## Actual Behavior

Instead, we receive:
```json
{
  "object": "error",
  "location": "https://www.omise.co/api-errors#authentication-failure",
  "code": "authentication_failure",
  "message": "authentication failed"
}
```

---

## Questions for Omise Support

1. **Are these API keys valid for creating payment sources?**
   - The Account API works, but source creation fails with the same credentials.

2. **Is our account fully activated?**
   - Do we need to complete any activation steps before we can create payment sources?

3. **Is PromptPay enabled for our account?**
   - Do we need to specifically enable PromptPay in test mode?

4. **Are there additional permissions required?**
   - Does creating sources require different permissions than reading account information?

5. **Is there a KYC or business verification requirement?**
   - Even for test mode, are there activation steps we need to complete?

---

## Impact on Business

This issue is blocking our wallet top-up feature implementation. Users cannot add funds to their wallets using PromptPay QR code payments, which is a critical feature for our application.

---

## Environment Details

- **Backend:** Node.js v22.20.0
- **Framework:** Strapi 3.6.8
- **Omise SDK:** omise-node (latest)
- **Application:** Flutter mobile app
- **Region:** Thailand

---

## What We've Already Tried

1. ✅ Verified API keys are correctly loaded from environment variables
2. ✅ Confirmed keys have no whitespace or formatting issues
3. ✅ Tested with fresh backend server restart
4. ✅ Verified Account API authentication works
5. ✅ Confirmed the same error occurs across different endpoints (capability, sources)
6. ✅ Used correct API version (2019-05-29)
7. ✅ Followed Omise documentation for source creation

---

## Request

Please investigate why our API credentials authenticate successfully for the Account API but fail for Capability and Source Creation APIs. If there are activation steps or permissions we need to configure, please provide guidance on how to proceed.

---

## Contact Information

**Email:** admin@chongjaroen.com
**Account ID:** account_5tuer3rednk8r6sft74
**Priority:** High - Blocking production feature deployment

---

## Attachments

- Full test script output (included above)
- Backend server logs (included above)
- Code implementation examples (included above)

Thank you for your assistance in resolving this issue.