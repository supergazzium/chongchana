const OneSignal = require('onesignal-node')

const slugify = str => {
  return str
    .toLowerCase()
    .replace(/\s+/g, '-') // Replace spaces with -
    .replace('%', 'เปอร์เซนต์') // Translate some charactor
    .replace(/[^\u0E00-\u0E7F\w\-]+/g, '') // Remove all non-word chars
    .replace(/\-\-+/g, '-') // Replace multiple - with single -
    .replace(/^-+/, '') // Trim - from start of text
    .replace(/-+$/, '')
}

// Never throws. Returns { success: bool, error?: any, response?: any }.
// Callers may safely fire-and-forget without risking unhandled rejections.
const sendPushNotification = async ({ content, heading, external_ids, additionalData }) => {
  if (!process.env.ONESIGNAL_APP_ID || !process.env.ONESIGNAL_API_KEY) {
    console.error('[OneSignal] ERROR: Missing credentials!');
    console.error('[OneSignal] ONESIGNAL_APP_ID:', process.env.ONESIGNAL_APP_ID ? 'SET' : 'EMPTY');
    console.error('[OneSignal] ONESIGNAL_API_KEY:', process.env.ONESIGNAL_API_KEY ? 'SET' : 'EMPTY');
    return { success: false, error: 'OneSignal credentials not configured' };
  }

  // OneSignal rejects notifications with empty contents/headings.
  // Validate up front to fail fast with a clear log instead of a 400 from the API.
  if (!content || (typeof content === 'string' && content.trim() === '')) {
    console.error('[OneSignal] Skipping notification: empty content', { heading, external_ids });
    return { success: false, error: 'empty_content' };
  }
  if (!heading || (typeof heading === 'string' && heading.trim() === '')) {
    console.error('[OneSignal] Skipping notification: empty heading', { content, external_ids });
    return { success: false, error: 'empty_heading' };
  }

  const client = new OneSignal.Client(
    process.env.ONESIGNAL_APP_ID,
    process.env.ONESIGNAL_API_KEY
  )

  const notification = {
    contents: {
      en: content,
    },
    headings: {
      en: heading,
    },
    data: additionalData,
    ...(!external_ids ? { included_segments: ['Subscribed Users'] } : {}),
    ...(external_ids ? { include_external_user_ids: external_ids } : {}),
  }

  try {
    console.log('[OneSignal] Sending push notification...');
    console.log('[OneSignal] Heading:', heading);
    console.log('[OneSignal] Content:', content);
    console.log('[OneSignal] External IDs:', external_ids);
    console.log('[OneSignal] Additional Data:', JSON.stringify(additionalData, null, 2));

    const response = await client.createNotification(notification)

    console.log('[OneSignal] ✅ Notification sent successfully!');
    console.log('[OneSignal] Notification ID:', response.body.id);
    console.log('[OneSignal] Recipients:', response.body.recipients);

    return { success: true, response };
  } catch (e) {
    console.error('[OneSignal] ❌ Failed to send notification');
    if (e instanceof OneSignal.HTTPError) {
      console.error('[OneSignal] HTTP Status:', e.statusCode);
      console.error('[OneSignal] Error Body:', JSON.stringify(e.body, null, 2));
    } else {
      console.error('[OneSignal] Error:', e.message);
      console.error('[OneSignal] Stack:', e.stack);
    }
    return { success: false, error: e };
  }
}

const imageDTO = (image, options) => {
  const opt = options || { mainSize: "original" };
  const { url, formats } = image || {};
  let result = null;

  if (url) {
    let mainURL = url;
    switch (opt.mainSize) {
      case "large":
        mainURL = formats?.large?.url;
        break;
      case "medium":
        mainURL = formats?.medium?.url;
        break;
      case "small":
        mainURL = formats?.small?.url;
        break;
      case "thumbnail":
        mainURL = formats?.thumbnail?.url;
        break;
    }
  

    result = {
      url: mainURL || url,
    };
  }

  return result;
};

module.exports = {
  slugify,
  sendPushNotification,
  imageDTO,
}
