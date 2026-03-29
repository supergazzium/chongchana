# Staff Portal Deployment Guide

## Overview
Staff portal is a **static Nuxt.js site** that connects to the backend API.

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
   - **Type:** Static Site
   - **Source Directory:** `packages/staff`
   - **Dockerfile Path:** `packages/staff/Dockerfile`
   - **HTTP Port:** 80
   - **Build Command:** Auto-detected from Dockerfile
   - **Output Directory:** Auto-detected from Dockerfile

4. **Environment Variables**
   Add these during app creation:
   ```
   NUXT_ENV_BASE_URL=https://wallet-backend-test-pc-ndd56.ondigitalocean.app
   NODE_ENV=production
   ```

5. **App Settings**
   - **App Name:** `wallet-staff-test-pc`
   - **Region:** Singapore (sgp1)
   - **Auto-deploy:** Enabled

6. **Deploy**
   - Click "Create Resources"
   - Wait 5-10 minutes for build
   - Get your app URL: `https://wallet-staff-test-pc-xxxxx.ondigitalocean.app`

---

### Option 2: Deploy via App Spec (CLI)

```bash
# Install doctl if not already installed
brew install doctl

# Authenticate
doctl auth init

# Create app from spec
doctl apps create --spec .do/staff-app.yaml

# Monitor deployment
doctl apps list
```

---

## After Deployment

### 1. Update Backend CORS

After getting the staff URL, update backend's CORS configuration:

**In `.do/app.yaml` (backend):**
```yaml
- key: CORS_ORIGIN
  value: https://wallet-staff-test-pc-xxxxx.ondigitalocean.app,https://wallet-admin-testing-pc-j48x5.ondigitalocean.app
```

Commit and push to redeploy backend with new CORS settings.

### 2. Test Staff Portal

1. Visit your staff portal URL
2. Click "Sign In"
3. Use your staff credentials
4. Verify you can:
   - View dashboard
   - Scan QR codes (if payment QR feature is enabled)
   - Access all authorized features

---

## Architecture

```
┌─────────────────────────────────┐
│  Staff Portal (Static Site)     │
│  - Nuxt.js SSG                  │
│  - Served by Nginx              │
│  - Client-side rendering        │
└────────────┬────────────────────┘
             │
             │ API Calls
             ↓
┌─────────────────────────────────┐
│  Backend API (Strapi)           │
│  - Node.js service              │
│  - JWT Authentication           │
│  - MySQL Database               │
└─────────────────────────────────┘
```

---

## Troubleshooting

### Build Fails
- Check Node version (requires >= 14.x)
- Check if `package-lock.json` exists
- Review build logs in DO dashboard

### CORS Errors
- Verify backend CORS_ORIGIN includes staff URL
- Check browser console for exact error
- Ensure no trailing slash in URLs

### 401 Unauthorized
- Check staff signin endpoint is enabled
- Verify JWT token configuration
- Check browser cookies/localStorage for token

### Static Assets Not Loading
- Verify nginx config in Dockerfile
- Check if `dist` folder is properly copied
- Review HTTP vs HTTPS (force HTTPS if needed)

---

## File Structure

```
packages/staff/
├── Dockerfile              # Multi-stage build (Node + Nginx)
├── .env.production        # Production environment vars
├── nuxt.config.js         # Nuxt configuration
├── package.json           # Dependencies
├── pages/                 # Vue pages/routes
├── components/            # Vue components
├── plugins/               # Nuxt plugins
└── static/                # Static assets
```

---

## URLs Summary

| Service | URL |
|---------|-----|
| Backend | https://wallet-backend-test-pc-ndd56.ondigitalocean.app |
| Admin Panel | https://wallet-admin-testing-pc-j48x5.ondigitalocean.app |
| Staff Portal | https://wallet-staff-test-pc-xxxxx.ondigitalocean.app (after deployment) |

---

## Next Steps After Staff Deployment

1. ✅ Deploy staff portal
2. ✅ Update backend CORS
3. ✅ Test staff login and features
4. Consider deploying website (if needed)
5. Set up custom domains (optional)
6. Configure SSL certificates (auto by DO)
