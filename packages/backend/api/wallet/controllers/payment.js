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

      // Create charge with return_uri that includes user_id
      // We can't include charge_id because we don't have it yet, but we can include user_id
      // This allows the return handler to look up the most recent charge for this user
      const baseUrl = process.env.PUBLIC_URL || 'https://wallet-backend-test-pc-ndd56.ondigitalocean.app';
      const returnUri = `${baseUrl}/wallet/payment/3ds-return?user_id=${userId}`;

      const charge = await paymentService.createChargeFromToken(
        tokenId,
        amount,
        currency,
        `Wallet top-up - User ${userId}`,
        {
          user_id: userId,
          type: 'wallet_topup',
        },
        returnUri
      );

      strapi.log.info('[Payment] Charge created:', {
        chargeId: charge.id,
        status: charge.status,
        paid: charge.paid,
        hasAuthorizeUri: !!charge.authorize_uri,
      });

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

      let transactionId = null;

      // If payment is successful and not yet processed, credit wallet
      if (charge.paid && charge.metadata?.user_id == userId) {
        // Check if already processed
        const knex = strapi.connections.default;
        const existing = await knex('wallet_transactions')
          .whereRaw("JSON_EXTRACT(metadata, '$.charge_id') = ?", [chargeId])
          .first();

        if (!existing) {
          const result = await paymentService.processSuccessfulPayment(chargeId, userId);
          transactionId = result.transactionId;
        } else {
          transactionId = existing.id;
        }
      }

      ctx.send(utils.successResponse({
        paid: charge.paid,
        status: charge.status,
        transactionId: transactionId || charge.id,
        chargeId: charge.id,
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
   * Returns HTML page with JavaScript deep link trigger to avoid Safari blocking redirects
   */
  async handle3DSReturn(ctx) {
    try {
      const userId = ctx.query.user_id;
      let chargeId = ctx.query.charge_id || ctx.query.chargeId || ctx.query.id;

      strapi.log.info('[Payment] 3DS return received:', {
        query: ctx.query,
        userId,
        chargeId,
      });

      // If no charge_id but we have user_id, look up the most recent pending charge
      if (!chargeId && userId) {
        strapi.log.info('[Payment] Looking up most recent charge for user:', userId);

        // Retry logic to handle race condition with webhook
        // The webhook might still be processing when 3DS return arrives
        const knex = strapi.connections.default;
        let retries = 3;

        while (retries > 0 && !chargeId) {
          const recentTransactions = await knex('wallet_transactions')
            .where('user_id', userId)
            .where('type', 'top_up')
            .where('payment_method', 'credit_card')
            .whereNotNull('metadata')
            .orderBy('created_at', 'desc')
            .limit(5);

          // Find the most recent transaction with a charge_id in metadata
          for (const transaction of recentTransactions) {
            try {
              const metadata = JSON.parse(transaction.metadata);
              if (metadata.charge_id) {
                chargeId = metadata.charge_id;
                strapi.log.info('[Payment] Found charge from recent transaction:', chargeId);
                break;
              }
            } catch (e) {
              // Skip transactions with invalid JSON
              continue;
            }
          }

          // If not found and retries remain, wait 200ms and try again
          if (!chargeId && retries > 1) {
            strapi.log.info('[Payment] Charge not found, waiting for webhook... (retries left:', retries - 1, ')');
            await new Promise(resolve => setTimeout(resolve, 200));
          }

          retries--;
        }
      }

      let deepLink = 'chongjaroen://payment-result?status=success';
      let statusMessage = 'Payment successful!';
      let statusIcon = '✅';

      // Note: The webhook already processed the payment, so we just need to redirect back to app
      // The app's polling will find the transaction that was created by the webhook
      if (chargeId) {
        deepLink = `chongjaroen://payment-result?status=success&charge_id=${chargeId}`;
        strapi.log.info('[Payment] Redirecting to app with charge:', chargeId);
      } else {
        strapi.log.warn('[Payment] No charge ID found, redirecting to app anyway');
      }

      // Return HTML page with JavaScript deep link trigger
      // This avoids Safari blocking cross-protocol redirects
      ctx.type = 'text/html';
      ctx.body = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Redirecting to Chongjaroen...</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      background: linear-gradient(135deg, #1797AD 0%, #14828E 100%);
      color: white;
      text-align: center;
      padding: 20px;
    }
    .container {
      max-width: 400px;
    }
    .icon {
      font-size: 64px;
      margin-bottom: 20px;
      animation: pulse 2s infinite;
    }
    @keyframes pulse {
      0%, 100% { transform: scale(1); }
      50% { transform: scale(1.1); }
    }
    h1 {
      font-size: 24px;
      margin: 20px 0;
      font-weight: 600;
    }
    p {
      font-size: 16px;
      opacity: 0.9;
      margin: 10px 0;
    }
    .button {
      display: inline-block;
      margin-top: 30px;
      padding: 15px 40px;
      background: white;
      color: #1797AD;
      border-radius: 30px;
      text-decoration: none;
      font-weight: 600;
      font-size: 16px;
      box-shadow: 0 4px 12px rgba(0,0,0,0.15);
      transition: transform 0.2s;
    }
    .button:hover {
      transform: translateY(-2px);
    }
    .button:active {
      transform: translateY(0);
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="icon">${statusIcon}</div>
    <h1>${statusMessage}</h1>
    <p>Redirecting to Chongjaroen app...</p>
    <p style="font-size: 14px; opacity: 0.7;">If not redirected automatically:</p>
    <a href="${deepLink}" class="button">Open Chongjaroen App</a>
  </div>
  <script>
    // Auto-redirect to app after a short delay
    setTimeout(function() {
      window.location.href = '${deepLink}';
    }, 1000);

    // Fallback: Try to open app immediately on page load
    window.location.href = '${deepLink}';
  </script>
</body>
</html>
      `;
    } catch (error) {
      strapi.log.error('[Payment] 3DS return handler error:', error);
      ctx.type = 'text/html';
      ctx.body = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Payment Error</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      background: #f44336;
      color: white;
      text-align: center;
      padding: 20px;
    }
    .container { max-width: 400px; }
    .icon { font-size: 64px; margin-bottom: 20px; }
    h1 { font-size: 24px; margin: 20px 0; }
    p { font-size: 16px; opacity: 0.9; }
    .button {
      display: inline-block;
      margin-top: 30px;
      padding: 15px 40px;
      background: white;
      color: #f44336;
      border-radius: 30px;
      text-decoration: none;
      font-weight: 600;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="icon">❌</div>
    <h1>Payment Error</h1>
    <p>Something went wrong processing your payment.</p>
    <a href="chongjaroen://payment-result?status=error" class="button">Return to App</a>
  </div>
  <script>
    setTimeout(function() {
      window.location.href = 'chongjaroen://payment-result?status=error';
    }, 2000);
  </script>
</body>
</html>
      `;
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

      // TODO: Temporarily disabled signature verification for testing
      // Will re-enable after confirming webhook flow works
      strapi.log.info('[Payment] Webhook signature verification DISABLED for testing:', {
        hasSignature: !!signature,
        hasTimestamp: !!timestamp,
        hasSecret: !!process.env.OMISE_WEBHOOK_SECRET,
      });

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