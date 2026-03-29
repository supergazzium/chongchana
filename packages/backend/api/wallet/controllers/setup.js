/**
 * Setup Controller - One-time setup endpoints
 * IMPORTANT: Remove this file after setup is complete
 */

module.exports = {
  /**
   * Create admin user and wallet-admin permissions
   * Call once: POST /wallet/setup
   */
  async runSetup(ctx) {
    try {
      const results = {
        adminUser: null,
        permissions: [],
        errors: [],
      };

      // 1. Create admin user if doesn't exist
      const adminEmail = 'admin@chongjaroen.com';
      const existingAdmin = await strapi.query('user', 'users-permissions').findOne({ email: adminEmail });

      if (!existingAdmin) {
        const adminRole = await strapi.query('role', 'users-permissions').findOne({ type: 'authenticated' });

        const newAdmin = await strapi.query('user', 'users-permissions').create({
          username: 'admin',
          email: adminEmail,
          password: 'TempPassword123!', // CHANGE THIS IMMEDIATELY AFTER LOGIN
          confirmed: true,
          blocked: false,
          role: adminRole.id,
        });

        results.adminUser = {
          email: adminEmail,
          password: 'TempPassword123!',
          message: '⚠️ CHANGE PASSWORD IMMEDIATELY AFTER LOGIN',
        };
      } else {
        results.adminUser = {
          email: adminEmail,
          message: 'Admin user already exists',
        };
      }

      // 2. Create wallet-admin permissions
      const authenticatedRole = await strapi.query('role', 'users-permissions').findOne({ type: 'authenticated' });

      if (!authenticatedRole) {
        results.errors.push('Authenticated role not found');
        return ctx.send(results, 500);
      }

      const adminActions = [
        'listwallets', 'getwalletdetail', 'adjustbalance', 'freezewallet',
        'getalltransactions', 'refundtransaction', 'getreports', 'createvoucher',
        'gettransfersettings', 'updatetransfersettings', 'getalltransfers',
        'getallpointredemptions', 'canceltransfer', 'approvepointredemption', 'rejectpointredemption'
      ];

      for (const action of adminActions) {
        // Check if permission already exists
        const existing = await strapi.query('permission', 'users-permissions').findOne({
          controller: 'admin',
          action: action,
          role: authenticatedRole.id,
          plugin: 'application::wallet.wallet',
        });

        if (!existing) {
          await strapi.query('permission', 'users-permissions').create({
            type: 'application',
            controller: 'admin',
            action: action,
            enabled: true,
            policy: '',
            role: authenticatedRole.id,
            plugin: 'application::wallet.wallet',
          });
          results.permissions.push(`✅ Created: ${action}`);
        } else {
          results.permissions.push(`⏭️ Exists: ${action}`);
        }
      }

      strapi.log.info('[Setup] Setup completed successfully');

      return ctx.send({
        success: true,
        message: '🎉 Setup completed successfully!',
        results,
      });

    } catch (error) {
      strapi.log.error('[Setup] Error:', error);
      return ctx.send({
        success: false,
        error: error.message,
        stack: error.stack,
      }, 500);
    }
  },
};
