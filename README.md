# docker-node

Ubuntu base image for node build and production:

## Example of usage:

cloudbuilder.yaml:

```yaml
steps:
  - name: "gcr.io/cloud-builders/docker"
    entrypoint: "bash"
    args:
      [
        "-c",
        'docker build --build-arg=GITHUB_PAT=$$GITHUB_PAT --tag="europe-west1-docker.pkg.dev/connectedcars-build/$REPO_NAME/$BRANCH_NAME:$COMMIT_SHA" .',
      ]
    secretEnv: ["GITHUB_PAT"]
images: ["europe-west1-docker.pkg.dev/connectedcars-build/$REPO_NAME/$BRANCH_NAME:$COMMIT_SHA"]
secrets:
  - kmsKeyName: projects/[Your project name]/locations/global/keyRings/cloudbuilder/cryptoKeys/[Your key name]
    secretEnv:
      GITHUB_PAT: [Your encrypted Github Personal Access Token]
```

Dockerfile:

```docker
ARG NODE_VERSION=16.x

FROM europe-west1-docker.pkg.dev/connectedcars-build/node-builder/master:$NODE_VERSION as builder

ARG GITHUB_PAT

WORKDIR /app

# Copy application code.
COPY . /app

RUN npm install

RUN npm test

FROM europe-west1-docker.pkg.dev/connectedcars-build/node-base/master:$NODE_VERSION

USER nobody

ENV NODE_ENV production

WORKDIR /app

EXPOSE 3100

COPY --from=builder /app .

CMD npm start
```

## Setup key encryption

Encrypt key:

```bash
echo "<api key>" | gcloud kms encrypt --plaintext-file=- --ciphertext-file=- --location=global --keyring=cloudbuilder --key=connectedcars-builder|base64
```

Test decryption:

```bash
echo "<encypted key>" | base64 -D | gcloud kms decrypt --plaintext-file=- --ciphertext-file=- --location=global --keyring=cloudbuilder --key=connectedcars-builder
```

## Testing the build

```bash
export NPM_TOKEN=`cat ~/.npmrc|grep _authToken|cut -d '=' -f 2`
# Only build specific node version on arm64
PROJECT_ID=connectedcars-staging NODE_VERSIONS="20.8.1" BUILD_PLATFORMS="linux/arm64" COMMIT_SHA=ABCD1234 BRANCH_NAME=`git symbolic-ref --short -q HEAD` ./build-all.sh
```

## Rollback to older version

```bash
export OLD_SHA=abcd1234
for NODE_VERSION in 18.7.0 16.16.0 14.20.0 12.22.12; do
  NODE_MAJOR_VERSION=$(echo "$NODE_VERSION" | cut -d. -f1)
  echo docker buildx imagetools create "europe-west1-docker.pkg.dev/connectedcars-build/node-builder.master:${NODE_VERSION}-${OLD_SHA}" --tag "europe-west1-docker.pkg.dev/connectedcars-build/node-builder/master:${NODE_MAJOR_VERSION}.x"
done
```
