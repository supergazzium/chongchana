/**
 * OneSignal Notification Service for Wallet
 * Handles all push notifications related to wallet operations
 */

const axios = require('axios');

const ONESIGNAL_API_URL = 'https://onesignal.com/api/v1/notifications';
const APP_ID = process.env.ONESIGNAL_APP_ID;
const API_KEY = process.env.ONESIGNAL_API_KEY;

/**
 * Base function to send OneSignal notification
 * @param {number} userId - User ID (external_id in OneSignal)
 * @param {string} title - Notification title
 * @param {string} message - Notification body
 * @param {object} additionalData - Custom data for notification
 * @returns {Promise<object>} - OneSignal response
 */
async function sendNotification(userId, title, message, additionalData = {}) {
  if (!APP_ID || !API_KEY) {
    strapi.log.error('[OneSignal] Missing APP_ID or API_KEY in environment variables');
    return { success: false, error: 'OneSignal not configured' };
  }

  try {
    const payload = {
      app_id: APP_ID,
      include_external_user_ids: [userId.toString()],
      headings: { en: title },
      contents: { en: message },
      data: {
        sendingMethod: 'inbox_push',
        ...additionalData,
      },
    };

    strapi.log.info(`[OneSignal] Sending notification to user ${userId}: ${title}`);
    strapi.log.debug(`[OneSignal] Payload:`, JSON.stringify(payload, null, 2));

    const response = await axios.post(ONESIGNAL_API_URL, payload, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Basic ${API_KEY}`,
      },
    });

    strapi.log.info(`[OneSignal] Notification sent successfully. ID: ${response.data.id}`);

    // Store notification in database for inbox retrieval
    try {
      const now = new Date();

      // Create the notification record
      const notification = await strapi.query('notification').create({
        title,
        body: message,
        cover_image: additionalData.coverImage || null,
        published_at: now,
      });

      strapi.log.debug(`[OneSignal] Notification created with ID: ${notification.id}`);

      // Create inbox entry to link notification to user
      await strapi.query('inbox').create({
        users_permissions_user: userId,
        notification: notification.id,
        published_at: now,
        read_at: null,
        deleted_at: null,
      });

      strapi.log.debug(`[OneSignal] Inbox entry created for user ${userId}`);
    } catch (dbError) {
      strapi.log.warn(`[OneSignal] Failed to store notification in database:`, dbError.message);
      // Don't fail the notification send if DB store fails
    }

    return { success: true, id: response.data.id, recipients: response.data.recipients };
  } catch (error) {
    strapi.log.error('[OneSignal] Failed to send notification:', error.response?.data || error.message);
    return { success: false, error: error.response?.data || error.message };
  }
}

/**
 * Send top-up success notification
 */
async function sendTopUpSuccessNotification(userId, amount, paymentMethod, chargeId) {
  const title = 'Top-up Successful';
  const message = `Your wallet has been topped up with ฿${amount.toFixed(2)}`;

  return sendNotification(userId, title, message, {
    type: 'wallet_topup',
    amount,
    paymentMethod,
    chargeId,
    timestamp: new Date().toISOString(),
  });
}

/**
 * Send top-up failed notification
 */
async function sendTopUpFailedNotification(userId, amount, reason) {
  const title = 'Top-up Failed';
  const message = `Failed to top up ฿${amount.toFixed(2)}. ${reason}`;

  return sendNotification(userId, title, message, {
    type: 'wallet_topup_failed',
    amount,
    reason,
    timestamp: new Date().toISOString(),
  });
}

/**
 * Send transfer sent notification
 */
async function sendTransferSentNotification(userId, amount, receiverName, transactionId) {
  const title = 'Transfer Sent';
  const message = `You sent ฿${amount.toFixed(2)} to ${receiverName}`;

  return sendNotification(userId, title, message, {
    type: 'wallet_transfer_sent',
    amount,
    receiverName,
    transactionId,
    timestamp: new Date().toISOString(),
  });
}

/**
 * Send transfer received notification
 */
async function sendTransferReceivedNotification(userId, amount, senderName, transactionId) {
  const title = 'Money Received';
  const message = `You received ฿${amount.toFixed(2)} from ${senderName}`;

  return sendNotification(userId, title, message, {
    type: 'wallet_transfer_received',
    amount,
    senderName,
    transactionId,
    timestamp: new Date().toISOString(),
  });
}

/**
 * Send payment success notification
 */
async function sendPaymentSuccessNotification(userId, amount, merchantName, transactionId) {
  const title = 'Payment Successful';
  const message = `You paid ฿${amount.toFixed(2)} to ${merchantName}`;

  return sendNotification(userId, title, message, {
    type: 'wallet_payment',
    amount,
    merchantName,
    transactionId,
    timestamp: new Date().toISOString(),
  });
}

/**
 * Send payment failed notification
 */
async function sendPaymentFailedNotification(userId, amount, reason) {
  const title = 'Payment Failed';
  const message = `Failed to process payment of ฿${amount.toFixed(2)}. ${reason}`;

  return sendNotification(userId, title, message, {
    type: 'wallet_payment_failed',
    amount,
    reason,
    timestamp: new Date().toISOString(),
  });
}

/**
 * Send QR payment notification
 */
async function sendQRPaymentNotification(userId, amount, merchantName, transactionId) {
  const title = 'QR Payment Successful';
  const message = `You paid ฿${amount.toFixed(2)} at ${merchantName}`;

  return sendNotification(userId, title, message, {
    type: 'wallet_qr_payment',
    amount,
    merchantName,
    transactionId,
    timestamp: new Date().toISOString(),
  });
}

/**
 * Send voucher redeemed notification
 */
async function sendVoucherRedeemedNotification(userId, amount, voucherCode) {
  const title = 'Voucher Redeemed';
  const message = `You redeemed voucher for ฿${amount.toFixed(2)}`;

  return sendNotification(userId, title, message, {
    type: 'wallet_voucher',
    amount,
    voucherCode,
    timestamp: new Date().toISOString(),
  });
}

/**
 * Send points converted notification
 */
async function sendPointsConvertedNotification(userId, points, creditAmount) {
  const title = 'Points Converted';
  const message = `You converted ${points} points to ฿${creditAmount.toFixed(2)}`;

  return sendNotification(userId, title, message, {
    type: 'wallet_points_convert',
    points,
    creditAmount,
    timestamp: new Date().toISOString(),
  });
}

module.exports = {
  sendNotification,
  sendTopUpSuccessNotification,
  sendTopUpFailedNotification,
  sendTransferSentNotification,
  sendTransferReceivedNotification,
  sendPaymentSuccessNotification,
  sendPaymentFailedNotification,
  sendQRPaymentNotification,
  sendVoucherRedeemedNotification,
  sendPointsConvertedNotification,
};
