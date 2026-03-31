'use strict';

const walletService = require('../services/wallet');
const utils = require('../services/utils');
const { sendPushNotification } = require('../../helpers');

/**
 * Wallet Controller
 * User-facing wallet endpoints
 */

module.exports = {
  /**
   * GET /api/wallet/balance
   * Get current user's wallet balance
   */
  async getBalance(ctx) {
    try {
      const userId = ctx.state.user.id;

      if (!userId) {
        return ctx.unauthorized('Authentication required');
      }

      const balance = await walletService.getBalance(userId);
      ctx.send(utils.successResponse(balance));
    } catch (error) {
      strapi.log.error('[Wallet] getBalance error:', error);
      ctx.badRequest(utils.errorResponse('WALLET_ERROR', error.message));
    }
  },

  /**
   * GET /api/wallet/transactions
   * Get user's wallet transaction history
   */
  async getTransactions(ctx) {
    try {
      const userId = ctx.state.user.id;

      if (!userId) {
        return ctx.unauthorized('Authentication required');
      }

      const { limit, offset, type, status, fromDate, toDate } = ctx.query;

      const result = await walletService.getTransactions({
        userId,
        limit: limit || 20,
        offset: offset || 0,
        type,
        status,
        fromDate,
        toDate,
      });

      ctx.send(utils.successResponse(result));
    } catch (error) {
      strapi.log.error('[Wallet] getTransactions error:', error);
      ctx.badRequest(utils.errorResponse('WALLET_ERROR', error.message));
    }
  },

  /**
   * POST /api/wallet/top-up
   * Initiate wallet top-up transaction
   * Note: This is a placeholder. Real implementation needs Omise integration
   */
  async topUp(ctx) {
    try {
      const userId = ctx.state.user.id;

      if (!userId) {
        return ctx.unauthorized('Authentication required');
      }

      const { amount, paymentMethod, returnUrl } = ctx.request.body;

      // Validate amount
      const validation = utils.validateAmount(amount, 'top_up');
      if (!validation.valid) {
        return ctx.badRequest(utils.errorResponse('WALLET_004', validation.error));
      }

      // Calculate fee
      const fee = utils.calculateFee(amount, paymentMethod);
      const netAmount = amount - fee;

      // Get request metadata
      const metadata = utils.getRequestMetadata(ctx);

      // TODO: Integrate with Omise payment gateway
      // For now, create a pending transaction
      const transactionId = await utils.generateTransactionId();

      // This is a simplified version. In production, you would:
      // 1. Create Omise charge
      // 2. Get payment URL/QR code
      // 3. Create pending transaction
      // 4. Handle webhook for payment confirmation
      // 5. Update transaction status to completed

      ctx.send(utils.successResponse({
        transactionId,
        amount,
        fee,
        netAmount,
        paymentMethod,
        status: 'pending',
        // In production, include Omise charge data here
        message: 'Payment gateway integration required',
        createdAt: new Date(),
      }));
    } catch (error) {
      strapi.log.error('[Wallet] topUp error:', error);
      ctx.badRequest(utils.errorResponse('WALLET_005', error.message));
    }
  },

  /**
   * POST /api/wallet/pay
   * Pay for order using wallet balance
   */
  async pay(ctx) {
    try {
      const userId = ctx.state.user.id;

      if (!userId) {
        return ctx.unauthorized('Authentication required');
      }

      const {
        amount,
        referenceType,
        referenceId,
        branchId,
        description,
        usePoints = 0,
      } = ctx.request.body;

      // Validate amount
      const validation = utils.validateAmount(amount, 'payment');
      if (!validation.valid) {
        return ctx.badRequest(utils.errorResponse('WALLET_004', validation.error));
      }

      // Get request metadata
      const metadata = utils.getRequestMetadata(ctx);

      // Create payment transaction
      const transaction = await walletService.createTransaction({
        userId,
        type: 'payment',
        amount,
        referenceType,
        referenceId,
        description: description || `Payment for ${referenceType} ${referenceId}`,
        metadata: {
          branchId,
          usePoints,
        },
        ...metadata,
      });

      // TODO: Handle points usage if usePoints > 0
      // TODO: Calculate points earned from this payment

      const pointsEarned = Math.floor(amount * 0.1); // 10% points earning rate

      // Send push notification for payment
      try {
        await sendPushNotification({
          content: `Payment of ฿${amount.toFixed(2)} successful${pointsEarned > 0 ? ` (+${pointsEarned} points)` : ''}`,
          heading: 'Payment Successful',
          external_ids: [userId.toString()],
          additionalData: {
            type: 'wallet_payment',
            transactionId: transaction.id,
            amount,
            referenceType,
            referenceId,
            pointsUsed: usePoints,
            pointsEarned,
            balanceAfter: parseFloat(transaction.balance_after),
            timestamp: new Date().toISOString(),
          },
        });

        strapi.log.info('[Wallet] Push notification sent for payment:', transaction.id);
      } catch (notificationError) {
        // Don't fail the payment if notification fails
        strapi.log.error('[Wallet] Failed to send push notification:', notificationError);
      }

      ctx.send(utils.successResponse({
        transactionId: transaction.id,
        type: 'payment',
        amount: parseFloat(transaction.amount),
        pointsUsed: usePoints,
        pointsEarned,
        balanceBefore: parseFloat(transaction.balance_before),
        balanceAfter: parseFloat(transaction.balance_after),
        status: transaction.status,
        referenceId,
        completedAt: transaction.completed_at,
      }));
    } catch (error) {
      strapi.log.error('[Wallet] pay error:', error);

      if (error.message === 'WALLET_001') {
        return ctx.badRequest(utils.errorResponse('WALLET_001', 'Insufficient balance'));
      }
      if (error.message === 'WALLET_002') {
        return ctx.badRequest(utils.errorResponse('WALLET_002', 'Wallet frozen'));
      }

      ctx.badRequest(utils.errorResponse('WALLET_ERROR', error.message));
    }
  },

  /**
   * POST /api/wallet/voucher/redeem
   * Redeem voucher code for wallet credit
   */
  async redeemVoucher(ctx) {
    try {
      const userId = ctx.state.user.id;

      if (!userId) {
        return ctx.unauthorized('Authentication required');
      }

      const { code } = ctx.request.body;

      if (!code) {
        return ctx.badRequest(utils.errorResponse('WALLET_ERROR', 'Voucher code required'));
      }

      // Get request metadata
      const metadata = utils.getRequestMetadata(ctx);

      // Redeem voucher
      const transaction = await walletService.redeemVoucher({
        userId,
        code: code.toUpperCase(),
        ...metadata,
      });

      ctx.send(utils.successResponse({
        transactionId: transaction.id,
        voucherCode: code,
        amount: parseFloat(transaction.amount),
        balanceBefore: parseFloat(transaction.balance_before),
        balanceAfter: parseFloat(transaction.balance_after),
        description: transaction.description,
        createdAt: transaction.created_at,
      }));
    } catch (error) {
      strapi.log.error('[Wallet] redeemVoucher error:', error);

      if (error.message === 'WALLET_007') {
        return ctx.badRequest(utils.errorResponse('WALLET_007', 'Voucher expired or invalid'));
      }
      if (error.message === 'WALLET_008') {
        return ctx.badRequest(utils.errorResponse('WALLET_008', 'Voucher limit reached'));
      }

      ctx.badRequest(utils.errorResponse('WALLET_ERROR', error.message));
    }
  },

  /**
   * POST /api/wallet/points/convert
   * Convert loyalty points to wallet credit
   */
  async convertPoints(ctx) {
    try {
      const userId = ctx.state.user.id;

      if (!userId) {
        return ctx.unauthorized('Authentication required');
      }

      const { points } = ctx.request.body;

      if (!points || points <= 0) {
        return ctx.badRequest(utils.errorResponse('WALLET_ERROR', 'Invalid points amount'));
      }

      // Conversion rate: 10 points = 1 THB (configurable)
      const conversionRate = 10;
      const walletCredit = points / conversionRate;

      // Check if user has enough points
      const userPoints = await strapi.connections.default.raw(`
        SELECT SUM(point) as total_points
        FROM point_log
        WHERE user_id = ?
      `, [userId]);

      const totalPoints = userPoints[0][0]?.total_points || 0;

      if (totalPoints < points) {
        return ctx.badRequest(utils.errorResponse('WALLET_ERROR', 'Insufficient points'));
      }

      // Get request metadata
      const metadata = utils.getRequestMetadata(ctx);

      // Create conversion transaction
      const transaction = await walletService.createTransaction({
        userId,
        type: 'conversion',
        amount: walletCredit,
        description: `Converted ${points} points to wallet credit`,
        metadata: {
          pointsConverted: points,
          conversionRate,
        },
        ...metadata,
      });

      // Deduct points from user
      await strapi.connections.default.raw(`
        INSERT INTO point_log (user_id, point, description, created_at)
        VALUES (?, ?, ?, NOW())
      `, [userId, -points, `Converted to wallet credit (${walletCredit} THB)`]);

      const pointsRemaining = totalPoints - points;

      // Send push notification for points conversion
      try {
        await sendPushNotification({
          content: `${points} points converted to ฿${walletCredit.toFixed(2)} wallet credit`,
          heading: 'Points Redeemed',
          external_ids: [userId.toString()],
          additionalData: {
            type: 'wallet_points_conversion',
            transactionId: transaction.id,
            pointsConverted: points,
            conversionRate,
            walletCredit,
            pointsRemaining,
            balanceAfter: parseFloat(transaction.balance_after),
            timestamp: new Date().toISOString(),
          },
        });

        strapi.log.info('[Wallet] Push notification sent for points conversion:', transaction.id);
      } catch (notificationError) {
        // Don't fail the conversion if notification fails
        strapi.log.error('[Wallet] Failed to send push notification:', notificationError);
      }

      ctx.send(utils.successResponse({
        transactionId: transaction.id,
        pointsConverted: points,
        conversionRate,
        walletCredit,
        pointsRemaining,
        balanceBefore: parseFloat(transaction.balance_before),
        balanceAfter: parseFloat(transaction.balance_after),
        createdAt: transaction.created_at,
      }));
    } catch (error) {
      strapi.log.error('[Wallet] convertPoints error:', error);
      ctx.badRequest(utils.errorResponse('WALLET_ERROR', error.message));
    }
  },

  /**
   * GET /api/wallet/settings
   * Get public wallet settings (for application use)
   * Returns only public-facing settings like fees, limits, and conversion rates
   */
  async getSettings(ctx) {
    try {
      // Get settings from database
      const settingsRows = await strapi.connections.default.raw(`
        SELECT setting_key, setting_value
        FROM wallet_transfer_settings
      `);

      const settings = {};
      if (settingsRows && settingsRows[0]) {
        settingsRows[0].forEach(row => {
          settings[row.setting_key] = row.setting_value;
        });
      }

      // Return public-facing settings
      ctx.send(utils.successResponse({
        pointConversion: {
          rate: parseFloat(settings.point_conversion_rate || 1),
          minimumRedemption: parseInt(settings.point_min_redemption || 100),
          requiresApproval: settings.point_redemption_requires_approval === 'true',
        },
        transfer: {
          feePercentage: parseFloat(settings.transfer_fee_percentage || 0),
          feeFixed: parseFloat(settings.transfer_fee_fixed || 0),
          minAmount: parseFloat(settings.transfer_min_amount || 1),
          maxAmount: parseFloat(settings.transfer_max_amount || 50000),
          dailyLimit: parseFloat(settings.transfer_daily_limit || 100000),
        },
        billboard: {
          enabled: settings.wallet_billboard_enabled === 'true',
          images: settings.wallet_billboard_images
            ? JSON.parse(settings.wallet_billboard_images)
            : [],
          autoPlayInterval: parseInt(settings.wallet_billboard_autoplay_interval || 5000),
        },
      }));
    } catch (error) {
      strapi.log.error('[Wallet] getSettings error:', error);
      ctx.badRequest(utils.errorResponse('WALLET_ERROR', 'Failed to load wallet settings'));
    }
  },
};
