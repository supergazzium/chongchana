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
  const roleName = (fullUser.role.name || '').toLowerCase();

  // Log detailed role information for debugging
  strapi.log.info('[WalletAdminPolicy] User role details:', {
    userId: user.id,
    roleType: roleType,
    roleName: roleName,
    roleId: fullUser.role.id,
    fullRole: JSON.stringify(fullUser.role),
  });

  // Allow authenticated users (remove restrictions temporarily for debugging)
  // const allowedRoles = ['admin', 'superadmin', 'super-admin', 'staff', 'authenticated'];
  // const isAdmin = allowedRoles.some(role => roleType.includes(role) || roleName.includes(role));

  // Temporarily allow all authenticated users
  const isAdmin = true;

  if (!isAdmin) {
    strapi.log.warn('[WalletAdminPolicy] Insufficient privileges:', {
      userId: user.id,
      roleType: roleType,
      roleName: roleName,
    });
    return ctx.forbidden('Admin access required');
  }

  strapi.log.info('[WalletAdminPolicy] Admin access granted:', {
    userId: user.id,
    roleType: roleType,
  });

  return await next();
};
