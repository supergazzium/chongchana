/**
 * OPTIONS Request Handler Middleware
 * Explicitly handles CORS preflight OPTIONS requests
 *
 * This middleware intercepts all OPTIONS requests and returns proper CORS headers
 * to fix the HTTP 500 error that was occurring with Strapi's default handling
 */

module.exports = strapi => {
  return {
    initialize() {
      strapi.app.use(async (ctx, next) => {
        // Handle OPTIONS requests (CORS preflight)
        if (ctx.method === 'OPTIONS') {
          const allowedOrigins = (process.env.CORS_ORIGIN || 'http://localhost:4040')
            .split(',')
            .map(origin => origin.trim());

          const requestOrigin = ctx.get('Origin');

          // Check if origin is allowed
          if (allowedOrigins.includes(requestOrigin) || allowedOrigins.includes('*')) {
            ctx.set('Access-Control-Allow-Origin', requestOrigin || '*');
            ctx.set('Access-Control-Allow-Methods', 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS');
            ctx.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Frame-Options, Authentication');
            ctx.set('Access-Control-Allow-Credentials', 'true');
            ctx.set('Access-Control-Max-Age', '86400'); // 24 hours

            strapi.log.debug(`[OPTIONS Handler] Preflight request from ${requestOrigin} to ${ctx.path}`);

            ctx.status = 204; // No Content
            ctx.body = '';
            return; // Don't call next(), stop here
          }
        }

        await next();
      });
    },
  };
};
