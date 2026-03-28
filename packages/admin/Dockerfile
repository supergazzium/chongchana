# Stage 1: Build Stage
FROM node:14.21.3-alpine AS builder

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm install

# Copy application files
COPY . .

# Build Nuxt application
RUN npm run build

# Prune dev dependencies
RUN npm prune --production

# Stage 2: Runtime Stage
FROM node:14.21.3-alpine

# Add tini for proper signal handling
RUN apk add --no-cache tini

# Create non-root user
RUN addgroup -g 1001 -S nuxt && \
    adduser -S -u 1001 -G nuxt nuxt

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Copy node_modules from builder
COPY --from=builder --chown=nuxt:nuxt /app/node_modules ./node_modules

# Copy built application
COPY --from=builder --chown=nuxt:nuxt /app/.nuxt ./.nuxt
COPY --from=builder --chown=nuxt:nuxt /app/static ./static

# Copy nuxt config and other necessary files
COPY --chown=nuxt:nuxt nuxt.config.js ./
COPY --chown=nuxt:nuxt . .

# Create .nuxt directory with proper permissions
RUN mkdir -p .nuxt && chown -R nuxt:nuxt /app

USER nuxt

EXPOSE 4040

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=4040

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD node -e "require('http').get('http://localhost:4040', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["npm", "run", "start"]
