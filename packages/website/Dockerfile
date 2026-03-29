# ============================================
# Website (Nuxt SSR) - Production Dockerfile
# ============================================
# Server-Side Rendering with Node.js

FROM node:18.19.0-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci && npm cache clean --force

# Copy source code
COPY . .

# Accept build-time environment variables from Digital Ocean
ARG BASE_URL
ARG NODE_ENV=production
ARG OMISE_PUBLIC_KEY
ARG OMISE_DEFAULT_PAYMENT_METHOD=credit_card
ARG OMISE_OTHER_PAYMENT_METHOD=promptpay
ARG GTM_ID

# Set as environment variables for the build
ENV BASE_URL=$BASE_URL
ENV NODE_ENV=$NODE_ENV
ENV OMISE_PUBLIC_KEY=$OMISE_PUBLIC_KEY
ENV OMISE_DEFAULT_PAYMENT_METHOD=$OMISE_DEFAULT_PAYMENT_METHOD
ENV OMISE_OTHER_PAYMENT_METHOD=$OMISE_OTHER_PAYMENT_METHOD
ENV GTM_ID=$GTM_ID

# Build for SSR (not static)
RUN npm run build

# ============================================
# Production Runtime
# ============================================
FROM node:18.19.0-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm ci --production && npm cache clean --force

# Copy built files from builder
COPY --from=builder /app/.nuxt ./.nuxt
COPY --from=builder /app/static ./static
COPY --from=builder /app/nuxt.config.js ./nuxt.config.js

# Set runtime environment variables
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=8080

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:8080/ || exit 1

# Start Nuxt server
CMD ["npm", "run", "start"]
