# ============================================
# Staff Portal (Nuxt SSG) - Production Dockerfile
# ============================================
# Static site served by nginx

FROM node:18.19.0-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci && npm cache clean --force

# Copy source code
COPY . .

# Build static site
ENV NODE_ENV=production
RUN npm run build

# ============================================
# Production Runtime with Nginx
# ============================================
FROM nginx:alpine

# Copy custom nginx config
COPY --from=builder /app/nginx.conf /etc/nginx/conf.d/default.conf 2>/dev/null || \
    echo 'server { \
        listen 80; \
        root /usr/share/nginx/html; \
        index index.html; \
        location / { \
            try_files $uri $uri/ /index.html; \
        } \
        gzip on; \
        gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript; \
    }' > /etc/nginx/conf.d/default.conf

# Copy built static files
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
