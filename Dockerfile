FROM node:18-bullseye as build

# Add Tini https://github.com/krallin/tini
RUN set -x \
    && apt-get update \
    && apt-get install tini \
    && rm -rf /var/cache/apt/*

# Create app directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install packages
RUN npm ci

# Copy the app code
COPY . .

# Build the project
RUN npm run build

# Install packages only production dependencies
RUN npm ci --omit=dev

FROM gcr.io/distroless/nodejs:18

ENV NODE_ENV production

COPY --from=build /usr/bin/tini /usr/bin/tini
COPY --from=build /app /app
WORKDIR /app

# Expose ports
EXPOSE 8080

# Run the application
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD [ "/nodejs/bin/node", "dist/start-manager.js" ]
