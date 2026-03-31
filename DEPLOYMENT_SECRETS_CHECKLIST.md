# 🔐 Deployment Secrets Checklist
## Digital Ocean App Platform - Environment Variables Setup

---

## 📋 Overview

This checklist helps you configure environment variables for all services on Digital Ocean App Platform. Copy values from local `.env` files to DO App Platform settings.

**Files Created:**
- ✅ `packages/backend/.env.production` - Backend config with secrets
- ✅ `packages/backend/.env.production.template` - Template with comments
- ✅ `packages/admin/.env.production` - Admin config
- ✅ `packages/staff/.env.production` - Staff config
- ✅ `packages/website/.env.production` - Website config

---

## 🔑 Backend Environment Variables

### Copy to Digital Ocean App Platform → Backend Service → Settings → Environment Variables

```bash
# Server Configuration
HOST=0.0.0.0
NODE_PORT=8080
NODE_ENV=production

# Database (Production)
DATABASE_HOST=chongjaroen-mysql-prod-do-user-10174906-0.b.db.ondigitalocean.com
DATABASE_PORT=25060
DATABASE_NAME=chongjaroen
DATABASE_USERNAME=doadmin
DATABASE_PASSWORD=XZzE4SQUikOm1QJt
DATABASE_SSL=true

# Security Secrets (from local .env)
ADMIN_JWT_SECRET=a377f11e2f5999d1ee979b09356d42c5f7b20b7867890e33a0a019c8ad569deb32091829dfcf8b95a2c041d25c7a06aed6826cd3931b6b8e60d5172004bbed6f
JWT_SECRET=16f8f17c5aa6164582d28dd17590bfde0639bed6ba3456f3d529f51bbaa0b79af6facfafed8b0463a7ce0d6e2fd48c8f8cba2b94ea4a259ed7acacbb2cbdf40e
BASIC_AUTHORIZATION=

# Payment Gateway (Omise)
OMISE_SECRET_KEY=skey_672xp2hgkg0pd5tu5kn
OMISE_PUBLIC_KEY=pkey_5tuer3rmwoxiudi0d04
OMISE_PROMPT_PAY_EXPIRE=15

# CORS - INITIAL VALUE (update after frontend deployment)
CORS_ORIGIN=https://localhost:8080

# Optional Services (leave empty if not using)
ONESIGNAL_APP_ID=
ONESIGNAL_API_KEY=
THAIBULK_OTP_ENPOINT=
THAIBULK_API_KEY=
THAIBULK_API_SECRET=
DO_SPACE_ACCESS_KEY=
DO_SPACE_SECRET_KEY=
DO_SPACE_ENDPOINT=
DO_SPACE_BUCKET=
DO_SPACE_DIRECTORY=
DO_SPACE_CDN=
```

**Important Notes for Backend:**
- ✅ All secrets are from local `packages/backend/.env`
- ⚠️ `NODE_PORT=8080` is REQUIRED by DO App Platform (not 7001)
- ⚠️ `DATABASE_SSL=true` is REQUIRED for DO managed MySQL
- ⚠️ `CORS_ORIGIN` must be updated AFTER deploying frontend services
- ⚠️ Verify `OMISE_SECRET_KEY` is for PRODUCTION (starts with `skey_` not `skey_test_`)

---

## 🖥️ Admin Environment Variables

### Copy to Digital Ocean App Platform → Admin Service → Settings → Environment Variables

```bash
# Backend API URL (UPDATE after backend deployment)
BASE_URL=https://chongjaroen-backend-xxxxx.ondigitalocean.app

# Environment
NODE_ENV=production

# Optional
BASIC_AUTHORIZATION=
GTM_ID=
```

**Important Notes for Admin:**
- ⚠️ Replace `xxxxx` in `BASE_URL` with actual backend URL from DO App Platform
- ⚠️ NO trailing slash in `BASE_URL`
- ⚠️ Deploy backend FIRST, then update this

---

## 👥 Staff Environment Variables

### Copy to Digital Ocean App Platform → Staff Service → Settings → Environment Variables

```bash
# Backend API URL (UPDATE after backend deployment)
NUXT_ENV_BASE_URL=https://chongjaroen-backend-xxxxx.ondigitalocean.app

# Environment
NODE_ENV=production
```

**Important Notes for Staff:**
- ⚠️ Replace `xxxxx` in `NUXT_ENV_BASE_URL` with actual backend URL
- ⚠️ Staff is deployed as STATIC SITE (no server runtime)
- ⚠️ Environment variables are baked into build

---

## 🌐 Website Environment Variables

### Copy to Digital Ocean App Platform → Website Service → Settings → Environment Variables

```bash
# Backend API URL (UPDATE after backend deployment)
BASE_URL=https://chongjaroen-backend-xxxxx.ondigitalocean.app

# Environment
NODE_ENV=production

# Payment Gateway (Public Key Only - safe for frontend)
OMISE_PUBLIC_KEY=pkey_5tuer3rmwoxiudi0d04
OMISE_DEFAULT_PAYMENT_METHOD=credit_card
OMISE_OTHER_PAYMENT_METHOD=promptpay

# Optional
BASIC_AUTHORIZATION=
GTM_ID=
```

**Important Notes for Website:**
- ⚠️ Replace `xxxxx` in `BASE_URL` with actual backend URL
- ⚠️ `OMISE_PUBLIC_KEY` is safe to expose (public key only)
- ⚠️ Verify this is PRODUCTION public key (starts with `pkey_` not `pkey_test_`)
- ⚠️ Secret key stays on backend only

---

## 🚀 Deployment Workflow

### Phase 1: Deploy Backend
1. ✅ Go to DO App Platform → Create App
2. ✅ Select GitHub repo → `chongjaroen-master` → `packages/backend`
3. ✅ Add ALL backend environment variables listed above
4. ✅ Set CORS_ORIGIN to temporary value
5. ✅ Deploy and wait for completion
6. ✅ **SAVE THE BACKEND URL**: `https://chongjaroen-backend-xxxxx.ondigitalocean.app`

### Phase 2: Deploy Frontends
7. ✅ Deploy Admin with `BASE_URL` pointing to backend
8. ✅ **SAVE ADMIN URL**: `https://chongjaroen-admin-xxxxx.ondigitalocean.app`
9. ✅ Deploy Staff with `NUXT_ENV_BASE_URL` pointing to backend
10. ✅ **SAVE STAFF URL**: `https://chongjaroen-staff-xxxxx.ondigitalocean.app`
11. ✅ Deploy Website with `BASE_URL` pointing to backend
12. ✅ **SAVE WEBSITE URL**: `https://chongjaroen-website-xxxxx.ondigitalocean.app`

### Phase 3: Update Backend CORS
13. ✅ Go to Backend Service → Settings → Environment Variables
14. ✅ Update `CORS_ORIGIN`:
```bash
CORS_ORIGIN=https://chongjaroen-admin-xxxxx.ondigitalocean.app,https://chongjaroen-staff-xxxxx.ondigitalocean.app,https://chongjaroen-website-xxxxx.ondigitalocean.app
```
15. ✅ Also update `WEBSITE_ENDPOINT_URL`:
```bash
WEBSITE_ENDPOINT_URL=https://chongjaroen-website-xxxxx.ondigitalocean.app
```
16. ✅ Redeploy backend

---

## ✅ Verification Checklist

### After Backend Deployment
- [ ] Backend responds at `https://chongjaroen-backend-xxxxx.ondigitalocean.app/admin`
- [ ] Database connection working (check logs)
- [ ] Health check passes
- [ ] Can access Strapi admin login page

### After Admin Deployment
- [ ] Admin panel loads at `https://chongjaroen-admin-xxxxx.ondigitalocean.app`
- [ ] Can connect to backend API
- [ ] No CORS errors in browser console

### After Staff Deployment
- [ ] Staff panel loads at `https://chongjaroen-staff-xxxxx.ondigitalocean.app`
- [ ] Static files served correctly
- [ ] Can make API calls to backend

### After Website Deployment
- [ ] Website loads at `https://chongjaroen-website-xxxxx.ondigitalocean.app`
- [ ] Can connect to backend API
- [ ] Omise payment form loads correctly
- [ ] Login/signup works

### After CORS Update
- [ ] All frontends can make API calls without CORS errors
- [ ] Test login from website
- [ ] Test admin panel operations
- [ ] Test staff panel QR scanning

---

## 🔒 Security Best Practices

### DO's
✅ Use DO App Platform's **encrypted environment variables** for secrets
✅ Verify all secrets before deployment
✅ Use HTTPS URLs only (no HTTP)
✅ Keep production keys separate from test keys
✅ Enable 2FA on Strapi admin after deployment
✅ Review CORS origins carefully (no wildcards)
✅ Use SSL for database connection (`DATABASE_SSL=true`)

### DON'Ts
❌ Never commit `.env.production` to Git
❌ Never share secrets in plain text (Slack, email, etc.)
❌ Don't use test keys in production
❌ Don't add `*` to CORS_ORIGIN
❌ Don't forget trailing commas in CORS list
❌ Don't use HTTP origins in production CORS

---

## 🆘 Troubleshooting

### Issue: CORS Errors
**Solution:**
- Check `CORS_ORIGIN` includes exact URL (no trailing slash)
- Verify URL format: `https://` not `http://`
- Check for typos in frontend URLs
- Redeploy backend after updating CORS

### Issue: Database Connection Failed
**Solution:**
- Verify `DATABASE_SSL=true`
- Check database credentials
- Ensure DO database firewall allows App Platform IPs
- Check database is running

### Issue: 502 Bad Gateway
**Solution:**
- Check if service is running (DO dashboard)
- Verify `NODE_PORT=8080` for backend
- Check application logs in DO dashboard
- Ensure build completed successfully

### Issue: Omise Payment Not Working
**Solution:**
- Verify `OMISE_PUBLIC_KEY` and `OMISE_SECRET_KEY` are LIVE keys
- Check Omise dashboard for test vs production mode
- Verify keys match on backend and frontend
- Test with Omise test card numbers first

---

## 📝 Quick Reference

### Backend URLs After Deployment
Replace these placeholders throughout the config:

```bash
# Backend
https://chongjaroen-backend-xxxxx.ondigitalocean.app

# Admin
https://chongjaroen-admin-xxxxx.ondigitalocean.app

# Staff
https://chongjaroen-staff-xxxxx.ondigitalocean.app

# Website
https://chongjaroen-website-xxxxx.ondigitalocean.app
```

### CORS Format
```bash
# Correct ✅
CORS_ORIGIN=https://admin.example.com,https://staff.example.com,https://example.com

# Wrong ❌
CORS_ORIGIN=https://admin.example.com, https://staff.example.com  # No spaces!
CORS_ORIGIN=https://admin.example.com/,https://staff.example.com/ # No trailing slash!
CORS_ORIGIN=*                                                       # No wildcards!
```

---

## 📚 Additional Resources

- [DO App Platform Environment Variables](https://docs.digitalocean.com/products/app-platform/how-to/use-environment-variables/)
- [Strapi Deployment Guide](https://docs.strapi.io/dev-docs/deployment)
- [Omise API Keys](https://dashboard.omise.co/test/api-keys)
- [DO Database SSL](https://docs.digitalocean.com/products/databases/mysql/how-to/connect/)

---

**Last Updated**: 2026-03-28
**Status**: Ready for deployment
**Next Step**: Deploy backend first with these environment variables
