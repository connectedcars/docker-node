ARG NODE_VERSION=10.0.0
ARG BRANCH_NAME=master

FROM gcr.io/connectedcars-staging/node-builder.$BRANCH_NAME:$NODE_VERSION as builder

#ARG GITHUB_PAT
ARG SSH_KEY_PASSWORD

WORKDIR /app

# Copy application code.
COPY . /app

RUN ls -l

RUN node -v
RUN npm -v
RUN yarn -v

RUN npm run export

RUN npm install

RUN npm test

FROM gcr.io/connectedcars-staging/node-base.$BRANCH_NAME:$NODE_VERSION

WORKDIR /app

EXPOSE 3100

COPY --from=builder /app .

CMD npm start
