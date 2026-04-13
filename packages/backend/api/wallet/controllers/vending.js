'use strict';

const crypto = require('crypto');
const Decimal = require('decimal.js');
const utils = require('../services/utils');
const { sendPushNotification } = require('../../helpers');

/**
 * Beer Vending Machine Controller
 * Handles reserved funds, session management, and volume tracking
 *
 * Flow:
 * 1. Reserve funds → Lock available balance
 * 2. Finalize → Charge actual amount, release remainder
 * 3. End session → Release any remaining reserved funds
 */

// Configuration
const VENDING_MINIMUM_BALANCE = 500; // ฿500 minimum
const VENDING_SESSION_TIMEOUT = 600000; // 10 minutes in ms
const PRICE_PER_ML = 2.00; // ฿2 per ml

module.exports = {
  /**
   * POST /wallet/vending/reserve
   * Reserve maximum available funds for vending session
   * Machine calls this after validating QR and checking minimum balance
   */
  async reserve(ctx) {
    try {
      const {
        nonce,
        machineId,
        branchId,
        metadata = {},
      } = ctx.request.body;

      // Validate inputs
      if (!nonce || !machineId) {
        return ctx.badRequest(utils.errorResponse('VENDING_ERROR', 'Nonce and machineId are required'));
      }

      strapi.log.info('[Vending] Creating reserve session:', { nonce, machineId, branchId });

      const knex = strapi.connections.default;

      // Get QR token from database
      const qrToken = await knex('payment_qr_tokens')
        .where({ nonce })
        .first();

      if (!qrToken) {
        return ctx.badRequest(utils.errorResponse('VENDING_ERROR', 'Invalid payment token'));
      }

      if (qrToken.status !== 'active') {
        return ctx.badRequest(utils.errorResponse('VENDING_ERROR', `Payment token is ${qrToken.status}`));
      }

      // Check if expired
      if (new Date() > new Date(qrToken.expires_at)) {
        await knex('payment_qr_tokens')
          .where({ nonce })
          .update({ status: 'expired' });
        return ctx.badRequest(utils.errorResponse('VENDING_ERROR', 'Payment token has expired'));
      }

      const userId = qrToken.user_id;

      // Start database transaction
      const trx = await knex.transaction();

      try {
        // Lock wallet row for update
        const wallet = await trx('wallets')
          .where({ user_id: userId })
          .forUpdate()
          .first();

        if (!wallet) {
          await trx.rollback();
          return ctx.badRequest(utils.errorResponse('WALLET_ERROR', 'Wallet not found'));
        }

        if (wallet.status === 'frozen') {
          await trx.rollback();
          return ctx.badRequest(utils.errorResponse('WALLET_002', 'Wallet is frozen'));
        }

        // Check minimum balance
        const balance = new Decimal(wallet.balance || 0);
        const reservedBalance = new Decimal(wallet.reserved_balance || 0);
        const availableBalance = balance.minus(reservedBalance);

        strapi.log.info('[Vending] Balance check:', {
          balance: balance.toFixed(2),
          reservedBalance: reservedBalance.toFixed(2),
          availableBalance: availableBalance.toFixed(2),
        });

        if (availableBalance.lessThan(VENDING_MINIMUM_BALANCE)) {
          await trx.rollback();
          return ctx.badRequest(utils.errorResponse(
            'VENDING_MINIMUM_NOT_MET',
            `Minimum balance of ฿${VENDING_MINIMUM_BALANCE} required. Available: ฿${availableBalance.toFixed(2)}`
          ));
        }

        // Reserve the available balance
        const reserveAmount = availableBalance;
        const newReservedBalance = reservedBalance.plus(reserveAmount);

        // Calculate max dispensable volume
        const pricePerMl = new Decimal(PRICE_PER_ML);
        const maxVolume = reserveAmount.dividedBy(pricePerMl).floor().toNumber(); // ml

        // Generate session ID
        const sessionId = `VS-${Date.now()}-${crypto.randomBytes(4).toString('hex').toUpperCase()}`;
        const expiresAt = new Date(Date.now() + VENDING_SESSION_TIMEOUT);

        // Create vending session
        await trx('wallet_vending_sessions').insert({
          id: sessionId,
          user_id: userId,
          qr_token_id: qrToken.id,
          machine_id: machineId,
          branch_id: branchId || null,
          reserved_amount: reserveAmount.toFixed(2),
          total_dispensed: 0,
          total_charged: 0.00,
          price_per_ml: pricePerMl.toFixed(2),
          status: 'active',
          started_at: new Date(),
          expires_at: expiresAt,
          metadata: JSON.stringify(metadata),
        });

        // Update wallet reserved balance
        await trx('wallets')
          .where({ user_id: userId })
          .update({
            reserved_balance: newReservedBalance.toFixed(2),
            updated_at: new Date(),
          });

        // Commit transaction
        await trx.commit();

        strapi.log.info('[Vending] Reserve successful:', {
          sessionId,
          userId,
          reserveAmount: reserveAmount.toFixed(2),
          maxVolume,
        });

        ctx.send(utils.successResponse({
          sessionId,
          userId,
          reservedAmount: parseFloat(reserveAmount.toFixed(2)),
          maxVolume,
          pricePerMl: parseFloat(pricePerMl.toFixed(2)),
          balance: parseFloat(balance.toFixed(2)),
          availableBalance: parseFloat(availableBalance.toFixed(2)),
          expiresAt: expiresAt.toISOString(),
          expiresIn: VENDING_SESSION_TIMEOUT / 1000, // seconds
        }));

      } catch (error) {
        await trx.rollback();
        throw error;
      }

    } catch (error) {
      strapi.log.error('[Vending] reserve error:', error);
      ctx.badRequest(utils.errorResponse('VENDING_ERROR', error.message));
    }
  },

  /**
   * POST /wallet/vending/finalize
   * Finalize vending transaction after dispensing
   * Deduct actual amount and release remaining reserved funds
   */
  async finalize(ctx) {
    try {
      const {
        sessionId,
        volumeDispensed, // in ml
        machineId,
        metadata = {},
      } = ctx.request.body;

      // Validate inputs
      if (!sessionId || volumeDispensed === undefined || !machineId) {
        return ctx.badRequest(utils.errorResponse('VENDING_ERROR', 'SessionId, volumeDispensed, and machineId are required'));
      }

      const volume = parseInt(volumeDispensed);
      if (isNaN(volume) || volume < 0) {
        return ctx.badRequest(utils.errorResponse('VENDING_ERROR', 'Invalid volume'));
      }

      strapi.log.info('[Vending] Finalizing session:', { sessionId, volumeDispensed: volume, machineId });

      const knex = strapi.connections.default;

      // Start database transaction
      const trx = await knex.transaction();

      try {
        // Get vending session with lock
        const session = await trx('wallet_vending_sessions')
          .where({ id: sessionId })
          .forUpdate()
          .first();

        if (!session) {
          await trx.rollback();
          return ctx.badRequest(utils.errorResponse('VENDING_ERROR', 'Session not found'));
        }

        if (session.status !== 'active') {
          await trx.rollback();
          return ctx.badRequest(utils.errorResponse('VENDING_ERROR', `Session is ${session.status}`));
        }

        if (session.machine_id !== machineId) {
          await trx.rollback();
          return ctx.badRequest(utils.errorResponse('VENDING_ERROR', 'Machine ID mismatch'));
        }

        // Check if session expired
        if (new Date() > new Date(session.expires_at)) {
          await trx('wallet_vending_sessions')
            .where({ id: sessionId })
            .update({ status: 'expired' });
          await trx.rollback();
          return ctx.badRequest(utils.errorResponse('VENDING_ERROR', 'Session has expired'));
        }

        const userId = session.user_id;
        const pricePerMl = new Decimal(session.price_per_ml);
        const reservedAmount = new Decimal(session.reserved_amount);

        // Calculate charge amount
        const chargeAmount = pricePerMl.times(volume);

        // Verify charge doesn't exceed reserved amount
        if (chargeAmount.greaterThan(reservedAmount)) {
          await trx.rollback();
          return ctx.badRequest(utils.errorResponse(
            'VENDING_ERROR',
            `Charge amount ฿${chargeAmount.toFixed(2)} exceeds reserved amount ฿${reservedAmount.toFixed(2)}`
          ));
        }

        // Lock wallet row
        const wallet = await trx('wallets')
          .where({ user_id: userId })
          .forUpdate()
          .first();

        if (!wallet) {
          await trx.rollback();
          return ctx.badRequest(utils.errorResponse('WALLET_ERROR', 'Wallet not found'));
        }

        const currentBalance = new Decimal(wallet.balance);
        const currentReserved = new Decimal(wallet.reserved_balance);

        // Deduct charge from balance and reserved
        const newBalance = currentBalance.minus(chargeAmount);
        const newReserved = currentReserved.minus(reservedAmount);

        // Update wallet
        await trx('wallets')
          .where({ user_id: userId })
          .update({
            balance: newBalance.toFixed(2),
            reserved_balance: newReserved.toFixed(2),
            updated_at: new Date(),
          });

        // Generate transaction ID
        const transactionId = await utils.generateTransactionId();

        // Get branch name if available
        let branch = null;
        if (session.branch_id) {
          const branchResult = await trx('branches')
            .select('name')
            .where({ id: session.branch_id })
            .first();
          branch = branchResult?.name || null;
        }

        // Create transaction record
        await trx('wallet_transactions').insert({
          id: transactionId,
          user_id: userId,
          type: 'beer_machine_payment',
          amount: chargeAmount.negated().toFixed(2), // Negative for deduction
          balance_before: currentBalance.toFixed(2),
          balance_after: newBalance.toFixed(2),
          status: 'completed',
          description: `Beer vending: ${volume}ml`,
          branch: branch,
          vending_session_id: sessionId,
          volume_dispensed: volume,
          metadata: JSON.stringify({
            ...metadata,
            machineId,
            pricePerMl: parseFloat(pricePerMl.toFixed(2)),
            volumeDispensed: volume,
            sessionId,
          }),
          created_at: new Date(),
        });

        // Update vending session
        const totalDispensed = session.total_dispensed + volume;
        const totalCharged = new Decimal(session.total_charged).plus(chargeAmount);

        await trx('wallet_vending_sessions')
          .where({ id: sessionId })
          .update({
            total_dispensed: totalDispensed,
            total_charged: totalCharged.toFixed(2),
            status: 'completed',
            ended_at: new Date(),
          });

        // Commit transaction
        await trx.commit();

        strapi.log.info('[Vending] Finalize successful:', {
          transactionId,
          sessionId,
          userId,
          volume,
          chargeAmount: chargeAmount.toFixed(2),
          newBalance: newBalance.toFixed(2),
        });

        // Send push notification
        try {
          await sendPushNotification({
            content: `฿${chargeAmount.toFixed(2)} - Beer Vending (${volume}ml)`,
            heading: 'Payment Successful',
            external_ids: [userId.toString()],
            additionalData: {
              type: 'vending_payment',
              transactionId,
              sessionId,
              amount: parseFloat(chargeAmount.toFixed(2)),
              volume,
              newBalance: parseFloat(newBalance.toFixed(2)),
              timestamp: new Date().toISOString(),
            },
          });
        } catch (notificationError) {
          strapi.log.error('[Vending] Failed to send push notification:', notificationError);
        }

        ctx.send(utils.successResponse({
          success: true,
          transactionId,
          sessionId,
          volumeDispensed: volume,
          amount: parseFloat(chargeAmount.toFixed(2)),
          balanceBefore: parseFloat(currentBalance.toFixed(2)),
          balanceAfter: parseFloat(newBalance.toFixed(2)),
          totalDispensed,
          totalCharged: parseFloat(totalCharged.toFixed(2)),
          timestamp: new Date().toISOString(),
        }));

      } catch (error) {
        await trx.rollback();
        throw error;
      }

    } catch (error) {
      strapi.log.error('[Vending] finalize error:', error);
      ctx.badRequest(utils.errorResponse('VENDING_ERROR', error.message));
    }
  },

  /**
   * POST /wallet/vending/end-session
   * End vending session and release reserved funds
   * Called when user is done or session needs to be cancelled
   */
  async endSession(ctx) {
    try {
      const {
        sessionId,
        machineId,
        reason = 'user_finished',
      } = ctx.request.body;

      if (!sessionId || !machineId) {
        return ctx.badRequest(utils.errorResponse('VENDING_ERROR', 'SessionId and machineId are required'));
      }

      strapi.log.info('[Vending] Ending session:', { sessionId, machineId, reason });

      const knex = strapi.connections.default;

      // Start database transaction
      const trx = await knex.transaction();

      try {
        // Get vending session with lock
        const session = await trx('wallet_vending_sessions')
          .where({ id: sessionId })
          .forUpdate()
          .first();

        if (!session) {
          await trx.rollback();
          return ctx.badRequest(utils.errorResponse('VENDING_ERROR', 'Session not found'));
        }

        if (session.machine_id !== machineId) {
          await trx.rollback();
          return ctx.badRequest(utils.errorResponse('VENDING_ERROR', 'Machine ID mismatch'));
        }

        if (session.status !== 'active') {
          // Already ended
          await trx.rollback();
          return ctx.send(utils.successResponse({
            sessionId,
            status: session.status,
            message: 'Session already ended',
          }));
        }

        const userId = session.user_id;
        const reservedAmount = new Decimal(session.reserved_amount);
        const totalCharged = new Decimal(session.total_charged);
        const releaseAmount = reservedAmount.minus(totalCharged);

        // Lock wallet row
        const wallet = await trx('wallets')
          .where({ user_id: userId })
          .forUpdate()
          .first();

        if (!wallet) {
          await trx.rollback();
          return ctx.badRequest(utils.errorResponse('WALLET_ERROR', 'Wallet not found'));
        }

        const currentReserved = new Decimal(wallet.reserved_balance);
        const newReserved = currentReserved.minus(releaseAmount);

        // Release reserved funds
        await trx('wallets')
          .where({ user_id: userId })
          .update({
            reserved_balance: newReserved.toFixed(2),
            updated_at: new Date(),
          });

        // Update session status
        const sessionStatus = reason === 'cancelled' ? 'cancelled' : 'completed';
        await trx('wallet_vending_sessions')
          .where({ id: sessionId })
          .update({
            status: sessionStatus,
            ended_at: new Date(),
          });

        // Commit transaction
        await trx.commit();

        strapi.log.info('[Vending] Session ended:', {
          sessionId,
          userId,
          releaseAmount: releaseAmount.toFixed(2),
          status: sessionStatus,
        });

        ctx.send(utils.successResponse({
          sessionId,
          releasedAmount: parseFloat(releaseAmount.toFixed(2)),
          finalBalance: parseFloat(wallet.balance),
          totalDispensed: session.total_dispensed,
          totalCharged: parseFloat(totalCharged.toFixed(2)),
          status: sessionStatus,
          endedAt: new Date().toISOString(),
        }));

      } catch (error) {
        await trx.rollback();
        throw error;
      }

    } catch (error) {
      strapi.log.error('[Vending] endSession error:', error);
      ctx.badRequest(utils.errorResponse('VENDING_ERROR', error.message));
    }
  },

  /**
   * GET /wallet/vending/session/:sessionId
   * Get vending session details
   */
  async getSession(ctx) {
    try {
      const { sessionId } = ctx.params;

      if (!sessionId) {
        return ctx.badRequest(utils.errorResponse('VENDING_ERROR', 'SessionId is required'));
      }

      const knex = strapi.connections.default;
      const session = await knex('wallet_vending_sessions')
        .where({ id: sessionId })
        .first();

      if (!session) {
        return ctx.notFound(utils.errorResponse('VENDING_ERROR', 'Session not found'));
      }

      ctx.send(utils.successResponse({
        sessionId: session.id,
        userId: session.user_id,
        machineId: session.machine_id,
        branchId: session.branch_id,
        reservedAmount: parseFloat(session.reserved_amount),
        totalDispensed: session.total_dispensed,
        totalCharged: parseFloat(session.total_charged),
        pricePerMl: parseFloat(session.price_per_ml),
        status: session.status,
        startedAt: session.started_at,
        endedAt: session.ended_at,
        expiresAt: session.expires_at,
        metadata: session.metadata ? JSON.parse(session.metadata) : null,
      }));

    } catch (error) {
      strapi.log.error('[Vending] getSession error:', error);
      ctx.badRequest(utils.errorResponse('VENDING_ERROR', error.message));
    }
  },
};
