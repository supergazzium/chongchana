'use strict';

/**
 * Global policy for wallet admin routes.
 * Requires an authenticated user with role type/name in the admin allowlist.
 */

const ALLOWED_ROLES = ['admin', 'superadmin', 'super-admin'];

module.exports = async (ctx, next) => {
  const user = ctx.state.user;

  if (!user || !user.id) {
    return ctx.unauthorized('Authentication required');
  }

  let role = user.role;
  if (!role || (!role.type && !role.name)) {
    const fullUser = await strapi
      .query('user', 'users-permissions')
      .findOne({ id: user.id }, ['role']);
    role = fullUser && fullUser.role ? fullUser.role : null;
  }

  if (!role) {
    return ctx.forbidden('No role assigned');
  }

  const roleType = (role.type || '').toLowerCase();
  const roleName = (role.name || '').toLowerCase();

  const isAdmin = ALLOWED_ROLES.some(
    (r) => roleType === r || roleName === r
  );

  if (!isAdmin) {
    return ctx.forbidden('Admin access required');
  }

  return await next();
};
