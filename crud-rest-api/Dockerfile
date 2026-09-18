FROM node:lts-trixie-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser
USER appuser
EXPOSE 3000
CMD ["node", "index.js"]