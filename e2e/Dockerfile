FROM mcr.microsoft.com/playwright

COPY package*.json ./
RUN npm ci --only=production
COPY . .
