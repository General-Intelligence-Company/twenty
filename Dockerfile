# Server-only Dockerfile for Render deployments
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

COPY ./packages/twenty-emails/package.json /app/packages/twenty-emails/
COPY ./packages/twenty-server/package.json /app/packages/twenty-server/
COPY ./packages/twenty-server/patches /app/packages/twenty-server/patches
COPY ./packages/twenty-ui/package.json /app/packages/twenty-ui/
COPY ./packages/twenty-shared/package.json /app/packages/twenty-shared/
COPY ./packages/twenty-front/package.json /app/packages/twenty-front/
COPY ./packages/twenty-utils/package.json /app/packages/twenty-utils/
COPY ./packages/twenty-sdk/package.json /app/packages/twenty-sdk/

RUN yarn && yarn cache clean && npx nx reset

###############################################
# Build: server only
###############################################
FROM common-deps AS twenty-server-build

COPY ./packages/twenty-shared /app/packages/twenty-shared
COPY ./packages/twenty-utils /app/packages/twenty-utils
COPY ./packages/twenty-emails /app/packages/twenty-emails
COPY ./packages/twenty-server /app/packages/twenty-server

RUN npx nx run twenty-server:build

RUN cd /app/packages/twenty-server && \
    yarn workspaces focus --production && \
    yarn cache clean

###############################################
# Runtime
###############################################
FROM node:24-alpine AS twenty

ARG IMAGE_TAG='unknown'
ENV IMAGE_TAG=${IMAGE_TAG}

WORKDIR /app/packages/twenty-server

# Install runtime dependencies
RUN apk add --no-cache postgresql-client curl

# Copy server build
COPY --from=twenty-server-build /app /app

# Copy entrypoint
COPY ./packages/twenty-docker/twenty/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Set environment defaults
ENV NODE_ENV=production \
    NODE_PORT=3000

EXPOSE 3000

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["node", "dist/main"]
