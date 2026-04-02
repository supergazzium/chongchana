# Credit Card Payment Security Audit
**Date**: 2026-04-02
**Scope**: Wallet Top-up via Credit Card (Mobile App → Backend → Omise → Bank)
**Environment**: Production (Live Omise Keys)

---

## Executive Summary

✅ **Overall Status**: Functional but requires security enhancements before full production deployment

**Key Findings**:
- ✅ Server-side tokenization correctly implemented
- ✅ 3D Secure authentication flow working
- ✅ Webhook handling implemented with IP verification
- ⚠️ **CRITICAL**: No HTTPS enforcement check
- ⚠️ **HIGH**: No rate limiting on token creation endpoint
- ⚠️ **MEDIUM**: Manual 3D Secure status checking (poor UX)

**Security Score**: 7/10 (Good foundation, needs hardening)

---

## Payment Flow Analysis

### Complete Transaction Flow

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│   Mobile    │      │   Backend   │      │    Omise    │      │   Bank/     │
│     App     │─────▶│   (Strapi)  │─────▶│   Gateway   │─────▶│  Card Net   │
└─────────────┘      └─────────────┘      └─────────────┘      └─────────────┘
       │                    │                     │                     │
       │ 1. Card Data       │                     │                     │
       │───────────────────▶│ 2. Create Token     │                     │
       │                    │────────────────────▶│                     │
       │                    │◀────────────────────│                     │
       │                    │    Token ID         │                     │
       │◀───────────────────│                     │                     │
       │    Token ID        │                     │                     │
       │                    │                     │                     │
       │ 3. Process Payment │                     │                     │
       │───────────────────▶│ 4. Create Charge    │                     │
       │                    │────────────────────▶│ 5. Authorize        │
       │                    │                     │────────────────────▶│
       │                    │                     │◀────────────────────│
       │                    │◀────────────────────│ 6. Auth Response    │
       │◀───────────────────│    authorize_uri    │                     │
       │  authorize_uri +   │    (if 3DS needed)  │                     │
       │     chargeId       │                     │                     │
       │                    │                     │                     │
       │ 7. Open Browser    │                     │                     │
       │────────────────────────────────────────▶ │                     │
       │                    │           3D Secure OTP Page              │
       │◀────────────────────────────────────────│                     │
       │  User completes    │                     │                     │
       │  authentication    │                     │                     │
       │                    │                     │                     │
       │ 8. Check Status    │                     │                     │
       │───────────────────▶│ 9. Get Charge       │                     │
       │                    │────────────────────▶│                     │
       │                    │◀────────────────────│                     │
       │◀───────────────────│    paid: true       │                     │
       │  Payment Success   │                     │                     │
       │                    │                     │                     │
       │                    │◀────────────────────│                     │
       │                    │  10. Webhook        │                     │
       │                    │  (charge.complete)  │                     │
       │                    │                     │                     │
       │                    │ 11. Credit Wallet   │                     │
       │                    │ + Send Notification │                     │
```

---

## Step-by-Step Security Analysis

### Step 1: Card Data Entry (Mobile App)
**File**: `lib/screens/wallet/credit_card_form.dart`

**What Happens**:
```dart
// User enters:
- Card number (with spaces auto-formatting)
- Cardholder name
- Expiration month/year
- CVV/CVC code
```

**Security Status**: ✅ **SECURE**
- Card data stored only in memory (TextField controllers)
- No persistence to disk/storage
- Input validation (Luhn algorithm for card number)
- CVV masked with obscureText: true
- Data cleared on widget disposal

**Concerns**: None

---

### Step 2: Token Creation (Backend via Public Key)
**Files**:
- Frontend: `lib/services/omise_payment.dart:24-87`
- Backend: `api/wallet/services/payment.js:30-55`
- Endpoint: `POST /wallet/payment/create-token`

**What Happens**:
```javascript
// Backend receives card data via HTTPS POST
const token = await omisePublic.tokens.create({
  card: {
    name: cardHolderName,
    number: cardNumber,
    expiration_month: expirationMonth,
    expiration_year: expirationYear,
    security_code: securityCode,
  },
});
// Returns: { id: 'tokn_xxxxx', card: { last_digits: '4242' } }
```

**Security Status**: ⚠️ **NEEDS IMPROVEMENT**

**✅ Correct Implementation**:
- Uses Omise PUBLIC key (pkey_xxx) for token creation ✅
- Follows Omise best practices for server-side tokenization ✅
- Card data transmitted over HTTPS ✅
- Backend doesn't store card data (memory only) ✅

**⚠️ Security Concerns**:
1. **CRITICAL**: No explicit HTTPS enforcement check
2. **HIGH**: No rate limiting - vulnerable to brute force token generation
3. **MEDIUM**: Backend briefly touches raw card data (PCI-DSS concern)
4. **LOW**: No input sanitization on card fields

**Recommendations**:
```javascript
// Add HTTPS enforcement
if (process.env.NODE_ENV === 'production' && ctx.request.protocol !== 'https') {
  return ctx.forbidden('HTTPS required for payment operations');
}

// Add rate limiting (5 attempts per 15 minutes)
const rateLimit = require('koa-ratelimit');
router.post('/wallet/payment/create-token',
  rateLimit({
    driver: 'memory',
    db: new Map(),
    duration: 15 * 60 * 1000, // 15 minutes
    max: 5,
    id: (ctx) => ctx.state.user.id,
  }),
  controller.createToken
);
```

---

### Step 3: Charge Creation (Backend via Secret Key)
**Files**:
- Backend: `api/wallet/controllers/payment.js:64-125`
- Service: `api/wallet/services/payment.js:135-166`
- Endpoint: `POST /wallet/payment/create-charge`

**What Happens**:
```javascript
// Backend creates charge using SECRET key
const charge = await omise.charges.create({
  amount: Math.round(amount * 100), // Convert to satangs
  currency: 'THB',
  card: tokenId, // Use token, not raw card data
  description: `Wallet top-up - User ${userId}`,
  metadata: { user_id: userId, type: 'wallet_topup' },
  capture: true, // Auto-capture
  // return_uri: OMITTED for credit cards (optional)
});
```

**Security Status**: ✅ **SECURE**

**✅ Correct Implementation**:
- Uses Omise SECRET key (skey_xxx) for charge creation ✅
- Token used instead of raw card data ✅
- Amount validation (min/max limits) ✅
- User authentication required (JWT) ✅
- Metadata includes user_id for tracking ✅
- No return_uri (avoids "return uri is invalid" error) ✅

**Response Handling**:
```javascript
// Three possible outcomes:
1. charge.paid === true → Immediate success (no 3DS)
2. charge.authorize_uri → 3D Secure required
3. charge.status === 'pending' → Awaiting bank approval
```

**Concerns**: None - correctly implemented per Omise documentation

---

### Step 4: 3D Secure Authentication (If Required)
**File**: `lib/screens/wallet/credit_card_form.dart:231-312`

**What Happens**:
```dart
// If authorizeUri is present:
1. Show dialog explaining 3D Secure requirement
2. Open authorize_uri in external browser
3. User completes OTP/biometric authentication on bank page
4. User returns to app manually
5. App prompts to check payment status
```

**Security Status**: ⚠️ **FUNCTIONAL BUT SUBOPTIMAL UX**

**✅ Correct Implementation**:
- Uses external browser (more secure than WebView) ✅
- Doesn't expose sensitive data in URL ✅
- authorize_uri is HTTPS with Omise domain ✅

**⚠️ UX/Security Concerns**:
1. **MEDIUM**: Manual status checking required (user must tap "Check Payment Status")
2. **LOW**: No automatic return to app (mobile browsers don't support this well)
3. **INFO**: Alternative: HTTPS callback page could auto-redirect via deep link

**Current Flow**:
```
User → Tap "Proceed" → Browser Opens → Complete 3DS → Manual Return → Tap "Check Status"
```

**Recommended Flow (Future Enhancement)**:
```
User → Tap "Proceed" → Browser Opens → Complete 3DS → Auto-redirect via callback page → App checks status automatically
```

**Implementation Suggestion**:
```javascript
// Backend: Add return_uri pointing to HTTPS callback page
return_uri: 'https://yourdomain.com/payment-callback?chargeId=' + charge.id

// Callback page (static HTML):
<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="refresh" content="0;url=chongjaroen://payment-result?chargeId=<?= chargeId ?>">
</head>
<body>Redirecting back to app...</body>
</html>
```

---

### Step 5: Payment Status Verification
**Files**:
- Frontend: `lib/services/omise_payment.dart:329-371`
- Backend: `api/wallet/controllers/payment.js:224-266`
- Endpoint: `GET /wallet/payment/status/:chargeId`

**What Happens**:
```javascript
// Backend retrieves charge from Omise
const charge = await omise.charges.retrieve(chargeId);

// If paid and not yet processed:
if (charge.paid && !existing) {
  await processSuccessfulPayment(chargeId, userId);
}
```

**Security Status**: ✅ **SECURE**

**✅ Correct Implementation**:
- Verifies charge ownership via metadata.user_id ✅
- Checks for duplicate processing ✅
- Uses Omise API as source of truth ✅
- Transaction-safe wallet updates ✅

**Concerns**: None

---

### Step 6: Webhook Handling (Async Confirmation)
**Files**:
- Backend: `api/wallet/controllers/payment.js:272-321`
- Service: `api/wallet/services/payment.js:319-361`
- Endpoint: `POST /wallet/payment/webhook`

**What Happens**:
```javascript
// Omise sends webhook when charge completes
if (event.key === 'charge.complete') {
  // Verify source IP
  if (!verifyWebhookSource(sourceIp)) {
    return ctx.unauthorized();
  }

  // Process payment if not already done
  if (!existing) {
    await processSuccessfulPayment(charge.id, userId);
  }
}
```

**Security Status**: ✅ **SECURE WITH LIMITATIONS**

**✅ Correct Implementation**:
- IP verification against Omise webhook IPs ✅
- Duplicate transaction check ✅
- Always returns 200 (prevents retry storms) ✅
- Logs all webhook events ✅

**⚠️ Limitations**:
1. **MEDIUM**: IP-based verification only (Omise doesn't provide HMAC signatures)
2. **INFO**: Webhook IPs hardcoded (need updating if Omise infrastructure changes)
3. **LOW**: Development mode allows localhost (acceptable for testing)

**Whitelisted IPs**:
```javascript
const OMISE_WEBHOOK_IPS = [
  '52.77.251.16',    // Singapore datacenter
  '52.77.251.52',    // Singapore datacenter
  '52.77.251.97',    // Singapore datacenter
  '54.254.229.219',  // Singapore datacenter
  '54.254.229.250',  // Singapore datacenter
];
```

**Recommendation**: Monitor Omise documentation for IP changes

---

### Step 7: Wallet Crediting (Database Transaction)
**File**: `api/wallet/services/payment.js:228-310`

**What Happens**:
```javascript
await knex.transaction(async (trx) => {
  // Get current balance
  const wallet = await trx('wallets').where({ user_id: userId }).first();
  const balanceBefore = parseFloat(wallet.balance);
  const balanceAfter = balanceBefore + amount;

  // Update wallet
  await trx('wallets').where({ user_id: userId }).update({
    balance: balanceAfter,
    updated_at: knex.fn.now()
  });

  // Record transaction
  await trx('wallet_transactions').insert({
    id: transactionId,
    user_id: userId,
    type: 'top_up',
    amount: amount,
    balance_before: balanceBefore,
    balance_after: balanceAfter,
    status: 'completed',
    payment_method: charge.source?.type || 'credit_card',
    metadata: JSON.stringify({ charge_id: chargeId }),
  });
});
```

**Security Status**: ✅ **SECURE**

**✅ Correct Implementation**:
- Database transaction ensures atomicity ✅
- Balance audit trail (before/after) ✅
- Unique transaction ID generation ✅
- Metadata includes charge_id for reconciliation ✅
- Amount stored in decimal (not float) ✅

**Concerns**: None - production-ready implementation

---

## Security Scorecard

| Component | Status | Score | Notes |
|-----------|--------|-------|-------|
| **Card Data Handling** | ✅ Secure | 10/10 | No persistence, memory only |
| **HTTPS Enforcement** | ⚠️ Missing | 0/10 | **CRITICAL: No check in production** |
| **Token Creation** | ✅ Correct | 9/10 | Uses public key per Omise docs |
| **Rate Limiting** | ⚠️ Missing | 0/10 | **HIGH: Vulnerable to abuse** |
| **Charge Creation** | ✅ Secure | 10/10 | Uses secret key, proper validation |
| **3D Secure Flow** | ✅ Working | 7/10 | Functional but manual UX |
| **Webhook Security** | ✅ Good | 8/10 | IP verification implemented |
| **Database Integrity** | ✅ Secure | 10/10 | Transactions + audit trail |
| **Error Handling** | ✅ Good | 9/10 | Type-safe with proper fallbacks |
| **PCI-DSS Compliance** | ⚠️ Gray Area | 6/10 | Server touches card data briefly |

**Overall Score**: 7.0/10

---

## Critical Issues Before Production

### 🔴 CRITICAL: HTTPS Enforcement

**Issue**: No check to ensure payment endpoints are accessed via HTTPS

**Risk**: Card data could be transmitted over HTTP in misconfigured environments

**Fix**:
```javascript
// Add to all payment-related endpoints
async function enforceHTTPS(ctx, next) {
  if (process.env.NODE_ENV === 'production' && ctx.request.protocol !== 'https') {
    return ctx.forbidden('HTTPS required for payment operations');
  }
  await next();
}

// Apply middleware
router.post('/wallet/payment/create-token', enforceHTTPS, controller.createToken);
router.post('/wallet/payment/create-charge', enforceHTTPS, controller.createChargeFromToken);
```

**Priority**: MUST FIX before production deployment

---

### 🟡 HIGH: Rate Limiting

**Issue**: No rate limiting on token creation endpoint

**Risk**:
- Brute force attacks on card validation
- Token generation abuse
- API cost accumulation

**Fix**:
```javascript
const rateLimit = require('koa-ratelimit');
const db = new Map();

// 5 attempts per 15 minutes per user
router.post('/wallet/payment/create-token',
  rateLimit({
    driver: 'memory',
    db: db,
    duration: 15 * 60 * 1000,
    max: 5,
    id: (ctx) => ctx.state.user?.id || ctx.request.ip,
    errorMessage: 'Too many payment attempts. Please try again later.'
  }),
  controller.createToken
);
```

**Priority**: SHOULD FIX before production deployment

---

### 🟡 MEDIUM: 3D Secure UX Improvement

**Issue**: Manual payment status checking required

**Current Flow**:
1. User opens browser for 3DS
2. Completes authentication
3. **Manually** returns to app
4. **Manually** taps "Check Payment Status"

**Recommended Flow**:
1. User opens browser for 3DS
2. Completes authentication
3. **Auto-redirects** to app via callback page
4. **Auto-checks** payment status

**Implementation**:
```javascript
// Backend: Add HTTPS callback URL
return_uri: `https://yourdomain.com/payment-callback?chargeId=${charge.id}&returnUrl=chongjaroen://payment-result`

// Static callback page (payment-callback.html):
<!DOCTYPE html>
<html>
<head>
  <title>Payment Processing</title>
  <script>
    const params = new URLSearchParams(window.location.search);
    const chargeId = params.get('chargeId');
    const returnUrl = params.get('returnUrl');
    window.location.href = `${returnUrl}?chargeId=${chargeId}`;
  </script>
</head>
<body>
  <p>Processing payment, please wait...</p>
</body>
</html>
```

**Frontend**: Listen for deep link with chargeId parameter, auto-check status

**Priority**: NICE TO HAVE (current implementation works, just not optimal)

---

## PCI-DSS Compliance Assessment

### Current Approach: Server-Side Tokenization

**What Happens**:
1. Mobile app sends raw card data to your backend via HTTPS
2. Backend sends card data to Omise to create token
3. Backend uses token to create charge
4. Backend never stores card data (memory only)

**PCI-DSS Level Required**:
- **SAQ D** (full PCI audit) - Your server touches raw card data

**Concerns**:
- Backend code handles raw card number, CVV, expiration
- Even though not stored, still passes through your system
- Requires PCI-DSS compliance certification for production

### Alternative: Client-Side Tokenization (Higher Security)

**How It Would Work**:
1. Mobile app sends card data **directly to Omise** (via Omise SDK)
2. Omise returns token to app
3. App sends token to backend
4. Backend creates charge with token
5. **Your backend never touches card data**

**PCI-DSS Level Required**:
- **SAQ A** (minimal compliance) - Your server never touches card data

**Implementation** (Future Enhancement):
```dart
// Frontend: Use Omise Flutter SDK (if available)
import 'package:omise_flutter/omise_flutter.dart';

// Initialize with PUBLIC key only
OmiseFlutter.initialize(publicKey: omisePublicKey);

// Create token client-side
final token = await OmiseFlutter.createToken(
  card: CreditCard(
    number: cardNumber,
    name: cardHolderName,
    expirationMonth: month,
    expirationYear: year,
    securityCode: cvv,
  ),
);

// Send only token to backend
final result = await Fetcher.fetch(
  Fetcher.post,
  '/wallet/payment/create-charge',
  params: { 'tokenId': token.id, 'amount': amount },
);
```

**Benefits**:
- Lower PCI-DSS compliance burden (SAQ A vs SAQ D)
- Backend never touches card data
- Reduced liability

**Tradeoffs**:
- Requires Omise Flutter SDK (may not exist or be maintained)
- More complex mobile implementation
- Current server-side approach is still valid if PCI-compliant

**Recommendation**: Current implementation is acceptable if you:
1. Complete PCI-DSS SAQ D self-assessment
2. Implement security controls (HTTPS enforcement, rate limiting, logging)
3. Consider client-side tokenization for future iteration

---

## Environment Configuration Review

### Current Setup (.env)

```bash
# Omise Configuration (LIVE KEYS - NOT TEST)
OMISE_SECRET_KEY=skey_672xp2hgkg0pd5tu5kn
OMISE_PUBLIC_KEY=pkey_5tuer3rmwoxiudi0d04
```

**Analysis**:
- ✅ Using **LIVE keys** (no "_test_" suffix)
- ⚠️ **Real money transactions** are processed
- ✅ Keys properly separated (public vs secret)
- ⚠️ Ensure .env is in .gitignore (never commit to repo)

**Security Checks**:
```bash
# Verify .env is not committed
grep -r "OMISE_SECRET_KEY" .git/  # Should return nothing

# Verify .env is gitignored
cat .gitignore | grep .env  # Should show .env
```

**Recommendation**: Use separate keys for staging/production
```bash
# .env.staging
OMISE_SECRET_KEY=skey_test_xxxxx
OMISE_PUBLIC_KEY=pkey_test_xxxxx

# .env.production
OMISE_SECRET_KEY=skey_672xp2hgkg0pd5tu5kn
OMISE_PUBLIC_KEY=pkey_5tuer3rmwoxiudi0d04
```

---

## Testing Recommendations

### Before Production Deployment

1. **Test with Real Cards**:
   - ✅ Already tested (user confirmed real card works)
   - Test 3D Secure flow end-to-end
   - Test non-3DS cards
   - Test declined cards

2. **Test Edge Cases**:
   - Network timeout during token creation
   - Network timeout during charge creation
   - User closes app during 3D Secure
   - Duplicate webhook delivery
   - Race condition: webhook vs manual status check

3. **Security Tests**:
   - Verify HTTPS enforcement (after implementing)
   - Test rate limiting (after implementing)
   - Attempt token creation with invalid user token (should fail)
   - Attempt charge creation with someone else's token (should fail)

4. **Load Testing**:
   - Simulate 100 concurrent top-ups
   - Monitor database transaction locks
   - Check webhook processing under load

---

## Deployment Checklist

### Pre-Production (Required)

- [ ] **Implement HTTPS enforcement** (CRITICAL)
- [ ] **Implement rate limiting** (HIGH)
- [ ] Verify .env is not in git repository
- [ ] Complete PCI-DSS SAQ D self-assessment
- [ ] Set up monitoring/alerting for failed payments
- [ ] Document 3D Secure flow for customer support
- [ ] Test webhook delivery in production environment
- [ ] Verify Omise webhook URL is configured in dashboard

### Post-Production (Monitoring)

- [ ] Monitor payment success rate (target: >95%)
- [ ] Monitor 3D Secure completion rate
- [ ] Track token creation failures
- [ ] Track charge creation failures
- [ ] Monitor webhook delivery latency
- [ ] Alert on duplicate transaction attempts

### Future Enhancements (Optional)

- [ ] Implement automatic 3D Secure callback (HTTPS page)
- [ ] Consider client-side tokenization (lower PCI burden)
- [ ] Add payment retry mechanism for failed charges
- [ ] Implement saved payment methods (requires PCI Vault)
- [ ] Add fraud detection rules (Omise Fraud Protection)

---

## Omise Documentation Compliance

### ✅ Correctly Implemented According to Docs

1. **Token Creation** ([docs.omise.co/tokens-api](https://docs.omise.co/tokens-api))
   - ✅ Uses public key (pkey_xxx)
   - ✅ Includes all required fields
   - ✅ Token used once and discarded

2. **Charge Creation** ([docs.omise.co/charges-api](https://docs.omise.co/charges-api))
   - ✅ Uses secret key (skey_xxx)
   - ✅ Amount in smallest currency unit (satangs)
   - ✅ capture: true for immediate capture
   - ✅ Metadata for tracking

3. **3D Secure** ([docs.omise.co/fraud-protection](https://docs.omise.co/fraud-protection))
   - ✅ Opens authorize_uri in browser
   - ✅ Checks payment status after user returns
   - ⚠️ return_uri optional for credit cards (correctly omitted)

4. **Webhooks** ([docs.omise.co/webhooks](https://docs.omise.co/webhooks))
   - ✅ Handles charge.complete event
   - ✅ IP verification implemented
   - ✅ Always returns 200 status
   - ✅ Duplicate processing check

### ⚠️ Deviations from Best Practices

1. **Rate Limiting**: Not mentioned in Omise docs, but industry standard
2. **HTTPS Enforcement**: Assumed by Omise docs, but should be explicit
3. **return_uri**: Omise recommends HTTPS callback page (we omit it entirely)

---

## Risk Assessment

### High-Risk Items (Fix Before Production)
1. 🔴 **HTTPS Enforcement** - Card data exposure risk
2. 🟡 **Rate Limiting** - Abuse and fraud risk

### Medium-Risk Items (Monitor in Production)
1. 🟡 **Manual 3D Secure UX** - User confusion, abandoned payments
2. 🟡 **PCI-DSS Compliance** - Server touches card data (need SAQ D)

### Low-Risk Items (Acceptable for Production)
1. ✅ Token creation flow
2. ✅ Charge creation flow
3. ✅ Webhook handling
4. ✅ Database transactions
5. ✅ Error handling

---

## Final Recommendation

### Can Deploy to Production? **YES, with conditions**

**Safe to Deploy If**:
1. ✅ HTTPS enforcement is implemented
2. ✅ Rate limiting is implemented
3. ✅ You complete PCI-DSS SAQ D self-assessment
4. ✅ You monitor payment metrics for first 2 weeks

**Acceptable to Deploy WITHOUT Fixes If**:
- This is a **staging/test environment** (not public production)
- User volume is low (<100 payments/day)
- You have manual fraud monitoring in place

**NOT Safe to Deploy If**:
- ❌ Backend is accessible via HTTP
- ❌ You haven't reviewed PCI-DSS requirements
- ❌ High transaction volume expected (>500/day)

---

## Contact and Support

**Omise Support**:
- Email: support@omise.co
- Dashboard: https://dashboard.omise.co
- Docs: https://docs.omise.co

**PCI-DSS Resources**:
- PCI Security Standards: https://www.pcisecuritystandards.org
- SAQ D: https://www.pcisecuritystandards.org/document_library

**Issue Tracking**:
- Critical security issues found: 2 (HTTPS, Rate Limiting)
- Medium improvements needed: 2 (3DS UX, PCI Compliance)
- Current implementation status: FUNCTIONAL

---

## Revision History

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-04-02 | 1.0 | Security Audit | Initial audit after credit card implementation |

---

**End of Security Audit Report**