'use strict';

const crypto = require('crypto');
const bcrypt = require('bcryptjs');

/**
 * PIN Service
 * Handles PIN reset OTP verification and reset functionality
 */

// In-memory OTP storage (in production, use Redis or database)
const otpStore = new Map();
const resetTokenStore = new Map();

// OTP configuration
const OTP_LENGTH = 6;
const OTP_EXPIRY_MINUTES = 10;
const RESET_TOKEN_EXPIRY_MINUTES = 15;

module.exports = {
  /**
   * Generate a random 6-digit OTP
   */
  generateOTP() {
    return Math.floor(100000 + Math.random() * 900000).toString();
  },

  /**
   * Generate a secure reset token
   */
  generateResetToken() {
    return crypto.randomBytes(32).toString('hex');
  },

  /**
   * Mask phone number for display
   * Example: 0812345678 -> 081****78
   */
  maskPhoneNumber(phone) {
    if (!phone || phone.length < 4) return phone;
    return `${phone.substring(0, 3)}****${phone.substring(phone.length - 2)}`;
  },

  /**
   * Mask email for display
   * Example: user@example.com -> us****@example.com
   */
  maskEmail(email) {
    if (!email) return email;
    const parts = email.split('@');
    if (parts.length !== 2) return email;

    const username = parts[0];
    const domain = parts[1];

    if (username.length <= 2) return email;

    return `${username.substring(0, 2)}****@${domain}`;
  },

  /**
   * Send OTP via SMS (placeholder - integrate with SMS provider)
   */
  async sendOTPviaSMS(phone, otp) {
    // TODO: Integrate with SMS provider (Twilio, AWS SNS, etc.)
    strapi.log.info(`[PIN Reset] SMS OTP to ${phone}: ${otp}`);

    // For development, log the OTP
    if (process.env.NODE_ENV === 'development') {
      strapi.log.info(`[DEV] OTP for ${phone}: ${otp}`);
    }

    // In production, send actual SMS
    // Example with Twilio:
    // const client = require('twilio')(accountSid, authToken);
    // await client.messages.create({
    //   body: `Your wallet PIN reset code is: ${otp}. Valid for ${OTP_EXPIRY_MINUTES} minutes.`,
    //   to: phone,
    //   from: twilioPhoneNumber
    // });

    return true;
  },

  /**
   * Send OTP via Email (placeholder - integrate with email provider)
   */
  async sendOTPviaEmail(email, otp, userName) {
    // TODO: Integrate with email provider (SendGrid, AWS SES, etc.)
    strapi.log.info(`[PIN Reset] Email OTP to ${email}: ${otp}`);

    // For development, log the OTP
    if (process.env.NODE_ENV === 'development') {
      strapi.log.info(`[DEV] OTP for ${email}: ${otp}`);
    }

    // In production, send actual email
    // Example with Strapi email plugin:
    // await strapi.plugins['email'].services.email.send({
    //   to: email,
    //   subject: 'Wallet PIN Reset Code',
    //   text: `Your wallet PIN reset code is: ${otp}. Valid for ${OTP_EXPIRY_MINUTES} minutes.`,
    //   html: `
    //     <h2>Wallet PIN Reset</h2>
    //     <p>Hello ${userName},</p>
    //     <p>Your wallet PIN reset code is: <strong>${otp}</strong></p>
    //     <p>This code is valid for ${OTP_EXPIRY_MINUTES} minutes.</p>
    //     <p>If you didn't request this, please ignore this email.</p>
    //   `
    // });

    return true;
  },

  /**
   * Store OTP with expiry
   */
  storeOTP(userId, method, otp) {
    const key = `${userId}:${method}`;
    const expiresAt = Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000;

    otpStore.set(key, {
      otp,
      expiresAt,
      attempts: 0,
    });

    strapi.log.info(`[PIN Reset] OTP stored for user ${userId} via ${method}, expires at ${new Date(expiresAt)}`);
  },

  /**
   * Verify OTP
   */
  verifyOTP(userId, method, otp) {
    const key = `${userId}:${method}`;
    const stored = otpStore.get(key);

    if (!stored) {
      return { valid: false, error: 'OTP not found or expired' };
    }

    // Check expiry
    if (Date.now() > stored.expiresAt) {
      otpStore.delete(key);
      return { valid: false, error: 'OTP expired' };
    }

    // Increment attempts
    stored.attempts += 1;

    // Check max attempts (5)
    if (stored.attempts > 5) {
      otpStore.delete(key);
      return { valid: false, error: 'Too many attempts' };
    }

    // Verify OTP
    if (stored.otp !== otp) {
      otpStore.set(key, stored);
      return { valid: false, error: 'Invalid OTP' };
    }

    // OTP is valid - clean up
    otpStore.delete(key);
    return { valid: true };
  },

  /**
   * Store reset token
   */
  storeResetToken(userId, token) {
    const expiresAt = Date.now() + RESET_TOKEN_EXPIRY_MINUTES * 60 * 1000;

    resetTokenStore.set(token, {
      userId,
      expiresAt,
    });

    strapi.log.info(`[PIN Reset] Reset token stored for user ${userId}, expires at ${new Date(expiresAt)}`);
    return token;
  },

  /**
   * Verify reset token
   */
  verifyResetToken(token) {
    const stored = resetTokenStore.get(token);

    if (!stored) {
      return { valid: false, error: 'Invalid or expired reset token' };
    }

    // Check expiry
    if (Date.now() > stored.expiresAt) {
      resetTokenStore.delete(token);
      return { valid: false, error: 'Reset token expired' };
    }

    return { valid: true, userId: stored.userId };
  },

  /**
   * Invalidate reset token after use
   */
  invalidateResetToken(token) {
    resetTokenStore.delete(token);
    strapi.log.info(`[PIN Reset] Reset token invalidated`);
  },

  /**
   * Hash PIN for storage
   */
  async hashPin(pin) {
    const salt = await bcrypt.genSalt(10);
    return bcrypt.hash(pin, salt);
  },

  /**
   * Update user's wallet PIN
   */
  async updateUserPin(userId, newPin) {
    try {
      // Hash the new PIN
      const hashedPin = await this.hashPin(newPin);

      // Update user's wallet_pin field
      await strapi.query('user', 'users-permissions').update(
        { id: userId },
        { wallet_pin: hashedPin }
      );

      strapi.log.info(`[PIN Reset] PIN updated successfully for user ${userId}`);
      return { success: true };
    } catch (error) {
      strapi.log.error(`[PIN Reset] Failed to update PIN for user ${userId}:`, error);
      return { success: false, error: error.message };
    }
  },

  /**
   * Request PIN reset OTP
   */
  async requestPinResetOTP(userId, method) {
    try {
      // Get user details
      const user = await strapi.query('user', 'users-permissions').findOne({ id: userId });

      if (!user) {
        return { success: false, message: 'User not found' };
      }

      // Generate OTP
      const otp = this.generateOTP();

      // Store OTP
      this.storeOTP(userId, method, otp);

      // Send OTP based on method
      let maskedContact;
      if (method === 'phone') {
        await this.sendOTPviaSMS(user.phone, otp);
        maskedContact = this.maskPhoneNumber(user.phone);
      } else if (method === 'email') {
        await this.sendOTPviaEmail(user.email, otp, user.username);
        maskedContact = this.maskEmail(user.email);
      } else {
        return { success: false, message: 'Invalid method. Use "phone" or "email"' };
      }

      return {
        success: true,
        maskedContact,
        message: `OTP sent to your ${method}`,
      };
    } catch (error) {
      strapi.log.error('[PIN Reset] requestPinResetOTP error:', error);
      return { success: false, message: error.message };
    }
  },

  /**
   * Verify PIN reset OTP
   */
  async verifyPinResetOTP(userId, otp, method) {
    try {
      // Verify OTP
      const verification = this.verifyOTP(userId, method, otp);

      if (!verification.valid) {
        return { success: false, message: verification.error };
      }

      // Generate reset token
      const resetToken = this.generateResetToken();
      this.storeResetToken(userId, resetToken);

      return {
        success: true,
        resetToken,
        message: 'OTP verified successfully',
      };
    } catch (error) {
      strapi.log.error('[PIN Reset] verifyPinResetOTP error:', error);
      return { success: false, message: error.message };
    }
  },

  /**
   * Reset PIN with token
   */
  async resetPinWithToken(resetToken, newPin) {
    try {
      // Verify reset token
      const verification = this.verifyResetToken(resetToken);

      if (!verification.valid) {
        return { success: false, message: verification.error };
      }

      const userId = verification.userId;

      // Validate PIN format (6 digits)
      if (!/^\d{6}$/.test(newPin)) {
        return { success: false, message: 'PIN must be exactly 6 digits' };
      }

      // Update PIN
      const result = await this.updateUserPin(userId, newPin);

      if (!result.success) {
        return { success: false, message: 'Failed to update PIN' };
      }

      // Invalidate reset token
      this.invalidateResetToken(resetToken);

      return {
        success: true,
        message: 'PIN reset successfully',
      };
    } catch (error) {
      strapi.log.error('[PIN Reset] resetPinWithToken error:', error);
      return { success: false, message: error.message };
    }
  },
};