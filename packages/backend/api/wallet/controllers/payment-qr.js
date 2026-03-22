'use strict';

const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const Decimal = require('decimal.js');
const utils = require('../services/utils');
const { sendPushNotification } = require('../../helpers');

/**
 * Payment QR Controller
 * Handles in-store payment QR code generation and validation
 * Used for:
 * 1. Staff scanning customer QR to deduct payment
 * 2. Beer machines scanning QR for automatic charging
 */

// QR Token configuration
const QR_TOKEN_EXPIRY = 900; // 15 minutes (like TrueMoney Wallet)
const QR_TOKEN_SECRET = process.env.JWT_SECRET || 'default-secret-change-in-production';

// NOTE: Expired tokens are cleaned up on validation (line ~178)
// For production, consider a periodic cleanup job (e.g., cron) to remove old expired tokens

module.exports = {
  /**
   * POST /wallet/payment-qr/generate
   * Generate dynamic QR code token for payment
   * Customer calls this to show QR code at store/beer machine
   */
  async generatePaymentQR(ctx) {
    try {
      const userId = ctx.state.user.id;

      if (!userId) {
        return ctx.unauthorized('Authentication required');
      }

      const { purpose = 'payment' } = ctx.request.body;

      // Validate purpose
      if (!['payment', 'store_payment', 'beer_machine'].includes(purpose)) {
        return ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', 'Invalid purpose. Must be payment, store_payment, or beer_machine'));
      }

      strapi.log.info('[Payment QR] Generating QR token:', { userId, purpose });

      // Get user's wallet and balance
      const knex = strapi.connections.default;
      const wallet = await knex('wallets')
        .where({ user_id: userId })
        .first();

      if (!wallet) {
        return ctx.badRequest(utils.errorResponse('WALLET_ERROR', 'Wallet not found'));
      }

      if (wallet.status === 'frozen') {
        return ctx.badRequest(utils.errorResponse('WALLET_002', 'Wallet is frozen'));
      }

      // Generate unique nonce (prevents replay attacks)
      const nonce = crypto.randomBytes(16).toString('hex');
      const expiresAt = new Date(Date.now() + QR_TOKEN_EXPIRY * 1000);

      // Create JWT token with user info
      const tokenPayload = {
        userId,
        nonce,
        purpose,
        walletId: wallet.id,
        exp: Math.floor(expiresAt.getTime() / 1000), // JWT expiry in seconds
      };

      const token = jwt.sign(tokenPayload, QR_TOKEN_SECRET);

      // Store nonce in database for validation and replay attack prevention
      await knex('payment_qr_tokens').insert({
        user_id: userId,
        token,
        nonce,
        purpose,
        status: 'active',
        expires_at: expiresAt,
      });

      // Tokens are marked expired during validation (no setTimeout needed)
      // This ensures proper cleanup even after server restarts

      // Get user info for display
      const user = await knex('users-permissions_user')
        .select('id', 'username', 'phone')
        .where({ id: userId })
        .first();

      ctx.send(utils.successResponse({
        token,
        qrData: token, // This is what gets encoded in QR code
        expiresAt: expiresAt.toISOString(),
        expiresIn: QR_TOKEN_EXPIRY,
        user: {
          id: user.id,
          username: user.username,
          phoneNumber: user.phone,
        },
        wallet: {
          balance: parseFloat(wallet.balance),
          status: wallet.status,
        },
        purpose,
      }));

    } catch (error) {
      strapi.log.error('[Payment QR] generatePaymentQR error:', error);
      ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', error.message));
    }
  },

  /**
   * POST /wallet/payment-qr/validate
   * Validate scanned QR code token
   * Staff/machine calls this after scanning customer QR
   */
  async validatePaymentQR(ctx) {
    try {
      const { token } = ctx.request.body;

      if (!token) {
        strapi.log.error('[Payment QR] No token provided in request');
        return ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', 'Token is required'));
      }

      // Log token length only (never log full token - security risk)
      strapi.log.info('[Payment QR] Validating QR token, length:', token.length);

      // Verify JWT token
      let decoded;
      try {
        decoded = jwt.verify(token, QR_TOKEN_SECRET);
      } catch (error) {
        if (error.name === 'TokenExpiredError') {
          return ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', 'QR code has expired'));
        }
        return ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', 'Invalid QR code'));
      }

      const { userId, nonce, purpose, walletId } = decoded;

      // Log minimal info (avoid logging full nonce or userId for security)
      strapi.log.info('[Payment QR] Validating token:', { purpose, hasWalletId: !!walletId });

      // Validate walletId exists in token
      if (!walletId) {
        strapi.log.error('[Payment QR] walletId missing from JWT token - this is an old QR code');
        return ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', 'QR code format is outdated. Please generate a new QR code.'));
      }

      // Check nonce in database (prevents replay attacks)
      const knex = strapi.connections.default;
      const qrToken = await knex('payment_qr_tokens')
        .where({ nonce })
        .first();

      if (!qrToken) {
        return ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', 'Invalid QR code'));
      }

      if (qrToken.status !== 'active') {
        return ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', `QR code is ${qrToken.status}`));
      }

      // Check if expired
      if (new Date() > new Date(qrToken.expires_at)) {
        await knex('payment_qr_tokens')
          .where({ nonce })
          .update({ status: 'expired' });
        return ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', 'QR code has expired'));
      }

      // Get user and wallet info
      const user = await knex('users-permissions_user')
        .select('id', 'username', 'phone')
        .where({ id: userId })
        .first();

      const wallet = await knex('wallets')
        .where({ id: walletId })
        .first();

      if (!wallet) {
        return ctx.badRequest(utils.errorResponse('WALLET_ERROR', 'Wallet not found'));
      }

      if (wallet.status === 'frozen') {
        return ctx.badRequest(utils.errorResponse('WALLET_002', 'Wallet is frozen'));
      }

      ctx.send(utils.successResponse({
        valid: true,
        nonce, // Return nonce for use in payment request
        user: {
          id: user.id,
          username: user.username,
          phoneNumber: user.phone,
        },
        wallet: {
          walletId: wallet.id,
          balance: parseFloat(wallet.balance),
          status: wallet.status,
        },
        purpose,
      }));

    } catch (error) {
      strapi.log.error('[Payment QR] validatePaymentQR error:', {
        message: error.message,
        stack: error.stack,
        name: error.name,
        code: error.code,
      });
      ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', error.message || 'Failed to validate QR code'));
    }
  },

  /**
   * POST /wallet/payment-qr/pay
   * Process payment after QR validation
   * Staff/machine calls this to deduct amount from customer wallet
   *
   * For store payment: One-time charge
   * For beer machine: Can be called with pre-auth or final charge
   */
  async processPayment(ctx) {
    try {
      const {
        nonce,
        amount,
        description,
        metadata, // Optional: { machineId, staffId, location, etc. }
      } = ctx.request.body;

      // Validate inputs
      if (!nonce || !amount) {
        return ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', 'Nonce and amount are required'));
      }

      const amountNum = parseFloat(amount);
      if (isNaN(amountNum) || amountNum <= 0) {
        return ctx.badRequest(utils.errorResponse('WALLET_004', 'Invalid amount'));
      }

      if (amountNum < 0.01) {
        return ctx.badRequest(utils.errorResponse('WALLET_004', 'Minimum payment amount is ฿0.01'));
      }

      if (amountNum > 10000) {
        return ctx.badRequest(utils.errorResponse('WALLET_004', 'Maximum payment amount is ฿10,000'));
      }

      strapi.log.info('[Payment QR] Processing payment:', { nonce, amount: amountNum });

      // Get QR token from database
      const knex = strapi.connections.default;
      const qrToken = await knex('payment_qr_tokens')
        .where({ nonce })
        .first();

      if (!qrToken) {
        return ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', 'Invalid payment token'));
      }

      if (qrToken.status !== 'active') {
        return ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', `Payment token is ${qrToken.status}`));
      }

      // Check if expired
      if (new Date() > new Date(qrToken.expires_at)) {
        await knex('payment_qr_tokens')
          .where({ nonce })
          .update({ status: 'expired' });
        return ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', 'Payment token has expired'));
      }

      const userId = qrToken.user_id;
      const purpose = qrToken.purpose;

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

        // Check sufficient balance - use Decimal.js for precision
        const currentBalance = new Decimal(wallet.balance || 0);
        const paymentAmount = new Decimal(amountNum);

        if (currentBalance.lessThan(paymentAmount)) {
          await trx.rollback();
          return ctx.badRequest(utils.errorResponse('WALLET_001', `Insufficient balance. Available: ฿${currentBalance.toFixed(2)}`));
        }

        // Deduct amount from wallet - use Decimal.js to prevent floating point errors
        const newBalance = currentBalance.minus(paymentAmount);
        await trx('wallets')
          .where({ user_id: userId })
          .update({
            balance: newBalance.toFixed(2),
            updated_at: new Date(),
          });

        // Generate transaction ID
        const transactionId = await utils.generateTransactionId();

        // Determine transaction type
        const transactionType = purpose === 'beer_machine' ? 'beer_machine_payment' : 'store_payment';

        // Create transaction record with precise decimal values
        await trx('wallet_transactions').insert({
          id: transactionId,
          user_id: userId,
          type: transactionType,
          amount: paymentAmount.negated().toFixed(2), // Negative for deduction, using Decimal.js
          balance_before: currentBalance.toFixed(2),
          balance_after: newBalance.toFixed(2),
          status: 'completed',
          description: description || `${purpose === 'beer_machine' ? 'Beer machine' : 'Store'} payment`,
          metadata: metadata ? JSON.stringify(metadata) : null,
          created_at: new Date(),
        });

        // Mark QR token as used
        await trx('payment_qr_tokens')
          .where({ nonce })
          .update({
            status: 'used',
            used_at: new Date(),
          });

        // Commit transaction
        await trx.commit();

        strapi.log.info('[Payment QR] Payment successful:', {
          transactionId,
          userId,
          amount: amountNum,
          newBalance,
        });

        // Send push notification to customer
        try {
          const notificationContent = `฿${amountNum.toFixed(2)} ${purpose === 'beer_machine' ? 'Beer Machine Payment' : 'Store Payment'}`;
          const notificationHeading = 'Payment Successful';

          await sendPushNotification({
            content: notificationContent,
            heading: notificationHeading,
            external_ids: [userId.toString()],
            additionalData: {
              type: 'payment_qr',
              transactionId,
              amount: amountNum,
              newBalance: newBalance,
              oldBalance: currentBalance,
              transactionType,
              timestamp: new Date().toISOString(),
            },
          });

          strapi.log.info('[Payment QR] Push notification sent to user:', userId);
        } catch (notificationError) {
          // Don't fail the payment if notification fails
          strapi.log.error('[Payment QR] Failed to send push notification:', notificationError);
        }

        ctx.send(utils.successResponse({
          success: true,
          transactionId,
          amount: amountNum,
          newBalance: newBalance,
          oldBalance: currentBalance,
          type: transactionType,
          timestamp: new Date().toISOString(),
        }));

      } catch (error) {
        await trx.rollback();
        throw error;
      }

    } catch (error) {
      strapi.log.error('[Payment QR] processPayment error:', error);
      ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', error.message));
    }
  },

  /**
   * GET /wallet/payment-qr/history
   * Get payment QR transaction history
   */
  async getPaymentHistory(ctx) {
    try {
      const userId = ctx.state.user.id;

      if (!userId) {
        return ctx.unauthorized('Authentication required');
      }

      const {
        page = 1,
        limit = 20,
        type, // 'store_payment' or 'beer_machine_payment'
      } = ctx.query;

      const offset = (parseInt(page) - 1) * parseInt(limit);

      strapi.log.info('[Payment QR] Getting payment history:', { userId, page, limit, type });

      const knex = strapi.connections.default;
      let query = knex('wallet_transactions')
        .select(
          'id',
          'type',
          'amount',
          'balance_before',
          'balance_after',
          'status',
          'description',
          'metadata',
          'created_at'
        )
        .where({ user_id: userId })
        .whereIn('type', ['store_payment', 'beer_machine_payment'])
        .orderBy('created_at', 'desc')
        .limit(parseInt(limit))
        .offset(offset);

      if (type) {
        query = query.where({ type });
      }

      const transactions = await query;

      // Get total count
      let countQuery = knex('wallet_transactions')
        .count('* as count')
        .where({ user_id: userId })
        .whereIn('type', ['store_payment', 'beer_machine_payment']);

      if (type) {
        countQuery = countQuery.where({ type });
      }

      const [{ count }] = await countQuery;

      const enrichedTransactions = transactions.map(tx => ({
        transactionId: tx.id,
        type: tx.type,
        amount: Math.abs(parseFloat(tx.amount)),
        balanceBefore: parseFloat(tx.balance_before),
        balanceAfter: parseFloat(tx.balance_after),
        status: tx.status,
        description: tx.description,
        metadata: tx.metadata ? JSON.parse(tx.metadata) : null,
        createdAt: tx.created_at,
      }));

      ctx.send(utils.successResponse({
        transactions: enrichedTransactions,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: parseInt(count),
          totalPages: Math.ceil(parseInt(count) / parseInt(limit)),
        },
      }));

    } catch (error) {
      strapi.log.error('[Payment QR] getPaymentHistory error:', error);
      ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', error.message));
    }
  },
};