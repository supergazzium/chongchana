-- Wallet Vending Sessions Migration
-- Creates tables for beer vending machine payment flow

-- 1. Create wallet_vending_sessions table
CREATE TABLE IF NOT EXISTS `wallet_vending_sessions` (
  `id` VARCHAR(50) NOT NULL,
  `user_id` INT UNSIGNED NOT NULL,
  `qr_token_id` INT UNSIGNED NULL,
  `machine_id` VARCHAR(50) NOT NULL,
  `branch_id` INT UNSIGNED NULL,
  `reserved_amount` DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  `total_dispensed` INT DEFAULT 0 COMMENT 'Total ml dispensed in this session',
  `total_charged` DECIMAL(10,2) DEFAULT 0.00,
  `price_per_ml` DECIMAL(10,2) DEFAULT 2.00,
  `status` ENUM('active', 'completed', 'cancelled', 'expired') NOT NULL DEFAULT 'active',
  `started_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ended_at` DATETIME NULL,
  `expires_at` DATETIME NOT NULL,
  `metadata` JSON NULL COMMENT 'Additional session data',
  PRIMARY KEY (`id`),
  KEY `idx_user_status` (`user_id`, `status`),
  KEY `idx_machine_status` (`machine_id`, `status`),
  KEY `idx_started_at` (`started_at`),
  KEY `idx_expires_at` (`expires_at`),
  CONSTRAINT `fk_vending_session_user` FOREIGN KEY (`user_id`) REFERENCES `users-permissions_user` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Add columns to wallet_transactions for vending tracking
ALTER TABLE `wallet_transactions`
  ADD COLUMN IF NOT EXISTS `vending_session_id` VARCHAR(50) NULL AFTER `branch`,
  ADD COLUMN IF NOT EXISTS `volume_dispensed` INT NULL COMMENT 'Volume in ml (for vending)' AFTER `vending_session_id`,
  ADD COLUMN IF NOT EXISTS `pos_terminal` VARCHAR(50) NULL AFTER `volume_dispensed`,
  ADD COLUMN IF NOT EXISTS `staff_id` INT UNSIGNED NULL AFTER `pos_terminal`;

-- Add indexes if they don't exist
ALTER TABLE `wallet_transactions`
  ADD KEY IF NOT EXISTS `idx_vending_session` (`vending_session_id`),
  ADD KEY IF NOT EXISTS `idx_pos_terminal` (`pos_terminal`);

-- 3. Add reserved_balance column to wallets table for tracking reserved funds
ALTER TABLE `wallets`
  ADD COLUMN IF NOT EXISTS `reserved_balance` DECIMAL(10,2) DEFAULT 0.00 AFTER `balance`,
  ADD COLUMN IF NOT EXISTS `available_balance` DECIMAL(10,2) GENERATED ALWAYS AS (`balance` - `reserved_balance`) STORED AFTER `reserved_balance`;

-- 4. Create indexes for better performance
CREATE INDEX IF NOT EXISTS `idx_wallets_available_balance` ON `wallets` (`available_balance`);
CREATE INDEX IF NOT EXISTS `idx_wallets_reserved_balance` ON `wallets` (`reserved_balance`);
