module.exports = ({ env }) => ({
  upload: {
    provider: 'do',
    providerOptions: {
      key: env('DO_SPACE_ACCESS_KEY'),
      secret: env('DO_SPACE_SECRET_KEY'),
      endpoint: env('DO_SPACE_ENDPOINT'),
      space: env('DO_SPACE_BUCKET'),
      directory: env('DO_SPACE_DIRECTORY', 'uploads'),
      cdn: env('DO_SPACE_CDN'),
    },
  },
  email: {
    provider: 'nodemailer',
    providerOptions: {
      host: 'smtp.gmail.com',
      port: 465,
      auth: {
        user: 'admin@chongjaroen.com',
        pass: 'zvhjmiafapduhutd',
      },
      // ... any custom nodemailer options
    },
    settings: {
      defaultFrom: 'noreply@chongjaroen.com',
      defaultReplyTo: 'noreply@chongjaroen.com',
    },
  },
  documentation: {
    enabled: false,
  },
});