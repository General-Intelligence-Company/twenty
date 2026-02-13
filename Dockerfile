# Server-only Dockerfile for Render preview environments
# Based on packages/twenty-docker/twenty/Dockerfile but skips the frontend build
# to reduce build time and memory usage on Render's standard plan.

###############################################
# Base: install dependencies
###############################################
FROM node:24-alpine AS common-deps

WORKDIR /app

# Copy dependency files
COPY ./package.json ./yarn.lock ./.yarnrc.yml ./tsconfig.base.json ./nx.json /app/
COPY ./.yarn/releases /app/.yarn/releases
COPY ./.yarn/patches /app/.yarn/patches

# Copy package.json files for dependency resolution
# Note: We include twenty-front and twenty-ui package.json files even though we don't
# build them, because yarn needs these for proper workspace dependency resolution
COPY ./packages/twenty-emails/package.json /app/packages/twenty-emails/
COPY ./packages/twenty-server/package.json /app/packages/twenty-server/
COPY ./packages/twenty-server/patches /app/packages/twenty-server/patches
COPY ./packages/twenty-shared/package.json /app/packages/twenty-shared/
COPY ./packages/twenty-ui/package.json /app/packages/twenty-ui/
COPY ./packages/twenty-front/package.json /app/packages/twenty-front/

# Install all dependencies
RUN yarn && yarn cache clean && npx nx reset


###############################################
# Build: server only
###############################################
FROM common-deps AS twenty-server-build

# Copy source code after installing dependencies to accelerate subsequent builds
COPY ./packages/twenty-emails /app/packages/twenty-emails
COPY ./packages/twenty-shared /app/packages/twenty-shared
COPY ./packages/twenty-server /app/packages/twenty-server

RUN npx nx run twenty-server:build

RUN yarn workspaces focus --production twenty-emails twenty-shared twenty-server


###############################################
# Runtime
###############################################
FROM node:24-alpine AS twenty-server

WORKDIR /app/packages/twenty-server

# Install runtime dependencies
RUN apk add --no-cache postgresql-client curl jq

# Install tsx globally for scripts
RUN npm install -g tsx

# Copy server build from previous stage
COPY --chown=1000 --from=twenty-server-build /app /app

# Copy entrypoint script for database migrations
COPY ./packages/twenty-docker/twenty/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Set metadata and labels
LABEL org.opencontainers.image.source=https://github.com/twentyhq/twenty
LABEL org.opencontainers.image.description="Twenty CRM server-only image for Render preview environments"

# Create local storage directories
RUN mkdir -p /app/.local-storage /app/packages/twenty-server/.local-storage && \
    chown -R 1000:1000 /app

# Set environment defaults
ARG APP_VERSION
ENV APP_VERSION=$APP_VERSION
ENV NODE_ENV=production

# Use non-root user with uid 1000
USER 1000

# Expose the default NestJS port
EXPOSE 3000

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["node", "dist/main"]
