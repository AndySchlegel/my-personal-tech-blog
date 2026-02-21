# ============================================
# Backend Dockerfile - Multi-Stage Build
#
# Stage 1: Install dependencies + compile TypeScript
# Stage 2: Run the compiled JavaScript (smaller image)
# ============================================

# --- Stage 1: Build ---
FROM node:22-alpine AS build

WORKDIR /app

# Copy package files first (better Docker layer caching)
# If package.json hasn't changed, npm install is skipped on rebuild
COPY package.json package-lock.json ./

# Install ALL dependencies (including dev deps for TypeScript compiler)
RUN npm ci

# Copy source code
COPY tsconfig.json ./
COPY src/ ./src/

# Compile TypeScript -> JavaScript (output goes to dist/)
RUN npm run build

# --- Stage 2: Production ---
FROM node:22-alpine

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install ONLY production dependencies (no TypeScript, no ESLint, etc.)
RUN npm ci --omit=dev

# Copy compiled JavaScript from build stage
COPY --from=build /app/dist ./dist

# Run as non-root user (security best practice)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Expose the port the server listens on
EXPOSE 3000

# Start the server
CMD ["node", "dist/server.js"]
