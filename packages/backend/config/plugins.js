module.exports = ({ env }) => ({
  upload: {
    provider: 'local',
    providerOptions: {
      sizeLimit: 100000000, // 100 MB
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