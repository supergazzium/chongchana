'use strict';

/**
 * Override strapi-admin bootstrap to handle permission reset errors gracefully
 * AND skip permission preloading in production to reduce memory usage
 */

module.exports = async () => {
  const adminStore = await strapi.store({
    environment: strapi.config.environment,
    type: 'type',
    name: 'setup',
  });

  const isInitialized = await adminStore.get({ key: 'isInitialized' });

  // If already initialized AND in production, skip everything to save memory
  if (isInitialized && strapi.config.environment === 'production') {
    strapi.log.info('[Admin Bootstrap Override] Production mode: Skipping permission preloading to reduce memory usage');
    return;
  }

  // If already initialized in development, skip the reset
  if (isInitialized) {
    strapi.log.info('[Admin Bootstrap Override] Admin already initialized, skipping all permission resets');
    return;
  }

  strapi.log.info('[Admin Bootstrap Override] First initialization - setting up admin with error handling');

  // Create default super admin role if it doesn't exist
  try {
    const superAdminRole = await strapi.query('role', 'admin').findOne({ code: 'strapi-super-admin' });

    if (!superAdminRole) {
      await strapi.query('role', 'admin').create({
        name: 'Super Admin',
        code: 'strapi-super-admin',
        description: 'Super Admins can access and manage all features and settings.',
      });
      strapi.log.info('[Admin Bootstrap Override] Created super admin role');
    }
  } catch (err) {
    strapi.log.warn('[Admin Bootstrap Override] Error creating super admin role:', err.message);
  }

  // Try to reset permissions, but catch ALL errors gracefully
  try {
    const roleService = strapi.admin.services.role;
    if (roleService && roleService.resetSuperAdminPermissions) {
      strapi.log.info('[Admin Bootstrap Override] Attempting to reset super admin permissions...');
      await roleService.resetSuperAdminPermissions();
      strapi.log.info('[Admin Bootstrap Override] ✅ Super admin permissions reset successfully');
    }
  } catch (err) {
    // Log the error but DON'T throw - allow Strapi to continue
    strapi.log.warn('[Admin Bootstrap Override] ⚠️  Could not reset super admin permissions');
    strapi.log.warn('[Admin Bootstrap Override] Error:', err.message);
    strapi.log.warn('[Admin Bootstrap Override] This is not critical - continuing bootstrap...');
    strapi.log.warn('[Admin Bootstrap Override] You can manually reset permissions from Strapi admin panel later');
  }

  // Always mark as initialized to prevent future attempts
  try {
    await adminStore.set({ key: 'isInitialized', value: true });
    strapi.log.info('[Admin Bootstrap Override] Admin initialization complete');
  } catch (err) {
    strapi.log.error('[Admin Bootstrap Override] Could not save initialization flag:', err.message);
    // Don't throw - this is not critical
  }
};
