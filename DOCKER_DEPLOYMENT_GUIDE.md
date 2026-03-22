# 🐳 Docker Deployment Guide - Chongjaroen Restaurant System

Complete guide for deploying the Chongjaroen system using Docker and Digital Ocean.

---

## 📋 Table of Contents

1. [Quick Start (Local Testing)](#quick-start)
2. [Project Structure](#project-structure)
3. [Local Development with Docker](#local-development)
4. [Production Deployment to Digital Ocean](#production-deployment)
5. [CI/CD with GitHub Actions](#cicd-setup)
6. [Troubleshooting](#troubleshooting)

---

## 🚀 Quick Start (Local Testing)

### Prerequisites
- Docker Desktop installed
- Docker Compose installed
- Environment variables configured

### 1. Setup Environment Variables

```bash
cd /Users/prachumchanman/Documents/chongjaroen-master
cp .env.example .env
# Edit .env with your actual credentials
```

### 2. Build and Run All Services

```bash
# Build all Docker images
docker-compose build

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f
```

### 3. Access Applications

- **Backend API**: http://localhost:1337
- **Admin Dashboard**: http://localhost:4040
- **Public Website**: http://localhost:3000
- **Staff Portal**: http://localhost:8080

### 4. Stop Services

```bash
docker-compose down
```

---

## 📁 Project Structure

```
chongjaroen-master/
├── packages/
│   ├── backend/              # Strapi 3.6.8 API
│   │   ├── Dockerfile        # Multi-stage build
│   │   └── .dockerignore
│   ├── admin/                # Nuxt SSR Dashboard
│   │   ├── Dockerfile
│   │   └── .dockerignore
│   ├── website/              # Nuxt SSG Public Site
│   │   ├── Dockerfile
│   │   └── .dockerignore
│   └── staff/                # Nuxt SSG Staff Portal
│       ├── Dockerfile
│       └── .dockerignore
├── docker-compose.yml        # Local development
├── .env.example              # Environment template
└── DOCKER_DEPLOYMENT_GUIDE.md
```

---

## 💻 Local Development with Docker

### Building Individual Services

```bash
# Backend only
docker-compose build backend
docker-compose up backend

# Admin only
docker-compose build admin
docker-compose up admin
```

### Viewing Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
```

### Rebuilding After Code Changes

```bash
# Rebuild specific service
docker-compose build --no-cache backend

# Rebuild all
docker-compose build --no-cache
```

---

## 🌐 Production Deployment to Digital Ocean

### Architecture Overview

```
GitHub → GitHub Actions → DO Container Registry → DO App Platform
```

### Step 1: Create Digital Ocean Container Registry

1. Go to Digital Ocean Dashboard → Container Registry
2. Click "Create Registry"
3. Choose Singapore (SGP1) region
4. Name: `chongjaroen-registry`
5. Plan: Starter ($5/month - 500MB storage)

### Step 2: Authenticate Docker with DO Registry

```bash
# Install doctl CLI
brew install doctl

# Authenticate
doctl auth init

# Login to registry
doctl registry login
```

### Step 3: Build and Push Images

```bash
# Set registry URL
export REGISTRY=registry.digitalocean.com/chongjaroen-registry

# Build and tag backend
cd packages/backend
docker build -t $REGISTRY/backend:latest .
docker push $REGISTRY/backend:latest

# Build and tag admin
cd ../admin
docker build -t $REGISTRY/admin:latest .
docker push $REGISTRY/admin:latest

# Build and tag website
cd ../website
docker build -t $REGISTRY/website:latest .
docker push $REGISTRY/website:latest

# Build and tag staff
cd ../staff
docker build -t $REGISTRY/staff:latest .
docker push $REGISTRY/staff:latest
```

### Step 4: Create Apps on Digital Ocean App Platform

#### Backend API

1. Go to Digital Ocean → Apps → Create App
2. Choose: Container Registry
3. Registry: `chongjaroen-registry`
4. Image: `backend`
5. Tag: `latest`
6. Resources: Basic ($5/month)
7. Environment Variables: Add all from `.env.example`
8. HTTP Port: `1337`
9. Health Check: `/admin` or `/_health`

#### Admin Dashboard

1. Create new App
2. Registry: `chongjaroen-registry`
3. Image: `admin`
4. Tag: `latest`
5. Resources: Basic ($5/month)
6. Environment Variables:
   ```
   API_URL=https://your-backend-url.ondigitalocean.app
   NODE_ENV=production
   ```
7. HTTP Port: `3000`

#### Website (Public)

1. Create new App
2. Registry: `chongjaroen-registry`
3. Image: `website`
4. Tag: `latest`
5. Resources: Basic ($5/month) or Static Site
6. HTTP Port: `80`

#### Staff Portal

1. Create new App
2. Registry: `chongjaroen-registry`
3. Image: `staff`
4. Tag: `latest`
5. Resources: Basic ($5/month) or Static Site
6. HTTP Port: `80`

---

## 🔄 CI/CD Setup with GitHub Actions

### Step 1: Add GitHub Secrets

Go to GitHub repository → Settings → Secrets → New repository secret

Add these secrets:

```
DIGITALOCEAN_ACCESS_TOKEN=your_do_token
REGISTRY_NAME=chongjaroen-registry
IMAGE_NAME_BACKEND=backend
IMAGE_NAME_ADMIN=admin
IMAGE_NAME_WEBSITE=website
IMAGE_NAME_STAFF=staff
```

### Step 2: Create GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Build and Deploy to Digital Ocean

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: [backend, admin, website, staff]

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Install doctl
        uses: digitalocean/action-doctl@v2
        with:
          token: ${{ secrets.DIGITALOCEAN_ACCESS_TOKEN }}

      - name: Log in to DO Container Registry
        run: doctl registry login --expiry-seconds 1200

      - name: Build Docker image
        run: |
          docker build \
            -t registry.digitalocean.com/${{ secrets.REGISTRY_NAME }}/${{ matrix.service }}:${{ github.sha }} \
            -t registry.digitalocean.com/${{ secrets.REGISTRY_NAME }}/${{ matrix.service }}:latest \
            ./packages/${{ matrix.service }}

      - name: Push image to DO Container Registry
        run: |
          docker push registry.digitalocean.com/${{ secrets.REGISTRY_NAME }}/${{ matrix.service }}:${{ github.sha }}
          docker push registry.digitalocean.com/${{ secrets.REGISTRY_NAME }}/${{ matrix.service }}:latest

      - name: Trigger deployment
        run: |
          echo "Image pushed successfully. DO App Platform will auto-deploy."
```

### Step 3: Enable Auto-Deploy

In Digital Ocean App Platform:
1. Go to each app → Settings
2. Enable "Auto-deploy"
3. Set source: Container Registry
4. Tag: `latest`

Now every push to `main` branch will:
1. Build Docker images
2. Push to DO Container Registry
3. Trigger auto-deployment

---

## 🐛 Troubleshooting

### Docker Build Fails

```bash
# Clear Docker cache
docker builder prune -a

# Check logs
docker-compose logs backend

# Rebuild without cache
docker-compose build --no-cache backend
```

### Container Won't Start

```bash
# Check container status
docker-compose ps

# View detailed logs
docker-compose logs -f backend

# Enter container for debugging
docker-compose exec backend sh
```

### Database Connection Issues

1. Verify environment variables:
   ```bash
   docker-compose exec backend env | grep DATABASE
   ```

2. Test connection from container:
   ```bash
   docker-compose exec backend sh
   nc -zv db-mysql-sgp1-51509-do-user-10174906-0.g.db.ondigitalocean.com 25060
   ```

### Port Already in Use

```bash
# Find process using port
lsof -i :1337

# Kill process
kill -9 <PID>

# Or change port in docker-compose.yml
```

### Image Too Large

Check `.dockerignore` files to exclude:
- `node_modules/`
- `.git/`
- `.env`
- `*.log`
- `*.md`

---

## 📊 Resource Requirements

### Minimum Requirements

| Service | Memory | CPU | Storage |
|---------|--------|-----|---------|
| Backend | 512MB  | 1   | 1GB     |
| Admin   | 512MB  | 1   | 500MB   |
| Website | 256MB  | 0.5 | 200MB   |
| Staff   | 256MB  | 0.5 | 200MB   |

### Recommended Production

| Service | Memory | CPU | Storage |
|---------|--------|-----|---------|
| Backend | 1GB    | 1   | 2GB     |
| Admin   | 1GB    | 1   | 1GB     |
| Website | 512MB  | 1   | 500MB   |
| Staff   | 512MB  | 1   | 500MB   |

---

## 🔒 Security Best Practices

1. **Never commit `.env` files**
   ```bash
   echo ".env" >> .gitignore
   ```

2. **Use secrets for sensitive data**
   - Digital Ocean App Platform has encrypted environment variables
   - GitHub has Secrets for CI/CD

3. **Use non-root users in containers**
   - All Dockerfiles already implement this

4. **Keep images updated**
   ```bash
   docker-compose pull
   docker-compose up -d
   ```

5. **Enable SSL/TLS**
   - Digital Ocean App Platform provides free SSL certificates

---

## 📞 Support

For issues or questions:
1. Check logs: `docker-compose logs -f`
2. Review this guide
3. Check Digital Ocean documentation
4. Contact team

---

**Last Updated**: March 22, 2026
**Version**: 1.0.0
