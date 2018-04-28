ARG NODE_VERSION=10.0.0

FROM gcr.io/connectedcars-staging/node-builder.master:$NODE_VERSION as builder

ARG GITHUB_PAT

WORKDIR /app

# Copy application code.
COPY . /app

RUN ls -l

RUN npm install

RUN npm test

FROM gcr.io/connectedcars-staging/node-base.master:$NODE_VERSION

WORKDIR /app

EXPOSE 3100

COPY --from=builder /app .

CMD npm start