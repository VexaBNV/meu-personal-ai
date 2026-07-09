FROM node:20-alpine
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build
RUN ls -la /app/dist/ && echo "Build OK"

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["node", "/app/dist/main.js"]
