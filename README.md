# docker-node

Docker Ubuntu 18.04 base image for node build and production:

## Example of usage:

cloudbuilder.yaml:

``` yaml
steps:
  - name: 'gcr.io/cloud-builders/docker'
    entrypoint: 'bash'
    args: ['-c', 'docker build --build-arg=GITHUB_PAT=$$GITHUB_PAT --tag="gcr.io/$PROJECT_ID/$REPO_NAME.$BRANCH_NAME:$COMMIT_SHA" .']
    secretEnv: ['GITHUB_PAT']
images: ['gcr.io/$PROJECT_ID/$REPO_NAME.$BRANCH_NAME:$COMMIT_SHA']
secrets:
- kmsKeyName: projects/[Your project name]/locations/global/keyRings/cloudbuilder/cryptoKeys/[Your key name]
  secretEnv:
    GITHUB_PAT: [Your encrypted Github Personal Access Token]
```

Dockerfile:

``` docker
ARG NODE_VERSION=10.x

FROM gcr.io/connectedcars-staging/node-builder.master:$NODE_VERSION as builder

ARG GITHUB_PAT

WORKDIR /app

# Copy application code.
COPY . /app

RUN npm install

RUN npm test

FROM gcr.io/connectedcars-staging/node-base.master:$NODE_VERSION

USER nobody

ENV NODE_ENV production

WORKDIR /app

EXPOSE 3100

COPY --from=builder /app .

CMD npm start
```

## Setup key encryption

Encrypt key:

``` bash
echo "<api key>" | gcloud kms encrypt --plaintext-file=- --ciphertext-file=- --location=global --keyring=cloudbuilder --key=containerbuilder|base64
```

Test decryption:

``` bash
echo "<encypted key>" | base64 -D | gcloud kms decrypt --plaintext-file=- --ciphertext-file=- --location=global --keyring=cloudbuilder --key=containerbuilder
```

## Testing the build

``` bash
docker build --build-arg=NODE_VERSION=10.0.0 --build-arg=NPM_VERSION=6.0.0 --build-arg=YARN_VERSION=1.6.0 --build-arg=GITHUB_PAT=... --target base -t node-base:10.0.0 -t node-base:10.x .
docker build --build-arg=NODE_VERSION=10.0.0 --build-arg=NPM_VERSION=6.0.0 --build-arg=YARN_VERSION=1.6.0 --target builder -t node-builder:10.0.0 -t node-builder:10.x .

docker build --build-arg=NODE_VERSION=8.11.1 --build-arg=NPM_VERSION=6.0.0 --build-arg=YARN_VERSION=1.6.0 --target base -t node-base:8.11.1 -t node-base:8.x .
docker build --build-arg=NODE_VERSION=8.11.1 --build-arg=NPM_VERSION=6.0.0 --build-arg=YARN_VERSION=1.6.0 --target builder -t node-builder:8.11.1 -t node-builder:8.x .
```