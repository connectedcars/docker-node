ARG NODE_VERSION=12.x
ARG BRANCH_NAME=master

FROM gcr.io/connectedcars-staging/node-builder.$BRANCH_NAME:$NODE_VERSION as builder

ARG NPM_TOKEN=""
ARG GITHUB_PAT
ARG SSH_KEY_PASSWORD

WORKDIR /app

USER builder

# Copy application code.
COPY --chown=builder:builder . /app

RUN ls -l

RUN node -v
RUN npm -v
RUN yarn -v

RUN npm run export

RUN npm run id

RUN ls -rl /tmp

ENV GIT_SSH_COMMAND "ssh -v"

RUN id

RUN npm install

RUN npm test

FROM gcr.io/connectedcars-staging/node-base.$BRANCH_NAME:$NODE_VERSION

WORKDIR /app

EXPOSE 3100

COPY --from=builder /app .

CMD node .
