# Wallet Settings Page - Setup & Testing Guide

## Overview
The Wallet Settings page allows administrators to configure:
- **Point Redemption Rules**: Conversion rates, minimum redemption, approval requirements
- **Wallet Transfer Settings**: Fees, limits, and daily caps

## Database Setup

### 1. Run the Migration

The settings require the `wallet_transfer_settings` table. Run this SQL migration:

```bash
# From MySQL command line or MySQL Workbench:
mysql -u YOUR_USERNAME -p YOUR_DATABASE < packages/backend/database/migrations/wallet_transfers_points.sql
```

Or use the simpler migration:
```bash
mysql -u YOUR_USERNAME -p YOUR_DATABASE < packages/backend/database/migrations/ensure_wallet_settings.sql
```

### 2. Verify Table Creation

```sql
-- Check if table exists
SHOW TABLES LIKE 'wallet_transfer_settings';

-- View current settings
SELECT * FROM wallet_transfer_settings;
```

## API Endpoints

### GET /api/wallet-admin/transfer-settings
Retrieves all wallet and point settings

**Response:**
```json
{
  "success": true,
  "data": {
    "settings": {
      "transferFeePercentage": 0,
      "transferFeeFixed": 0,
      "transferMinAmount": 1,
      "transferMaxAmount": 50000,
      "transferDailyLimit": 100000,
      "pointConversionRate": 1,
      "pointMinRedemption": 100,
      "pointRedemptionRequiresApproval": false
    }
  }
}
```

### PUT /api/wallet-admin/transfer-settings
Updates wallet and point settings

**Request Body:**
```json
{
  "transferFeePercentage": 0.5,
  "transferFeeFixed": 5,
  "transferMinAmount": 10,
  "transferMaxAmount": 100000,
  "transferDailyLimit": 500000,
  "pointConversionRate": 1.5,
  "pointMinRedemption": 200,
  "pointRedemptionRequiresApproval": true
}
```

## Testing the Settings Page

### 1. Access the Page
Navigate to: `http://localhost:4040/wallets/settings`

### 2. Test Cases

#### Test 1: Load Settings
- **Expected**: Page loads with current settings from database
- **On Error**: Shows detailed error message with solutions

#### Test 2: Update Point Conversion Rate
1. Change "Point Conversion Rate" to `2.0`
2. Preview shows: `100 points = ฿50` (100 / 2.0 = 50)
3. Click "Save Changes"
4. **Expected**: Success message, settings persisted

#### Test 3: Input Validation
Try these invalid inputs:
- Point Conversion Rate: `0` or negative
- Minimum Points: `0` or negative
- Transfer Fee %: `101` (over 100%)
- Max Amount < Min Amount
- **Expected**: Validation error with specific messages

#### Test 4: Transfer Fee Calculator
1. Set Transfer Fee % to `2`
2. Set Fixed Fee to `5`
3. Enter transfer amount: `1000`
4. **Expected**:
   - Percentage Fee: ฿20 (2% of 1000)
   - Fixed Fee: ฿5
   - Total Fee: ฿25
   - Recipient Receives: ฿975

#### Test 5: Mobile Responsiveness
1. Resize browser to mobile width (< 768px)
2. **Expected**:
   - Single column layout
   - Buttons stack vertically
   - Calculators remain functional

#### Test 6: Reset Changes
1. Modify several settings
2. Click "Reset Changes"
3. **Expected**: All values revert to original

## Troubleshooting

### Error: "Failed to load settings"

**Cause**: Database table doesn't exist

**Solution**:
1. Run migration: `packages/backend/database/migrations/wallet_transfers_points.sql`
2. Verify database connection in backend
3. Check backend logs for detailed error

### Error: "Table not found"

**Cause**: Migration not applied

**Solution**:
```sql
-- Run this SQL directly
CREATE TABLE IF NOT EXISTS `wallet_transfer_settings` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `setting_key` VARCHAR(100) NOT NULL UNIQUE,
  `setting_value` TEXT NOT NULL,
  `description` TEXT NULL,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert defaults
INSERT INTO `wallet_transfer_settings` (`setting_key`, `setting_value`, `description`) VALUES
('transfer_fee_percentage', '0', 'Transfer fee percentage'),
('transfer_fee_fixed', '0', 'Fixed transfer fee'),
('transfer_min_amount', '1', 'Minimum transfer amount'),
('transfer_max_amount', '50000', 'Maximum transfer amount'),
('transfer_daily_limit', '100000', 'Daily transfer limit'),
('point_conversion_rate', '1', 'Points per 1 THB'),
('point_min_redemption', '100', 'Minimum points for redemption'),
('point_redemption_requires_approval', 'false', 'Require approval')
ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value);
```

### Settings Not Saving

**Check**:
1. Backend server running on port 7001
2. Admin user authenticated
3. Browser console for errors
4. Backend logs for errors

## Features

### Input Validation
- All numeric fields validated for proper ranges
- Transfer Max > Min enforced
- Daily Limit >= Max Amount enforced
- Percentage fee limited to 0-100%

### Real-Time Calculators
- **Point Calculator**: Shows exact cash amount for points
- **Transfer Fee Calculator**: Shows breakdown of all fees

### UX Improvements
- Detailed error messages with solutions
- Loading states during API calls
- Disabled save button when no changes
- Mobile-responsive design
- Visual feedback for validation errors

### Security
- Admin authentication required
- Input sanitization on backend
- SQL injection prevention via parameterized queries

## Architecture

```
Frontend (Admin Panel)
└── pages/wallets/settings.vue
    └── services/walletService.js
        └── API: /api/wallet-admin/transfer-settings

Backend (Strapi)
└── api/wallet/controllers/admin.js
    ├── getTransferSettings()
    └── updateTransferSettings()
        ├── services/transfer.js
        └── services/redemption.js
            └── Database: wallet_transfer_settings
```

## Database Schema

```sql
CREATE TABLE `wallet_transfer_settings` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `setting_key` VARCHAR(100) NOT NULL UNIQUE,
  `setting_value` TEXT NOT NULL,
  `description` TEXT NULL,
  `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### Settings Keys
- `transfer_fee_percentage` - Fee as percentage (0-100)
- `transfer_fee_fixed` - Fixed fee amount in THB
- `transfer_min_amount` - Minimum transfer in THB
- `transfer_max_amount` - Maximum transfer in THB
- `transfer_daily_limit` - Daily limit per user in THB
- `point_conversion_rate` - Points needed for ฿1
- `point_min_redemption` - Minimum points to redeem
- `point_redemption_requires_approval` - Boolean (true/false)

## Recommended Settings

### Conservative (Low Risk)
```
Point Conversion: 1.0 (1 point = ฿1)
Min Redemption: 100 points
Require Approval: true
Transfer Fee %: 1%
Fixed Fee: ฿10
Daily Limit: ฿50,000
```

### Moderate
```
Point Conversion: 1.0
Min Redemption: 50 points
Require Approval: false
Transfer Fee %: 0.5%
Fixed Fee: ฿5
Daily Limit: ฿100,000
```

### Generous (High Engagement)
```
Point Conversion: 1.0
Min Redemption: 10 points
Require Approval: false
Transfer Fee %: 0%
Fixed Fee: ฿0
Daily Limit: ฿1,000,000
```

## Support

For issues or questions:
1. Check backend logs: `packages/backend/logs/`
2. Verify database connection
3. Test API endpoints with Postman
4. Check browser console for frontend errors
