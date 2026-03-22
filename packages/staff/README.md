# Chongjaroen Staff Portal

Staff portal for restaurant operations and customer service.

## Features

- Order management
- Table management
- Customer check-in
- QR code scanning
- Payment processing
- Real-time updates
- Shift management

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

Access at: http://localhost:3001

## Environment Variables

```bash
BASE_URL=http://localhost:7001
STAFF_URL=http://localhost:3001
NODE_ENV=development
```

## Deployment (Digital Ocean)

- Build: `npm install && npm run build`
- Run: `npm start`
- Domain: `staff.chongjaroen.com`

Environment in DO:
```
BASE_URL=https://api.chongjaroen.com
STAFF_URL=https://staff.chongjaroen.com
NODE_ENV=production
```

## Access Control

Restricted to staff users only. Role-based permissions with activity logging.
