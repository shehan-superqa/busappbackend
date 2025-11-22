# Use Node.js 18 LTS
FROM node:18-slim

# Set working directory
WORKDIR /app

# Install PM2 globally
RUN npm install -g pm2

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --omit=dev --no-audit --no-fund

# Copy application code
COPY . .

# Create logs directory
RUN mkdir -p /var/log

# Expose ports
EXPOSE 3000 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application with PM2
CMD ["pm2-runtime", "start", "ecosystem.config.js"]

