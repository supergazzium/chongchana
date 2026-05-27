'use strict';

/**
 * Commission Service
 * Reads and writes the global branch commission percentage stored in
 * wallet_transfer_settings. Used by the Wallet Overview to derive each
 * branch's commission deduction and net payable amount from gross
 * store_payment + beer_machine_payment volume in the selected period.
 */

const SETTING_KEY = 'commission_percentage';

function clampPercentage(value) {
  const pct = parseFloat(value);
  if (Number.isNaN(pct)) return 0;
  if (pct < 0) return 0;
  if (pct > 100) return 100;
  return pct;
}

module.exports = {
  async getPercentage() {
    const rows = await strapi.connections.default.raw(
      `SELECT setting_value FROM wallet_transfer_settings WHERE setting_key = ?`,
      [SETTING_KEY]
    );
    const raw = rows[0][0] && rows[0][0].setting_value;
    if (raw === undefined || raw === null) return 0;
    return clampPercentage(raw);
  },

  async setPercentage(value) {
    const pct = parseFloat(value);
    if (Number.isNaN(pct) || pct < 0 || pct > 100) {
      throw new Error('commission_percentage must be a number between 0 and 100');
    }
    await strapi.connections.default.raw(
      `INSERT INTO wallet_transfer_settings (setting_key, setting_value)
       VALUES (?, ?)
       ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)`,
      [SETTING_KEY, String(pct)]
    );
    return pct;
  },
};
