FROM node:20-alpine
WORKDIR /app

COPY meu-personal-ai/backend/package.json meu-personal-ai/backend/package-lock.json ./
RUN npm ci

COPY meu-personal-ai/backend/ .
RUN npm run build

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["node", "dist/main.js"]
