'use strict';

const Decimal = require('decimal.js');

/**
 * Release any of this user's vending sessions whose expires_at has passed
 * but whose status is still 'active'. Returns the total amount released
 * back into available balance.
 *
 * Without this, a crash/timeout between reserve and finalize permanently
 * locks the user's reserved_balance and blocks all future vending.
 *
 * Caller may pass an existing transaction (preferred when the cleanup is
 * part of a larger atomic operation) or omit it to use a short-lived one.
 */
async function releaseExpiredSessions(knexOrTrx, userId) {
  const now = new Date();

  const run = async (trx) => {
    const stale = await trx('wallet_vending_sessions')
      .where({ user_id: userId, status: 'active' })
      .andWhere('expires_at', '<', now)
      .forUpdate();

    if (stale.length === 0) {
      return new Decimal(0);
    }

    let totalReleased = new Decimal(0);
    for (const session of stale) {
      const reserved = new Decimal(session.reserved_amount);
      const charged = new Decimal(session.total_charged);
      totalReleased = totalReleased.plus(reserved.minus(charged));
    }

    await trx('wallet_vending_sessions')
      .where({ user_id: userId, status: 'active' })
      .andWhere('expires_at', '<', now)
      .update({ status: 'expired', ended_at: now });

    if (totalReleased.greaterThan(0)) {
      await trx('wallets')
        .where({ user_id: userId })
        .update({
          reserved_balance: trx.raw(
            'GREATEST(CAST(reserved_balance AS DECIMAL(20,2)) - ?, 0)',
            [totalReleased.toFixed(2)]
          ),
          updated_at: now,
        });
    }

    strapi.log.info('[Vending] Released expired sessions:', {
      userId,
      count: stale.length,
      released: totalReleased.toFixed(2),
    });

    return totalReleased;
  };

  // If caller passed a transaction (knex.transaction has commit/rollback),
  // use it directly. Otherwise spin up our own.
  if (knexOrTrx && typeof knexOrTrx.commit === 'function') {
    return run(knexOrTrx);
  }
  return knexOrTrx.transaction(run);
}

/**
 * Safely parse a metadata column. MySQL JSON columns may be returned
 * as already-parsed objects; older string columns return a string.
 */
function parseMetadata(value) {
  if (value === null || value === undefined) return null;
  if (typeof value === 'object') return value;
  if (typeof value === 'string') {
    try {
      return JSON.parse(value);
    } catch (e) {
      return null;
    }
  }
  return null;
}

module.exports = {
  releaseExpiredSessions,
  parseMetadata,
};
