# syntax=docker/dockerfile:1.7

# Builder: keep the workshop base and patch the vulnerable transitive dependency.
FROM node:20.11-slim AS builder
WORKDIR /app
COPY app/package*.json ./
RUN npm pkg set overrides.proxy-addr=2.0.8 \
    && npm install --package-lock-only --omit=dev --ignore-scripts \
    && npm ci --omit=dev
COPY app/src/ ./src/
COPY app/db/ ./db/

# Runtime: update OS security packages and omit unused package managers.
FROM node:20.11-slim
RUN apt-get update \
    && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/* /usr/local/lib/node_modules/npm /opt/yarn-* \
    && rm -f /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/yarn /usr/local/bin/yarnpkg
WORKDIR /app
COPY --from=builder /app /app
ENV NODE_ENV=production
EXPOSE 3000
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
    CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode===200?0:1)).on('error', () => process.exit(1))"
CMD ["node", "src/index.js"]
