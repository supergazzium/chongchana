module.exports = ({ env }) => ({
  host: env('HOST', '0.0.0.0'),
  port: env.int('NODE_PORT', 7000),
  admin: {
    auth: {
      secret: env('ADMIN_JWT_SECRET', 'jwt_secret'),
    },
    // Disable admin panel build in production (API-only mode)
    // The admin panel is served separately from packages/admin
    autoOpen: false,
    watchIgnoreFiles: env('NODE_ENV') === 'production' ? ['**/*'] : [],
  },
	cron :{
    enabled: true
  },
});
