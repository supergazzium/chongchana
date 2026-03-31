# Digital Ocean App Platform Deployment Plan
## Chongjaroen Restaurant Project

---

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture Design](#architecture-design)
3. [Service Breakdown](#service-breakdown)
4. [Deployment Steps](#deployment-steps)
5. [Environment Variables](#environment-variables)
6. [Cost Estimation](#cost-estimation)
7. [Post-Deployment Tasks](#post-deployment-tasks)

---

## 🎯 Project Overview

**Current Setup:**
- **Backend**: Strapi 3.6.8 (Node 14.x)
- **Admin**: Nuxt SSR (Node >=14.x)
- **Staff**: Nuxt SSG (Node >=14.x)
- **Website**: Nuxt SSR (Node >=14.x)
- **Database**: MySQL on Digital Ocean (already deployed)

**Goal:** Deploy all services to Digital Ocean App Platform with proper inter-service communication and production configurations.

---

## 🏗️ Architecture Design

```
┌─────────────────────────────────────────────────────────┐
│                   Digital Ocean                         │
│                                                          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐       │
│  │  Website   │  │   Admin    │  │   Staff    │       │
│  │  (Nuxt)    │  │  (Nuxt)    │  │  (Nuxt)    │       │
│  │   SSR      │  │   SSR      │  │   Static   │       │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘       │
│        │               │               │               │
│        └───────────────┼───────────────┘               │
│                        │                               │
│                  ┌─────▼──────┐                        │
│                  │  Backend   │                        │
│                  │  (Strapi)  │                        │
│                  │   Node 14  │                        │
│                  └─────┬──────┘                        │
│                        │                               │
│                  ┌─────▼──────┐                        │
│                  │   MySQL    │                        │
│                  │  Database  │                        │
│                  │ (existing) │                        │
│                  └────────────┘                        │
└─────────────────────────────────────────────────────────┘
```

---

## 📦 Service Breakdown

### 1. Backend Service (Strapi API)
- **Type**: Web Service
- **Environment**: Node 14.x
- **Build Command**: `npm install && npm run build`
- **Start Command**: `npm run start`
- **Port**: 8080 (App Platform default)
- **Health Check**: `/_health` or `/admin`
- **Resource**: Basic ($5/month) or Professional ($12/month)

### 2. Admin Service (Nuxt SSR)
- **Type**: Web Service
- **Environment**: Node 14.x+
- **Build Command**: `npm install && npm run build`
- **Start Command**: `npm run start`
- **Port**: 3000 (default)
- **Resource**: Basic ($5/month)

### 3. Staff Service (Nuxt Static)
- **Type**: Static Site
- **Environment**: Node 14.x+
- **Build Command**: `npm install && npm run build`
- **Output Directory**: `dist`
- **Resource**: Static Site ($3/month or free with Basic plan)

### 4. Website Service (Nuxt SSR)
- **Type**: Web Service
- **Environment**: Node 14.x+
- **Build Command**: `npm install && npm run build`
- **Start Command**: `npm run start`
- **Port**: 3000 (default)
- **Resource**: Basic ($5/month) or Professional ($12/month)

---

## 🚀 Deployment Steps

### Phase 1: Preparation (Local)

#### Step 1.1: Update Node Version Constraints
The backend requires Node 14.x but npm 8 requires Node >=12. Update `packages/backend/package.json`:

```json
"engines": {
  "node": "14.x",
  "npm": ">=6.x"
}
```

#### Step 1.2: Create Production Environment Files
Create `.env.production` files for each service:

**Backend** (`packages/backend/.env.production`):
```bash
# Already exists - verify these settings:
DATABASE_HOST=chongjaroen-mysql-prod-do-user-10174906-0.b.db.ondigitalocean.com
DATABASE_PORT=25060
DATABASE_NAME=chongjaroen
DATABASE_USERNAME=doadmin
DATABASE_PASSWORD=XZzE4SQUikOm1QJt
DATABASE_SSL=true

# Will be added after deployment:
HOST=0.0.0.0
NODE_PORT=8080
CORS_ORIGIN=https://admin-xxxxx.ondigitalocean.app,https://staff-xxxxx.ondigitalocean.app,https://website-xxxxx.ondigitalocean.app,https://yourdomain.com
```

**Admin** (`packages/admin/.env.production`):
```bash
BASE_URL=https://backend-xxxxx.ondigitalocean.app
```

**Staff** (`packages/staff/.env.production`):
```bash
BASE_URL=https://backend-xxxxx.ondigitalocean.app
```

**Website** (`packages/website/.env.production`):
```bash
BASE_URL=https://backend-xxxxx.ondigitalocean.app
OMISE_PUBLIC_KEY=pkey_5tuer3rmwoxiudi0d04
```

#### Step 1.3: Verify Build Scripts
Ensure all packages have correct build scripts in `package.json`:

- Backend: `"build": "strapi build"`
- Admin: `"build": "nuxt build"`
- Staff: `"build": "nuxt generate"`
- Website: `"build": "nuxt build"`

#### Step 1.4: Add Health Check Endpoint (Backend)
Strapi already has `/admin` endpoint. No action needed.

---

### Phase 2: Deploy Backend (First)

#### Step 2.1: Create Backend App
1. Go to Digital Ocean App Platform
2. Click **"Create App"**
3. Select **GitHub** as source
4. Choose repository: `chongjaroen-master`
5. Select branch: `main`
6. **Source Directory**: `packages/backend`

#### Step 2.2: Configure Backend Service
- **Name**: `chongjaroen-backend`
- **Environment**:
  - **Node Version**: 14.x
- **Build Command**:
  ```bash
  npm install && npm run build
  ```
- **Run Command**:
  ```bash
  npm run start
  ```
- **HTTP Port**: 8080
- **Routes**: `/`
- **Health Check**:
  - Path: `/admin`
  - Success Code: `200`, `302`, `307`

#### Step 2.3: Configure Backend Environment Variables
Add these as encrypted environment variables:

```bash
# Server Config
HOST=0.0.0.0
NODE_PORT=8080
NODE_ENV=production

# Database (from .env.production)
DATABASE_HOST=chongjaroen-mysql-prod-do-user-10174906-0.b.db.ondigitalocean.com
DATABASE_PORT=25060
DATABASE_NAME=chongjaroen
DATABASE_USERNAME=doadmin
DATABASE_PASSWORD=${DATABASE_PASSWORD}  # Use encrypted value
DATABASE_SSL=true

# JWT Secrets (from local .env)
ADMIN_JWT_SECRET=${ADMIN_JWT_SECRET}
JWT_SECRET=${JWT_SECRET}

# Omise (from local .env)
OMISE_SECRET_KEY=${OMISE_SECRET_KEY}
OMISE_PUBLIC_KEY=${OMISE_PUBLIC_KEY}

# Digital Ocean Spaces (if using)
DO_SPACE_ACCESS_KEY=${DO_SPACE_ACCESS_KEY}
DO_SPACE_SECRET_KEY=${DO_SPACE_SECRET_KEY}
DO_SPACE_ENDPOINT=${DO_SPACE_ENDPOINT}
DO_SPACE_BUCKET=${DO_SPACE_BUCKET}
DO_SPACE_CDN=${DO_SPACE_CDN}

# CORS - UPDATE AFTER FRONTEND DEPLOYMENTS
CORS_ORIGIN=https://admin-xxxxx.ondigitalocean.app,https://staff-xxxxx.ondigitalocean.app,https://website-xxxxx.ondigitalocean.app

# Optional
BASIC_AUTHORIZATION=${BASIC_AUTHORIZATION}
ONESIGNAL_APP_ID=${ONESIGNAL_APP_ID}
ONESIGNAL_API_KEY=${ONESIGNAL_API_KEY}
```

#### Step 2.4: Deploy Backend
1. Click **"Create Resources"**
2. Wait for build and deployment (~5-10 minutes)
3. **Save the backend URL**: `https://chongjaroen-backend-xxxxx.ondigitalocean.app`

#### Step 2.5: Test Backend
```bash
curl https://chongjaroen-backend-xxxxx.ondigitalocean.app/admin
# Should return Strapi admin login page
```

---

### Phase 3: Deploy Admin Panel

#### Step 3.1: Create Admin App
1. Click **"Create App"** (or add component to existing app)
2. Select **GitHub** as source
3. Choose repository: `chongjaroen-master`
4. **Source Directory**: `packages/admin`

#### Step 3.2: Configure Admin Service
- **Name**: `chongjaroen-admin`
- **Environment**: Node 14.x+
- **Build Command**:
  ```bash
  npm install && npm run build
  ```
- **Run Command**:
  ```bash
  npm run start
  ```
- **HTTP Port**: 3000

#### Step 3.3: Configure Admin Environment Variables
```bash
BASE_URL=https://chongjaroen-backend-xxxxx.ondigitalocean.app
NODE_ENV=production
```

#### Step 3.4: Deploy and Save URL
Save URL: `https://chongjaroen-admin-xxxxx.ondigitalocean.app`

---

### Phase 4: Deploy Staff Panel

#### Step 4.1: Create Staff App
1. Click **"Create App"** or add component
2. **Source Directory**: `packages/staff`

#### Step 4.2: Configure Staff Service
- **Name**: `chongjaroen-staff`
- **Type**: **Static Site**
- **Environment**: Node 14.x+
- **Build Command**:
  ```bash
  npm install && npm run build
  ```
- **Output Directory**: `dist`

#### Step 4.3: Configure Staff Environment Variables
```bash
BASE_URL=https://chongjaroen-backend-xxxxx.ondigitalocean.app
NODE_ENV=production
```

#### Step 4.4: Deploy and Save URL
Save URL: `https://chongjaroen-staff-xxxxx.ondigitalocean.app`

---

### Phase 5: Deploy Website

#### Step 5.1: Create Website App
1. Click **"Create App"** or add component
2. **Source Directory**: `packages/website`

#### Step 5.2: Configure Website Service
- **Name**: `chongjaroen-website`
- **Environment**: Node 14.x+
- **Build Command**:
  ```bash
  npm install && npm run build
  ```
- **Run Command**:
  ```bash
  npm run start
  ```
- **HTTP Port**: 3000

#### Step 5.3: Configure Website Environment Variables
```bash
BASE_URL=https://chongjaroen-backend-xxxxx.ondigitalocean.app
OMISE_PUBLIC_KEY=pkey_5tuer3rmwoxiudi0d04
NODE_ENV=production
```

#### Step 5.4: Deploy and Save URL
Save URL: `https://chongjaroen-website-xxxxx.ondigitalocean.app`

---

### Phase 6: Update CORS Configuration

#### Step 6.1: Update Backend CORS
1. Go to backend app settings
2. Update `CORS_ORIGIN` environment variable:
```bash
CORS_ORIGIN=https://chongjaroen-admin-xxxxx.ondigitalocean.app,https://chongjaroen-staff-xxxxx.ondigitalocean.app,https://chongjaroen-website-xxxxx.ondigitalocean.app
```
3. Redeploy backend

#### Step 6.2: Test CORS
```bash
curl -H "Origin: https://chongjaroen-website-xxxxx.ondigitalocean.app" \
     -I https://chongjaroen-backend-xxxxx.ondigitalocean.app/api/app-init
# Should include Access-Control-Allow-Origin header
```

---

## 🔐 Environment Variables Reference

### Backend (.env)
```bash
# ===== Server Configuration =====
HOST=0.0.0.0
NODE_PORT=8080
NODE_ENV=production

# ===== Database (Production) =====
DATABASE_HOST=chongjaroen-mysql-prod-do-user-10174906-0.b.db.ondigitalocean.com
DATABASE_PORT=25060
DATABASE_NAME=chongjaroen
DATABASE_USERNAME=doadmin
DATABASE_PASSWORD=<from-local-env>
DATABASE_SSL=true

# ===== Security Secrets =====
ADMIN_JWT_SECRET=<from-local-env>
JWT_SECRET=<from-local-env>
BASIC_AUTHORIZATION=<from-local-env>

# ===== CORS (Update with actual URLs) =====
CORS_ORIGIN=https://admin.yourdomain.com,https://staff.yourdomain.com,https://yourdomain.com

# ===== Payment Gateway (Omise) =====
OMISE_SECRET_KEY=<from-local-env>
OMISE_PUBLIC_KEY=<from-local-env>
OMISE_PROMPT_PAY_EXPIRE=15

# ===== Digital Ocean Spaces (File Storage) =====
DO_SPACE_ACCESS_KEY=<if-using>
DO_SPACE_SECRET_KEY=<if-using>
DO_SPACE_ENDPOINT=<if-using>
DO_SPACE_BUCKET=<if-using>
DO_SPACE_DIRECTORY=<if-using>
DO_SPACE_CDN=<if-using>

# ===== Push Notifications (Optional) =====
ONESIGNAL_APP_ID=<if-using>
ONESIGNAL_API_KEY=<if-using>

# ===== SMS (Optional) =====
THAIBULK_OTP_ENPOINT=<if-using>
THAIBULK_API_KEY=<if-using>
THAIBULK_API_SECRET=<if-using>
```

### Admin (.env)
```bash
BASE_URL=https://chongjaroen-backend-xxxxx.ondigitalocean.app
NODE_ENV=production
```

### Staff (.env)
```bash
BASE_URL=https://chongjaroen-backend-xxxxx.ondigitalocean.app
NODE_ENV=production
```

### Website (.env)
```bash
BASE_URL=https://chongjaroen-backend-xxxxx.ondigitalocean.app
OMISE_PUBLIC_KEY=pkey_5tuer3rmwoxiudi0d04
OMISE_DEFAULT_PAYMENT_METHOD=credit_card
OMISE_OTHER_PAYMENT_METHOD=promptpay
GTM_ID=<if-using>
NODE_ENV=production
```

---

## 💰 Cost Estimation

### Option 1: Individual Apps (Simple Setup)
| Service | Type | Tier | Cost/Month |
|---------|------|------|------------|
| Backend | Web Service | Basic | $5 |
| Admin | Web Service | Basic | $5 |
| Staff | Static Site | Starter | $3 |
| Website | Web Service | Basic | $5 |
| **Total** | | | **$18/month** |

### Option 2: Monorepo App (Recommended)
| Service | Type | Tier | Cost/Month |
|---------|------|------|------------|
| Monorepo (all services) | App | 4 components | $5 × 3 + $3 × 1 = $18 |
| **Total** | | | **$18/month** |

### Option 3: With Custom Domains
| Item | Cost/Month |
|------|------------|
| Services (from above) | $18 |
| SSL Certificates | Free (Let's Encrypt) |
| Domain (if new) | ~$1-2/month |
| **Total** | **$19-20/month** |

**Notes:**
- Database is already deployed (cost not included)
- All tiers include SSL certificates
- Bandwidth: 1TB included per app
- Professional tier ($12/month) recommended for backend if traffic is high

---

## ✅ Post-Deployment Tasks

### 1. Domain Configuration
After deployment, configure custom domains:

**Backend:**
- Domain: `api.yourdomain.com`
- Update CORS to include custom domains

**Admin:**
- Domain: `admin.yourdomain.com`

**Staff:**
- Domain: `staff.yourdomain.com`

**Website:**
- Domain: `www.yourdomain.com` or `yourdomain.com`

### 2. Test All Endpoints

```bash
# Backend API
curl https://api.yourdomain.com/api/app-init

# Admin Panel
curl https://admin.yourdomain.com

# Staff Panel
curl https://staff.yourdomain.com

# Website
curl https://yourdomain.com
```

### 3. Update Strapi Admin User
1. Visit `https://api.yourdomain.com/admin`
2. Create admin user or update password
3. Configure roles and permissions

### 4. Configure File Uploads
If using Digital Ocean Spaces for file uploads:
1. Create a Space in DO
2. Generate API keys
3. Update backend environment variables
4. Test file upload functionality

### 5. Set Up Monitoring
- Enable App Platform metrics
- Set up alerts for:
  - CPU usage > 80%
  - Memory usage > 80%
  - Response time > 2s
  - Error rate > 1%

### 6. Database Backups
Verify automatic backups are enabled for MySQL database:
- Daily snapshots
- 7-day retention

### 7. Security Hardening
- [ ] Verify all secrets are encrypted
- [ ] Enable 2FA on Strapi admin
- [ ] Review CORS configuration
- [ ] Check rate limiting settings
- [ ] Verify SSL/TLS configuration

### 8. Performance Optimization
- [ ] Enable caching headers
- [ ] Configure CDN for static assets
- [ ] Optimize database queries
- [ ] Set up Redis for sessions (optional)

---

## 🔧 Troubleshooting

### Build Failures

**Issue**: Node version mismatch
```bash
# Solution: Update package.json engines
"engines": {
  "node": "14.x"
}
```

**Issue**: Build timeout
```bash
# Solution: Increase build timeout in App Platform settings
# Or optimize build process (remove unused dependencies)
```

### CORS Errors

**Issue**: Frontend can't connect to backend
```bash
# Solution: Update backend CORS_ORIGIN with exact frontend URLs
# Include both .ondigitalocean.app and custom domains
```

### Database Connection Errors

**Issue**: Cannot connect to MySQL
```bash
# Solution: Verify DATABASE_SSL=true
# Check database credentials
# Verify database firewall allows App Platform IPs
```

### Memory Issues

**Issue**: Backend crashes due to OOM
```bash
# Solution: Upgrade to Professional tier ($12/month)
# Or optimize memory usage in Strapi
# Add NODE_OPTIONS="--max-old-space-size=896"
```

---

## 📚 Additional Resources

- [Digital Ocean App Platform Docs](https://docs.digitalocean.com/products/app-platform/)
- [Strapi Deployment Guide](https://docs.strapi.io/dev-docs/deployment)
- [Nuxt.js Deployment](https://nuxtjs.org/deployments/digitalocean)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)

---

## 🎯 Quick Start Checklist

- [ ] Review current environment variables (local .env files)
- [ ] Update Node version constraints in package.json
- [ ] Deploy backend first
- [ ] Save backend URL
- [ ] Deploy admin with backend URL
- [ ] Deploy staff with backend URL
- [ ] Deploy website with backend URL
- [ ] Update backend CORS with all frontend URLs
- [ ] Test all services
- [ ] Configure custom domains (optional)
- [ ] Set up monitoring and alerts
- [ ] Enable database backups verification
- [ ] Document deployment URLs and credentials

---

**Last Updated**: 2026-03-28
**Author**: Claude Code
**Version**: 1.0
