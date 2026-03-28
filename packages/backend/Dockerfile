# =============================================================================
# Stage 1: Build Stage (runs with plenty of RAM on build servers)
# =============================================================================
FROM node:14.21.3-alpine AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    gcc \
    autoconf \
    automake \
    libtool \
    nasm \
    libpng-dev \
    vips-dev

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ALL dependencies (including devDependencies for build)
RUN npm ci

# Copy source code
COPY . .

# Set NODE_ENV to production for optimized build
ENV NODE_ENV=production

# Build Strapi admin panel (memory-intensive step happens here on build server)
RUN npm run build

# =============================================================================
# Stage 2: Runtime Stage (lean and optimized for 512MB RAM)
# =============================================================================
FROM node:14.21.3-alpine

# Install only runtime dependencies
RUN apk add --no-cache \
    vips-dev \
    tini

# Create app user for security
RUN addgroup -g 1001 -S strapi && \
    adduser -S -u 1001 -G strapi strapi

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install ONLY production dependencies (no devDependencies)
RUN npm ci --only=production && \
    npm cache clean --force

# Copy built admin panel from builder stage
COPY --from=builder --chown=strapi:strapi /app/build ./build

# Copy source code (excluding node_modules)
COPY --chown=strapi:strapi . .

# Switch to non-root user
USER strapi

# Expose port
EXPOSE 8080

# Set production environment
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD node -e "require('http').get('http://localhost:8080/_health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Use tini to handle signals properly
ENTRYPOINT ["/sbin/tini", "--"]

# Start Strapi
CMD ["npm", "run", "start"]
