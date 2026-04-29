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
   * Create a card token using Omise SDK
   * Card data is sent to Omise to create a secure token
   * Uses PUBLIC KEY for token creation
   */
  async createCardToken({ cardNumber, cardHolderName, expirationMonth, expirationYear, securityCode }) {
    try {
      strapi.log.info('[Payment] Creating card token using Omise SDK');

      // Use PUBLIC KEY client for token creation (per Omise documentation)
      const token = await omisePublic.tokens.create({
        card: {
          name: cardHolderName,
          number: cardNumber,
          expiration_month: expirationMonth,
          expiration_year: expirationYear,
          security_code: securityCode,
        },
      });

      strapi.log.info('[Payment] Created card token:', {
        id: token.id,
        card_last_digits: token.card?.last_digits,
      });

      return token;
    } catch (error) {
      strapi.log.error('[Payment] createCardToken error:', error);
      throw new Error(error.message || 'Failed to create card token');
    }
  },

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
  async createChargeFromToken(tokenId, amount, currency, description, metadata = {}, returnUri) {
    try {
      const chargeParams = {
        amount: Math.round(amount * 100),
        currency: currency || 'THB',
        card: tokenId,
        description: description,
        metadata: metadata,
        capture: true, // Auto-capture the charge
      };

      // Add return_uri for 3D Secure authentication redirect
      if (returnUri) {
        chargeParams.return_uri = returnUri;
      }

      const charge = await omise.charges.create(chargeParams);

      strapi.log.info('[Payment] Created charge from token:', {
        id: charge.id,
        amount: charge.amount,
        status: charge.status,
        paid: charge.paid,
        card: charge.card?.last_digits,
        authorize_uri: charge.authorize_uri || null,
        failure_code: charge.failure_code,
        failure_message: charge.failure_message,
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
   * Update charge with return_uri (for 3D Secure)
   * Required because we need the charge ID to construct proper return_uri
   */
  async updateChargeReturnUri(chargeId, returnUri) {
    try {
      strapi.log.info('[Payment] Updating charge return_uri:', {
        chargeId,
        returnUri,
      });

      const charge = await omise.charges.update(chargeId, {
        return_uri: returnUri,
      });

      strapi.log.info('[Payment] Charge updated with return_uri:', {
        id: charge.id,
        authorize_uri: charge.authorize_uri ? 'present' : 'none',
      });

      return charge;
    } catch (error) {
      strapi.log.error('[Payment] updateChargeReturnUri error:', error);
      throw new Error(error.message || 'Failed to update charge');
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

      // Fire-and-forget the push notification so the webhook can return promptly.
      // Omise retries webhooks after ~30s and Cloudflare cuts off around 100s — we
      // must not let a slow OneSignal call delay the 200 response.
      const paymentMethod = charge.source?.type || 'credit_card';
      notificationService
        .sendTopUpSuccessNotification(userId, amount, paymentMethod, chargeId)
        .then(() => {
          strapi.log.info('[Payment] OneSignal notification sent for top-up:', userId);
        })
        .catch((notificationError) => {
          strapi.log.error('[Payment] Failed to send OneSignal notification:', notificationError);
        });

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
   * Verify webhook authenticity using HMAC signature verification
   * This is the industry-standard secure method for webhook verification
   *
   * @param {string} signature - Signature from Omise-Signature header
   * @param {string} timestamp - Timestamp from Omise-Signature-Timestamp header
   * @param {string} rawBody - Raw request body (must be unmodified)
   * @returns {boolean} - true if signature is valid, false otherwise
   */
  verifyWebhookSignature(signature, timestamp, rawBody) {
    const crypto = require('crypto');

    // Get webhook secret from environment
    const webhookSecret = process.env.OMISE_WEBHOOK_SECRET;

    if (!webhookSecret) {
      strapi.log.error('[Payment] OMISE_WEBHOOK_SECRET not configured');
      return false;
    }

    if (!signature || !timestamp || !rawBody) {
      strapi.log.warn('[Payment] Missing required webhook verification parameters');
      return false;
    }

    // Verify timestamp to prevent replay attacks (allow 5-minute window)
    const currentTime = Math.floor(Date.now() / 1000);
    const timestampAge = currentTime - parseInt(timestamp);

    if (timestampAge > 300) { // 5 minutes
      strapi.log.warn('[Payment] Webhook timestamp too old:', {
        age: timestampAge,
        maxAge: 300,
      });
      return false;
    }

    // Construct the signed payload: timestamp.rawBody
    const signedPayload = `${timestamp}.${rawBody}`;

    // Compute HMAC-SHA256 signature
    const expectedSignature = crypto
      .createHmac('sha256', webhookSecret)
      .update(signedPayload, 'utf8')
      .digest('hex');

    // Handle multiple signatures (during secret rotation)
    // Signature header format: "v1=signature1,v1=signature2"
    const signatures = signature.split(',').map(sig => {
      const parts = sig.trim().split('=');
      return parts.length === 2 ? parts[1] : sig.trim();
    });

    // Use constant-time comparison to prevent timing attacks
    let isValid = false;
    for (const sig of signatures) {
      try {
        // crypto.timingSafeEqual requires buffers of same length
        if (sig.length === expectedSignature.length) {
          const sigBuffer = Buffer.from(sig, 'utf8');
          const expectedBuffer = Buffer.from(expectedSignature, 'utf8');

          if (crypto.timingSafeEqual(sigBuffer, expectedBuffer)) {
            isValid = true;
            break;
          }
        }
      } catch (err) {
        // Continue checking other signatures
        continue;
      }
    }

    if (!isValid) {
      strapi.log.warn('[Payment] Invalid webhook signature');
    }

    return isValid;
  },

  /**
   * Get supported payment methods and Omise public key
   */
  async getSupportedPaymentMethods() {
    return {
      omisePublicKey: process.env.OMISE_PUBLIC_KEY,
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
