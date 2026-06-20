-- Add Beer Name Column to Wallet Transactions
-- Date: 2026-06-20
-- Description: Adds beer_name column to wallet_transactions for beer vending machine
-- payments so the wallet admin can display and filter by which beer was dispensed.
--
-- The vending machine sends `beerName` on /wallet/vending/finalize and the
-- backend persists it both into this dedicated column (for indexable filtering)
-- and inside the metadata JSON (for backwards compatibility / audit).

ALTER TABLE `wallet_transactions`
ADD COLUMN `beer_name` VARCHAR(120) NULL COMMENT 'Beer name for beer_machine_payment transactions' AFTER `volume_dispensed`,
ADD INDEX `idx_beer_name` (`beer_name`),
ADD INDEX `idx_type_beer_name` (`type`, `beer_name`);

-- Backfill from existing metadata JSON for any rows that already have beerName
-- recorded there (defensive — older firmware that started sending the field
-- before the column existed).
UPDATE `wallet_transactions` wt
SET `beer_name` = JSON_UNQUOTE(JSON_EXTRACT(`metadata`, '$.beerName'))
WHERE `type` = 'beer_machine_payment'
  AND `beer_name` IS NULL
  AND `metadata` IS NOT NULL
  AND JSON_VALID(`metadata`)
  AND JSON_EXTRACT(`metadata`, '$.beerName') IS NOT NULL
  AND JSON_TYPE(JSON_EXTRACT(`metadata`, '$.beerName')) = 'STRING';
