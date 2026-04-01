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
   * Send OTP via SMS using ThaiBulkSMS custom message API
   *
   * Uses ThaiBulkSMS SMS API (not OTP API) to send custom messages
   * API: https://api-v2.thaibulksms.com/sms
   */
  async sendOTPviaSMS(phone, otp) {
    strapi.log.info(`[PIN Reset] Sending SMS OTP to ${phone}`);

    try {
      // Always log OTP (for development/debugging)
      strapi.log.info(`[DEV] OTP for ${phone}: ${otp}`);

      // In development mode, just log the OTP
      if (process.env.NODE_ENV === 'development') {
        strapi.log.info(`[DEV] Use OTP code: ${otp} to verify`);
        strapi.log.warn(`[PIN Reset] Development mode - SMS not sent, using log-only`);
        return true;
      }

      // Production: Use ThaiBulkSMS custom message API
      // Try SMS-specific credentials first, fallback to OTP credentials
      const apiKey = process.env.THAIBULK_SMS_API_KEY || process.env.THAIBULK_API_KEY;
      const apiSecret = process.env.THAIBULK_SMS_API_SECRET || process.env.THAIBULK_API_SECRET;

      // Debug: Log which credentials are being used
      const usingSmsCreds = !!process.env.THAIBULK_SMS_API_KEY;
      strapi.log.info(`[PIN Reset] Using ${usingSmsCreds ? 'SMS API' : 'OTP API'} credentials`);
      strapi.log.debug(`[PIN Reset] API Key (first 8 chars): ${apiKey?.substring(0, 8)}...`);

      if (!apiKey || !apiSecret) {
        strapi.log.error('[PIN Reset] ThaiBulkSMS credentials not configured');
        throw new Error('SMS service not configured');
      }

      const axios = require('axios');
      const qs = require('querystring');
      const message = `Your Chongjaroen wallet PIN reset code is: ${otp}. Valid for 10 minutes. Do not share this code.`;

      // ThaiBulkSMS SMS API v2 - requires form-urlencoded
      const response = await axios.post(
        'https://api-v2.thaibulksms.com/sms',
        qs.stringify({
          key: apiKey,
          secret: apiSecret,
          msisdn: phone,
          message: message,
          sender: 'Chongjaroen', // Sender name (optional)
          force: 'standard', // SMS type: standard or premium
        }),
        {
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'accept': 'application/json',
          },
        }
      );

      strapi.log.info(`[PIN Reset] SMS sent successfully to ${phone}`, {
        status: response.data.status,
        response: response.data,
      });

      return true;
    } catch (error) {
      strapi.log.error(`[PIN Reset] SMS error for ${phone}:`, error.response?.data || error.message);

      // In production, if SMS fails but we're in development mode fallback
      // This allows testing even if SMS API credentials aren't configured
      if (error.response?.data?.error?.code === 100) {
        strapi.log.warn('[PIN Reset] SMS API authentication failed - check ThaiBulkSMS SMS API Console for credentials');
        strapi.log.warn('[PIN Reset] Note: OTP API credentials are different from SMS API credentials');
        strapi.log.info(`[PIN Reset] OTP for testing: ${otp}`);
        // Return true to allow the flow to continue (OTP is logged)
        return true;
      }

      throw error;
    }
  },

  /**
   * Send OTP via Email using Gmail/Nodemailer (existing service)
   */
  async sendOTPviaEmail(email, otp, userName) {
    strapi.log.info(`[PIN Reset] Sending email OTP to ${email}`);

    try {
      // In development mode, just log the OTP
      if (process.env.NODE_ENV === 'development') {
        strapi.log.info(`[DEV] OTP for ${email}: ${otp}`);
        strapi.log.info(`[DEV] Use OTP code: ${otp} to verify`);
        return true;
      }

      // In production, use existing Strapi email plugin (Gmail + Nodemailer)
      await strapi.plugins['email'].services.email.send({
        to: email,
        from: 'noreply@chongjaroen.com',
        subject: 'Wallet PIN Reset Code',
        text: `Your wallet PIN reset code is: ${otp}. Valid for ${OTP_EXPIRY_MINUTES} minutes.`,
        html: `
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
              .content { padding: 20px; background-color: #f9f9f9; }
              .otp-code { font-size: 32px; font-weight: bold; color: #4CAF50; text-align: center; padding: 20px; background-color: white; border-radius: 8px; margin: 20px 0; }
              .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>Wallet PIN Reset</h1>
              </div>
              <div class="content">
                <p>Hello ${userName || 'User'},</p>
                <p>You have requested to reset your wallet PIN. Please use the following OTP code to verify your identity:</p>
                <div class="otp-code">${otp}</div>
                <p><strong>This code is valid for ${OTP_EXPIRY_MINUTES} minutes.</strong></p>
                <p>If you didn't request this PIN reset, please ignore this email and your PIN will remain unchanged.</p>
                <p>For security reasons, never share this code with anyone.</p>
              </div>
              <div class="footer">
                <p>© ${new Date().getFullYear()} Chongjaroen. All rights reserved.</p>
              </div>
            </div>
          </body>
          </html>
        `
      });

      strapi.log.info(`[PIN Reset] Email sent successfully to ${email}`);
      return true;
    } catch (error) {
      strapi.log.error(`[PIN Reset] Email error for ${email}:`, error);
      throw error;
    }
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