# Beer Vending Machine API Documentation

## Overview

This API implements a complete beer vending machine payment flow with:
- **Reserved funds** - Lock customer balance during dispensing
- **Session management** - Track vending sessions with multiple pours
- **Volume tracking** - Record ml dispensed and calculate charges
- **Minimum balance enforcement** - Require ฿500 minimum to start vending

## Database Setup

Run the migration to create necessary tables:

```bash
mysql -u root -p chongjaroen < /path/to/backend/database/migrations/wallet_vending_sessions.sql
```

This creates:
1. `wallet_vending_sessions` - Track active vending sessions
2. Adds `reserved_balance` to `wallets` table
3. Adds `vending_session_id` and `volume_dispensed` to `wallet_transactions`

## API Endpoints

### 1. Generate Payment QR

**Endpoint:** `POST /wallet/payment-qr/generate`

**Authentication:** Required (JWT)

**Request:**
```json
{
  "purpose": "beer_machine"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "qrData": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresAt": "2026-04-13T20:00:00.000Z",
    "expiresIn": 900,
    "user": {
      "id": 123,
      "username": "user123",
      "phoneNumber": "0812345678"
    },
    "wallet": {
      "balance": 1250.00,
      "status": "active"
    },
    "purpose": "beer_machine"
  }
}
```

---

### 2. Validate Payment QR

**Endpoint:** `POST /wallet/payment-qr/validate`

**Authentication:** Public (with isPublicPaymentQR policy)

**Request:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (Beer Machine):**
```json
{
  "success": true,
  "data": {
    "valid": true,
    "nonce": "abc123def456...",
    "user": {
      "id": 123,
      "username": "user123",
      "phoneNumber": "0812345678"
    },
    "wallet": {
      "walletId": 45,
      "balance": 1250.00,
      "reservedBalance": 0.00,
      "availableBalance": 1250.00,
      "status": "active"
    },
    "purpose": "beer_machine",
    "vending": {
      "meetsMinimumBalance": true,
      "minimumRequired": 500,
      "canProceed": true
    }
  }
}
```

**Response (Insufficient Balance):**
```json
{
  "success": true,
  "data": {
    "valid": true,
    "nonce": "abc123def456...",
    "user": { ... },
    "wallet": {
      "availableBalance": 300.00,
      ...
    },
    "purpose": "beer_machine",
    "vending": {
      "meetsMinimumBalance": false,
      "minimumRequired": 500,
      "canProceed": false,
      "message": "Minimum balance of ฿500 required. Available: ฿300.00"
    }
  }
}
```

---

### 3. Reserve Funds

**Endpoint:** `POST /wallet/vending/reserve`

**Authentication:** Public (with isPublicPaymentQR policy)

**Request:**
```json
{
  "nonce": "abc123def456...",
  "machineId": "BVM-001",
  "branchId": 5,
  "metadata": {
    "location": "Asoke Branch",
    "temperature": 4
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "sessionId": "VS-1744717200000-A1B2C3D4",
    "userId": 123,
    "reservedAmount": 1250.00,
    "maxVolume": 625,
    "pricePerMl": 2.00,
    "balance": 1250.00,
    "availableBalance": 1250.00,
    "expiresAt": "2026-04-13T20:10:00.000Z",
    "expiresIn": 600
  }
}
```

**What happens:**
1. Checks minimum balance (฿500)
2. Locks available balance in `reserved_balance` field
3. Creates active vending session
4. Calculates max dispensable volume (฿1250 ÷ ฿2/ml = 625ml)
5. Returns session ID for tracking

---

### 4. Finalize Transaction

**Endpoint:** `POST /wallet/vending/finalize`

**Authentication:** Public (with isPublicPaymentQR policy)

**Request:**
```json
{
  "sessionId": "VS-1744717200000-A1B2C3D4",
  "volumeDispensed": 175,
  "machineId": "BVM-001",
  "metadata": {
    "pourDuration": 12,
    "temperature": 4
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "success": true,
    "transactionId": "TXN-1744717250000-XYZ123",
    "sessionId": "VS-1744717200000-A1B2C3D4",
    "volumeDispensed": 175,
    "amount": 350.00,
    "balanceBefore": 1250.00,
    "balanceAfter": 900.00,
    "totalDispensed": 175,
    "totalCharged": 350.00,
    "timestamp": "2026-04-13T20:05:30.000Z"
  }
}
```

**What happens:**
1. Validates session is active
2. Calculates charge: 175ml × ฿2/ml = ฿350
3. Deducts ฿350 from wallet balance
4. Releases remaining reserved funds (฿900)
5. Creates transaction record with volume tracking
6. Marks session as completed
7. Sends push notification to user

---

### 5. End Session

**Endpoint:** `POST /wallet/vending/end-session`

**Authentication:** Public (with isPublicPaymentQR policy)

**Request:**
```json
{
  "sessionId": "VS-1744717200000-A1B2C3D4",
  "machineId": "BVM-001",
  "reason": "user_finished"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "sessionId": "VS-1744717200000-A1B2C3D4",
    "releasedAmount": 900.00,
    "finalBalance": 900.00,
    "totalDispensed": 175,
    "totalCharged": 350.00,
    "status": "completed",
    "endedAt": "2026-04-13T20:06:00.000Z"
  }
}
```

**Reasons:**
- `user_finished` - User completed transaction
- `cancelled` - User or machine cancelled
- `timeout` - Session expired

**What happens:**
1. Releases any remaining reserved funds
2. Marks session as completed/cancelled
3. Returns balance to available

---

### 6. Get Session Details

**Endpoint:** `GET /wallet/vending/session/:sessionId`

**Authentication:** Public (with isPublicPaymentQR policy)

**Response:**
```json
{
  "success": true,
  "data": {
    "sessionId": "VS-1744717200000-A1B2C3D4",
    "userId": 123,
    "machineId": "BVM-001",
    "branchId": 5,
    "reservedAmount": 1250.00,
    "totalDispensed": 175,
    "totalCharged": 350.00,
    "pricePerMl": 2.00,
    "status": "completed",
    "startedAt": "2026-04-13T20:00:00.000Z",
    "endedAt": "2026-04-13T20:06:00.000Z",
    "expiresAt": "2026-04-13T20:10:00.000Z",
    "metadata": {
      "location": "Asoke Branch",
      "temperature": 4
    }
  }
}
```

---

## Complete Flow Example

### User Journey

```
1. User opens wallet app
   ↓
2. Taps "Show Payment QR"
   POST /wallet/payment-qr/generate { purpose: "beer_machine" }
   ← QR code displayed (valid 15 min)
   ↓
3. User shows QR to vending machine
   ↓
4. Machine scans QR
   POST /wallet/payment-qr/validate { token: "..." }
   ← Validates wallet, checks ฿500 minimum
   ↓
5. Machine reserves funds
   POST /wallet/vending/reserve { nonce, machineId, branchId }
   ← Locks ฿1250, returns max 625ml
   ↓
6. User presses dispense button
   Machine monitors ml dispensed in real-time
   User releases button at 175ml
   ↓
7. Machine finalizes transaction
   POST /wallet/vending/finalize {
     sessionId,
     volumeDispensed: 175,
     machineId
   }
   ← Charges ฿350, releases ฿900, creates transaction
   ↓
8. User receives push notification
   "฿350.00 - Beer Vending (175ml)"
   Balance: ฿900
```

---

## Configuration

Default values (can be customized):

```javascript
const VENDING_MINIMUM_BALANCE = 500; // ฿500
const VENDING_SESSION_TIMEOUT = 600000; // 10 minutes
const PRICE_PER_ML = 2.00; // ฿2 per ml
```

---

## Error Handling

### Common Errors

| Error Code | Message | Action |
|------------|---------|--------|
| `VENDING_MINIMUM_NOT_MET` | Minimum balance of ฿500 required | User needs to top up |
| `VENDING_ERROR` | Session not found | Invalid session ID |
| `VENDING_ERROR` | Session has expired | Start new session |
| `VENDING_ERROR` | Machine ID mismatch | Security check failed |
| `WALLET_002` | Wallet is frozen | Contact support |
| `PAYMENT_ERROR` | QR code has expired | Generate new QR |

---

## Security Features

1. **Reserved Balance Lock** - Prevents overdraft during dispensing
2. **Session Timeout** - Auto-expires after 10 minutes
3. **Machine ID Validation** - Ensures finalize request comes from same machine
4. **Minimum Balance Enforcement** - Requires ฿500 before starting
5. **Volume Validation** - Prevents charging more than reserved
6. **Nonce-based QR** - Prevents replay attacks

---

## Database Schema

### wallet_vending_sessions

```sql
CREATE TABLE `wallet_vending_sessions` (
  `id` VARCHAR(50) PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL,
  `qr_token_id` INT UNSIGNED NULL,
  `machine_id` VARCHAR(50) NOT NULL,
  `branch_id` INT UNSIGNED NULL,
  `reserved_amount` DECIMAL(10,2) NOT NULL,
  `total_dispensed` INT DEFAULT 0,
  `total_charged` DECIMAL(10,2) DEFAULT 0.00,
  `price_per_ml` DECIMAL(10,2) DEFAULT 2.00,
  `status` ENUM('active', 'completed', 'cancelled', 'expired'),
  `started_at` DATETIME NOT NULL,
  `ended_at` DATETIME NULL,
  `expires_at` DATETIME NOT NULL,
  `metadata` JSON NULL
);
```

### wallets (updated)

```sql
ALTER TABLE `wallets`
  ADD `reserved_balance` DECIMAL(10,2) DEFAULT 0.00,
  ADD `available_balance` DECIMAL(10,2) GENERATED ALWAYS AS
    (`balance` - `reserved_balance`) STORED;
```

### wallet_transactions (updated)

```sql
ALTER TABLE `wallet_transactions`
  ADD `vending_session_id` VARCHAR(50) NULL,
  ADD `volume_dispensed` INT NULL;
```

---

## Testing

### Test with cURL

```bash
# 1. Generate QR (requires user JWT)
curl -X POST http://localhost:1337/wallet/payment-qr/generate \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"purpose": "beer_machine"}'

# 2. Validate QR (public - machine uses this)
curl -X POST http://localhost:1337/wallet/payment-qr/validate \
  -H "Content-Type: application/json" \
  -d '{"token": "YOUR_QR_TOKEN"}'

# 3. Reserve funds
curl -X POST http://localhost:1337/wallet/vending/reserve \
  -H "Content-Type: application/json" \
  -d '{
    "nonce": "NONCE_FROM_VALIDATE",
    "machineId": "BVM-001",
    "branchId": 5
  }'

# 4. Finalize transaction
curl -X POST http://localhost:1337/wallet/vending/finalize \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId": "SESSION_ID_FROM_RESERVE",
    "volumeDispensed": 175,
    "machineId": "BVM-001"
  }'

# 5. End session (optional - if not finalized)
curl -X POST http://localhost:1337/wallet/vending/end-session \
  -H "Content-Type: application/json" \
  -d '{
    "sessionId": "SESSION_ID",
    "machineId": "BVM-001",
    "reason": "user_finished"
  }'
```

---

## Migration Path

If you have existing simple vending payments, they will continue to work. The new flow is additive:

**Old Flow (still works):**
```
Generate QR → Validate → Pay (processPayment)
```

**New Flow (recommended):**
```
Generate QR → Validate → Reserve → Finalize → End Session
```

Choose based on your vending machine capabilities:
- **Simple machines** - Use old flow with fixed amounts
- **Variable dispensing** - Use new flow with sessions

---

## Support

For issues or questions, contact the development team or check the main documentation at `packages/Beer Vending Machine & Restaurant POS Pa.md`
