'use strict';

const pinService = require('../services/pin');

/**
 * PIN Controller
 * Handles wallet PIN reset functionality
 */

module.exports = {
  /**
   * POST /api/wallet/pin/request-reset-otp
   * Request OTP for PIN reset
   *
   * Body: {
   *   method: 'phone' | 'email'
   * }
   */
  async requestResetOTP(ctx) {
    try {
      const userId = ctx.state.user?.id;

      if (!userId) {
        return ctx.unauthorized('Authentication required');
      }

      const { method } = ctx.request.body;

      if (!method) {
        return ctx.badRequest('Method is required (phone or email)');
      }

      if (method !== 'phone' && method !== 'email') {
        return ctx.badRequest('Invalid method. Use "phone" or "email"');
      }

      strapi.log.info(`[PIN Reset] OTP request from user ${userId} via ${method}`);

      const result = await pinService.requestPinResetOTP(userId, method);

      if (!result.success) {
        return ctx.badRequest(result.message);
      }

      ctx.send({
        success: true,
        maskedContact: result.maskedContact,
        message: result.message,
      });
    } catch (error) {
      strapi.log.error('[PIN Reset] requestResetOTP error:', error);
      ctx.badRequest('An error occurred while requesting OTP');
    }
  },

  /**
   * POST /api/wallet/pin/verify-reset-otp
   * Verify OTP and get reset token
   *
   * Body: {
   *   otp: '123456',
   *   method: 'phone' | 'email'
   * }
   */
  async verifyResetOTP(ctx) {
    try {
      const userId = ctx.state.user?.id;

      if (!userId) {
        return ctx.unauthorized('Authentication required');
      }

      const { otp, method } = ctx.request.body;

      if (!otp || !method) {
        return ctx.badRequest('OTP and method are required');
      }

      if (method !== 'phone' && method !== 'email') {
        return ctx.badRequest('Invalid method. Use "phone" or "email"');
      }

      strapi.log.info(`[PIN Reset] OTP verification from user ${userId} via ${method}`);

      const result = await pinService.verifyPinResetOTP(userId, otp, method);

      if (!result.success) {
        return ctx.badRequest(result.message);
      }

      ctx.send({
        success: true,
        resetToken: result.resetToken,
        message: result.message,
      });
    } catch (error) {
      strapi.log.error('[PIN Reset] verifyResetOTP error:', error);
      ctx.badRequest('An error occurred while verifying OTP');
    }
  },

  /**
   * POST /api/wallet/pin/reset-with-token
   * Reset PIN using verified token
   *
   * Body: {
   *   resetToken: 'abc123...',
   *   newPin: '123456'
   * }
   */
  async resetWithToken(ctx) {
    try {
      const userId = ctx.state.user?.id;

      if (!userId) {
        return ctx.unauthorized('Authentication required');
      }

      const { resetToken, newPin } = ctx.request.body;

      if (!resetToken || !newPin) {
        return ctx.badRequest('Reset token and new PIN are required');
      }

      // Validate PIN format
      if (!/^\d{6}$/.test(newPin)) {
        return ctx.badRequest('PIN must be exactly 6 digits');
      }

      strapi.log.info(`[PIN Reset] PIN reset request from user ${userId}`);

      const result = await pinService.resetPinWithToken(resetToken, newPin);

      if (!result.success) {
        return ctx.badRequest(result.message);
      }

      ctx.send({
        success: true,
        message: result.message,
      });
    } catch (error) {
      strapi.log.error('[PIN Reset] resetWithToken error:', error);
      ctx.badRequest('An error occurred while resetting PIN');
    }
  },

  /**
   * POST /wallet/sms/webhook
   * ThaiBulkSMS webhook for SMS delivery status
   *
   * ThaiBulkSMS will POST to this endpoint with delivery status:
   * {
   *   status: 'success' | 'fail',
   *   msisdn: '0812345678',
   *   message_id: '123456',
   *   ...other params
   * }
   */
  async smsWebhook(ctx) {
    try {
      const body = ctx.request.body;

      strapi.log.info('[ThaiBulkSMS Webhook] Received delivery status:', {
        status: body.status,
        msisdn: body.msisdn,
        message_id: body.message_id,
        timestamp: new Date().toISOString(),
      });

      // Log full webhook data for debugging
      strapi.log.debug('[ThaiBulkSMS Webhook] Full payload:', body);

      // You can add additional logic here to:
      // - Track SMS delivery success/failure rates
      // - Store delivery status in database
      // - Send notifications on delivery failures
      // - Update user records

      // Always return success to ThaiBulkSMS
      ctx.send({
        success: true,
        message: 'Webhook received',
      });
    } catch (error) {
      strapi.log.error('[ThaiBulkSMS Webhook] Error processing webhook:', error);

      // Still return success to avoid retries
      ctx.send({
        success: true,
        message: 'Webhook received with errors',
      });
    }
  },
};