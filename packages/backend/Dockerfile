# ============================================
# Backend (Strapi 3.6.8) - Production Dockerfile
# ============================================
# Using Debian-based image for better Sharp compatibility

FROM node:18.19.0-slim AS builder

# Install build dependencies for native modules
RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    libvips-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ALL dependencies (including devDependencies for build)
RUN npm ci && npm cache clean --force

# Copy source code
COPY . .

# Build Strapi admin panel
ENV NODE_ENV=production
# Increase Node.js memory limit + OpenSSL legacy provider for Webpack 4
ENV NODE_OPTIONS="--max-old-space-size=4096 --openssl-legacy-provider"
RUN npm run build

# ============================================
# Production Runtime Stage
# ============================================
FROM node:18.19.0-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libvips42 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd --gid 1001 nodejs && \
    useradd --uid 1001 --gid nodejs --shell /bin/bash --create-home strapi

WORKDIR /app

# Copy built artifacts and production dependencies
COPY --from=builder --chown=strapi:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=strapi:nodejs /app/.cache ./.cache
COPY --from=builder --chown=strapi:nodejs /app/build ./build
COPY --from=builder --chown=strapi:nodejs /app/public ./public
COPY --from=builder --chown=strapi:nodejs /app/api ./api
COPY --from=builder --chown=strapi:nodejs /app/config ./config
COPY --from=builder --chown=strapi:nodejs /app/extensions ./extensions
COPY --from=builder --chown=strapi:nodejs /app/middlewares ./middlewares
COPY --from=builder --chown=strapi:nodejs /app/package*.json ./

# Switch to non-root user
USER strapi

# Expose port
EXPOSE 1337

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD node -e "require('http').get('http://localhost:1337/_health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})" || exit 1

# Start Strapi
CMD ["npm", "start"]
