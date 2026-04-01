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
};