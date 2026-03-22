'use strict';

const paymentController = require('../../wallet/controllers/payment');

/**
 * Omise Controller
 * Handles Omise webhook events at /api/omise/events
 * This endpoint is shared with other Omise integrations
 */

module.exports = {
  /**
   * POST /api/omise/events
   * Handle Omise webhook events
   * Routes wallet-related events to the wallet payment controller
   */
  async handleEvents(ctx) {
    const event = ctx.request.body;

    strapi.log.info('[Omise] Webhook event received:', {
      key: event.key,
      id: event.id,
    });

    // Check if this is a wallet-related event
    const walletEventTypes = [
      'charge.complete',
      'charge.create',
      'charge.expire',
      'source.chargeable',
    ];

    if (walletEventTypes.includes(event.key)) {
      // Route to wallet payment webhook handler
      strapi.log.info('[Omise] Routing to wallet payment handler');
      return await paymentController.handleWebhook(ctx);
    }

    // If not a wallet event, return success (for other integrations)
    strapi.log.info('[Omise] Event not related to wallet, acknowledging');
    ctx.send({ received: true, message: 'Event acknowledged but not processed by wallet' });
  },
};
