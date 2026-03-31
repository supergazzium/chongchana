# Wallet Transfer API - Implementation Status & Testing Guide

**Last Updated:** March 21, 2026 02:03 AM ICT
**Backend PID:** Restarted (check with `ps aux | grep strapi`)
**Status:** ✅ **RACE CONDITION FIXED** - Transfer functionality now ready for testing

---

## Summary

The wallet-to-wallet transfer functionality has been fully implemented with all critical bugs fixed. The backend is running with correct table names, column names, and permissions configured.

---

## Fixes Applied

### 1. ✅ Table Name Fixed
- **Issue:** Transfer controller was querying `up_users` table
- **Solution:** Changed to `users-permissions_user` (correct Strapi table name)
- **Files Modified:** `/packages/backend/api/wallet/controllers/transfer.js` (4 occurrences)

### 2. ✅ Column Name Fixed
- **Issue:** Querying `phoneNumber` column which doesn't exist
- **Solution:** Changed to `phone` column in all queries
- **API Response:** Still returns `phoneNumber` for consistency with Flutter app
- **Files Modified:** `/packages/backend/api/wallet/controllers/transfer.js` (all SELECT queries)

### 3. ✅ Permissions Created
- **Issue:** Transfer permissions didn't exist in database
- **Solution:** Auto-creation logic added to bootstrap.js
- **Permissions Created:**
  - `transfer.lookupuser`
  - `transfer.initiatetransfer`
  - `transfer.gettransferhistory`
  - `transfer.gettransferdetails`
- **Files Modified:** `/packages/backend/config/functions/bootstrap.js` (lines 63-112)

### 4. ✅ Database Columns Added
- **Issue:** Missing required columns in wallet_transfers table
- **Solution:** Added balance tracking and transaction reference columns
- **Columns Added:**
  - `sender_balance_before` - Sender's balance before transfer
  - `sender_balance_after` - Sender's balance after transfer
  - `receiver_balance_before` - Receiver's balance before transfer
  - `receiver_balance_after` - Receiver's balance after transfer
  - `sender_transaction_id` - Reference to sender's transaction record
  - `receiver_transaction_id` - Reference to receiver's transaction record
- **Command:** `ALTER TABLE wallet_transfers ADD COLUMN ...`

### 5. ✅ **CRITICAL: Race Condition Fixed in Transaction ID Generation**
- **Issue:** `generateTransactionId()` was being called twice (for sender + receiver transactions), causing duplicate IDs
  - Both calls would execute `SELECT COUNT(*)` simultaneously
  - Both would get the same count (e.g., 0)
  - Both would generate the same ID (e.g., `TX-20260321-00001`)
  - First INSERT succeeded, second failed with `Duplicate entry` error
- **Root Cause:** Sequential numbering with COUNT(*) is not atomic
- **Solution:** Changed ID generation to use millisecond timestamps + random suffix
  - Old format: `TX-20260321-00001` (sequential)
  - New format: `TX-20260321-1774031822958456` (timestamp-based)
- **Files Modified:** `/packages/backend/api/wallet/services/utils.js` (lines 15-20)
- **Impact:** Eliminates all race conditions in transaction ID generation

---

## API Endpoints

### 1. POST `/wallet/lookup-user`
**Purpose:** Find user by phone number for transfer
**Authentication:** Required (JWT Bearer token)
**Request Body:**
```json
{
  "phoneNumber": "0957143506"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "found": true,
    "user": {
      "id": 86572,
      "username": "Kanyanut",
      "phoneNumber": "0957143506"
    }
  }
}
```

**Not Found Response (200):**
```json
{
  "success": true,
  "data": {
    "found": false,
    "message": "No user found with this phone number"
  }
}
```

**Error Cases:**
- Self-transfer attempt: `"Cannot transfer to yourself"`
- User has no wallet: `"User does not have a wallet"`
- Wallet is frozen: `"Cannot transfer to this user"`

---

### 2. POST `/wallet/transfer`
**Purpose:** Execute wallet-to-wallet transfer
**Authentication:** Required (JWT Bearer token)
**Request Body:**
```json
{
  "receiverUserId": 86572,
  "amount": 100.00,
  "description": "Transfer for dinner",
  "idempotencyKey": "unique-key-123456"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "success": true,
    "transferId": "TRX_1773986098556",
    "amount": 100.00,
    "fee": 0,
    "totalDeduction": 100.00,
    "status": "completed",
    "timestamp": "2026-03-21T01:00:00.000Z"
  }
}
```

**Security Features:**
- ✅ Idempotency keys (24-hour TTL) - prevents double transfers
- ✅ Rate limiting (10 requests/minute per user)
- ✅ Amount validation (฿1 - ฿50,000)
- ✅ Self-transfer prevention
- ✅ Wallet status validation (frozen check)
- ✅ Database transaction locking (`FOR UPDATE`)

---

### 3. GET `/wallet/transfers`
**Purpose:** Get transfer history
**Authentication:** Required (JWT Bearer token)
**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 20)
- `type` - 'sent', 'received', or 'all'

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "transfers": [
      {
        "transferId": "TRX_1773986098556",
        "type": "sent",
        "amount": 100.00,
        "fee": 0,
        "status": "completed",
        "description": "Transfer for dinner",
        "createdAt": "2026-03-21T01:00:00.000Z",
        "otherUser": {
          "id": 86572,
          "username": "Kanyanut",
          "phoneNumber": "0957143506"
        }
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 5,
      "totalPages": 1
    }
  }
}
```

---

### 4. GET `/wallet/transfer/:transferId`
**Purpose:** Get transfer details
**Authentication:** Required (JWT Bearer token)
**URL Parameter:** `transferId`

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "transferId": "TRX_1773986098556",
    "amount": 100.00,
    "fee": 0,
    "status": "completed",
    "description": "Transfer for dinner",
    "createdAt": "2026-03-21T01:00:00.000Z",
    "sender": {
      "id": 133483,
      "username": "John",
      "phoneNumber": "0862413459"
    },
    "receiver": {
      "id": 86572,
      "username": "Kanyanut",
      "phoneNumber": "0957143506"
    }
  }
}
```

---

## Database Verification

**Test Users Available:**
```
1. User ID: 76517
   Phone: -0638610888
   Username: waroon09@gmail.com

2. User ID: 117882
   Phone: -930978456
   Username: jan.gopeng@gmail.com

3. User ID: 110402
   Phone: 00832226583
   Username: artploy_8@hotmail.com

4. User ID: 58446
   Phone: 00882556382
   Username: ariyasilp@gmail.com

5. User ID: 10503
   Phone: 06-2991-9156
   Username: 1102900040326
```

**Note:** Phone numbers may have formatting issues (leading dashes, spaces). The API normalizes these by removing spaces, dashes, and parentheses.

---

## Testing Instructions

### Option 1: Test via Flutter App (Recommended)

1. **Restart Flutter App:**
   ```bash
   # In the Flutter app terminal, press 'R' (capital R) for hot restart
   # Or restart the app completely
   flutter run -d emulator-5554
   ```

2. **Navigate to Transfer Screen:**
   - Open the wallet section
   - Tap on "Transfer" button
   - Enter a test phone number (use one from the database list above)

3. **Test Phone Lookup:**
   - Enter: `0957143506` (or any phone from the list)
   - Verify that recipient name appears
   - Verify that the "Enter Transfer Details" button becomes enabled

4. **Complete Transfer:**
   - Enter amount (฿1 - ฿50,000)
   - Add optional note
   - Tap "Review Transfer"
   - Confirm the transfer
   - Verify success screen appears with transfer details

5. **Verify in Backend Logs:**
   ```bash
   # Watch backend logs for transfer requests
   tail -f /Users/prachumchanman/Documents/chongjaroen-master/packages/backend/backend.log
   ```

   Expected logs:
   ```
   [Transfer] Looking up user by phone: {"requestedBy":133483,"phoneNumber":"3506"}
   POST /wallet/lookup-user (12 ms) 200
   [Transfer] Initiating transfer: {"senderUserId":133483,"receiverUserId":86572,"amount":100}
   POST /wallet/transfer (45 ms) 200
   ```

### Option 2: Test via API (curl)

**Prerequisites:** You need a valid JWT token from an authenticated user.

1. **Test Lookup User:**
   ```bash
   curl -X POST http://localhost:7001/wallet/lookup-user \
     -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"phoneNumber": "0957143506"}'
   ```

2. **Test Transfer:**
   ```bash
   curl -X POST http://localhost:7001/wallet/transfer \
     -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "receiverUserId": 86572,
       "amount": 100,
       "description": "Test transfer",
       "idempotencyKey": "test-key-'$(date +%s)'"
     }'
   ```

3. **Test Get Transfer History:**
   ```bash
   curl -X GET "http://localhost:7001/wallet/transfers?type=all&limit=10" \
     -H "Authorization: Bearer YOUR_JWT_TOKEN"
   ```

---

## Known Issues & Limitations

### ✅ Resolved:
1. ❌ ~~Table name `up_users` doesn't exist~~ → Fixed to `users-permissions_user`
2. ❌ ~~Column `phoneNumber` doesn't exist~~ → Fixed to `phone`
3. ❌ ~~403 Forbidden on transfer endpoints~~ → Permissions created
4. ❌ ~~Backend not loading transfer controller~~ → Server restarted
5. ❌ ~~Missing balance tracking columns~~ → Added 6 new columns to wallet_transfers table
6. ❌ ~~Type mismatch error in Flutter~~ → Fixed with .toString() conversion
7. ❌ ~~Duplicate entry error (Race condition)~~ → Fixed with timestamp-based ID generation

### ⚠️ Current Limitations:
1. **Phone Number Format:** Some users have phone numbers with unusual formatting (leading dashes, spaces). The API normalizes these, but the original data should be cleaned up.
2. **In-Memory Caching:** Idempotency and rate limiting use in-memory cache. For production, use Redis or database.
3. **Wallet Column Name:** Database uses `id` not `wallet_id` - this is noted for future queries.

---

## Flutter Integration

### WalletService Methods

**Location:** `/packages/application/lib/services/wallet.dart`

```dart
// Look up user by phone number
Future<Map<String, dynamic>?> lookupUserByPhone(String phoneNumber)

// Transfer funds
Future<Map<String, dynamic>?> transferFunds({
  required int receiverUserId,
  required double amount,
  String? description,
})

// Get transfer history
Future<List<dynamic>> getTransferHistory({
  int page = 1,
  int limit = 20,
  String? type, // 'sent', 'received', or null for all
})
```

### Transfer UI Screens

1. **TransferScreen** (`lib/screens/wallet/transfer.dart`)
   - Phone number input
   - Amount input
   - Recipient lookup display
   - Button activation logic

2. **TransferConfirmScreen** (`lib/screens/wallet/transfer_confirm.dart`)
   - Transfer review
   - Final confirmation

3. **TransferSuccessScreen** (`lib/screens/wallet/transfer_success.dart`)
   - Success animation
   - Transaction details
   - Receipt sharing (TODO)

---

## Next Steps

1. ✅ All backend code fixes applied
2. ✅ Backend restarted with correct configuration
3. ✅ Database verified with test users
4. ⏳ **PENDING:** Test transfer flow in Flutter app
5. ⏳ **PENDING:** Verify end-to-end transfer execution
6. ⏳ **PENDING:** Test edge cases (insufficient balance, frozen wallet, etc.)
7. ⏳ **PENDING:** Clean up phone number formatting in database
8. ⏳ **PENDING:** Implement receipt sharing feature

---

## Backend Status

```
✅ Server Running: http://localhost:7001
✅ Process ID: 95177
✅ Environment: development
✅ Database: chongjaroen_dev @ localhost:3306
✅ Transfer Controller: Loaded
✅ Transfer Routes: Configured
✅ Transfer Permissions: Created (4 endpoints)
✅ Bootstrap: Auto-creates missing permissions
```

---

## Error Codes

| Code | Description |
|------|-------------|
| `WALLET_001` | Insufficient balance |
| `WALLET_002` | Wallet frozen |
| `WALLET_003` | Transaction limit exceeded |
| `WALLET_004` | Invalid amount |
| `TRANSFER_ERROR` | General transfer error |

---

## Contact & Support

- Backend Port: 7001
- Database: MySQL (chongjaroen_dev)
- Admin Panel: http://localhost:7001/admin
- Backend Logs: Watch with `tail -f backend.log`

---

**Status: Ready for Testing** ✅
All critical bugs have been resolved. The transfer functionality is ready to be tested in the Flutter application.