# 🚀 Deployment Checklist - Chongjaroen Restaurant System

Complete step-by-step checklist for deploying to Digital Ocean App Platform.

---

## Phase 1: Pre-Deployment Preparation

### ✅ Repository Setup

- [ ] Split monorepo into 4 separate repositories:
  - [ ] `chongjaroen-backend` (Strapi API)
  - [ ] `chongjaroen-website` (Customer portal)
  - [ ] `chongjaroen-admin` (Admin portal)
  - [ ] `chongjaroen-staff` (Staff portal)

- [ ] Create GitHub repositories (all private)
- [ ] Push each package to its repository
- [ ] Verify all repositories have:
  - [ ] `.env.example` file (template)
  - [ ] `.gitignore` file (includes `.env`)
  - [ ] `README.md` file

### ⚠️ CRITICAL: Security Cleanup

- [ ] **Revoke exposed Omise keys immediately**:
  - Current keys in .env: `skey_672xp2hgkg0pd5tu5kn` / `pkey_5tuer3rmwoxiudi0d04`
  - Go to: https://dashboard.omise.co/
  - Settings → API Keys → Revoke old keys
  - Generate NEW test keys for staging
  - Generate NEW live keys for production

- [ ] Remove `.env` from all git repositories:
  ```bash
  cd packages/backend
  git rm --cached .env
  git commit -m "Remove .env from version control"
  git push
  ```

- [ ] Rotate JWT secrets (generate new ones for production):
  ```bash
  node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
  ```

### 🗄️ Database Preparation

- [ ] Export local database:
  ```bash
  mysqldump -u root -p chongjaroen_dev > chongjaroen_production.sql
  ```

- [ ] Review exported data:
  - [ ] Remove test users
  - [ ] Remove test transactions
  - [ ] Sanitize sensitive data

---

## Phase 2: Digital Ocean Setup

### 📝 Account Setup

- [ ] Create/Login to Digital Ocean account
- [ ] Enable 2FA for security
- [ ] Add payment method
- [ ] Connect GitHub account to DO

### 🗄️ Create Managed Database

1. [ ] Go to: Databases → Create Database Cluster
2. [ ] Configuration:
   - [ ] Engine: MySQL 8
   - [ ] Plan: Basic ($15/month)
   - [ ] Datacenter: Singapore (SGP1)
   - [ ] Database name: `chongjaroen-db`
   - [ ] Cluster name: `chongjaroen-cluster`
3. [ ] Wait for provisioning (~5 minutes)
4. [ ] Save credentials securely:
   - [ ] Host
   - [ ] Port (25060)
   - [ ] Database name
   - [ ] Username (doadmin)
   - [ ] Password
   - [ ] CA Certificate

### 💾 Create Spaces (Object Storage)

1. [ ] Go to: Spaces → Create Space
2. [ ] Configuration:
   - [ ] Name: `chongjaroen-assets`
   - [ ] Region: Singapore (SGP1)
   - [ ] Enable CDN: Yes
3. [ ] Generate Spaces Keys:
   - [ ] API → Spaces → Generate New Key
   - [ ] Save Access Key
   - [ ] Save Secret Key
4. [ ] Note CDN URL: `https://chongjaroen-assets.sgp1.cdn.digitaloceanspaces.com`

---

## Phase 3: Backend Deployment

### 🔧 Deploy Backend API

1. [ ] Go to: App Platform → Create App
2. [ ] Source: Connect GitHub → Select `chongjaroen-backend`
3. [ ] Branch: `main`
4. [ ] Auto-deploy: Enabled

5. [ ] Build Settings:
   - [ ] Type: Web Service
   - [ ] Name: `chongjaroen-api`
   - [ ] Build Command: `npm install && npm run build`
   - [ ] Run Command: `npm start`
   - [ ] HTTP Port: `1337`
   - [ ] Environment: Node.js
   - [ ] Instance Size: Basic ($5/month)

6. [ ] Environment Variables:

**General:**
```
NODE_ENV=production
HOST=0.0.0.0
NODE_PORT=${APP_PORT}
WEBSITE_ENDPOINT_URL=https://chongjaroen.com
```

**Database:** (from Managed Database)
```
DATABASE_HOST=<your-cluster>.db.ondigitalocean.com
DATABASE_PORT=25060
DATABASE_NAME=chongjaroen-db
DATABASE_USERNAME=doadmin
DATABASE_PASSWORD=<password>  [ENCRYPT]
DATABASE_SSL=true
```

**Spaces:** (from Spaces)
```
DO_SPACE_ACCESS_KEY=<access-key>  [ENCRYPT]
DO_SPACE_SECRET_KEY=<secret-key>  [ENCRYPT]
DO_SPACE_ENDPOINT=sgp1.digitaloceanspaces.com
DO_SPACE_BUCKET=chongjaroen-assets
DO_SPACE_DIRECTORY=production
DO_SPACE_CDN=https://chongjaroen-assets.sgp1.cdn.digitaloceanspaces.com
```

**Security:**
```
ADMIN_JWT_SECRET=<new-128-char-secret>  [ENCRYPT]
JWT_SECRET=<new-128-char-secret>  [ENCRYPT]
BASIC_AUTHORIZATION=
```

**CORS:**
```
CORS_ORIGIN=https://chongjaroen.com,https://admin.chongjaroen.com,https://staff.chongjaroen.com
```

**OneSignal:** (get from OneSignal dashboard)
```
ONESIGNAL_APP_ID=<app-id>  [ENCRYPT]
ONESIGNAL_API_KEY=<api-key>  [ENCRYPT]
```

**SMS:**
```
THAIBULK_OTP_ENPOINT=https://api.thaibulksms.com/v1
THAIBULK_API_KEY=<api-key>  [ENCRYPT]
THAIBULK_API_SECRET=<api-secret>  [ENCRYPT]
```

**Omise:** (NEW PRODUCTION KEYS - not test!)
```
OMISE_SECRET_KEY=skey_<new-live-key>  [ENCRYPT]
OMISE_PUBLIC_KEY=pkey_<new-live-key>
OMISE_PROMPT_PAY_EXPIRE=15
```

7. [ ] Create Resources
8. [ ] Wait for deployment (~10 minutes)
9. [ ] Note app URL: `https://chongjaroen-api-xxxxx.ondigitalocean.app`

### 🔗 Add Custom Domain to Backend

1. [ ] In backend app: Settings → Domains → Add Domain
2. [ ] Enter: `api.chongjaroen.com`
3. [ ] Configure DNS at your registrar:
   ```
   Type: CNAME
   Host: api
   Value: chongjaroen-api-xxxxx.ondigitalocean.app
   TTL: 3600
   ```
4. [ ] Wait for DNS propagation (~30 minutes)
5. [ ] DO auto-provisions SSL certificate
6. [ ] Verify: https://api.chongjaroen.com/_health

### 📊 Import Database

```bash
# Connect to DO database and import
mysql -h <your-cluster>.db.ondigitalocean.com \
      -P 25060 \
      -u doadmin \
      -p \
      --ssl-mode=REQUIRED \
      chongjaroen-db < chongjaroen_production.sql

# Verify import
mysql -h <your-cluster>.db.ondigitalocean.com \
      -P 25060 \
      -u doadmin \
      -p \
      --ssl-mode=REQUIRED \
      -e "USE chongjaroen-db; SHOW TABLES;"
```

- [ ] Database imported successfully
- [ ] Tables verified
- [ ] Test admin login works

---

## Phase 4: Frontend Deployments

### 🌐 Deploy Website

1. [ ] Create new app: `chongjaroen-website`
2. [ ] GitHub: `chongjaroen-website` repo
3. [ ] Build Settings:
   - [ ] Build: `npm install && npm run build`
   - [ ] Run: `npm start`
   - [ ] Port: `3000`
   - [ ] Instance: Basic ($5/month)

4. [ ] Environment Variables:
   ```
   BASE_URL=https://api.chongjaroen.com
   WEBSITE_URL=https://chongjaroen.com
   NODE_ENV=production
   ```

5. [ ] Deploy & wait
6. [ ] Add domain: `chongjaroen.com`
7. [ ] Configure DNS:
   ```
   Type: CNAME
   Host: @  (or www)
   Value: chongjaroen-website-xxxxx.ondigitalocean.app
   ```

### 👨‍💼 Deploy Admin Portal

1. [ ] Create new app: `chongjaroen-admin`
2. [ ] Same build settings as website
3. [ ] Environment Variables:
   ```
   BASE_URL=https://api.chongjaroen.com
   ADMIN_URL=https://admin.chongjaroen.com
   NODE_ENV=production
   ```
4. [ ] Deploy
5. [ ] Add domain: `admin.chongjaroen.com`
6. [ ] Configure DNS

### 👥 Deploy Staff Portal

1. [ ] Create new app: `chongjaroen-staff`
2. [ ] Same build settings
3. [ ] Environment Variables:
   ```
   BASE_URL=https://api.chongjaroen.com
   STAFF_URL=https://staff.chongjaroen.com
   NODE_ENV=production
   ```
4. [ ] Deploy
5. [ ] Add domain: `staff.chongjaroen.com`
6. [ ] Configure DNS

---

## Phase 5: External Service Integration

### 🔔 OneSignal Setup (Push Notifications)

1. [ ] Sign up: https://onesignal.com/
2. [ ] Create app: "Chongjaroen Restaurant"
3. [ ] Configure platforms:
   - [ ] **iOS**: Upload Apple Push Certificate (.p12)
   - [ ] **Android**: Add Firebase Server Key

4. [ ] Get credentials:
   - [ ] App ID
   - [ ] REST API Key

5. [ ] Update backend environment variables in DO:
   ```
   ONESIGNAL_APP_ID=<your-app-id>
   ONESIGNAL_API_KEY=<your-api-key>
   ```

6. [ ] Test notification from backend

### 💳 Omise Webhook Configuration

1. [ ] Login to Omise: https://dashboard.omise.co/
2. [ ] Switch to LIVE mode (not TEST)
3. [ ] Go to: Settings → Webhooks
4. [ ] Create webhook:
   - [ ] URL: `https://api.chongjaroen.com/webhooks/omise`
   - [ ] Events:
     - [ ] charge.complete
     - [ ] charge.create
     - [ ] charge.update
     - [ ] refund.create
     - [ ] transfer.create

5. [ ] Test webhook (Omise will send test event)
6. [ ] Check backend logs for receipt confirmation

### 📱 Mobile App Configuration

Update Flutter app config:

**iOS (Info.plist):**
```xml
<key>OneSignalAppId</key>
<string>YOUR_ONESIGNAL_APP_ID</string>
<key>ApiBaseUrl</key>
<string>https://api.chongjaroen.com</string>
```

**Android (AndroidManifest.xml):**
```xml
<meta-data
    android:name="onesignal_app_id"
    android:value="YOUR_ONESIGNAL_APP_ID" />
<meta-data
    android:name="api_base_url"
    android:value="https://api.chongjaroen.com" />
```

---

## Phase 6: Testing & Verification

### 🧪 Backend Testing

- [ ] API Health: `curl https://api.chongjaroen.com/_health`
- [ ] Admin panel: https://api.chongjaroen.com/admin
- [ ] Database connected (check logs)
- [ ] CORS working (test from website)
- [ ] File upload working
- [ ] Strapi API docs: https://api.chongjaroen.com/documentation

### 🌐 Frontend Testing

- [ ] Website loads: https://chongjaroen.com
- [ ] Admin loads: https://admin.chongjaroen.com
- [ ] Staff loads: https://staff.chongjaroen.com
- [ ] Login works on all portals
- [ ] HTTPS/SSL active (check for 🔒)

### 💰 Wallet & Payment Testing

- [ ] View wallet balance
- [ ] Top-up with Credit Card (test with Omise test card)
- [ ] Top-up with PromptPay (test with test QR)
- [ ] Transfer between users
- [ ] Transaction history displays correctly
- [ ] Webhook receives Omise events (check logs)
- [ ] Push notification sent after top-up

**Omise Test Card:**
```
Number: 4242424242424242
Expiry: 12/25
CVC: 123
Name: Any name
```

### 🔔 Push Notification Testing

- [ ] Test notification from OneSignal dashboard
- [ ] Test notification from backend API
- [ ] Notification received on mobile app
- [ ] Notification on wallet top-up
- [ ] Notification on booking confirmation

---

## Phase 7: Security Verification

### 🔒 Security Checklist

- [ ] `.env` files NOT in git (all repos)
- [ ] All HTTPS (no HTTP)
- [ ] SSL certificates active
- [ ] Database connections use SSL
- [ ] JWT secrets rotated from dev
- [ ] Omise keys are LIVE (not test)
- [ ] CORS restricted to production domains
- [ ] Environment variables encrypted in DO
- [ ] No exposed secrets in code
- [ ] No console.log with sensitive data

### 🛡️ Penetration Testing

- [ ] Test SQL injection (should be blocked)
- [ ] Test XSS attacks (should be sanitized)
- [ ] Test CSRF (should be protected)
- [ ] Test unauthorized API access (should return 401)
- [ ] Test rate limiting

---

## Phase 8: Monitoring & Backups

### 📊 Setup Monitoring

- [ ] Enable DO App Platform monitoring
- [ ] Setup alerts:
  - [ ] CPU > 80%
  - [ ] Memory > 80%
  - [ ] Response time > 2s
  - [ ] Downtime

- [ ] Optional: Integrate Sentry for error tracking
  ```bash
  npm install @sentry/node
  ```

- [ ] Optional: Setup UptimeRobot for uptime monitoring

### 💾 Database Backups

- [ ] Enable daily backups in DO database dashboard
- [ ] Set retention: 7 days
- [ ] Test restore procedure
- [ ] Document backup/restore process

---

## Phase 9: Mobile App Deployment

### 📱 iOS App Store

1. [ ] Apple Developer Account ($99/year)
2. [ ] Create App ID
3. [ ] Configure push certificate
4. [ ] Build release with Xcode
5. [ ] Upload to TestFlight
6. [ ] Internal testing
7. [ ] Submit for review
8. [ ] Publish to App Store

### 🤖 Google Play Store

1. [ ] Google Play Console ($25 one-time)
2. [ ] Create app
3. [ ] Configure Firebase
4. [ ] Build release APK/AAB
   ```bash
   flutter build appbundle --release
   ```
5. [ ] Upload to Internal Testing
6. [ ] Production release

---

## Phase 10: Go-Live Checklist

### 🚀 Final Pre-Launch

- [ ] All services deployed and running
- [ ] All domains configured with SSL
- [ ] Database populated with production data
- [ ] All integrations tested (Omise, OneSignal, SMS)
- [ ] Mobile apps submitted to stores
- [ ] Monitoring active
- [ ] Backups enabled
- [ ] Team trained on admin/staff portals
- [ ] Documentation complete
- [ ] Support email configured

### 📣 Launch Day

- [ ] Monitor error logs closely
- [ ] Monitor server resources
- [ ] Monitor payment transactions
- [ ] Be ready for user support
- [ ] Collect user feedback
- [ ] Note any issues for quick fixes

### 📈 Post-Launch (Week 1)

- [ ] Daily monitoring
- [ ] Review error logs
- [ ] Check database performance
- [ ] Verify all payments successful
- [ ] Monitor user signups
- [ ] Fix critical bugs immediately
- [ ] Plan next sprint features

---

## 💰 Monthly Costs Estimate

| Service | Cost |
|---------|------|
| Backend API | $5 |
| Website | $5 |
| Admin | $5 |
| Staff | $5 |
| MySQL Database | $15 |
| Spaces + CDN | $5 |
| Bandwidth | ~$5 |
| **Total** | **~$45/month** |

Additional:
- OneSignal: Free (up to 10k)
- Omise: Transaction fees only
- Domain: $10-15/year
- Apple Developer: $99/year
- Google Play: $25 one-time

---

## 🆘 Rollback Plan

If critical issues occur:

1. **Immediate Rollback:**
   ```bash
   # In DO dashboard
   Deployments → Previous deployment → Rollback
   ```

2. **Database Rollback:**
   ```bash
   # Restore from backup
   # DO Dashboard → Database → Backups → Restore
   ```

3. **Emergency Contact:**
   - Digital Ocean Support
   - Omise Support
   - Team lead

---

## ✅ Success Criteria

Launch is successful when:
- [ ] 99.9% uptime for 1 week
- [ ] All payment transactions successful
- [ ] No critical bugs reported
- [ ] Mobile apps approved on both stores
- [ ] Users can successfully:
  - [ ] Register/Login
  - [ ] Make bookings
  - [ ] Top-up wallet
  - [ ] Make payments
  - [ ] Transfer funds
  - [ ] Receive notifications

---

**Deployment Date:** _______________  
**Deployed By:** _______________  
**Version:** _______________  

Good luck with your deployment! 🚀
