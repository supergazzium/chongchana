# Website Wallet Permission Fix

## Problem Summary

The website wallet functions were experiencing **403 Forbidden** or **401 Unauthorized** errors when trying to access wallet APIs:

- `GET /wallet/balance` - Get user wallet balance
- `GET /wallet/transactions` - Get user transaction history
- `GET /wallet/settings` - Get wallet settings
- All other wallet, payment, and transfer endpoints

## Root Cause

The issue was caused by the website's Nuxt auth configuration:

```javascript
// website/nuxt.config.js
auth: {
  strategies: {
    local: {
      token: {
        property: 'jwt',
        global: false  // ⚠️ THIS PREVENTS AUTO-INJECTION OF AUTH HEADERS
      },
```

**Key Difference from Staff Portal:**

- **Website**: `global: false` - Auth headers NOT automatically added
- **Staff Portal**: No `global: false` (defaults to true) - Auth headers automatically added

When `global: false`, the @nuxtjs/auth-next module does NOT automatically attach the JWT token to axios requests. This means all API calls go out WITHOUT the Authorization header, causing the backend to reject them as unauthorized.

## The Fix

Updated all wallet-related methods in `website/plugins/mixins.js` to manually add the Authorization header, following the same pattern already used by `__updateUser` and `__changeProfileImage`:

### Before (BROKEN):
```javascript
async __getWalletBalance() {
  try {
    const response = await this.$axios.$get('/wallet/balance')
    // ❌ No Authorization header sent!
    return response
  } catch (error) {
    console.error('Error fetching wallet balance:', error)
    throw error
  }
}
```

### After (FIXED):
```javascript
async __getWalletBalance() {
  try {
    let token = this.$auth.strategy.token.get()
    const response = await this.$axios.$get('/wallet/balance', {
      headers: {
        Authorization: `${token}`  // ✅ Auth header manually added
      }
    })
    return response
  } catch (error) {
    console.error('Error fetching wallet balance:', error)
    throw error
  }
}
```

## Fixed Methods

All wallet-related methods have been updated:

### Wallet Methods
- ✅ `__getWalletBalance()` - Get balance
- ✅ `__getWalletTransactions()` - Get transactions
- ✅ `__walletTopUp()` - Top up wallet
- ✅ `__walletPay()` - Make payment
- ✅ `__redeemVoucher()` - Redeem voucher
- ✅ `__convertPoints()` - Convert points
- ✅ `__getWalletSettings()` - Get settings

### Payment Methods
- ✅ `__getPaymentMethods()` - Get payment methods
- ✅ `__createPaymentToken()` - Create payment token
- ✅ `__createCharge()` - Create charge
- ✅ `__createPaymentSource()` - Create payment source
- ✅ `__checkPaymentStatus()` - Check payment status

### Transfer Methods
- ✅ `__lookupUser()` - Lookup user for transfer
- ✅ `__initiateTransfer()` - Initiate transfer
- ✅ `__getTransferHistory()` - Get transfer history
- ✅ `__getTransferDetails()` - Get transfer details

### Payment QR Methods
- ✅ `__generatePaymentQR()` - Generate QR code
- ⚠️ `__validatePaymentQR()` - Validate QR (public endpoint, no auth needed)
- ⚠️ `__processQRPayment()` - Process QR payment (public endpoint, no auth needed)
- ✅ `__getPaymentQRHistory()` - Get QR history

**Note:** The `__validatePaymentQR()` and `__processQRPayment()` methods do NOT add auth headers because these are public endpoints handled by the `isPublicPaymentQR` backend policy (see PAYMENT_QR_PERMISSION_FIX.md in staff portal).

## Comparison with Staff Portal Issue

### Staff Portal Problem (Different Issue)
- **Issue**: Public endpoints receiving unwanted auth headers
- **Cause**: @nuxtjs/auth-next automatically injecting headers on ALL requests
- **Solution**: Create separate `$publicAxios` instance to bypass auth module
- **File**: `staff/plugins/axios-public-instance.js`

### Website Problem (This Fix)
- **Issue**: Authenticated endpoints NOT receiving required auth headers
- **Cause**: `global: false` prevents automatic header injection
- **Solution**: Manually add auth headers to each method
- **File**: `website/plugins/mixins.js`

**Key Insight:** Same auth module (`@nuxtjs/auth-next`), opposite problems:
- Staff portal: Too many headers (needed to remove)
- Website: Not enough headers (needed to add)

## Why This Approach Works

1. **Respects Configuration**: Maintains `global: false` setting (possibly intentional for security/control)
2. **Follows Existing Pattern**: Uses same approach as `__updateUser()` method
3. **Selective Auth**: Only adds headers where needed, allows public endpoints to remain public
4. **No Breaking Changes**: Doesn't affect other parts of the application

## Testing

After applying this fix, all wallet endpoints should work correctly:

1. **Login to website** with a test user account
2. **Navigate to wallet page** (`/account/wallet`)
3. **Verify balance loads** without 403/401 errors
4. **Verify transactions load** without errors
5. **Test other wallet features** (top-up, transfer, etc.)

## Files Modified

- `website/plugins/mixins.js` - Added Authorization headers to all wallet methods

## Files Created

- `website/WALLET_PERMISSION_FIX.md` - This documentation
- `backend/test-website-wallet.js` - Test script for wallet endpoints

## Related Documentation

- `staff/PAYMENT_QR_PERMISSION_FIX.md` - Similar permission issue with different solution
- `website/WEBSITE_API_CONFIGURATION.md` - API endpoints documentation
- `backend/api/wallet/config/routes.json` - Backend route configuration

## Deployment Notes

After deployment:
- ✅ No backend changes required
- ✅ Website needs to be rebuilt and redeployed
- ✅ Users should clear browser cache/localStorage if experiencing issues
- ✅ Test all wallet features in production environment

---

**Fixed By:** Claude Code
**Date:** March 22, 2026
**Issue Type:** Permission/Authentication Error
**Severity:** High (blocked all wallet functionality)
**Status:** ✅ RESOLVED
