'use strict';

/**
 * Payment Service
 * Handles Omise payment integration for wallet top-ups
 */

const { sendPushNotification } = require('../../helpers');
const notificationService = require('./notification');

// Create TWO Omise clients according to best practices:
// 1. Public key client for creating sources (PromptPay, Mobile Banking)
// 2. Secret key client for creating charges and other sensitive operations
const omisePublic = require('omise')({
  publicKey: process.env.OMISE_PUBLIC_KEY,
  omiseVersion: '2019-05-29',
});

const omise = require('omise')({
  secretKey: process.env.OMISE_SECRET_KEY,
  omiseVersion: '2019-05-29',
});

module.exports = {
  /**
   * Create a payment source for mobile banking
   * Supports: mobile_banking_kbank, mobile_banking_scb, mobile_banking_bay, etc.
   * Uses PUBLIC KEY as per Omise best practices
   */
  async createMobileBankingSource(amount, currency, type, returnUri, platformType) {
    try {
      // Build source creation params
      const sourceParams = {
        type: type, // e.g., 'mobile_banking_kbank', 'mobile_banking_scb'
        amount: Math.round(amount * 100), // Convert to smallest currency unit (satang)
        currency: currency || 'THB',
        phone_number: undefined, // Optional: can be provided
        return_uri: returnUri, // Deep link to return to the app
      };

      // Add platform_type if provided (IOS or ANDROID)
      // This helps Omise optimize the banking app redirection
      if (platformType) {
        sourceParams.platform_type = platformType;
      }

      strapi.log.info('[Payment] Creating mobile banking source with params:', {
        type: sourceParams.type,
        amount: sourceParams.amount,
        platform_type: sourceParams.platform_type,
      });

      // Use PUBLIC KEY client for source creation (per Omise documentation)
      const source = await omisePublic.sources.create(sourceParams);

      strapi.log.info('[Payment] Created mobile banking source:', {
        id: source.id,
        type: source.type,
        amount: source.amount,
      });

      return source;
    } catch (error) {
      strapi.log.error('[Payment] createMobileBankingSource error:', error);
      throw new Error(error.message || 'Failed to create payment source');
    }
  },

  /**
   * Create a PromptPay QR payment source
   * Uses PUBLIC KEY as per Omise best practices
   */
  async createPromptPaySource(amount, currency) {
    try {
      strapi.log.info('[Payment] Creating PromptPay source with PUBLIC KEY:', {
        publicKey: process.env.OMISE_PUBLIC_KEY ? `${process.env.OMISE_PUBLIC_KEY.substring(0, 15)}...` : 'NOT SET',
        amount: Math.round(amount * 100),
        currency: currency || 'THB',
      });

      // Use PUBLIC KEY client for source creation (per Omise documentation)
      const source = await omisePublic.sources.create({
        type: 'promptpay',
        amount: Math.round(amount * 100),
        currency: currency || 'THB',
      });

      strapi.log.info('[Payment] Created PromptPay source:', {
        id: source.id,
        amount: source.amount,
      });

      return source;
    } catch (error) {
      strapi.log.error('[Payment] createPromptPaySource error:', error);
      throw new Error(error.message || 'Failed to create PromptPay source');
    }
  },

  /**
   * Create a charge from a token (Credit/Debit Card)
   */
  async createChargeFromToken(tokenId, amount, currency, description, metadata = {}) {
    try {
      const charge = await omise.charges.create({
        amount: Math.round(amount * 100),
        currency: currency || 'THB',
        card: tokenId,
        description: description,
        metadata: metadata,
        capture: true, // Auto-capture the charge
      });

      strapi.log.info('[Payment] Created charge from token:', {
        id: charge.id,
        amount: charge.amount,
        status: charge.status,
        card: charge.card?.last_digits,
      });

      return charge;
    } catch (error) {
      strapi.log.error('[Payment] createChargeFromToken error:', error);
      throw new Error(error.message || 'Failed to create charge from token');
    }
  },

  /**
   * Create a charge from a source (Mobile Banking, PromptPay)
   */
  async createCharge(sourceId, amount, currency, description, metadata = {}) {
    try {
      // Build charge parameters
      const chargeParams = {
        amount: Math.round(amount * 100),
        currency: currency || 'THB',
        source: sourceId,
        description: description,
        metadata: metadata,
      };

      // Only add return_uri for online payment methods (mobile banking)
      // PromptPay is offline (QR code) and doesn't need return_uri
      if (metadata.return_uri && metadata.payment_method !== 'promptpay') {
        chargeParams.return_uri = metadata.return_uri;
      }

      const charge = await omise.charges.create(chargeParams);

      strapi.log.info('[Payment] Created charge:', {
        id: charge.id,
        amount: charge.amount,
        status: charge.status,
        source: sourceId,
        hasReturnUri: !!chargeParams.return_uri,
      });

      return charge;
    } catch (error) {
      strapi.log.error('[Payment] createCharge error:', error);
      throw new Error(error.message || 'Failed to create charge');
    }
  },

  /**
   * Get charge status
   */
  async getChargeStatus(chargeId) {
    try {
      const charge = await omise.charges.retrieve(chargeId);

      strapi.log.info('[Payment] Retrieved charge status:', {
        id: charge.id,
        status: charge.status,
        paid: charge.paid,
      });

      return charge;
    } catch (error) {
      strapi.log.error('[Payment] getChargeStatus error:', error);
      throw new Error(error.message || 'Failed to retrieve charge');
    }
  },

  /**
   * Process successful payment and credit wallet
   */
  async processSuccessfulPayment(chargeId, userId) {
    try {
      const charge = await this.getChargeStatus(chargeId);

      if (!charge.paid) {
        throw new Error('Charge is not paid');
      }

      const amount = charge.amount / 100; // Convert back to main currency unit

      // Create wallet transaction
      const knex = strapi.connections.default;
      const transactionId = `topup_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

      await knex.transaction(async (trx) => {
        // Get current balance
        const wallet = await trx('wallets')
          .where({ user_id: userId })
          .first();

        const balanceBefore = parseFloat(wallet.balance);
        const balanceAfter = balanceBefore + amount;

        // Credit wallet
        await trx('wallets')
          .where({ user_id: userId })
          .update({
            balance: balanceAfter,
            updated_at: knex.fn.now()
          });

        // Record transaction
        await trx('wallet_transactions').insert({
          id: transactionId,
          user_id: userId,
          type: 'top_up',
          amount: amount,
          balance_before: balanceBefore,
          balance_after: balanceAfter,
          status: 'completed',
          payment_method: charge.source?.type || 'credit_card',
          description: `Wallet top-up via ${charge.source?.type || 'credit card'}`,
          metadata: JSON.stringify({
            charge_id: chargeId,
            source_type: charge.source?.type,
            payment_method: charge.source?.type || 'credit_card',
          }),
        });

        strapi.log.info('[Payment] Wallet credited successfully:', {
          userId,
          amount,
          chargeId,
          transactionId,
        });
      });

      // Send push notification for successful top-up
      try {
        const paymentMethod = charge.source?.type || 'credit_card';
        await notificationService.sendTopUpSuccessNotification(
          userId,
          amount,
          paymentMethod,
          chargeId
        );
        strapi.log.info('[Payment] OneSignal notification sent for top-up:', userId);
      } catch (notificationError) {
        // Don't fail the payment if notification fails
        strapi.log.error('[Payment] Failed to send OneSignal notification:', notificationError);
      }

      return {
        success: true,
        transactionId,
        amount,
        chargeId,
      };
    } catch (error) {
      strapi.log.error('[Payment] processSuccessfulPayment error:', error);
      throw error;
    }
  },

  /**
   * Verify webhook authenticity using IP whitelisting
   * Omise doesn't use HMAC signatures, so we verify by checking source IP
   *
   * @param {string} sourceIp - IP address from which the webhook was sent
   * @returns {boolean} - true if IP is from Omise, false otherwise
   */
  verifyWebhookSource(sourceIp) {
    // Omise webhook IP addresses (as of 2024)
    // These should be updated if Omise changes their infrastructure
    // Source: https://docs.opn.ooo/security-best-practices#webhook-security
    const OMISE_WEBHOOK_IPS = [
      '52.77.251.16',    // Singapore datacenter
      '52.77.251.52',    // Singapore datacenter
      '52.77.251.97',    // Singapore datacenter
      '54.254.229.219',  // Singapore datacenter
      '54.254.229.250',  // Singapore datacenter
    ];

    // Only allow localhost in development environment
    if (process.env.NODE_ENV === 'development' || strapi.config.environment === 'development') {
      OMISE_WEBHOOK_IPS.push('127.0.0.1', '::1');
    }

    if (!sourceIp) {
      strapi.log.warn('[Payment] Webhook source IP not provided');
      return false;
    }

    // Extract IP from X-Forwarded-For if behind proxy (Cloudflare, AWS ALB, etc.)
    let ip = sourceIp;
    if (ip.includes(',')) {
      ip = ip.split(',')[0].trim();
    }
    // Remove IPv6 prefix if present (::ffff:xxx.xxx.xxx.xxx)
    if (ip.startsWith('::ffff:')) {
      ip = ip.substring(7);
    }

    const isAllowed = OMISE_WEBHOOK_IPS.includes(ip);

    if (!isAllowed) {
      strapi.log.warn('[Payment] Webhook from unauthorized IP:', {
        sourceIp: ip,
        allowedIps: OMISE_WEBHOOK_IPS,
      });
    }

    return isAllowed;
  },

  /**
   * Get supported payment methods
   */
  async getSupportedPaymentMethods() {
    return {
      credit_card: {
        id: 'credit_card',
        name: 'Credit/Debit Card',
        icon: 'credit_card',
        supportedBrands: ['Visa', 'MasterCard', 'JCB'],
      },
      mobile_banking: [
        {
          id: 'mobile_banking_kbank',
          name: 'K PLUS',
          bank: 'Kasikorn Bank',
          icon: 'kbank',
        },
        {
          id: 'mobile_banking_scb',
          name: 'SCB Easy',
          bank: 'Siam Commercial Bank',
          icon: 'scb',
        },
        {
          id: 'mobile_banking_bay',
          name: 'KMA',
          bank: 'Bank of Ayudhya (Krungsri)',
          icon: 'bay',
        },
        {
          id: 'mobile_banking_bbl',
          name: 'Bualuang mBanking',
          bank: 'Bangkok Bank',
          icon: 'bbl',
        },
      ],
      promptpay: {
        id: 'promptpay',
        name: 'PromptPay QR',
        icon: 'promptpay',
      },
    };
  },
};
