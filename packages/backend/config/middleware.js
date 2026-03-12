module.exports = ({ env }) => ({
  settings: {
    cors: {
      enabled: true,
      origin: env.array('CORS_ORIGIN'),
      headers: [
        "Content-Type",
        "Authorization",
        "X-Frame-Options",
        "Authentication",
      ],
    },
  },
});
