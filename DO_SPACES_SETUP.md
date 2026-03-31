# DO Spaces Configuration Guide

## 📦 Your Space Information

**Space Name:** `[PROD] Chongjaroen`
**Access Key:** `DO00J46PE6XFH8ZMV7AP` ✅

---

## 🔑 Still Needed:

### 1. Secret Key
- **Where to find:** Digital Ocean Dashboard → API → Spaces Keys
- **Format:** Long alphanumeric string (like the access key)
- **Note:** This is shown only once when created. If lost, you'll need to create new keys.

### 2. Space Region/Endpoint
Click on your Space **"[PROD] Chongjaroen"** in the Spaces dashboard, then:

**You'll see the endpoint URL, like:**
- `https://[PROD]-chongjaroen.sgp1.digitaloceanspaces.com` → Region is `sgp1`
- `https://[PROD]-chongjaroen.nyc3.digitaloceanspaces.com` → Region is `nyc3`
- `https://[PROD]-chongjaroen.sfo3.digitaloceanspaces.com` → Region is `sfo3`

**Extract the region code** (sgp1, nyc3, etc.)

### 3. CDN URL (Optional)
- **Where to find:** Space Settings → CDN (if enabled)
- **Example:** `https://[PROD]-chongjaroen.sgp1.cdn.digitaloceanspaces.com`
- **If not enabled:** Leave blank

---

## 📋 Configuration Template

Once you provide the details, I'll configure:

```javascript
// packages/backend/config/plugins.js
upload: {
  provider: 'do',
  providerOptions: {
    key: 'DO00J46PE6XFH8ZMV7AP',
    secret: 'YOUR_SECRET_KEY_HERE',
    endpoint: 'sgp1.digitaloceanspaces.com',  // or your region
    space: '[PROD] Chongjaroen',
    directory: 'uploads',
    cdn: 'https://your-cdn-url',  // optional
  },
},
```

And update environment variables:
```bash
DO_SPACE_ACCESS_KEY=DO00J46PE6XFH8ZMV7AP
DO_SPACE_SECRET_KEY=YOUR_SECRET_KEY
DO_SPACE_ENDPOINT=sgp1.digitaloceanspaces.com
DO_SPACE_BUCKET=[PROD] Chongjaroen
DO_SPACE_DIRECTORY=uploads
DO_SPACE_CDN=https://your-cdn-url  # optional
```

---

## 🚀 Next Steps

Please provide:
1. **Secret Key** (from Spaces Keys)
2. **Region** (from Space URL - sgp1, nyc3, etc.)
3. **CDN URL** (if enabled, otherwise skip)

Then I'll:
1. Update `plugins.js`
2. Update `.env.production`
3. Commit and push
4. Redeploy backend

---

**Waiting for:** Secret Key + Region
