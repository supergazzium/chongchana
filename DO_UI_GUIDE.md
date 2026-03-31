# Digital Ocean App Platform UI Guide
## Where to Configure Each Setting

---

## 🎯 Step-by-Step with Screenshots Description

### Screen 1: Create App - Source Selection

**What you'll see:**
- GitHub icon and "GitHub" button
- "GitLab" and "Container Registry" options

**What to do:**
1. Click **"GitHub"**
2. If first time: Click **"Manage Access"** → Grant DO access to your repos
3. Select **Repository**: `chongjaroen-master`
4. Select **Branch**: `main`
5. **Autodeploy**: Leave checked (✅)
6. Click **"Next"**

---

### Screen 2: Configure Resources

This is where you configure EVERYTHING. Here's what you'll see:

#### Section: "Resources"

You'll see a card for your app component with these fields:

---

#### 📁 **Source Directory** (Top of the card)

**Location:** First field in the resource card

**What you'll see:**
```
Source Directory: [____________________]
```

**What to enter:**
```
packages/backend
```

**Tip:** Type this EXACTLY. No leading/trailing slashes.

---

#### ⚙️ **Type** (Below Source Directory)

**What you'll see:**
```
Type: [Dropdown ▼]
```

**Options:**
- Web Service ← **Select this one**
- Worker
- Static Site
- Job

**What to select:** **Web Service**

---

#### 🔧 **Environment Variables** (Click to expand)

**What you'll see:**
```
Environment Variables [Edit ▼]
```

**What to do:**
1. Click **"Edit"** button
2. A modal will open with:
   - Key field
   - Value field
   - Encrypt checkbox (🔒)
   - Type dropdown (Text/Secret)

**Add each variable:**
```
Key: HOST                Value: 0.0.0.0
Key: NODE_PORT           Value: 8080               [🔒 Encrypt: No]
Key: NODE_ENV            Value: production
Key: DATABASE_HOST       Value: chongjaroen-mysql-prod...
Key: DATABASE_PASSWORD   Value: XZzE4SQU...        [🔒 Encrypt: YES]
... (continue for all variables)
```

3. Click **"Save"** when done

---

#### 🏗️ **Build & Deploy** (Click to expand)

**What you'll see:**
```
Build & Deploy [Edit ▼]
```

**What to do:**
1. Click **"Edit"**
2. You'll see:

**Build Command:**
```
[npm ci --production]  ← Default, CHANGE THIS
```
**Change to:**
```
npm install && npm run build
```

**Run Command:**
```
[npm start]  ← Default, CHANGE THIS
```
**Change to:**
```
npm run start
```

**Dockerfile Path:** Leave empty

3. Click **"Save"**

---

#### 🌐 **HTTP Port** (Below Build & Deploy)

**What you'll see:**
```
HTTP Port: [8080]  ← Should auto-detect
```

**What to do:**
- **Usually auto-detected as 8080** for Node.js apps
- If not shown, click the field and type: `8080`
- This tells DO which port your app listens on

**Important:** This MUST match `NODE_PORT=8080` in your environment variables

---

#### 🚦 **HTTP Routes** (Below HTTP Port)

**What you'll see:**
```
HTTP Routes: [/]  ← Default
```

**What to do:**
- Leave as `/` (root path)
- This means all requests go to this service

---

#### 🏥 **Health Check** (Optional, click to expand)

**What you'll see:**
```
Health Check [Edit ▼]
```

**What to configure (optional but recommended):**
```
HTTP Path: /admin
HTTP Port: 8080
Success Codes: 200,302,307
Initial Delay: 60 seconds
Period: 30 seconds
Timeout: 10 seconds
```

**Or leave default** - DO will use basic health checks

---

#### 📦 **Node.js Version** (If not visible, expand "Build & Deploy")

**Where to find it:**
1. Expand **"Build & Deploy"** section
2. Look for **"Environment"** or **"Runtime"**

**What you'll see:**
```
Node.js Version: [Latest ▼]  ← Dropdown
```

**What to select:**
- Click dropdown
- Select **"14.x"** or **"14"**
- **CRITICAL:** Must be 14.x for Strapi 3.6.8

**If you don't see version selector:**
- It might auto-detect from `package.json` engines
- Check package.json has: `"node": ">=10.16.0 <=14.x.x"`

---

### Screen 3: Name Your Service

**What you'll see:**
```
App Name: [________________]
```

**What to enter:**
```
chongjaroen-backend
```

Or any name you prefer. This is just for display.

---

### Screen 4: Plan Selection

**What you'll see:**
```
Plan:
○ Basic ($5/month)     ← Select this
○ Professional ($12/month)
○ Pro Plus ($24/month)
```

**What to select:** **Basic ($5/month)** to start

**Resources shown:**
- 512 MB RAM / 0.5 vCPU
- Good enough for Strapi with moderate traffic
- Can upgrade later

---

### Screen 5: Review

**What you'll see:**
- Summary of all configurations
- Estimated cost: $5/month
- List of all environment variables (hidden values for encrypted ones)

**What to do:**
1. Review everything
2. Scroll down
3. Click **"Create Resources"**

---

## 🔍 Common Questions

### Q: I don't see "HTTP Port" field
**A:** It might be in the "Advanced Options" or under "Settings" section. Look for:
- A gear icon ⚙️
- "Advanced Settings"
- Or it auto-detects from your code

### Q: I don't see "Node.js Version" selector
**A:**
1. Check if it's in "Build & Deploy" → "Environment"
2. Or DO auto-detects from `package.json` engines field
3. After first deploy, you can change it in Settings

### Q: Where exactly is "Build & Deploy"?
**A:**
- In the resource card (the white box showing your service)
- Below "Environment Variables"
- Click "Edit" to expand it

### Q: HTTP Port shows 3000 but I need 8080
**A:**
- Click on the port number
- Change it to `8080`
- Make sure `NODE_PORT=8080` in environment variables

---

## 🖼️ Visual Layout (Text Representation)

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃  Resources                                   ┃
┃  ┌────────────────────────────────────────┐ ┃
┃  │ 📦 chongjaroen-backend                 │ ┃
┃  │                                         │ ┃
┃  │ Source Directory: packages/backend     │ ┃
┃  │ Type: Web Service                      │ ┃
┃  │                                         │ ┃
┃  │ Environment Variables [Edit ▼]         │ ┃
┃  │ • 15 variables configured              │ ┃
┃  │                                         │ ┃
┃  │ Build & Deploy [Edit ▼]                │ ┃
┃  │ • Build: npm install && npm run build  │ ┃
┃  │ • Run: npm run start                   │ ┃
┃  │                                         │ ┃
┃  │ HTTP Port: 8080                        │ ┃
┃  │ HTTP Routes: /                         │ ┃
┃  │                                         │ ┃
┃  │ Health Check [Edit ▼]                  │ ┃
┃  │                                         │ ┃
┃  │ Resources                              │ ┃
┃  │ Basic • $5/mo                          │ ┃
┃  └────────────────────────────────────────┘ ┃
┃                                              ┃
┃  [⬅ Back]              [Next ➡]             ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

---

## ✅ Quick Checklist

After configuring, verify these are set:

- [ ] Source Directory: `packages/backend`
- [ ] Type: `Web Service`
- [ ] Build Command: `npm install && npm run build`
- [ ] Run Command: `npm run start`
- [ ] HTTP Port: `8080`
- [ ] Node Version: `14.x`
- [ ] Environment Variables: 15+ variables added
- [ ] Encrypted variables marked with 🔒
- [ ] Plan: Basic ($5/month)

---

## 🎬 Alternative: Use YAML Config (Advanced)

If you prefer, you can use `.do/app.yaml`:

```yaml
name: chongjaroen
services:
- name: backend
  source_dir: packages/backend
  github:
    repo: your-username/chongjaroen-master
    branch: main
  build_command: npm install && npm run build
  run_command: npm run start
  http_port: 8080
  instance_count: 1
  instance_size_slug: basic-xxs
  env:
  - key: NODE_PORT
    value: "8080"
  - key: NODE_ENV
    value: production
  # ... more env vars
```

But the UI is easier for first deployment!

---

## 🆘 Still Can't Find Port Setting?

**Try this:**

1. **After creating the app**, go to:
   - Settings → Components → Backend → Edit

2. **Or look in these sections:**
   - "Configuration"
   - "HTTP Request Routes"
   - "Network & Ports"

3. **The port might be called:**
   - "HTTP Port"
   - "Port"
   - "Container Port"
   - "Internal Port"

4. **On older DO UI versions:**
   - It might be in "Advanced Options" at bottom

---

**Need more help?** Let me know which screen you're on and I'll guide you through it!
