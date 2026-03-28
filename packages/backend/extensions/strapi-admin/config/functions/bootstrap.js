'use strict';

/**
 * Override strapi-admin bootstrap to handle permission reset errors gracefully
 * This prevents deployment failures when database permissions reference
 * content types that no longer exist in the code
 */

module.exports = async () => {
  const adminStore = await strapi.store({
    environment: strapi.config.environment,
    type: 'type',
    name: 'setup',
  });

  const isInitialized = await adminStore.get({ key: 'isInitialized' });

  // If already initialized, skip the rest to avoid permission reset issues
  if (isInitialized) {
    strapi.log.info('[Admin Bootstrap] Admin already initialized, skipping permission reset');
    return;
  }

  // Only on first initialization
  try {
    strapi.log.info('[Admin Bootstrap] First initialization detected, setting up admin...');

    // Create default super admin role if it doesn't exist
    const superAdminRole = await strapi.query('role', 'admin').findOne({ code: 'strapi-super-admin' });

    if (!superAdminRole) {
      await strapi.query('role', 'admin').create({
        name: 'Super Admin',
        code: 'strapi-super-admin',
        description: 'Super Admins can access and manage all features and settings.',
      });
      strapi.log.info('[Admin Bootstrap] Created super admin role');
    }

    // Try to reset permissions, but catch errors gracefully
    try {
      const roleService = strapi.admin.services.role;
      if (roleService && roleService.resetSuperAdminPermissions) {
        await roleService.resetSuperAdminPermissions();
        strapi.log.info('[Admin Bootstrap] Super admin permissions reset successfully');
      }
    } catch (err) {
      // Log the error but don't fail the bootstrap
      strapi.log.warn('[Admin Bootstrap] Could not reset super admin permissions:', err.message);
      strapi.log.warn('[Admin Bootstrap] This is not critical - continuing bootstrap...');
    }

    // Mark as initialized
    await adminStore.set({ key: 'isInitialized', value: true });
    strapi.log.info('[Admin Bootstrap] Admin initialization complete');
  } catch (err) {
    strapi.log.error('[Admin Bootstrap] Error during initialization:', err);
    // Don't throw - allow Strapi to continue starting
  }
};
