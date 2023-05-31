ARG NODE_VERSION=18.x
ARG BRANCH_NAME=master

FROM gcr.io/connectedcars-staging/node-builder.$BRANCH_NAME:$NODE_VERSION as builder

ARG NPM_TOKEN=""

WORKDIR /app

USER builder

# Copy application code.
COPY --chown=builder:builder . /app

RUN ls -l

RUN node -v
RUN npm -v
RUN yarn -v

RUN npm run id

RUN ls -rl /tmp

ENV GIT_SSH_COMMAND "ssh -v"

# Check if host key is working
RUN (ssh -o "BatchMode yes" github.com 2>&1 || true) | grep 'Permission denied (publickey)'

RUN id

RUN uname -a

RUN export | sed 's/\(NPM_TOKEN=....\).*\(....\)/\1___\2/g'

RUN npm install

RUN npm test

# Install a binary dependency to see if gyp works
RUN npm install --loglevel verbose node-expat

FROM gcr.io/connectedcars-staging/node-base.$BRANCH_NAME:$NODE_VERSION

WORKDIR /app

EXPOSE 3100

COPY --from=builder /app .

CMD node .
