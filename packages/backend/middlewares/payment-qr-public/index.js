module.exports = strapi => {
  return {
    initialize() {
      strapi.app.use(async (ctx, next) => {
        // Skip authentication for payment QR validation and payment endpoints
        const publicQRRoutes = [
          '/wallet/payment-qr/validate',
          '/wallet/payment-qr/pay'
        ];

        if (publicQRRoutes.includes(ctx.path)) {
          strapi.log.debug('[payment-qr-public] Bypassing auth for:', ctx.path);

          // Mark route as public - this must be set BEFORE calling next()
          if (!ctx.state.route) {
            ctx.state.route = {};
          }
          if (!ctx.state.route.config) {
            ctx.state.route.config = {};
          }
          ctx.state.route.config.auth = false;

          // Remove user state to ensure no auth is required
          ctx.state.user = undefined;
        }

        await next();
      });
    },
  };
};
