# Chongjaroen Admin Portal

Admin dashboard for managing Chongjaroen restaurant operations.

## Features

- User management
- Booking management  
- Menu & content management
- Wallet administration
- Transaction monitoring
- Settings & configuration
- Analytics & reports

## Tech Stack

- Nuxt.js 2.x
- Bootstrap 5
- Vuex
- @nuxtjs/auth-next

## Quick Start

```bash
npm install
cp .env.example .env
npm run dev
```

Access at: http://localhost:4040

## Environment Variables

```bash
BASE_URL=http://localhost:7001
ADMIN_URL=http://localhost:4040
NODE_ENV=development
```

## Deployment (Digital Ocean)

- Build: `npm install && npm run build`
- Run: `npm start`
- Domain: `admin.chongjaroen.com`

Environment in DO:
```
BASE_URL=https://api.chongjaroen.com
ADMIN_URL=https://admin.chongjaroen.com
NODE_ENV=production
```

## Access Control

Restricted to admin users only. Multi-level permissions with audit logging.
