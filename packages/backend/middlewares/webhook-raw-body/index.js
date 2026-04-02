/**
 * Webhook Raw Body Middleware
 * Captures the raw request body for Omise webhook signature verification
 *
 * IMPORTANT: This middleware must run BEFORE the body parser
 */

const getRawBody = require('raw-body');

module.exports = strapi => {
  return {
    initialize() {
      strapi.app.use(async (ctx, next) => {
        // Only capture raw body for webhook endpoint
        if (ctx.path === '/wallet/payment/webhook' && ctx.method === 'POST') {
          try {
            // Get raw body before it's parsed by body parser
            const rawBody = await getRawBody(ctx.req, {
              length: ctx.request.length,
              limit: '1mb',
              encoding: 'utf8'
            });

            // Store raw body for signature verification
            ctx.request.rawBody = rawBody;

            strapi.log.debug('[Webhook] Raw body captured, length:', rawBody.length);
          } catch (err) {
            strapi.log.error('[Webhook] Failed to capture raw body:', err);
          }
        }

        await next();
      });
    },
  };
};