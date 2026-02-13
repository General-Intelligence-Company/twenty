# Server-only Dockerfile for Render preview environments
# This builds only the twenty-server without the frontend to reduce build time and memory usage

# Base image for common dependencies
FROM node:24-alpine AS common-deps

WORKDIR /app

# Copy only the necessary files for dependency resolution
COPY ./package.json ./yarn.lock ./.yarnrc.yml ./tsconfig.base.json ./nx.json /app/
COPY ./.yarn/releases /app/.yarn/releases
COPY ./.yarn/patches /app/.yarn/patches

COPY ./packages/twenty-emails/package.json /app/packages/twenty-emails/
COPY ./packages/twenty-server/package.json /app/packages/twenty-server/
COPY ./packages/twenty-server/patches /app/packages/twenty-server/patches
COPY ./packages/twenty-shared/package.json /app/packages/twenty-shared/

# Install dependencies (skip frontend packages)
RUN yarn && yarn cache clean && npx nx reset


# Build the server
FROM common-deps AS twenty-server-build

# Copy source code after installing dependencies to accelerate subsequent builds
COPY ./packages/twenty-emails /app/packages/twenty-emails
COPY ./packages/twenty-shared /app/packages/twenty-shared
COPY ./packages/twenty-server /app/packages/twenty-server

RUN npx nx run twenty-server:build

RUN yarn workspaces focus --production twenty-emails twenty-shared twenty-server


# Final stage: Run the server
FROM node:24-alpine AS twenty-server

# Used to run healthcheck in docker
RUN apk add --no-cache curl jq

RUN npm install -g tsx

RUN apk add --no-cache postgresql-client

WORKDIR /app/packages/twenty-server

ARG APP_VERSION
ENV APP_VERSION=$APP_VERSION

# Copy built server from previous stage
COPY --chown=1000 --from=twenty-server-build /app /app

# Set metadata and labels
LABEL org.opencontainers.image.source=https://github.com/twentyhq/twenty
LABEL org.opencontainers.image.description="Twenty CRM server-only image for Render preview environments"

RUN mkdir -p /app/.local-storage /app/packages/twenty-server/.local-storage && \
    chown -R 1000:1000 /app

# Use non root user with uid 1000
USER 1000

# Expose the default NestJS port
EXPOSE 3000

CMD ["node", "dist/main"]
