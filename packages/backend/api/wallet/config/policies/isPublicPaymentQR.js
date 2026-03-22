module.exports = async (ctx, next) => {
  // Bypass authentication completely for payment QR endpoints
  // This policy runs BEFORE auth middleware, allowing truly public access

  // Remove any authentication state that might have been set
  ctx.state.user = null;

  // Mark this request as not requiring authentication
  ctx.request.route = {
    ...ctx.request.route,
    config: {
      ...ctx.request.route?.config,
      policies: [],
      auth: false
    }
  };

  strapi.log.debug('[isPublicPaymentQR] Bypassing auth for:', ctx.request.url);

  return await next();
};
