# 🚀 START DEPLOYMENT NOW
## Step-by-Step Backend Deployment Guide

---

## ✅ Pre-Deployment Verification

All files are ready:
- ✅ `packages/backend/.env.production` - Production configuration
- ✅ `packages/admin/.env.production` - Admin configuration
- ✅ `packages/staff/.env.production` - Staff configuration
- ✅ `packages/website/.env.production` - Website configuration
- ✅ `DEPLOYMENT_SECRETS_CHECKLIST.md` - Reference guide

---

## 🎯 PHASE 1: Deploy Backend (15 minutes)

### Step 1: Access Digital Ocean App Platform
1. Open browser: https://cloud.digitalocean.com/apps
2. Click **"Create App"** button

### Step 2: Connect GitHub Repository
1. **Source**: Select **GitHub**
2. Click **"Manage Access"** if needed
3. Grant access to `chongjaroen-master` repository
4. **Repository**: Select `chongjaroen-master`
5. **Branch**: Select `main`
6. Click **"Next"**

### Step 3: Configure Backend Service
1. **Source Directory**: `packages/backend`
2. **Type**: Web Service (should auto-detect)
3. **Environment**:
   - **Build Phase**: Node.js
   - **Node Version**: `14.x` (IMPORTANT!)
4. **Build Command**:
   ```bash
   npm install && npm run build
   ```
5. **Run Command**:
   ```bash
   npm run start
   ```
6. **HTTP Port**: `8080` (IMPORTANT!)
7. **HTTP Routes**: `/`

### Step 4: Name the Service
- **Name**: `chongjaroen-backend` (or your preferred name)
- **Region**: Choose closest to your users (e.g., Singapore)

### Step 5: Set Environment Variables

Click **"Edit"** next to Environment Variables, then add these one by one:

#### Required Variables (Copy-Paste from packages/backend/.env.production):

```bash
HOST=0.0.0.0
NODE_PORT=8080
NODE_ENV=production
DATABASE_HOST=chongjaroen-mysql-prod-do-user-10174906-0.b.db.ondigitalocean.com
DATABASE_PORT=25060
DATABASE_NAME=chongjaroen
DATABASE_USERNAME=doadmin
DATABASE_PASSWORD=XZzE4SQUikOm1QJt
DATABASE_SSL=true
ADMIN_JWT_SECRET=a377f11e2f5999d1ee979b09356d42c5f7b20b7867890e33a0a019c8ad569deb32091829dfcf8b95a2c041d25c7a06aed6826cd3931b6b8e60d5172004bbed6f
JWT_SECRET=16f8f17c5aa6164582d28dd17590bfde0639bed6ba3456f3d529f51bbaa0b79af6facfafed8b0463a7ce0d6e2fd48c8f8cba2b94ea4a259ed7acacbb2cbdf40e
OMISE_SECRET_KEY=skey_672xp2hgkg0pd5tu5kn
OMISE_PUBLIC_KEY=pkey_5tuer3rmwoxiudi0d04
OMISE_PROMPT_PAY_EXPIRE=15
CORS_ORIGIN=https://localhost:8080
```

**Important Notes:**
- Mark `DATABASE_PASSWORD`, `ADMIN_JWT_SECRET`, `JWT_SECRET`, and `OMISE_SECRET_KEY` as **encrypted** (🔒)
- `CORS_ORIGIN` is temporary - will update later
- Leave optional variables empty for now (ONESIGNAL, THAIBULK, DO_SPACE)

### Step 6: Configure Resources
- **Plan**: Start with **Basic ($5/month)**
- Can upgrade to **Professional ($12/month)** later if needed
- **Instances**: 1 (can scale later)

### Step 7: Review and Deploy
1. Review all settings
2. Estimated cost: **$5/month**
3. Click **"Create Resources"**

### Step 8: Wait for Deployment
- **Initial build**: 5-10 minutes
- Watch the build logs in real-time
- Wait for status: **"Deployed"** (green checkmark)

### Step 9: Get Backend URL
1. Once deployed, click on the backend service
2. Copy the URL (looks like):
   ```
   https://chongjaroen-backend-xxxxx.ondigitalocean.app
   ```
3. **SAVE THIS URL** - You'll need it for frontend deployments

### Step 10: Test Backend
Open in browser:
```
https://chongjaroen-backend-xxxxx.ondigitalocean.app/admin
```

**Expected Result**: Should see Strapi admin login page

If you see errors, check:
- Build logs for errors
- Database connection (check credentials)
- Node version is 14.x

---

## 🎯 PHASE 2: Deploy Website (5 minutes)

### Step 1: Add Website Component
1. In DO App Platform, click **"Create"** → **"Add Component"**
2. Or create new app and repeat GitHub connection

### Step 2: Configure Website Service
1. **Source Directory**: `packages/website`
2. **Type**: Web Service
3. **Environment**: Node.js
4. **Build Command**:
   ```bash
   npm install && npm run build
   ```
5. **Run Command**:
   ```bash
   npm run start
   ```
6. **HTTP Port**: `3000`

### Step 3: Update Environment Variables
Replace backend URL with actual URL from Step 9:

```bash
BASE_URL=https://chongjaroen-backend-xxxxx.ondigitalocean.app
NODE_ENV=production
OMISE_PUBLIC_KEY=pkey_5tuer3rmwoxiudi0d04
OMISE_DEFAULT_PAYMENT_METHOD=credit_card
OMISE_OTHER_PAYMENT_METHOD=promptpay
```

### Step 4: Deploy and Save URL
1. Click **"Create Resources"**
2. Wait 3-5 minutes
3. **SAVE WEBSITE URL**: `https://chongjaroen-website-xxxxx.ondigitalocean.app`

---

## 🎯 PHASE 3: Deploy Admin (5 minutes)

### Step 1: Add Admin Component
**"Create"** → **"Add Component"**

### Step 2: Configure Admin Service
1. **Source Directory**: `packages/admin`
2. **Build Command**: `npm install && npm run build`
3. **Run Command**: `npm run start`
4. **HTTP Port**: `3000`

### Step 3: Environment Variables
```bash
BASE_URL=https://chongjaroen-backend-xxxxx.ondigitalocean.app
NODE_ENV=production
```

### Step 4: Deploy and Save URL
**SAVE ADMIN URL**: `https://chongjaroen-admin-xxxxx.ondigitalocean.app`

---

## 🎯 PHASE 4: Deploy Staff (5 minutes)

### Step 1: Add Staff Component
**"Create"** → **"Add Component"**

### Step 2: Configure Staff Service
1. **Source Directory**: `packages/staff`
2. **Type**: **Static Site** (Important!)
3. **Build Command**: `npm install && npm run build`
4. **Output Directory**: `dist`

### Step 3: Environment Variables
```bash
NUXT_ENV_BASE_URL=https://chongjaroen-backend-xxxxx.ondigitalocean.app
NODE_ENV=production
```

### Step 4: Deploy and Save URL
**SAVE STAFF URL**: `https://chongjaroen-staff-xxxxx.ondigitalocean.app`

---

## 🎯 PHASE 5: Update Backend CORS (2 minutes)

### Step 1: Go to Backend Settings
1. Click on **Backend Service**
2. Go to **Settings** → **Environment Variables**

### Step 2: Update CORS_ORIGIN
Replace with all three frontend URLs (comma-separated, no spaces):

```bash
CORS_ORIGIN=https://chongjaroen-admin-xxxxx.ondigitalocean.app,https://chongjaroen-staff-xxxxx.ondigitalocean.app,https://chongjaroen-website-xxxxx.ondigitalocean.app
```

### Step 3: Update WEBSITE_ENDPOINT_URL
Add new variable:
```bash
WEBSITE_ENDPOINT_URL=https://chongjaroen-website-xxxxx.ondigitalocean.app
```

### Step 4: Redeploy Backend
Click **"Save"** → Backend will automatically redeploy (~2 minutes)

---

## ✅ PHASE 6: Final Testing (3 minutes)

### Test Backend
```bash
curl https://chongjaroen-backend-xxxxx.ondigitalocean.app/admin
# Should return Strapi admin page HTML
```

### Test Website
1. Open: `https://chongjaroen-website-xxxxx.ondigitalocean.app`
2. Try login with test credentials:
   - Email: `test@test.com`
   - Password: `test123`
3. Check browser console - should have NO CORS errors

### Test Admin
1. Open: `https://chongjaroen-admin-xxxxx.ondigitalocean.app`
2. Should load admin panel
3. Try connecting to backend

### Test Staff
1. Open: `https://chongjaroen-staff-xxxxx.ondigitalocean.app`
2. Should load staff panel
3. Try QR scanning features

---

## 📝 Record Your URLs

After deployment, save these URLs:

```
BACKEND: https://chongjaroen-backend-_____.ondigitalocean.app
WEBSITE: https://chongjaroen-website-_____.ondigitalocean.app
ADMIN:   https://chongjaroen-admin-_____.ondigitalocean.app
STAFF:   https://chongjaroen-staff-_____.ondigitalocean.app
```

---

## 🆘 Common Issues & Solutions

### Issue: Build Fails with "Node version not supported"
**Solution:**
- Edit service → Build & Deploy
- Change Node version to exactly `14.x`
- Redeploy

### Issue: "Cannot connect to database"
**Solution:**
- Verify `DATABASE_SSL=true`
- Check database credentials match exactly
- Verify database is running in DO

### Issue: "502 Bad Gateway"
**Solution:**
- Check service logs (Runtime Logs tab)
- Verify `NODE_PORT=8080` for backend
- Ensure service is running

### Issue: CORS errors in browser
**Solution:**
- Check `CORS_ORIGIN` has exact URLs (no trailing /)
- Verify all three frontend URLs are included
- Redeploy backend after updating CORS

### Issue: Omise payment not working
**Solution:**
- Verify you're using LIVE keys (not test keys)
- Check keys match in Omise dashboard
- Verify `OMISE_PUBLIC_KEY` on frontend matches backend

---

## 🎉 Deployment Complete!

**Total Time:** ~30 minutes
**Total Cost:** ~$18/month

### What's Next?

1. **Set up Strapi Admin User**
   - Visit: `https://chongjaroen-backend-xxxxx.ondigitalocean.app/admin`
   - Create admin account
   - Configure permissions

2. **Test All Features**
   - User registration/login
   - Booking system
   - Payment with Omise
   - Admin panel operations
   - Staff QR scanning

3. **Optional: Custom Domains**
   - Add custom domains in DO App Platform
   - Update DNS records
   - Update CORS with custom domains

4. **Monitor & Maintain**
   - Set up alerts in DO dashboard
   - Monitor error rates
   - Check performance metrics

---

## 📞 Need Help?

- **Deployment Issues**: Check logs in DO App Platform
- **CORS Errors**: Refer to `DEPLOYMENT_SECRETS_CHECKLIST.md`
- **General Questions**: Review `DO_DEPLOYMENT_PLAN.md`

---

**Ready to deploy?** Start with Phase 1 above! 🚀

**Last Updated**: 2026-03-28
**Status**: Ready for deployment
