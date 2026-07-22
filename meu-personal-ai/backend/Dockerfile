# ══════════════════════════════════════════════════════════════
# Meu Personal AI — Dockerfile (Railway-compatible)
# ══════════════════════════════════════════════════════════════

FROM node:20-alpine AS builder
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install

COPY . .
RUN npm run build

# ── Produção ──────────────────────────────────────────────────
FROM node:20-alpine AS production
WORKDIR /app

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nestjs

COPY --from=builder --chown=nestjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nestjs:nodejs /app/node_modules ./node_modules
COPY --chown=nestjs:nodejs package.json ./

ENV NODE_ENV=production \
    PORT=3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget -qO- http://localhost:${PORT}/health || exit 1

USER nestjs
EXPOSE 3000

CMD ["node", "dist/main.js"]
