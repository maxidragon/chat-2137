FROM node:18-slim

RUN npm install -g @nestjs/cli

WORKDIR /app
ENV NODE_ENV production

RUN apt-get update && apt-get install -y openssl

COPY package*.json ./
RUN npm install

COPY . .
RUN npx prisma generate
RUN npm run build

RUN chmod +x /app/entrypoint.sh

EXPOSE 5000

CMD [ "/app/entrypoint.sh" ]