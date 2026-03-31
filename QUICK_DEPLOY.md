# Quick Deployment Guide
## Digital Ocean App Platform - Chongjaroen Project

---

## 🚀 Deploy in 30 Minutes

### Prerequisites
- [ ] GitHub repository access
- [ ] Digital Ocean account
- [ ] MySQL database already running on DO
- [ ] Local `.env` files with secrets

---

## Step-by-Step Deployment

### 1️⃣ Deploy Backend (10 minutes)

1. **Create App**: DO Dashboard → App Platform → Create App
2. **Connect GitHub**: Select `chongjaroen-master` repo
3. **Configure**:
   - Source Directory: `packages/backend`
   - Build Command: `npm install && npm run build`
   - Run Command: `npm run start`
   - HTTP Port: `8080`
   - Node Version: `14.x`

4. **Environment Variables** (copy from local `.env`):
   ```bash
   HOST=0.0.0.0
   NODE_PORT=8080
   NODE_ENV=production
   DATABASE_HOST=chongjaroen-mysql-prod-do-user-10174906-0.b.db.ondigitalocean.com
   DATABASE_PORT=25060
   DATABASE_NAME=chongjaroen
   DATABASE_USERNAME=doadmin
   DATABASE_PASSWORD=<from-local>
   DATABASE_SSL=true
   ADMIN_JWT_SECRET=<from-local>
   JWT_SECRET=<from-local>
   OMISE_SECRET_KEY=<from-local>
   OMISE_PUBLIC_KEY=<from-local>
   CORS_ORIGIN=https://localhost:3000
   ```

5. **Deploy** → Wait 5-10 minutes
6. **Save URL**: `https://chongjaroen-backend-xxxxx.ondigitalocean.app`

---

### 2️⃣ Deploy Website (5 minutes)

1. **Add Component** to existing app
2. **Configure**:
   - Source Directory: `packages/website`
   - Build Command: `npm install && npm run build`
   - Run Command: `npm run start`
   - HTTP Port: `3000`

3. **Environment Variables**:
   ```bash
   BASE_URL=https://chongjaroen-backend-xxxxx.ondigitalocean.app
   OMISE_PUBLIC_KEY=pkey_5tuer3rmwoxiudi0d04
   NODE_ENV=production
   ```

4. **Deploy** → Wait 3-5 minutes
5. **Save URL**: `https://chongjaroen-website-xxxxx.ondigitalocean.app`

---

### 3️⃣ Deploy Admin (5 minutes)

1. **Add Component** to existing app
2. **Configure**:
   - Source Directory: `packages/admin`
   - Build Command: `npm install && npm run build`
   - Run Command: `npm run start`
   - HTTP Port: `3000`

3. **Environment Variables**:
   ```bash
   BASE_URL=https://chongjaroen-backend-xxxxx.ondigitalocean.app
   NODE_ENV=production
   ```

4. **Deploy** → Wait 3-5 minutes
5. **Save URL**: `https://chongjaroen-admin-xxxxx.ondigitalocean.app`

---

### 4️⃣ Deploy Staff (5 minutes)

1. **Add Component** to existing app
2. **Configure**:
   - Type: **Static Site**
   - Source Directory: `packages/staff`
   - Build Command: `npm install && npm run build`
   - Output Directory: `dist`

3. **Environment Variables**:
   ```bash
   BASE_URL=https://chongjaroen-backend-xxxxx.ondigitalocean.app
   NODE_ENV=production
   ```

4. **Deploy** → Wait 3-5 minutes
5. **Save URL**: `https://chongjaroen-staff-xxxxx.ondigitalocean.app`

---

### 5️⃣ Update Backend CORS (2 minutes)

1. Go to **Backend Settings** → **Environment Variables**
2. Update `CORS_ORIGIN`:
   ```bash
   CORS_ORIGIN=https://chongjaroen-admin-xxxxx.ondigitalocean.app,https://chongjaroen-staff-xxxxx.ondigitalocean.app,https://chongjaroen-website-xxxxx.ondigitalocean.app
   ```
3. **Redeploy** backend

---

### 6️⃣ Test Everything (3 minutes)

```bash
# Test backend
curl https://chongjaroen-backend-xxxxx.ondigitalocean.app/admin

# Test website
curl https://chongjaroen-website-xxxxx.ondigitalocean.app

# Test admin
curl https://chongjaroen-admin-xxxxx.ondigitalocean.app

# Test staff
curl https://chongjaroen-staff-xxxxx.ondigitalocean.app
```

---

## ✅ Deployment Complete!

**Your URLs:**
- Backend: `https://chongjaroen-backend-xxxxx.ondigitalocean.app`
- Website: `https://chongjaroen-website-xxxxx.ondigitalocean.app`
- Admin: `https://chongjaroen-admin-xxxxx.ondigitalocean.app`
- Staff: `https://chongjaroen-staff-xxxxx.ondigitalocean.app`

**Cost:** ~$18/month

---

## 🔧 Common Issues

### Build Fails
```bash
# Check Node version in package.json:
"engines": { "node": "14.x" }
```

### CORS Error
```bash
# Make sure backend CORS_ORIGIN includes all frontend URLs
# No trailing slashes!
```

### Database Connection Error
```bash
# Verify DATABASE_SSL=true
# Check database credentials
```

### 502 Bad Gateway
```bash
# Check if service is running
# Verify HTTP port matches
# Check logs in DO dashboard
```

---

## 📖 Need More Details?

See full deployment plan: `DO_DEPLOYMENT_PLAN.md`

---

**Estimated Total Time:** 30 minutes
**Cost:** $18/month
