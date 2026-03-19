module.exports = ({ env }) => ({
  settings: {
    cors: {
      enabled: true,
      origin: env('CORS_ORIGIN', 'http://localhost:4040').split(','),
      credentials: true,
      headers: [
        "Content-Type",
        "Authorization",
        "X-Frame-Options",
        "Authentication",
      ],
    },
    'wallet-admin-auth': {
      enabled: true,
    },
  },
});
