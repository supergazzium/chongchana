'use strict';

/**
 * An asynchronous bootstrap function that runs before
 * your application gets started.
 *
 * This gives you an opportunity to set up your data model,
 * run jobs, or perform some special logic.
 *
 * See more details here: https://strapi.io/documentation/developer-docs/latest/setup-deployment-guides/configurations.html#bootstrap
 */

module.exports = async () => {
  // ============================================================================
  // CRITICAL: Handle OPTIONS requests BEFORE authentication middleware
  // ============================================================================
  // This fixes the HTTP 500 error on CORS preflight requests
  strapi.app.use(async (ctx, next) => {
    if (ctx.method === 'OPTIONS') {
      strapi.log.debug(`[OPTIONS] Intercepting OPTIONS request to ${ctx.path} from ${ctx.get('Origin')}`);

      const allowedOrigins = (process.env.CORS_ORIGIN || 'http://localhost:4040')
        .split(',')
        .map(origin => origin.trim());

      const requestOrigin = ctx.get('Origin');

      strapi.log.debug(`[OPTIONS] Allowed origins: ${JSON.stringify(allowedOrigins)}`);
      strapi.log.debug(`[OPTIONS] Request origin: ${requestOrigin}`);

      // Allow ALL OPTIONS requests regardless of origin to fix CORS
      ctx.set('Access-Control-Allow-Origin', requestOrigin || '*');
      ctx.set('Access-Control-Allow-Methods', 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS');
      ctx.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Frame-Options, Authentication');
      ctx.set('Access-Control-Allow-Credentials', 'true');
      ctx.set('Access-Control-Max-Age', '86400'); // 24 hours

      ctx.status = 204; // No Content
      ctx.body = '';

      strapi.log.info(`[OPTIONS] Responding to OPTIONS ${ctx.path} with 204`);
      return; // Stop here, don't call next()
    }

    await next();
  });

  strapi.log.info('[Bootstrap] OPTIONS preflight handler installed');

  // Set permissions for public role to access staffSignin
  const publicRole = await strapi.query('role', 'users-permissions').findOne({ type: 'public' });

  if (publicRole) {
    const publicPermissions = await strapi.query('permission', 'users-permissions').find({ role: publicRole.id });

    const staffSigninPermission = publicPermissions.find(
      permission => permission.controller === 'api' && permission.action === 'staffsignin'
    );

    if (staffSigninPermission && !staffSigninPermission.enabled) {
      await strapi.query('permission', 'users-permissions').update(
        { id: staffSigninPermission.id },
        { enabled: true }
      );
      console.log('✅ Enabled public access to staffSignin endpoint');
    }

    // Set permissions for wallet-admin endpoints
    const walletAdminActions = [
      'listwallet', 'getwalletdetail', 'adjustbalance', 'freezewallet',
      'getalltransactions', 'refundtransaction', 'getreports', 'createvoucher',
      'gettransfersettings', 'updatetransfersettings'
    ];

    for (const action of walletAdminActions) {
      const walletPermission = publicPermissions.find(
        permission => permission.controller === 'admin' && permission.action === action && permission.type === 'application' && permission.plugin === 'api::wallet.wallet'
      );

      if (walletPermission && !walletPermission.enabled) {
        await strapi.query('permission', 'users-permissions').update(
          { id: walletPermission.id },
          { enabled: true }
        );
        console.log(`✅ Enabled public access to wallet ${action} endpoint`);
      }
    }
  }

  // Set permissions for authenticated role to access wallet endpoints
  const authenticatedRole = await strapi.query('role', 'users-permissions').findOne({ type: 'authenticated' });

  if (authenticatedRole) {
    const authenticatedPermissions = await strapi.query('permission', 'users-permissions').find({ role: authenticatedRole.id });

    strapi.log.info(`[Bootstrap] Found ${authenticatedPermissions.length} permissions for authenticated role`);

    // Enable all wallet and payment endpoints for authenticated users
    const walletActions = ['getbalance', 'gettransactions', 'topup', 'pay', 'redeemvoucher', 'convertpoints', 'getsettings'];
    const paymentActions = ['getpaymentmethods', 'createtoken', 'createchargefromtoken', 'createpaymentsource', 'checkpaymentstatus'];
    const transferActions = ['lookupuser', 'initiatetransfer', 'gettransferhistory', 'gettransferdetails'];
    const paymentQRActions = ['generatepaymentqr', 'validatepaymentqr', 'processpayment', 'getpaymenthistory'];

    // Check if wallet permissions exist, if not create them
    const walletPermissions = authenticatedPermissions.filter(p =>
      (p.controller || '').toLowerCase() === 'wallet' && p.plugin === 'application::wallet.wallet'
    );

    // Delete old wallet permissions without proper plugin field
    const oldWalletPermissions = authenticatedPermissions.filter(p =>
      (p.controller || '').toLowerCase() === 'wallet' && !p.plugin
    );
    for (const oldPerm of oldWalletPermissions) {
      await strapi.query('permission', 'users-permissions').delete({ id: oldPerm.id });
      strapi.log.info(`🗑️  Deleted old wallet permission: ${oldPerm.controller}.${oldPerm.action}`);
    }

    if (walletPermissions.length === 0) {
      strapi.log.info('[Bootstrap] No wallet permissions found in database, creating them...');

      // Create wallet permissions for authenticated role
      // IMPORTANT: Action names MUST match the handler function names exactly (case-sensitive)
      const walletActionsToCreate = ['getbalance', 'gettransactions', 'topup', 'pay', 'redeemvoucher', 'convertpoints', 'getsettings'];

      for (const action of walletActionsToCreate) {
        await strapi.query('permission', 'users-permissions').create({
          type: 'application',
          controller: 'wallet',
          action: action,
          enabled: true,
          policy: '',
          role: authenticatedRole.id,
        });
        strapi.log.info(`✅ Created and enabled permission: wallet.${action}`);
      }
    } else {
      strapi.log.info(`[Bootstrap] Found ${walletPermissions.length} wallet permissions:`,
        walletPermissions.map(p => `${p.controller}.${p.action} (enabled: ${p.enabled})`));
    }

    // Check if payment permissions exist, if not create them
    const paymentPermissions = authenticatedPermissions.filter(p =>
      (p.controller || '').toLowerCase() === 'payment' && p.plugin === 'application::wallet.wallet'
    );

    // Delete old payment permissions without proper plugin field
    const oldPaymentPermissions = authenticatedPermissions.filter(p =>
      (p.controller || '').toLowerCase() === 'payment' && !p.plugin
    );
    for (const oldPerm of oldPaymentPermissions) {
      await strapi.query('permission', 'users-permissions').delete({ id: oldPerm.id });
      strapi.log.info(`🗑️  Deleted old payment permission: ${oldPerm.controller}.${oldPerm.action}`);
    }

    if (paymentPermissions.length === 0) {
      strapi.log.info('[Bootstrap] No payment permissions found in database, creating them...');

      // Create payment permissions for authenticated role
      const paymentActionsToCreate = ['getPaymentMethods', 'createToken', 'createChargeFromToken', 'createPaymentSource', 'checkPaymentStatus'];

      for (const action of paymentActionsToCreate) {
        await strapi.query('permission', 'users-permissions').create({
          type: 'application',
          controller: 'payment',
          action: action.toLowerCase(),
          enabled: true,
          policy: '',
          role: authenticatedRole.id,
          plugin: 'application::wallet.wallet',
        });
        strapi.log.info(`✅ Created and enabled permission: payment.${action.toLowerCase()}`);
      }
    } else {
      strapi.log.info(`[Bootstrap] Found ${paymentPermissions.length} payment permissions:`,
        paymentPermissions.map(p => `${p.controller}.${p.action} (enabled: ${p.enabled})`));
    }

    // Check if transfer permissions exist, if not create them
    const transferPermissions = authenticatedPermissions.filter(p =>
      (p.controller || '').toLowerCase() === 'transfer' && p.plugin === 'application::wallet.wallet'
    );

    // Delete old transfer permissions without proper plugin field
    const oldTransferPermissions = authenticatedPermissions.filter(p =>
      (p.controller || '').toLowerCase() === 'transfer' && !p.plugin
    );
    for (const oldPerm of oldTransferPermissions) {
      await strapi.query('permission', 'users-permissions').delete({ id: oldPerm.id });
      strapi.log.info(`🗑️  Deleted old transfer permission: ${oldPerm.controller}.${oldPerm.action}`);
    }

    if (transferPermissions.length === 0) {
      strapi.log.info('[Bootstrap] No transfer permissions found in database, creating them...');

      // Create transfer permissions for authenticated role
      const transferActionsToCreate = ['lookupUser', 'initiateTransfer', 'getTransferHistory', 'getTransferDetails'];

      for (const action of transferActionsToCreate) {
        await strapi.query('permission', 'users-permissions').create({
          type: 'application',
          controller: 'transfer',
          action: action.toLowerCase(),
          enabled: true,
          policy: '',
          role: authenticatedRole.id,
          plugin: 'application::wallet.wallet',
        });
        strapi.log.info(`✅ Created and enabled permission: transfer.${action.toLowerCase()}`);
      }
    } else {
      strapi.log.info(`[Bootstrap] Found ${transferPermissions.length} transfer permissions:`,
        transferPermissions.map(p => `${p.controller}.${p.action} (enabled: ${p.enabled})`));
    }

    // Check if payment-qr permissions exist, if not create them
    const paymentQRPermissions = authenticatedPermissions.filter(p =>
      (p.controller || '').toLowerCase() === 'payment-qr' && p.plugin === 'application::wallet.wallet'
    );

    // Delete old payment-qr permissions without proper plugin field
    const oldPaymentQRPermissions = authenticatedPermissions.filter(p =>
      (p.controller || '').toLowerCase() === 'payment-qr' && !p.plugin
    );
    for (const oldPerm of oldPaymentQRPermissions) {
      await strapi.query('permission', 'users-permissions').delete({ id: oldPerm.id });
      strapi.log.info(`🗑️  Deleted old payment-qr permission: ${oldPerm.controller}.${oldPerm.action}`);
    }

    if (paymentQRPermissions.length === 0) {
      strapi.log.info('[Bootstrap] No payment-qr permissions found in database, creating them...');

      // Create payment-qr permissions for authenticated role (only generatePaymentQR and getPaymentHistory)
      const authenticatedActionsToCreate = ['generatePaymentQR', 'getPaymentHistory'];

      for (const action of authenticatedActionsToCreate) {
        await strapi.query('permission', 'users-permissions').create({
          type: 'application',
          controller: 'payment-qr',
          action: action.toLowerCase(),
          enabled: true,
          policy: '',
          role: authenticatedRole.id,
          plugin: 'application::wallet.wallet',
        });
        strapi.log.info(`✅ Created AUTHENTICATED permission: payment-qr.${action.toLowerCase()}`);
      }
    } else {
      strapi.log.info(`[Bootstrap] Found ${paymentQRPermissions.length} payment-qr permissions:`,
        paymentQRPermissions.map(p => `${p.controller}.${p.action} (enabled: ${p.enabled})`));
    }

    // Create PUBLIC role permissions for validatePaymentQR and processPayment
    const publicQRPermissions = await strapi.query('permission', 'users-permissions').find({
      role: publicRole.id,
      controller: 'payment-qr'
    });

    const publicActionsNeeded = ['validatepaymentqr', 'processpayment'];
    for (const action of publicActionsNeeded) {
      const existing = publicQRPermissions.find(p => p.action === action);
      if (!existing) {
        await strapi.query('permission', 'users-permissions').create({
          type: 'application',
          controller: 'payment-qr',
          action: action,
          enabled: true,
          policy: '',
          role: publicRole.id,
          plugin: 'application::wallet.wallet',
        });
        strapi.log.info(`✅ Created PUBLIC permission: payment-qr.${action}`);
      } else if (!existing.enabled) {
        await strapi.query('permission', 'users-permissions').update(
          { id: existing.id },
          { enabled: true }
        );
        strapi.log.info(`✅ Enabled PUBLIC permission: payment-qr.${action}`);
      }
    }

    for (const permission of authenticatedPermissions) {
      const action = (permission.action || '').toLowerCase();
      const controller = (permission.controller || '').toLowerCase();

      // Check if this is a wallet, payment, transfer, or payment-qr permission
      const isWalletPermission = controller === 'wallet' && walletActions.includes(action);
      const isPaymentPermission = controller === 'payment' && paymentActions.includes(action);
      const isTransferPermission = controller === 'transfer' && transferActions.includes(action);
      const isPaymentQRPermission = controller === 'payment-qr' && paymentQRActions.includes(action);

      if ((isWalletPermission || isPaymentPermission || isTransferPermission || isPaymentQRPermission) && !permission.enabled) {
        await strapi.query('permission', 'users-permissions').update(
          { id: permission.id },
          { enabled: true }
        );
        strapi.log.info(`✅ Enabled authenticated access to ${permission.controller}.${permission.action}`);
      }
    }

    strapi.log.info('[Bootstrap] Wallet permissions configuration completed');
  }
};
