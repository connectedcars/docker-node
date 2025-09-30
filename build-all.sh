#!/bin/bash

set -eux

NODE_STABLE="22"
NODE_VERSIONS=${NODE_VERSIONS:="22.17.1 20.19.4 18.20.8"}
YARN_VERSION=${YARN_VERSION:="1.22.19"}
NPM_VERSION=${NPM_VERSION:="10.9.2"}
# Disabled arm builds for now as they're only used locally
BUILD_PLATFORMS=${BUILD_PLATFORMS:='linux/amd64'}
# BUILD_PLATFORMS=${BUILD_PLATFORMS:='linux/amd64 linux/arm64'}

# External variables
PROJECT_ID=${PROJECT_ID:-}
NPM_TOKEN=${NPM_TOKEN:-}
COMMIT_SHA=${COMMIT_SHA:-}
BRANCH_NAME=${BRANCH_NAME:-}
PUSH=${PUSH:-}

if [[ ! -n "$PROJECT_ID" ]]; then
    echo "PROJECT_ID needs to be set"
    exit 255
fi

if [[ ! -n "$NPM_TOKEN" ]]; then
    echo "NPM_TOKEN needs to be set"
    exit 255
fi

if [[ ! -n "$COMMIT_SHA" ]]; then
    echo "COMMIT_SHA needs to be set"
    exit 255
fi

if [[ ! -n "$BRANCH_NAME" ]]; then
    echo "BRANCH_NAME needs to be set"
    exit 255
fi

DOCKER_PLATFORMS=$(echo "$BUILD_PLATFORMS" | sed "s/ /,/g")

# buildkit sane defaults
export PROGRESS_NO_TRUNC=1

# This is all a bit wierd because dockers local image store does not handle multi-arch images so it can only point to one arch at a time
# It should be fixed soonish https://github.com/docker/roadmap/issues/371 but right now we have to use buildx cache and build in some clear way to get it working
for NODE_VERSION in $NODE_VERSIONS; do
    NODE_MAJOR_VERSION=$(echo "$NODE_VERSION" | cut -d. -f1)

    DOCKER_NODE_BUILD_ARGS="--build-arg=NODE_VERSION=${NODE_VERSION} --build-arg=NPM_VERSION=${NPM_VERSION} --build-arg=YARN_VERSION=${YARN_VERSION}"
    
    # Build image cache for all platforms so it's ready
    echo "Building node $NODE_VERSION images for $BUILD_PLATFORMS";
    docker buildx build --platform="${DOCKER_PLATFORMS}" --progress=plain ${DOCKER_NODE_BUILD_ARGS} --load -t "downloader" . -f Dockerfile.downloader;
    docker buildx build --platform="${DOCKER_PLATFORMS}" --progress=plain ${DOCKER_NODE_BUILD_ARGS} --load -t "common:${NODE_VERSION}" . -f Dockerfile.common;
    docker buildx build --platform="${DOCKER_PLATFORMS}" --progress=plain ${DOCKER_NODE_BUILD_ARGS} -t "builder:${NODE_VERSION}" . -f Dockerfile.builder;
    docker buildx build --platform="${DOCKER_PLATFORMS}" --progress=plain ${DOCKER_NODE_BUILD_ARGS} --load -t "base:${NODE_VERSION}" . -f Dockerfile.base;
    docker buildx build --platform="${DOCKER_PLATFORMS}" --progress=plain ${DOCKER_NODE_BUILD_ARGS} -t "fat-base:${NODE_VERSION}" . -f Dockerfile.fat-base;

    # Build test images to see it work
    for PLATFORM in $BUILD_PLATFORMS; do
        echo "Load node $NODE_VERSION builder and base image into dockers image store for $PLATFORM"
        docker buildx build --platform="${PLATFORM}" --progress=plain . -f Dockerfile.base --load --tag="europe-west1-docker.pkg.dev/connectedcars-build/node-base/${BRANCH_NAME}:${NODE_VERSION}" ${DOCKER_NODE_BUILD_ARGS}
        docker buildx build --platform="${PLATFORM}" --progress=plain . -f Dockerfile.builder --load --tag="europe-west1-docker.pkg.dev/connectedcars-build/node-builder/${BRANCH_NAME}:${NODE_VERSION}" ${DOCKER_NODE_BUILD_ARGS}
        docker buildx build --platform="${PLATFORM}" --progress=plain . -f Dockerfile.fat-base --load --tag="europe-west1-docker.pkg.dev/connectedcars-build/node-fat-base/${BRANCH_NAME}:${NODE_VERSION}" ${DOCKER_NODE_BUILD_ARGS}

        # These builds are no longer necessary since we use buildx
        # echo "Building test image with old docker build for node $NODE_VERSION for $PLATFORM"
        # DOCKER_BUILDKIT=0 docker build --platform="${PLATFORM}" --tag="test:${NODE_VERSION}" --build-arg=NODE_VERSION="${NODE_VERSION}" --build-arg=BRANCH_NAME="${BRANCH_NAME}" --build-arg=NPM_TOKEN="${NPM_TOKEN}" -f test/Dockerfile.old test/
        # echo "Running test image for node $NODE_VERSION for $PLATFORM"
        # docker run --platform="${PLATFORM}" "test:${NODE_VERSION}"

        echo "Building test image with buildx for node $NODE_VERSION for $PLATFORM"
        # For some reason the multi arch builder does not have access to the 
        # local images on google cloud builds version of docker so we need 
        # to use default to get this working. Also docker for mac no creates
        # a desktop-linux context where you can't set builder so we need to
        # also set the context for this to work there.
        docker --context default buildx build --builder default --platform="${PLATFORM}" --progress=plain --load --tag="test:${NODE_VERSION}" --secret id=NPM_TOKEN --build-arg=NODE_VERSION="${NODE_VERSION}" --build-arg=BRANCH_NAME="${BRANCH_NAME}" test/
        echo "Running test image for node $NODE_VERSION for $PLATFORM"
        docker run --platform="${PLATFORM}" "test:${NODE_VERSION}"
    done

    if [[ -n "$PUSH" ]]; then
        TAG_BASE_STABLE=""
        TAG_BUILDER_STABLE=""
        TAG_FAT_BASE_STABLE=""
        echo  "$NODE_MAJOR_VERSION = $NODE_STABLE" 
        if [ "$NODE_MAJOR_VERSION" = "$NODE_STABLE" ]; then
            TAG_BASE_STABLE="--tag=europe-west1-docker.pkg.dev/connectedcars-build/node-base/${BRANCH_NAME}:stable"
            TAG_BUILDER_STABLE="--tag=europe-west1-docker.pkg.dev/connectedcars-build/node-builder/${BRANCH_NAME}:stable"
            TAG_FAT_BASE_STABLE="--tag=europe-west1-docker.pkg.dev/connectedcars-build/node-fat-base/${BRANCH_NAME}:stable"
        fi

        echo Push base images
        docker buildx build --platform="${DOCKER_PLATFORMS}" --progress=plain . -f Dockerfile.base ${DOCKER_NODE_BUILD_ARGS} --push \
        --tag="europe-west1-docker.pkg.dev/connectedcars-build/node-base/${BRANCH_NAME}:${NODE_VERSION}-${COMMIT_SHA}" \
        --tag="europe-west1-docker.pkg.dev/connectedcars-build/node-base/${BRANCH_NAME}:${NODE_VERSION}" \
        --tag="europe-west1-docker.pkg.dev/connectedcars-build/node-base/${BRANCH_NAME}:${NODE_MAJOR_VERSION}.x" \
        $TAG_BASE_STABLE \
        .

        echo Push builder images
        docker buildx build --platform="${DOCKER_PLATFORMS}" --progress=plain . -f Dockerfile.builder ${DOCKER_NODE_BUILD_ARGS} --push \
        --tag="europe-west1-docker.pkg.dev/connectedcars-build/node-builder/${BRANCH_NAME}:${NODE_VERSION}-${COMMIT_SHA}" \
        --tag="europe-west1-docker.pkg.dev/connectedcars-build/node-builder/${BRANCH_NAME}:${NODE_VERSION}" \
        --tag="europe-west1-docker.pkg.dev/connectedcars-build/node-builder/${BRANCH_NAME}:${NODE_MAJOR_VERSION}.x" \
        $TAG_BUILDER_STABLE \
        .

        echo Push fat-base images
        docker buildx build --platform="${DOCKER_PLATFORMS}" --progress=plain . -f Dockerfile.fat-base ${DOCKER_NODE_BUILD_ARGS} --push \
        --tag="europe-west1-docker.pkg.dev/connectedcars-build/node-fat-base/${BRANCH_NAME}:${NODE_VERSION}-${COMMIT_SHA}" \
        --tag="europe-west1-docker.pkg.dev/connectedcars-build/node-fat-base/${BRANCH_NAME}:${NODE_VERSION}" \
        --tag="europe-west1-docker.pkg.dev/connectedcars-build/node-fat-base/${BRANCH_NAME}:${NODE_MAJOR_VERSION}.x" \
        $TAG_FAT_BASE_STABLE \
        .
    fi
done
