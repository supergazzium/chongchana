⏺ 🧪 Complete Beer Vending Machine API Testing Guide

  Prerequisites

  Before starting, you need:
  - Backend deployed and running on DigitalOcean
  - Database access (MySQL client connected)
  - A test user account with wallet
  - Testing tool (curl, Postman, or browser)

  ---
  Phase 1: Setup & Preparation

  Step 1.1: Find or Create Test User

  -- Find an existing test user
  SELECT
    u.id,
    u.username,
    u.email,
    u.phone,
    w.balance,
    w.reserved_balance,
    w.available_balance,
    w.status
  FROM `users-permissions_user` u
  JOIN wallets w ON w.user_id = u.id
  WHERE u.email LIKE '%test%'  -- Or use your email
  LIMIT 5;

  Note down: user_id, email, and current balance

  ---
  Step 1.2: Set Test Balance (if needed)

  -- Ensure test user has at least ฿1,500
  UPDATE wallets
  SET balance = 1500.00
  WHERE user_id = YOUR_USER_ID;

  -- Verify
  SELECT user_id, balance, reserved_balance, available_balance
  FROM wallets
  WHERE user_id = YOUR_USER_ID;

  Expected: balance = 1500.00, reserved_balance = 0.00, available_balance = 1500.00

  ---
  Step 1.2.5: Auto-Cleanup of Stale Sessions (Informational)

  As of the latest backend, the following endpoints automatically release
  any vending sessions where status='active' but expires_at has passed:

  - POST /wallet/payment-qr/validate
  - POST /wallet/vending/reserve

  This means: if your previous test left a session stuck (e.g., crashed
  between reserve and finalize), simply scanning a fresh QR or calling
  reserve will sweep it. You should NOT see reserved_balance > 0 from
  prior aborted tests blocking new sessions.

  Manual recovery is no longer required for expired sessions. For sessions
  that are still within their 10-minute window but you want to abandon,
  use POST /wallet/vending/end-session (Step 3.6).

  ---
  Step 1.3: Get User JWT Token

  Option A: Login via API

  curl -X POST https://wallet-backend-test-pc-ndd56.ondigitalocean.app/auth/local \
    -H "Content-Type: application/json" \
    -d '{
      "identifier": "YOUR_EMAIL",
      "password": "YOUR_PASSWORD"
    }'

  Expected Response:
  {
    "jwt": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 123,
      "username": "testuser",
      "email": "test@example.com"
    }
  }

  Save the JWT: Copy the jwt value for next steps.

  Option B: Use existing token from your app (if already logged in)

  ---
  Phase 2: Test Complete Beer Vending Flow

  Step 2.1: Generate Payment QR Code

  curl -X POST
  https://wallet-backend-test-pc-ndd56.ondigitalocean.app/wallet/payment-qr/generate \
    -H "Authorization: Bearer YOUR_JWT_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"purpose": "payment"}'

  Expected Response:
  {
    "success": true,
    "data": {
      "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "qrData": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expiresAt": "2026-04-15T10:15:00.000Z",
      "expiresIn": 900,
      "user": {
        "id": 123,
        "username": "testuser",
        "phoneNumber": "0812345678"
      },
      "wallet": {
        "balance": 1500.00,
        "status": "active"
      },
      "purpose": "payment"
    }
  }

  Checklist:
  - success: true
  - token exists
  - wallet.balance shows correct amount
  - expiresIn is 900 (15 minutes)

  Save: Copy the token value (the long string starting with "eyJ...")

  Verify in Database:
  SELECT * FROM payment_qr_tokens
  WHERE user_id = YOUR_USER_ID
  ORDER BY created_at DESC
  LIMIT 1;

  Expected: New row with status = 'active', purpose = 'payment'

  ---
  Step 2.2: Validate QR Code (Machine Scans QR)

  curl -X POST
  https://wallet-backend-test-pc-ndd56.ondigitalocean.app/wallet/payment-qr/validate \
    -H "Content-Type: application/json" \
    -d '{
      "token": "PASTE_TOKEN_FROM_STEP_2.1"
    }'

  Expected Response (✅ WITH VENDING INFO - This is the fix!):
  {
    "success": true,
    "data": {
      "valid": true,
      "nonce": "72e8c290e8e98a0c0aaf22727812b2ff",
      "user": {
        "id": 123,
        "username": "testuser",
        "phoneNumber": "0812345678"
      },
      "wallet": {
        "walletId": 45,
        "balance": 1500.00,
        "reservedBalance": 0.00,
        "availableBalance": 1500.00,
        "status": "active"
      },
      "purpose": "payment",
      "vending": {
        "meetsMinimumBalance": true,
        "minimumRequired": 500,
        "canProceed": true
      }
    }
  }

  Checklist:
  - valid: true
  - nonce exists (long hex string)
  - wallet.availableBalance = 1500.00
  - vending object exists ← This is the Universal QR fix!
  - vending.canProceed: true
  - vending.meetsMinimumBalance: true

  Save: Copy the nonce value

  ---
  Step 2.3: Reserve Funds (Machine Locks Balance)

  Reserve locks a bounded amount for the session. The machine declares its
  price band up front by passing minAmount and maxAmount:

  - minAmount (optional): the smallest charge this machine will ever
    finalize (e.g. cheapest beer's price). Backend rejects finalize calls
    below this. Also requires availableBalance >= minAmount at reserve time.
  - maxAmount (optional): the largest charge this machine will ever
    finalize (e.g. most expensive beer × max pours). Backend locks
    min(maxAmount, availableBalance), so an abandoned session does not
    strand the user's full wallet.

  Backwards-compatibility: if both fields are omitted, behavior matches the
  legacy contract — no min check on finalize, and the entire available
  balance is locked. Existing firmware keeps working unchanged.

  Recommended (new firmware):

  curl -X POST https://wallet-backend-test-pc-ndd56.ondigitalocean.app/wallet/vending/reserve \
    -H "Content-Type: application/json" \
    -d '{
      "nonce": "PASTE_NONCE_FROM_STEP_2.2",
      "machineId": "BVM-TEST-001",
      "branchId": 1,
      "minAmount": 80,
      "maxAmount": 500,
      "metadata": {
        "location": "Test Branch",
        "temperature": 4
      }
    }'

  Expected Response (with bounds):
  {
    "success": true,
    "data": {
      "sessionId": "VS-1744717200000-A1B2C3D4",
      "userId": 123,
      "reservedAmount": 500.00,
      "balance": 1500.00,
      "availableBalance": 1500.00,
      "minAmount": 80.00,
      "maxAmount": 500.00,
      "expiresAt": "2026-04-15T10:10:00.000Z",
      "expiresIn": 600
    }
  }

  Checklist:
  - success: true
  - sessionId exists
  - reservedAmount = min(maxAmount, availableBalance) = 500.00
  - minAmount and maxAmount echoed back
  - expiresIn = 600 (10 minutes)

  Legacy form (no bounds — locks full balance):

  curl -X POST https://wallet-backend-test-pc-ndd56.ondigitalocean.app/wallet/vending/reserve \
    -H "Content-Type: application/json" \
    -d '{
      "nonce": "PASTE_NONCE_FROM_STEP_2.2",
      "machineId": "BVM-TEST-001",
      "branchId": 1
    }'

  Expected Response (legacy):
  {
    "success": true,
    "data": {
      "sessionId": "VS-1744717200000-A1B2C3D4",
      "userId": 123,
      "reservedAmount": 1500.00,
      "balance": 1500.00,
      "availableBalance": 1500.00,
      "expiresAt": "2026-04-15T10:10:00.000Z",
      "expiresIn": 600
    }
  }

  Note: minAmount/maxAmount are absent from the legacy response.

  Save: Copy the sessionId value

  Verify in Database:
  -- Check session created (bounds persisted in metadata JSON)
  SELECT id, reserved_amount, status, metadata
  FROM wallet_vending_sessions
  WHERE user_id = YOUR_USER_ID
  ORDER BY started_at DESC
  LIMIT 1;

  -- Check wallet balance locked
  SELECT
    balance,
    reserved_balance,
    available_balance
  FROM wallets
  WHERE user_id = YOUR_USER_ID;

  Expected Database State (bounded reserve, maxAmount=500):
  - Session: status = 'active', reserved_amount = 500.00,
             metadata contains { "minAmount": 80, "maxAmount": 500, ... }
  - Wallet: balance = 1500.00, reserved_balance = 500.00,
             available_balance = 1000.00

  Expected Database State (legacy reserve, no bounds):
  - Session: status = 'active', reserved_amount = 1500.00
  - Wallet: balance = 1500.00, reserved_balance = 1500.00,
             available_balance = 0.00

  ---
  Step 2.4: Finalize Transaction (Dispense 200ml Beer)

  The machine computes the total price (it knows the per-beer rates) and
  sends both volumeDispensed (for analytics) and amount (the charge in baht).
  Both are required. Backend rejects amount > ฿10,000 per dispense or
  amount > reservedAmount.

  curl -X POST https://wallet-backend-test-pc-ndd56.ondigitalocean.app/wallet/vending/finalize
  \
    -H "Content-Type: application/json" \
    -d '{
      "sessionId": "PASTE_SESSION_ID_FROM_STEP_2.3",
      "volumeDispensed": 200,
      "amount": 400.00,
      "machineId": "BVM-TEST-001",
      "metadata": {
        "pourDuration": 15,
        "temperature": 4
      }
    }'

  Expected Response:
  {
    "success": true,
    "data": {
      "success": true,
      "transactionId": "TXN-1744717250000-XYZ123",
      "sessionId": "VS-1744717200000-A1B2C3D4",
      "volumeDispensed": 200,
      "amount": 400.00,
      "balanceBefore": 1500.00,
      "balanceAfter": 1100.00,
      "totalDispensed": 200,
      "totalCharged": 400.00,
      "timestamp": "2026-04-15T10:05:30.000Z"
    }
  }

  Checklist:
  - success: true
  - transactionId exists
  - volumeDispensed = 200 (dispensed amount in ml, for analytics)
  - amount = 400.00 (total price machine sent)
  - balanceBefore = 1500.00
  - balanceAfter = 1100.00
  - totalDispensed = 200
  - totalCharged = 400.00

  Verify in Database:
  -- Check transaction created
  SELECT
    id,
    type,
    amount,
    balance_before,
    balance_after,
    vending_session_id,
    volume_dispensed,
    status,
    created_at
  FROM wallet_transactions
  WHERE user_id = YOUR_USER_ID
    AND type = 'beer_machine_payment'
  ORDER BY created_at DESC
  LIMIT 1;

  -- Check wallet updated
  SELECT
    balance,
    reserved_balance,
    available_balance
  FROM wallets
  WHERE user_id = YOUR_USER_ID;

  -- Check session completed
  SELECT
    id,
    status,
    total_dispensed,
    total_charged,
    ended_at
  FROM wallet_vending_sessions
  WHERE id = 'YOUR_SESSION_ID';

  Expected Database State:
  - Transaction:
    - type = 'beer_machine_payment'
    - amount = -400.00 (negative)
    - balance_after = 1100.00
    - volume_dispensed = 200
    - status = 'completed'
  - Wallet:
    - balance = 1100.00
    - reserved_balance = 0.00
    - available_balance = 1100.00
  - Session:
    - status = 'completed'
    - total_dispensed = 200
    - total_charged = 400.00
    - ended_at has timestamp

  ---
  Step 2.5: Get Session Details (Optional Verification)

  curl -X GET https://wallet-backend-test-pc-ndd56.ondigitalocean.app/wallet/vending/session/YO
  UR_SESSION_ID \
    -H "Content-Type: application/json"

  Expected Response:
  {
    "success": true,
    "data": {
      "sessionId": "VS-1744717200000-A1B2C3D4",
      "userId": 123,
      "machineId": "BVM-TEST-001",
      "branchId": 1,
      "reservedAmount": 1500.00,
      "totalDispensed": 200,
      "totalCharged": 400.00,
      "status": "completed",
      "startedAt": "2026-04-15T10:00:00.000Z",
      "endedAt": "2026-04-15T10:05:30.000Z",
      "expiresAt": "2026-04-15T10:10:00.000Z",
      "metadata": {
        "location": "Test Branch",
        "temperature": 4
      }
    }
  }

  Checklist:
  - status: "completed"
  - totalDispensed: 200
  - totalCharged: 400.00
  - endedAt has timestamp
  - metadata is returned as a JSON object (not a string)

  Note: Previously this endpoint returned 400 "Unexpected token o in JSON at
  position 1" due to a double-parse bug on the metadata column. Fixed in
  vending.js → parseMetadata helper.

  ---
  Phase 3: Test Error Scenarios

  Step 3.1: Test Insufficient Balance (< ฿500)

  Setup:
  UPDATE wallets SET balance = 300.00 WHERE user_id = YOUR_USER_ID;

  Test: Repeat Steps 2.1 and 2.2

  Expected in Step 2.2:
  {
    "success": true,
    "data": {
      "valid": true,
      "wallet": {
        "availableBalance": 300.00
      },
      "vending": {
        "meetsMinimumBalance": false,
        "minimumRequired": 500,
        "canProceed": false,
        "message": "Minimum balance of ฿500 required. Available: ฿300.00"
      }
    }
  }

  Checklist:
  - vending.canProceed: false
  - vending.meetsMinimumBalance: false
  - Error message shows correct balance

  Try to reserve:
  curl -X POST https://wallet-backend-test-pc-ndd56.ondigitalocean.app/wallet/vending/reserve \
    -H "Content-Type: application/json" \
    -d '{
      "nonce": "YOUR_NONCE",
      "machineId": "BVM-TEST-001",
      "branchId": 1
    }'

  Expected:
  {
    "success": false,
    "error": {
      "code": "VENDING_MINIMUM_NOT_MET",
      "message": "Minimum balance of ฿500 required. Available: ฿300.00"
    }
  }

  Reset balance:
  UPDATE wallets SET balance = 1500.00 WHERE user_id = YOUR_USER_ID;

  ---
  Step 3.2: Test Expired QR Token

  Setup:
  -- Expire the most recent token
  UPDATE payment_qr_tokens
  SET expires_at = DATE_SUB(NOW(), INTERVAL 1 HOUR)
  WHERE user_id = YOUR_USER_ID
  ORDER BY created_at DESC
  LIMIT 1;

  Test: Try to validate the expired token

  Expected:
  {
    "success": false,
    "error": {
      "code": "PAYMENT_ERROR",
      "message": "QR code has expired"
    }
  }

  Checklist:
  - Error code is correct
  - Error message is clear

  ---
  Step 3.3: Test Invalid Session ID

  curl -X POST https://wallet-backend-test-pc-ndd56.ondigitalocean.app/wallet/vending/finalize
  \
    -H "Content-Type: application/json" \
    -d '{
      "sessionId": "INVALID-SESSION-123",
      "volumeDispensed": 100,
      "machineId": "BVM-TEST-001"
    }'

  Expected:
  {
    "success": false,
    "error": {
      "code": "VENDING_ERROR",
      "message": "Session not found"
    }
  }

  ---
  Step 3.4: Test Machine ID Mismatch

  Setup: Create a session with one machine ID, try to finalize with different ID

  1. Reserve with machineId: "BVM-001"
  2. Try to finalize with machineId: "BVM-999"

  Expected:
  {
    "success": false,
    "error": {
      "code": "VENDING_ERROR",
      "message": "Machine ID mismatch"
    }
  }

  ---
  Step 3.5: Test Charge Amount Exceeds Reserved

  curl -X POST https://wallet-backend-test-pc-ndd56.ondigitalocean.app/wallet/vending/finalize
  \
    -H "Content-Type: application/json" \
    -d '{
      "sessionId": "YOUR_ACTIVE_SESSION_ID",
      "volumeDispensed": 200,
      "amount": 5000.00,
      "machineId": "BVM-TEST-001"
    }'

  Expected (when reservedAmount is ฿1,500):
  {
    "success": false,
    "error": {
      "code": "VENDING_ERROR",
      "message": "Charge amount ฿5000.00 exceeds reserved amount ฿1500.00"
    }
  }

  ---
  Step 3.5b: Test Finalize amount Validation

  Verifies that finalize rejects missing or out-of-range amount values.

  Test 1 — Missing amount:
  curl -X POST https://wallet-backend-test-pc-ndd56.ondigitalocean.app/wallet/vending/finalize \
    -H "Content-Type: application/json" \
    -d '{
      "sessionId": "YOUR_ACTIVE_SESSION_ID",
      "volumeDispensed": 200,
      "machineId": "BVM-TEST-001"
    }'

  Expected:
  {
    "success": false,
    "error": {
      "code": "VENDING_ERROR",
      "message": "amount is required"
    }
  }

  Test 2 — Negative amount:
  Body: { ..., "amount": -50 }
  Expected: "amount must be a non-negative number"

  Test 3 — Above per-dispense ceiling (฿10,000):
  Body: { ..., "amount": 99999 }
  Expected: "amount exceeds per-dispense maximum of ฿10000"

  Test 4 — Non-numeric:
  Body: { ..., "amount": "abc" }
  Expected: "amount must be a non-negative number"

  ---
  Step 3.5c: Test Reserve minAmount/maxAmount Validation

  Verifies that reserve rejects malformed bounds.

  Test 1 — Negative minAmount:
  Body: { ..., "minAmount": -10 }
  Expected: "minAmount must be a non-negative number"

  Test 2 — Zero or negative maxAmount:
  Body: { ..., "maxAmount": 0 }
  Expected: "maxAmount must be a positive number"

  Test 3 — Non-numeric maxAmount:
  Body: { ..., "maxAmount": "abc" }
  Expected: "maxAmount must be a positive number"

  Test 4 — minAmount above per-dispense ceiling:
  Body: { ..., "minAmount": 20000 }
  Expected: "minAmount exceeds per-dispense ceiling of ฿10000"

  Test 5 — maxAmount above per-dispense ceiling:
  Body: { ..., "maxAmount": 20000 }
  Expected: "maxAmount exceeds per-dispense ceiling of ฿10000"

  Test 6 — minAmount > maxAmount:
  Body: { ..., "minAmount": 600, "maxAmount": 500 }
  Expected: "minAmount (฿600.00) cannot exceed maxAmount (฿500.00)"

  Test 7 — Available balance below minAmount:
  Setup: UPDATE wallets SET balance = 600 WHERE user_id = YOUR_USER_ID;
  (Available is ฿600, well above ฿500 global floor — so the global gate
  passes, but the machine's minAmount=฿800 must reject.)
  Body: {
    "nonce": "...",
    "machineId": "BVM-TEST-001",
    "branchId": 1,
    "minAmount": 800,
    "maxAmount": 1000
  }
  Expected:
  {
    "success": false,
    "error": {
      "code": "VENDING_MINIMUM_NOT_MET",
      "message": "Insufficient balance for this machine. Required: ฿800.00, available: ฿600.00"
    }
  }

  Reset: UPDATE wallets SET balance = 1500 WHERE user_id = YOUR_USER_ID;

  ---
  Step 3.5d: Test Finalize Against Session Price Band

  Verifies that finalize enforces the minAmount/maxAmount that the machine
  declared at reserve time. These are independent of the global per-dispense
  ceiling tested in Step 3.5b.

  Setup: Create a session with bounds:
  Reserve body: { ..., "minAmount": 80, "maxAmount": 500 }
  → reservedAmount = 500.00 (assuming availableBalance >= 500)

  Test 1 — Charge below session minimum:
  curl -X POST https://wallet-backend-test-pc-ndd56.ondigitalocean.app/wallet/vending/finalize \
    -H "Content-Type: application/json" \
    -d '{
      "sessionId": "YOUR_BOUNDED_SESSION_ID",
      "volumeDispensed": 50,
      "amount": 50.00,
      "machineId": "BVM-TEST-001"
    }'

  Expected:
  {
    "success": false,
    "error": {
      "code": "VENDING_ERROR",
      "message": "Charge amount ฿50.00 is below session minimum ฿80.00"
    }
  }

  Test 2 — Charge above session maximum:
  Body: { ..., "amount": 600 }
  Expected:
  {
    "success": false,
    "error": {
      "code": "VENDING_ERROR",
      "message": "Charge amount ฿600.00 exceeds session maximum ฿500.00"
    }
  }

  Test 3 — Charge inside band succeeds:
  Body: { ..., "amount": 250 }
  Expected: success, balanceAfter = balanceBefore - 250

  Test 4 — Legacy session (no bounds) ignores band check:
  Setup: Reserve with no minAmount/maxAmount.
  Body: { ..., "amount": 0.01 }
  Expected: success (no session-level floor applies; only the global
  rules from Step 3.5b enforce here).

  Checklist:
  - Floor enforcement returns "below session minimum" with both values
  - Ceiling enforcement returns "exceeds session maximum" with both values
  - Mid-band charges succeed normally
  - Legacy (unbounded) sessions are unaffected — backwards compatible

  ---
  Step 3.6: Test End Session (Cancel Without Finalizing)

  Setup: Create a new session (repeat Steps 2.1-2.3)

  Test:
  curl -X POST
  https://wallet-backend-test-pc-ndd56.ondigitalocean.app/wallet/vending/end-session \
    -H "Content-Type: application/json" \
    -d '{
      "sessionId": "YOUR_SESSION_ID",
      "machineId": "BVM-TEST-001",
      "reason": "cancelled"
    }'

  Expected:
  {
    "success": true,
    "data": {
      "sessionId": "VS-...",
      "releasedAmount": 1500.00,
      "finalBalance": 1500.00,
      "totalDispensed": 0,
      "totalCharged": 0.00,
      "status": "cancelled",
      "endedAt": "2026-04-15T10:06:00.000Z"
    }
  }

  Verify:
  SELECT balance, reserved_balance, available_balance
  FROM wallets
  WHERE user_id = YOUR_USER_ID;

  Expected: reserved_balance = 0.00, available_balance = balance

  ---
  Step 3.7: Expired Session Auto-Recovery

  Verifies that an expired-but-still-active session is automatically
  released on the next validate or reserve call.

  Setup:
  1. Run Steps 2.1 → 2.3 to create an active session
  2. Note the sessionId and the wallet's reserved_balance (should equal
     the reservedAmount)
  3. Manually expire the session via SQL:

  UPDATE wallet_vending_sessions
  SET expires_at = DATE_SUB(NOW(), INTERVAL 1 HOUR)
  WHERE id = 'YOUR_SESSION_ID';

  Test: Generate and validate a new QR (Steps 2.1 → 2.2)

  Expected validate response:
  {
    "success": true,
    "data": {
      "valid": true,
      "wallet": {
        "reservedBalance": 0.00,
        "availableBalance": 1500.00
      },
      "vending": {
        "canProceed": true
      }
    }
  }

  Checklist:
  - reservedBalance returned to 0.00 (released automatically)
  - availableBalance equals total balance
  - vending.canProceed: true

  Verify in Database:
  SELECT id, status, ended_at
  FROM wallet_vending_sessions
  WHERE id = 'YOUR_SESSION_ID';

  Expected: status = 'expired', ended_at has timestamp

  -- Confirm wallet reserved cleared
  SELECT reserved_balance, available_balance
  FROM wallets
  WHERE user_id = YOUR_USER_ID;

  Expected: reserved_balance = 0.00

  ---
  Phase 4: Final Verification

  Step 4.1: Check All Tables

  -- Active sessions
  SELECT COUNT(*) as active_sessions
  FROM wallet_vending_sessions
  WHERE status = 'active';

  -- Should be 0

  -- Completed sessions
  SELECT
    id,
    user_id,
    status,
    total_dispensed,
    total_charged
  FROM wallet_vending_sessions
  WHERE user_id = YOUR_USER_ID
  ORDER BY started_at DESC
  LIMIT 5;

  -- Recent transactions
  SELECT
    id,
    type,
    amount,
    volume_dispensed,
    status
  FROM wallet_transactions
  WHERE user_id = YOUR_USER_ID
    AND type = 'beer_machine_payment'
  ORDER BY created_at DESC
  LIMIT 5;

  -- QR tokens
  SELECT
    nonce,
    purpose,
    status,
    expires_at
  FROM payment_qr_tokens
  WHERE user_id = YOUR_USER_ID
  ORDER BY created_at DESC
  LIMIT 5;

  ---
  ✅ Testing Checklist Summary

  - Setup Complete
    - Test user created with ฿1,500 balance
    - JWT token obtained
    - Database permissions verified
  - Happy Path Works
    - Generate QR → Returns token
    - Validate QR → Includes vending info (Universal QR!)
    - Reserve funds → Creates session, locks balance
    - Finalize → Charges correct amount, releases remainder
    - Get session → Returns correct details
  - Error Handling Works
    - Insufficient balance rejected
    - Expired QR rejected
    - Invalid session rejected
    - Machine ID mismatch rejected
    - Excess volume rejected
    - Cancel session releases funds
    - Expired session auto-released on next validate/reserve
    - Missing/invalid amount on finalize rejected with clear message
  - Database Consistency
    - No orphaned reserved balances
    - All sessions properly closed
    - Transactions match wallet balances

  ---
  🎉 Success Criteria

  ✅ All happy path tests pass✅ All error scenarios handled correctly✅ Database state is
  consistent✅ Vending info appears in QR validation (Universal QR working!)




  From the beer machine side, here's what you need to implement:

  Flow:

  1. Scan QR Code (shown by user on their phone)
    - Extract the token from the QR code data
  2. Validate the QR
  POST /wallet/payment-qr/validate
  Body: { "token": "scanned_token" }
    - Check if valid: true
    - Check if vending.canProceed: true
    - Extract the nonce from response
  3. Reserve Balance
  POST /wallet/vending/reserve
  Body: {
    "nonce": "from_step_2",
    "machineId": "YOUR_MACHINE_ID",
    "branchId": YOUR_BRANCH_ID,
    "minAmount": <cheapest_beer_price>,
    "maxAmount": <most_expensive_beer_price * max_pours>,
    "metadata": { "location": "...", "temperature": ... }
  }
    - minAmount and maxAmount declare the price band this machine will
      operate in. They are OPTIONAL but strongly recommended:
      * minAmount: the smallest charge the machine will ever finalize.
        Backend rejects finalize calls below this. Reserve also rejects
        if availableBalance < minAmount.
      * maxAmount: the largest charge the machine will ever finalize.
        Backend locks min(maxAmount, availableBalance) — so abandoned
        sessions don't strand the user's full wallet.
    - When both are omitted, legacy behavior applies: full available
      balance is locked, no per-charge floor at finalize.
    - No exact price is sent here: each beer can have a different rate,
      so the machine computes the total at finalize time.
    - Save the sessionId and reservedAmount. The response also echoes
      minAmount/maxAmount when provided.
  4. Dispense Beer (physical hardware action)
    - Track actual volumeDispensed in ml.
    - Compute total amount in baht using the machine's local per-beer
      pricing (whatever model you use — fixed per-pour, ml-based, etc.).
    - Ensure the computed amount falls inside [minAmount, maxAmount].
  5. Finalize Transaction
  POST /wallet/vending/finalize
  Body: {
    "sessionId": "from_step_3",
    "volumeDispensed": actual_ml,
    "amount": total_in_baht,
    "machineId": "YOUR_MACHINE_ID",
    "metadata": { "pourDuration": ..., "temperature": ... }
  }
    - amount is required; it is the total to charge the user.
    - amount must be ≥ 0, ≤ ฿10,000, and ≤ session.reservedAmount.
    - If the session was created with minAmount/maxAmount, amount must
      also be inside that band; otherwise finalize returns
      VENDING_ERROR "below session minimum" or "exceeds session maximum".
    - volumeDispensed is required (recorded for analytics; does not
      drive the charge).

  Key Points:

  - Machine needs QR scanner hardware
  - Machine needs API credentials (not user JWT)
  - Handle timeout errors (sessions expire in 10 minutes)
  - Handle dispense failures (call finalize with actual volume, even if 0)
  - Pass minAmount/maxAmount on reserve so an abandoned session only
    locks the machine's price ceiling, not the user's whole wallet