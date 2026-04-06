FROM node:20-alpine

WORKDIR /app

COPY package.json ./
RUN npm install --omit=dev

COPY src ./src

ENV NODE_ENV=production
ENV PORT=3000
ENV APP_NAME=freshtie

EXPOSE 3000

CMD ["npm", "start"]