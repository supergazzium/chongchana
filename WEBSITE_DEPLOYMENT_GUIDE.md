# Website Deployment Guide

## Overview
Website is a **Nuxt.js SSR (Server-Side Rendering)** application that runs on Node.js.

## Pre-requisites
✅ Backend already deployed at: `https://wallet-backend-test-pc-ndd56.ondigitalocean.app`

## Deployment Steps

### Option 1: Deploy via Digital Ocean Dashboard (Recommended)

1. **Go to Digital Ocean Apps**
   - Visit: https://cloud.digitalocean.com/apps

2. **Create New App**
   - Click "Create App"
   - Choose "GitHub" as source
   - Select repository: `supergazzium/chongchana`
   - Branch: `main`

3. **Configure Build Settings**
   - **Type:** Web Service (NOT Static Site!)
   - **Source Directory:** `packages/website`
   - **Dockerfile Path:** `packages/website/Dockerfile`
   - **HTTP Port:** 8080
   - **Build Command:** Auto-detected from Dockerfile
   - **Run Command:** Auto-detected from Dockerfile

4. **Environment Variables** (Build Time)
   Add these during app creation:
   ```
   BASE_URL=https://wallet-backend-test-pc-ndd56.ondigitalocean.app
   NODE_ENV=production
   OMISE_PUBLIC_KEY=pkey_5tuer3rmwoxiudi0d04
   OMISE_DEFAULT_PAYMENT_METHOD=credit_card
   OMISE_OTHER_PAYMENT_METHOD=promptpay
   GTM_ID=
   ```

   **Important:** Set all to **BUILD_TIME** scope!

5. **App Settings**
   - **App Name:** `wallet-website-test-pc`
   - **Region:** Singapore (sgp1)
   - **Instance Size:** Basic (1 vCPU, 512 MB RAM)
   - **Auto-deploy:** Enabled

6. **Deploy**
   - Click "Create Resources"
   - Wait 5-10 minutes for build
   - Get your app URL: `https://wallet-website-test-pc-xxxxx.ondigitalocean.app`

---

### Option 2: Deploy via App Spec (CLI)

```bash
# Install doctl if not already installed
brew install doctl

# Authenticate
doctl auth init

# Create app from spec
doctl apps create --spec .do/website-app.yaml

# Monitor deployment
doctl apps list
```

---

## After Deployment

### 1. Update Backend CORS

After getting the website URL, update backend's CORS configuration:

**In `.do/app.yaml` (backend):**
```yaml
- key: CORS_ORIGIN
  value: https://wallet-admin-testing-pc-j48x5.ondigitalocean.app,https://wallet-staff-testing-pc-b9lkt.ondigitalocean.app,https://wallet-website-test-pc-xxxxx.ondigitalocean.app
```

Commit and push to redeploy backend with new CORS settings.

### 2. Test Website

1. Visit your website URL
2. Browse the public pages
3. Try user registration/login
4. Test wallet features (top-up, payments, etc.)
5. Verify Omise payment integration works

---

## Architecture

```
┌─────────────────────────────────┐
│  Website (SSR - Nuxt.js)        │
│  - Node.js server               │
│  - Server-side rendering        │
│  - Port 8080                    │
└────────────┬────────────────────┘
             │
             │ API calls
             ↓
┌─────────────────────────────────┐
│  Backend API (Strapi)           │
│  - Node.js service              │
│  - JWT Authentication           │
│  - MySQL Database               │
└─────────────────────────────────┘
```

---

## Key Differences from Staff Portal

| Feature | Staff Portal | Website |
|---------|-------------|---------|
| Type | Static Site (SSG) | Server-Side Rendered (SSR) |
| Server | Nginx | Node.js |
| Build | `nuxt generate` | `nuxt build` |
| Start | N/A (static) | `nuxt start` |
| Port | 80 | 8080 |
| Memory | 512 MB | 512 MB |

---

## Troubleshooting

### Build Fails
- Check Node version (requires >= 14.x)
- Check if `package-lock.json` exists
- Review build logs in DO dashboard
- Verify all environment variables are set to BUILD_TIME

### CORS Errors
- Verify backend CORS_ORIGIN includes website URL
- Check browser console for exact error
- Ensure no trailing slash in URLs

### 401 Unauthorized
- Check auth endpoints in nuxt.config.js
- Verify JWT token configuration
- Check browser cookies for token

### Omise Payment Issues
- Verify `OMISE_PUBLIC_KEY` is correct (starts with `pkey_`)
- Check if using LIVE key vs TEST key
- Test key: `pkey_test_xxxxx`
- Live key: `pkey_xxxxx`
- Ensure PUBLIC key (not secret key) is used in frontend

### SSR Errors
- Check server logs in DO dashboard
- Verify all required pages/components exist
- Check for client-only code running on server
- Ensure `process.browser` checks where needed

---

## Environment Variables Summary

| Variable | Description | Example |
|----------|-------------|---------|
| `BASE_URL` | Backend API URL | `https://wallet-backend-test-pc-ndd56.ondigitalocean.app` |
| `NODE_ENV` | Environment | `production` |
| `OMISE_PUBLIC_KEY` | Omise public key | `pkey_5tuer3rmwoxiudi0d04` |
| `OMISE_DEFAULT_PAYMENT_METHOD` | Default payment | `credit_card` |
| `OMISE_OTHER_PAYMENT_METHOD` | Other payment | `promptpay` |
| `GTM_ID` | Google Tag Manager | (optional) |

**All must be set to BUILD_TIME scope!**

---

## Security Notes

- ✅ Only OMISE_PUBLIC_KEY is exposed (safe for frontend)
- ❌ OMISE_SECRET_KEY stays on backend only
- ✅ Test keys vs Live keys have different prefixes
- ✅ All secrets encrypted by Digital Ocean

---

## URLs Summary

| Service | URL |
|---------|-----|
| Backend | https://wallet-backend-test-pc-ndd56.ondigitalocean.app |
| Admin Panel | https://wallet-admin-testing-pc-j48x5.ondigitalocean.app |
| Staff Portal | https://wallet-staff-testing-pc-b9lkt.ondigitalocean.app |
| Website | https://wallet-website-test-pc-xxxxx.ondigitalocean.app (after deployment) |

---

## Next Steps After Website Deployment

1. ✅ Deploy website
2. ✅ Update backend CORS
3. ✅ Test website features
4. Consider setting up custom domain
5. Configure SSL certificates (auto by DO)
6. Set up monitoring and alerts
