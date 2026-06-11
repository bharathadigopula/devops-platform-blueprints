#==============================================================================
# BASE IMAGE
#==============================================================================

FROM node:22-alpine3.22

#==============================================================================
# IMAGE METADATA
#==============================================================================

LABEL org.opencontainers.image.title="AWS ECS Fargate GitHub OIDC App"
LABEL org.opencontainers.image.description="Small HTTP service for the ECS Fargate portfolio blueprint"
LABEL org.opencontainers.image.source="https://github.com/bharathadigopula/devops-platform-blueprints"

#==============================================================================
# RUNTIME ENVIRONMENT
#==============================================================================

ENV NODE_ENV=production
ENV PORT=8080

#==============================================================================
# RUNTIME PACKAGE HARDENING
#==============================================================================

RUN apk add --no-cache libcrypto3=3.5.7-r0 libssl3=3.5.7-r0 && \
    rm -rf /usr/local/bin/corepack \
    /usr/local/bin/npm \
    /usr/local/bin/npx \
    /usr/local/bin/yarn \
    /usr/local/bin/yarnpkg \
    /usr/local/lib/node_modules/corepack \
    /usr/local/lib/node_modules/npm \
    /opt/yarn-v*

#==============================================================================
# APPLICATION WORKDIR
#==============================================================================

WORKDIR /app

#==============================================================================
# APPLICATION SOURCE
#==============================================================================

COPY --chown=node:node package.json ./
COPY --chown=node:node src ./src

#==============================================================================
# NON ROOT USER
#==============================================================================

USER node

#==============================================================================
# APPLICATION PORT
#==============================================================================

EXPOSE 8080

#==============================================================================
# APPLICATION HEALTHCHECK
#==============================================================================

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 CMD ["node", "-e", "fetch('http://127.0.0.1:8080/health').then((response) => { if (!response.ok) process.exit(1); }).catch(() => process.exit(1));"]

#==============================================================================
# APPLICATION COMMAND
#==============================================================================

CMD ["node", "src/server.js"]
