/**
 * Wallet Admin Policy
 * Ensures only admin users can access wallet admin endpoints
 */

module.exports = async (ctx, next) => {
  const user = ctx.state.user;

  // Require authentication
  if (!user || !user.id) {
    strapi.log.warn('[WalletAdminPolicy] Unauthorized access attempt');
    return ctx.unauthorized('Authentication required');
  }

  // Fetch user with role
  const fullUser = await strapi.query('user', 'users-permissions').findOne({
    id: user.id,
  }, ['role']);

  if (!fullUser || !fullUser.role) {
    strapi.log.error('[WalletAdminPolicy] User has no role:', user.id);
    return ctx.forbidden('No role assigned');
  }

  // Check for admin privileges
  const roleType = (fullUser.role.type || fullUser.role.name || '').toLowerCase();
  const allowedRoles = ['admin', 'superadmin', 'super-admin'];
  const isAdmin = allowedRoles.some(role => roleType.includes(role));

  if (!isAdmin) {
    strapi.log.warn('[WalletAdminPolicy] Insufficient privileges:', {
      userId: user.id,
      role: roleType,
    });
    return ctx.forbidden('Admin access required');
  }

  strapi.log.info('[WalletAdminPolicy] Admin access granted:', {
    userId: user.id,
    role: roleType,
  });

  return await next();
};
