# Chongjaroen Website

Customer-facing website for Chongjaroen restaurant, built with Nuxt.js.

## 🚀 Features

- **User Authentication** - Login, registration, password reset
- **Profile Management** - Update personal information, change password
- **Digital Wallet** - View balance, top-up, make payments, transfer funds
- **Booking System** - Reserve tables, view booking history
- **Menu Browsing** - View restaurant menu with images
- **Responsive Design** - Mobile-first, works on all devices

## 🛠️ Tech Stack

- **Framework**: Nuxt.js 2.x (Vue.js)
- **UI**: Bootstrap 5 + Custom SCSS
- **State Management**: Vuex
- **Authentication**: @nuxtjs/auth-next
- **HTTP Client**: @nuxtjs/axios

## 📋 Prerequisites

- Node.js 14.x or higher
- npm or yarn

## 🔧 Installation

```bash
# Clone repository
git clone git@github.com:your-username/chongjaroen-website.git
cd chongjaroen-website

# Install dependencies
npm install

# Copy environment variables
cp .env.example .env

# Start development server
npm run dev
```

## 📝 Environment Setup

Create `.env` file:

```bash
BASE_URL=http://localhost:7001
WEBSITE_URL=http://localhost:8080
NODE_ENV=development
```

Production:
```bash
BASE_URL=https://api.chongjaroen.com
WEBSITE_URL=https://chongjaroen.com
NODE_ENV=production
```

## 🏃 Running Locally

```bash
# Development mode (with hot-reload)
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Generate static site
npm run generate
```

Access at: http://localhost:8080

## 📂 Project Structure

```
chongjaroen-website/
├── assets/           # SCSS, images, fonts
├── components/       # Vue components
│   ├── dashboard/    # Account settings components
│   └── wallet/       # Wallet-related components
├── layouts/          # Page layouts
├── pages/            # Application pages/routes
│   ├── account/      # User account pages
│   │   ├── wallet.vue
│   │   ├── name.vue
│   │   └── email.vue
│   ├── booking/      # Booking pages
│   └── index.vue     # Homepage
├── plugins/          # Nuxt plugins
│   └── mixins.js     # Global methods (wallet API calls)
├── static/           # Static files (favicon, images)
├── store/            # Vuex store
└── nuxt.config.js    # Nuxt configuration
```

## 🔑 Key Features Implemented

### Wallet Management
- View current balance
- Top-up via Omise (Credit Card, PromptPay, Mobile Banking)
- Transfer funds to other users
- Transaction history with pagination
- Real-time balance updates

### Security Features
- XSS protection (no v-html with user data)
- CSRF protection
- JWT token authentication
- Secure payment tokenization

### UX Enhancements
- Professional gradient wallet cards
- Smooth animations and transitions
- Loading states and error handling
- Responsive mobile design

## 🚀 Deployment (Digital Ocean)

### Build Configuration

**Build Command:**
```bash
npm install && npm run build
```

**Run Command:**
```bash
npm start
```

**Port:** `3000` (or `${APP_PORT}`)

### Environment Variables (Set in DO)

| Variable | Value |
|----------|-------|
| `BASE_URL` | `https://api.chongjaroen.com` |
| `WEBSITE_URL` | `https://chongjaroen.com` |
| `NODE_ENV` | `production` |

### Custom Domain

- Domain: `chongjaroen.com`
- Or: `www.chongjaroen.com`

## 🧪 Testing

### Test Wallet Features
```bash
# 1. Start backend
cd ../backend && npm run dev

# 2. Start website
npm run dev

# 3. Test flows:
# - Register new account
# - Login
# - View wallet balance
# - Navigate through account settings
# - Check transaction history
```

## 🔒 Security Notes

### Authentication
- Uses `@nuxtjs/auth-next` with `global: false`
- Manually attaches JWT tokens to API requests
- Token refresh on expiration

### XSS Prevention
- All user data rendered with `{{ }}` (not `v-html`)
- Toast notifications use DOM API (not innerHTML)
- Form inputs sanitized

## 📱 Mobile App Deep Links

The website supports deep linking from the mobile app:

**iOS:**
```
chongchana://chongjaroen.com/account/wallet
```

**Android:**
```
intent://chongjaroen.com/account/wallet#Intent;scheme=https;end
```

## 🐛 Common Issues

### API Connection Errors
```
Error: Network Error
```
- Check BASE_URL is correct
- Verify backend is running
- Check CORS settings in backend

### Authentication Issues
```
Error: 401 Unauthorized
```
- JWT token may be expired
- Check Authorization header is being sent
- Verify token in localStorage

### Build Failures
```
ERROR: Cannot find module '@nuxtjs/auth-next'
```
- Delete `node_modules` and `.nuxt`
- Run `npm install` again

## 📖 Documentation

- [Nuxt.js Documentation](https://nuxtjs.org/docs)
- [Vue.js Guide](https://vuejs.org/guide/)
- [@nuxtjs/auth-next](https://auth.nuxtjs.org/)

## 🤝 Contributing

1. Create feature branch
2. Make changes
3. Test thoroughly
4. Submit pull request

## 📄 License

Proprietary - Chongjaroen Restaurant
