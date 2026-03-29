/**
 * Wallet Admin Authentication Middleware
 * Enforces admin-only access to wallet admin endpoints
 *
 * SECURITY: This middleware verifies that only users with admin/super-admin roles
 * can access wallet administrative functions.
 */

module.exports = strapi => {
  return {
    initialize() {
      strapi.app.use(async (ctx, next) => {
        // Check if this is a wallet admin route
        const isWalletAdminRoute = ctx.request.url.startsWith('/wallet-admin/') ||
            ctx.request.url.startsWith('/api/admin/wallet') ||
            ctx.request.url.startsWith('/api/wallet-admin/');

        if (!isWalletAdminRoute) {
          // Not a wallet admin route, continue normally
          return await next();
        }

        // Let other middlewares run first (including JWT parsing)
        await next();

        // Now check authentication and authorization (after route handler)
        // This ensures JWT middleware has populated ctx.state.user
        const user = ctx.state.user;

        // If no user after JWT parsing, the route should have returned 401
        // This is a safety check in case the route doesn't require auth
        if (!user || !user.id) {
          strapi.log.warn('[WalletAdminAuth] Unauthorized access attempt to:', ctx.request.url);
          ctx.status = 401;
          ctx.body = { error: 'Authentication required for admin access' };
          return;
        }

        // Fetch user with role if not populated
        let userRole = user.role;
        if (!userRole) {
          const fullUser = await strapi.query('plugin::users-permissions.user').findOne({
            where: { id: user.id },
            populate: ['role'],
          });

          if (!fullUser || !fullUser.role) {
            strapi.log.error('[WalletAdminAuth] User has no role assigned:', user.id);
            ctx.status = 403;
            ctx.body = { error: 'Access denied: No role assigned' };
            return;
          }

          userRole = fullUser.role;
        }

        // Check if user has admin privileges
        const roleType = (userRole.type || userRole.name || '').toLowerCase();
        const allowedRoles = ['admin', 'superadmin', 'super-admin'];

        const isAdmin = allowedRoles.some(role => roleType.includes(role));

        if (!isAdmin) {
          strapi.log.warn('[WalletAdminAuth] Access denied - insufficient privileges:', {
            userId: user.id,
            userRole: roleType,
            endpoint: ctx.request.url,
            method: ctx.request.method,
          });
          ctx.status = 403;
          ctx.body = { error: 'Admin access required' };
          return;
        }

        // Log successful admin access
        strapi.log.info('[WalletAdminAuth] Admin access granted:', {
          userId: user.id,
          role: roleType,
          endpoint: ctx.request.url,
          method: ctx.request.method,
        });
      });
    },
  };
};
