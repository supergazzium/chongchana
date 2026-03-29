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
        // Apply to wallet admin routes
        if (ctx.request.url.startsWith('/wallet-admin/') ||
            ctx.request.url.startsWith('/api/admin/wallet') ||
            ctx.request.url.startsWith('/api/wallet-admin/')) {

          const user = ctx.state.user;

          // Require authentication
          if (!user || !user.id) {
            strapi.log.warn('[WalletAdminAuth] Unauthorized access attempt to:', ctx.request.url);
            return ctx.unauthorized('Authentication required for admin access');
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
              return ctx.forbidden('Access denied: No role assigned');
            }

            userRole = fullUser.role;
            user.role = userRole; // Cache for this request
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
            return ctx.forbidden('Admin access required');
          }

          // Log successful admin access
          strapi.log.info('[WalletAdminAuth] Admin access granted:', {
            userId: user.id,
            role: roleType,
            endpoint: ctx.request.url,
            method: ctx.request.method,
          });
        }

        await next();
      });
    },
  };
};
