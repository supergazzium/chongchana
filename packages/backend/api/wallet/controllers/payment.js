'use strict';

const paymentService = require('../services/payment');
const utils = require('../services/utils');

/**
 * Payment Controller
 * Handles Omise payment operations for wallet top-ups
 */

module.exports = {
  /**
   * GET /api/wallet/payment/methods
   * Get supported payment methods
   */
  async getPaymentMethods(ctx) {
    try {
      const methods = await paymentService.getSupportedPaymentMethods();
      ctx.send(utils.successResponse(methods));
    } catch (error) {
      strapi.log.error('[Payment] getPaymentMethods error:', error);
      ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', error.message));
    }
  },

  /**
   * POST /api/wallet/payment/create-token
   * Create a card token using server-side Omise SDK
   * NOTE: Server must be PCI-DSS compliant to handle raw card data
   */
  async createToken(ctx) {
    try {
      const { cardNumber, cardHolderName, expirationMonth, expirationYear, securityCode } = ctx.request.body;

      if (!cardNumber || !cardHolderName || !expirationMonth || !expirationYear || !securityCode) {
        return ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', 'All card fields are required'));
      }

      strapi.log.info('[Payment] Creating token for card ending in:', cardNumber.slice(-4));

      // Create token using Omise SDK
      const token = await paymentService.createCardToken({
        cardNumber,
        cardHolderName,
        expirationMonth,
        expirationYear,
        securityCode,
      });

      ctx.send(utils.successResponse({
        success: true,
        tokenId: token.id,
      }));
    } catch (error) {
      strapi.log.error('[Payment] createToken error:', error);
      ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', error.message));
    }
  },

  /**
   * POST /api/wallet/payment/create-charge
   * Create a charge from a token (Credit/Debit Card)
   */
  async createChargeFromToken(ctx) {
    try {
      const userId = ctx.state.user.id;

      if (!userId) {
        return ctx.unauthorized('Authentication required');
      }

      const { tokenId, amount, currency = 'THB' } = ctx.request.body;

      if (!tokenId || !amount) {
        return ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', 'Token ID and amount are required'));
      }

      // Validate amount
      const validation = utils.validateAmount(amount, 'top_up');
      if (!validation.valid) {
        return ctx.badRequest(utils.errorResponse('WALLET_004', validation.error));
      }

      // Create charge with return_uri that includes charge_id in query parameter
      // We'll use a temporary token approach - store charge in metadata
      const baseUrl = process.env.PUBLIC_URL || 'https://wallet-backend-test-pc-ndd56.ondigitalocean.app';

      // First create charge without return_uri to get the charge ID
      let charge = await paymentService.createChargeFromToken(
        tokenId,
        amount,
        currency,
        `Wallet top-up - User ${userId}`,
        {
          user_id: userId,
          type: 'wallet_topup',
        }
      );

      // If charge requires 3DS (has authorize_uri), update it with proper return_uri
      if (charge.authorize_uri && charge.status === 'pending') {
        const returnUri = `${baseUrl}/wallet/payment/3ds-return?charge_id=${charge.id}`;

        strapi.log.info('[Payment] Updating charge with return_uri for 3DS:', {
          chargeId: charge.id,
          returnUri: returnUri,
        });

        try {
          // Update the charge with return_uri containing the charge_id
          charge = await paymentService.updateChargeReturnUri(charge.id, returnUri);
        } catch (error) {
          strapi.log.error('[Payment] Failed to update return_uri, continuing anyway:', error);
        }
      }

      // If charge is successful, credit wallet immediately
      if (charge.paid) {
        const result = await paymentService.processSuccessfulPayment(charge.id, userId);

        ctx.send(utils.successResponse({
          success: true,
          chargeId: charge.id,
          transactionId: result.transactionId,
          amount: amount,
          status: 'completed',
          paid: true,
        }));
      } else {
        // Charge pending or failed
        ctx.send(utils.successResponse({
          success: charge.status === 'successful' || charge.status === 'pending',
          chargeId: charge.id,
          amount: amount,
          status: charge.status,
          paid: false,
          failureMessage: charge.failure_message,
          authorizeUri: charge.authorize_uri, // 3D Secure authentication URL
        }));
      }
    } catch (error) {
      strapi.log.error('[Payment] createChargeFromToken error:', error);
      ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', error.message));
    }
  },

  /**
   * POST /api/wallet/payment/create-source
   * Create a payment source (Mobile Banking, PromptPay)
   */
  async createPaymentSource(ctx) {
    const { amount, currency = 'THB', paymentMethod, returnUri, platformType } = ctx.request.body;

    try {
      const userId = ctx.state.user.id;

      if (!userId) {
        return ctx.unauthorized('Authentication required');
      }

      if (!amount || !paymentMethod) {
        return ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', 'Amount and payment method are required'));
      }

      // Validate amount
      const validation = utils.validateAmount(amount, 'top_up');
      if (!validation.valid) {
        return ctx.badRequest(utils.errorResponse('WALLET_004', validation.error));
      }

      let source;
      let charge;

      // Create source based on payment method
      if (paymentMethod.startsWith('mobile_banking_')) {
        source = await paymentService.createMobileBankingSource(
          amount,
          currency,
          paymentMethod,
          returnUri || `chongjaroen://payment-result`,
          platformType  // Pass platform type to Omise (IOS or ANDROID)
        );
      } else if (paymentMethod === 'promptpay') {
        source = await paymentService.createPromptPaySource(amount, currency);
      } else {
        return ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', 'Invalid payment method'));
      }

      // Create charge from source
      charge = await paymentService.createCharge(
        source.id,
        amount,
        currency,
        `Wallet top-up - User ${userId}`,
        {
          user_id: userId,
          type: 'wallet_topup',
          payment_method: paymentMethod,
          return_uri: returnUri || `chongjaroen://payment-result`,
        }
      );

      // According to Omise documentation, scannable_code is available on charge.source after creating the charge
      // The source object must be retrieved from the charge to get the QR code
      const scannableCode = charge.source?.scannable_code || null;

      strapi.log.info('[Payment] Charge created with source:', {
        chargeId: charge.id,
        sourceId: charge.source?.id,
        hasScannableCode: !!scannableCode,
        scannableCodeType: scannableCode?.type,
      });

      // Do not log scannable_code data - contains sensitive QR payment information

      ctx.send(utils.successResponse({
        success: true,
        chargeId: charge.id,
        sourceId: charge.source?.id || source.id,
        amount: amount,
        status: charge.status,
        authorizeUri: charge.authorize_uri,
        scannableCode: scannableCode, // For PromptPay QR (from charge.source, not source)
        expiresAt: charge.source?.expires_at || source.expires_at,
      }));
    } catch (error) {
      strapi.log.error('[Payment] createPaymentSource error:', error);

      // Check if this is a KTB-specific error (requires account activation)
      if (paymentMethod === 'mobile_banking_ktb' && error.message &&
          (error.message.includes('not enabled') || error.message.includes('not supported') || error.message.includes('not valid') || error.message.includes('invalid'))) {
        return ctx.badRequest(utils.errorResponse('PAYMENT_ERROR',
          'Krungthai NEXT is not enabled for this account. Please contact Omise support at support@omise.co to activate this payment method.'));
      }

      ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', error.message));
    }
  },

  /**
   * GET /api/wallet/payment/status/:chargeId
   * Check payment status
   */
  async checkPaymentStatus(ctx) {
    try {
      const userId = ctx.state.user.id;

      if (!userId) {
        return ctx.unauthorized('Authentication required');
      }

      const { chargeId } = ctx.params;

      if (!chargeId) {
        return ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', 'Charge ID is required'));
      }

      const charge = await paymentService.getChargeStatus(chargeId);

      // If payment is successful and not yet processed, credit wallet
      if (charge.paid && charge.metadata?.user_id == userId) {
        // Check if already processed
        const knex = strapi.connections.default;
        const existing = await knex('wallet_transactions')
          .whereRaw("JSON_EXTRACT(metadata, '$.charge_id') = ?", [chargeId])
          .first();

        if (!existing) {
          await paymentService.processSuccessfulPayment(chargeId, userId);
        }
      }

      ctx.send(utils.successResponse({
        chargeId: charge.id,
        status: charge.status,
        paid: charge.paid,
        amount: charge.amount / 100,
        currency: charge.currency,
        failureMessage: charge.failure_message,
        paidAt: charge.paid_at,
      }));
    } catch (error) {
      strapi.log.error('[Payment] checkPaymentStatus error:', error);
      ctx.badRequest(utils.errorResponse('PAYMENT_ERROR', error.message));
    }
  },

  /**
   * GET /api/wallet/payment/3ds-return
   * Handle 3D Secure return redirect
   * User is redirected here after completing 3DS authentication at their bank
   */
  async handle3DSReturn(ctx) {
    try {
      // Omise sends the charge ID in various ways - check all possibilities
      // Examples: ?charge_id=chrg_xxx or ?id=chrg_xxx or in path
      const chargeId = ctx.query.charge_id || ctx.query.chargeId || ctx.query.id;

      strapi.log.info('[Payment] 3DS return received:', {
        query: ctx.query,
        chargeId: chargeId,
      });

      if (!chargeId) {
        strapi.log.warn('[Payment] 3DS return: No charge ID found in query');
        // Redirect to app with unknown status
        ctx.redirect('chongjaroen://payment-result?status=unknown');
        return;
      }

      strapi.log.info('[Payment] 3DS return processing charge:', chargeId);

      // Get the charge status
      const charge = await paymentService.getChargeStatus(chargeId);

      // If payment is successful and not yet processed, credit wallet
      if (charge.paid && charge.metadata?.user_id) {
        const userId = parseInt(charge.metadata.user_id);

        // Check if already processed
        const knex = strapi.connections.default;
        const existing = await knex('wallet_transactions')
          .whereRaw("JSON_EXTRACT(metadata, '$.charge_id') = ?", [chargeId])
          .first();

        if (!existing) {
          await paymentService.processSuccessfulPayment(chargeId, userId);
          strapi.log.info('[Payment] 3DS payment processed successfully for user:', userId);
        }

        // Redirect to app with success
        ctx.redirect(`chongjaroen://payment-result?status=success&charge_id=${chargeId}`);
      } else if (charge.status === 'failed') {
        // Payment failed
        strapi.log.info('[Payment] 3DS payment failed:', chargeId);
        ctx.redirect(`chongjaroen://payment-result?status=failed&charge_id=${chargeId}`);
      } else {
        // Payment still pending (authentication might not be complete)
        strapi.log.info('[Payment] 3DS payment still pending:', chargeId);
        ctx.redirect(`chongjaroen://payment-result?status=pending&charge_id=${chargeId}`);
      }
    } catch (error) {
      strapi.log.error('[Payment] 3DS return handler error:', error);
      ctx.redirect('chongjaroen://payment-result?status=error');
    }
  },

  /**
   * POST /api/wallet/payment/webhook
   * Handle Omise webhook events with HMAC signature verification
   */
  async handleWebhook(ctx) {
    try {
      const event = ctx.request.body;

      strapi.log.info('[Payment] Webhook received:', {
        key: event.key,
        chargeId: event.data?.id,
      });

      // Get signature and timestamp from headers
      const signature = ctx.request.headers['omise-signature'];
      const timestamp = ctx.request.headers['omise-signature-timestamp'];

      // Verify webhook signature if secret is configured
      if (signature && timestamp) {
        // Get raw body for signature verification
        // The webhook-raw-body middleware captures this before parsing
        const rawBody = ctx.request.rawBody || JSON.stringify(event);

        const isValid = paymentService.verifyWebhookSignature(signature, timestamp, rawBody);

        strapi.log.info('[Payment] Webhook signature verification:', {
          hasSignature: !!signature,
          hasTimestamp: !!timestamp,
          hasSecret: !!process.env.OMISE_WEBHOOK_SECRET,
          isValid: isValid,
        });

        if (!isValid) {
          strapi.log.error('[Payment] Webhook rejected - invalid signature');
          return ctx.unauthorized('Invalid webhook signature');
        }

        strapi.log.info('[Payment] Webhook signature verified successfully');
      } else {
        strapi.log.warn('[Payment] Webhook received without signature headers');
      }

      // Handle different event types
      if (event.key === 'charge.complete') {
        const charge = event.data;

        if (charge.paid && charge.metadata?.user_id) {
          const userId = parseInt(charge.metadata.user_id);

          // Check if already processed
          const knex = strapi.connections.default;
          const existing = await knex('wallet_transactions')
            .where('metadata', 'like', `%${charge.id}%`)
            .first();

          if (!existing) {
            await paymentService.processSuccessfulPayment(charge.id, userId);
            strapi.log.info('[Payment] Webhook processed successfully for user:', userId);
          } else {
            strapi.log.info('[Payment] Charge already processed:', charge.id);
          }
        }
      }

      // Respond to Omise
      ctx.send({ received: true });
    } catch (error) {
      strapi.log.error('[Payment] Webhook error:', error);
      // Still respond with 200 to prevent Omise from retrying
      ctx.send({ received: false, error: error.message });
    }
  },
};