# Chongjaroen Backend API

REST API backend for Chongjaroen restaurant management system, built with Strapi CMS.

## 🚀 Features

- **User Authentication** - JWT-based authentication with role-based access control
- **Wallet System** - Digital wallet with top-up, payments, transfers
- **Payment Gateway** - Omise integration (Credit Card, PromptPay, Mobile Banking)
- **Booking System** - Restaurant table booking management
- **Push Notifications** - OneSignal integration for mobile app
- **SMS Integration** - ThaiBulkSMS for OTP verification
- **File Storage** - Digital Ocean Spaces for image/file uploads
- **Content Management** - Menu, promotions, news management

## 🛠️ Tech Stack

- **Framework**: Strapi 3.6.8 (Headless CMS)
- **Runtime**: Node.js 14.x
- **Database**: MySQL 8
- **Payment**: Omise Payment Gateway
- **Storage**: Digital Ocean Spaces
- **Notifications**: OneSignal
- **SMS**: ThaiBulkSMS

## 📋 Prerequisites

- Node.js 14.x (Strapi 3.6.8 requires <=14.x)
- MySQL 8.0+
- npm or yarn

## 🔧 Installation

```bash
# Clone the repository
git clone git@github.com:your-username/chongjaroen-backend.git
cd chongjaroen-backend

# Install dependencies
npm install

# Copy environment variables
cp .env.example .env

# Edit .env with your actual values
# See .env.example for all required variables

# Run database migrations (if any)
npm run strapi -- migrate

# Start development server
npm run dev
```

## 📝 Environment Setup

1. **Copy `.env.example` to `.env`**
2. **Fill in required values:**
   - Database credentials
   - JWT secrets (generate with crypto)
   - Omise API keys (get from dashboard.omise.co)
   - OneSignal credentials (get from onesignal.com)
   - Digital Ocean Spaces credentials

### Generate JWT Secrets

```bash
# Generate secure secrets
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
```

## 🏃 Running Locally

```bash
# Development mode (with auto-reload)
npm run dev

# Production mode
npm start

# Build for production
npm run build
```

Access Strapi admin at: http://localhost:7001/admin

## 🗄️ Database Setup

### Local MySQL

```bash
# Create database
mysql -u root -p
CREATE DATABASE chongjaroen_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# Import schema (if you have a dump)
mysql -u root -p chongjaroen_dev < database_dump.sql
```

### Production (Digital Ocean Managed Database)

- Database is automatically provisioned
- Connection details provided in DO dashboard
- SSL is required for connections

## 🔑 API Endpoints

### Public Endpoints
- `POST /auth/local` - Login
- `POST /auth/local/register` - Register
- `POST /auth/forgot-password` - Password reset
- `GET /bookings` - List bookings
- `GET /menus` - List menus

### Authenticated Endpoints
- `GET /wallet/balance` - Get wallet balance
- `POST /wallet/top-up` - Top up wallet
- `POST /wallet/transfer` - Transfer funds
- `GET /wallet/transactions` - Get transaction history
- `POST /bookings` - Create booking

### Admin Endpoints
- `GET /wallet-admin/*` - Wallet administration
- `POST /admin/*` - Admin operations

Full API documentation: http://localhost:7001/documentation

## 🧪 Testing

### Test Omise Webhooks Locally

Webhooks won't work in local development (localhost isn't public). Use these alternatives:

#### Option 1: ngrok
```bash
# Install ngrok
npm install -g ngrok

# Tunnel to local backend
ngrok http 7001

# Use the ngrok URL in Omise dashboard
# https://xxxx.ngrok.io/webhooks/omise
```

#### Option 2: Wait for Production
Webhooks only fully work after deployment to Digital Ocean.

## 🚀 Deployment (Digital Ocean App Platform)

### Prerequisites
1. Digital Ocean account
2. GitHub repository
3. Managed MySQL database created
4. Spaces bucket created

### Deployment Steps

1. **Create App in DO**
   - Connect GitHub repo
   - Choose branch: `main`
   - Auto-deploy: Enabled

2. **Build Settings**
   - Build Command: `npm install && npm run build`
   - Run Command: `npm start`
   - HTTP Port: `1337`

3. **Environment Variables** (Set in DO dashboard)
   ```
   NODE_ENV=production
   HOST=0.0.0.0
   NODE_PORT=${APP_PORT}
   DATABASE_SSL=true
   [... all variables from .env.example]
   ```

4. **Database Connection**
   - Use DO Managed Database credentials
   - Enable SSL: `DATABASE_SSL=true`

5. **Custom Domain**
   - Add: `api.chongjaroen.com`
   - Configure DNS CNAME

6. **Omise Webhook Setup**
   - URL: `https://api.chongjaroen.com/webhooks/omise`
   - Events: charge.complete, charge.create, refund.create

## 🔒 Security Checklist

- [ ] `.env` is in `.gitignore` (NEVER commit)
- [ ] Strong JWT secrets generated (128 characters)
- [ ] Omise keys rotated (revoke any exposed keys)
- [ ] Database SSL enabled in production
- [ ] CORS restricted to production domains only
- [ ] Rate limiting enabled
- [ ] HTTPS enforced
- [ ] Database backups enabled

## 📊 Monitoring

### Digital Ocean Monitoring
- Enable in DO App Platform dashboard
- Monitor: CPU, Memory, Response Time
- Set up alerts for downtime

### Recommended Tools
- **Error Tracking**: Sentry
- **Uptime**: UptimeRobot
- **Logs**: Papertrail or Loggly

## 🐛 Troubleshooting

### Database Connection Errors
```
Error: ER_ACCESS_DENIED_ERROR
```
- Check DATABASE_USERNAME and DATABASE_PASSWORD
- Verify SSL settings match environment

### Omise Webhook Not Receiving
- Webhooks don't work on localhost
- Verify webhook URL in Omise dashboard
- Check IP whitelist in payment.js service

### Build Failures
```
Error: Cannot find module 'strapi'
```
- Delete node_modules
- Run `npm install` again
- Check Node.js version (must be 14.x)

## 📖 Documentation

- [Strapi Documentation](https://strapi.io/documentation/developer-docs/latest)
- [Omise API Docs](https://docs.opn.ooo/)
- [OneSignal Docs](https://documentation.onesignal.com/)
- [Digital Ocean App Platform](https://docs.digitalocean.com/products/app-platform/)

## 🤝 Contributing

1. Create feature branch (`git checkout -b feature/amazing-feature`)
2. Commit changes (`git commit -m 'Add amazing feature'`)
3. Push to branch (`git push origin feature/amazing-feature`)
4. Open Pull Request

## 📄 License

Proprietary - Chongjaroen Restaurant

## 👥 Team

- Development: Your Team Name
- Email: support@chongjaroen.com
