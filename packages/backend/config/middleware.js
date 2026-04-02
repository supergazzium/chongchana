module.exports = ({ env }) => ({
  settings: {
    'webhook-raw-body': {
      enabled: true,
    },
    'options-handler': {
      enabled: true,
    },
    cors: {
      enabled: true,
      origin: ['http://localhost:1337', ...env('CORS_ORIGIN', 'http://localhost:4040').split(',')],
      credentials: true,
      headers: ['Content-Type', 'Authorization', 'X-Frame-Options', 'Authentication'],
    },
    'wallet-admin-auth': {
      enabled: false,
    },
    'payment-qr-public': {
      enabled: true,
    },
  },
});
