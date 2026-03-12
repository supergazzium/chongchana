module.exports = ({ env }) => ({
  defaultConnection: 'default',
  connections: {
    default: {
      connector: 'bookshelf',
      settings: {
        client: 'mysql',
        host: env('DATABASE_HOST'),
        port: env.int('DATABASE_PORT', 25060),
        database: env('DATABASE_NAME'),
        username: env('DATABASE_USERNAME'),
        password: env('DATABASE_PASSWORD'),
        ssl: env.bool('DATABASE_SSL', true),
        charset: "utf8mb4",
      },
      options: {
        charset: "utf8mb4",
        debug: env.bool('DATABASE_QUERY_DEBUG', false),
        pool: {
          max: env.int('DATABASE_POOL_MAX', 10),
        }
      }
    },
  },
});
