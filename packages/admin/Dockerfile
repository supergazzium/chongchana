# ============================================
# Admin Dashboard (Nuxt SSR) - Production Dockerfile
# ============================================

FROM node:18.19.0-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci && npm cache clean --force

# Copy source code
COPY . .

# Build Nuxt for production (SSR mode)
ENV NODE_ENV=production
RUN npm run build

# ============================================
# Production Runtime
# ============================================
FROM node:18.19.0-alpine

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nuxt -u 1001

WORKDIR /app

# Copy built application
COPY --from=builder --chown=nuxt:nodejs /app/.nuxt ./.nuxt
COPY --from=builder --chown=nuxt:nodejs /app/static ./static
COPY --from=builder --chown=nuxt:nodejs /app/nuxt.config.js ./
COPY --from=builder --chown=nuxt:nodejs /app/package*.json ./
COPY --from=builder --chown=nuxt:nodejs /app/node_modules ./node_modules

# Switch to non-root user
USER nuxt

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})" || exit 1

# Start Nuxt
CMD ["npm", "start"]
