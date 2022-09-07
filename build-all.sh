#!/bin/bash

set -eu

NODE_VERSIONS="18.7.0 16.16.0 14.20.0 12.22.12"
YARN_VERSION="1.22.19"
NPM_VERSION="8.16.0"
BUILD_PLATFORMS='linux/amd64 linux/arm64'

# External variables
PROJECT_ID=${PROJECT_ID:-}
NPM_TOKEN=${NPM_TOKEN:-}
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

if [[ ! -n "$BRANCH_NAME" ]]; then
    echo "BRANCH_NAME needs to be set"
    exit 255
fi

DOCKER_PLATFORMS=$(echo $BUILD_PLATFORMS | sed "s/ /,/g")

# buildkit sane defaults
export PROGRESS_NO_TRUNC=1

# This is all a bit wierd because dockers local image store does not handle multi-arch images so it can only point to one arch at a time
# It should be fixed soonish https://github.com/docker/roadmap/issues/371 but right now we have to use buildx cache and build in some clear way to get it working
for NODE_VERSION in $NODE_VERSIONS; do
    NODE_MAJOR_VERSION=$(echo $NODE_VERSION | cut -d. -f1)

    DOCKER_NODE_BUILD_ARGS="--build-arg=NODE_VERSION=${NODE_VERSION} --build-arg=NPM_VERSION=${NPM_VERSION} --build-arg=YARN_VERSION=${YARN_VERSION}"
    DOCKER_TEST_BUILD_ARGS="--build-arg=NODE_VERSION=${NODE_VERSION} --build-arg=NPM_TOKEN=${NPM_TOKEN} --build-arg=BRANCH_NAME=${BRANCH_NAME}"

    # Build image cache for all platforms so it's ready
    echo "Building node $NODE_VERSION images for $BUILD_PLATFORMS";
    docker buildx build --platform=${DOCKER_PLATFORMS} --progress=plain ${DOCKER_NODE_BUILD_ARGS} .

    # Build test images to see it work
    for PLATFORM in $BUILD_PLATFORMS; do
        echo "Load node $NODE_VERSION builder and base image into dockers image store for $PLATFORM"
        docker buildx build --platform=${PLATFORM} --progress=plain --target=base --load --tag=gcr.io/${PROJECT_ID}/node-base.${BRANCH_NAME}:${NODE_VERSION} ${DOCKER_NODE_BUILD_ARGS} .
        docker buildx build --platform=${PLATFORM} --progress=plain --target=builder --load --tag=gcr.io/${PROJECT_ID}/node-builder.${BRANCH_NAME}:${NODE_VERSION} ${DOCKER_NODE_BUILD_ARGS} .
        docker buildx build --platform=${PLATFORM} --progress=plain --target=fat-base --load --tag=gcr.io/${PROJECT_ID}/node-fat-base.${BRANCH_NAME}:${NODE_VERSION} ${DOCKER_NODE_BUILD_ARGS} .

        echo "Building test image for node $NODE_VERSION for $PLATFORM";
        docker buildx build --platform=${PLATFORM} --progress=plain ${DOCKER_TEST_BUILD_ARGS} --builder default --load --tag=test:${NODE_VERSION} test/
        echo docker buildx build --platform=${PLATFORM} --progress=plain ${DOCKER_TEST_BUILD_ARGS} --target=builder --builder default --load --tag=test-builder:${NODE_VERSION} test/

        echo "Running test image for node $NODE_VERSION for $PLATFORM";
        docker run --platform=${PLATFORM} test:${NODE_VERSION}
    done

    if [[ -n "$PUSH" ]]; then
        echo Push base images
        docker buildx build --platform=${DOCKER_PLATFORMS} --progress=plain --target=base ${DOCKER_NODE_BUILD_ARGS} --push \
        --tag=gcr.io/${PROJECT_ID}/node-base.${BRANCH_NAME}:${NODE_VERSION} \
        --tag=gcr.io/${PROJECT_ID}/node-base.${BRANCH_NAME}:$NODE_MAJOR_VERSION.x \
        .

        echo Push builder images
        docker buildx build --platform=${DOCKER_PLATFORMS} --progress=plain --target=builder ${DOCKER_NODE_BUILD_ARGS} --push \
        --tag=gcr.io/${PROJECT_ID}/node-builder.${BRANCH_NAME}:$NODE_VERSION.x \
        --tag=gcr.io/${PROJECT_ID}/node-builder.${BRANCH_NAME}:$NODE_MAJOR_VERSION.x \
        .

        echo Push fat-base images
        docker buildx build --platform=${DOCKER_PLATFORMS} --progress=plain --target=fat-base ${DOCKER_NODE_BUILD_ARGS} --push \
        --tag=gcr.io/${PROJECT_ID}/node-fat-base.${BRANCH_NAME}:${NODE_VERSION} \
        --tag=gcr.io/${PROJECT_ID}/node-fat-base.${BRANCH_NAME}:$NODE_MAJOR_VERSION.x \
        .
    fi
done
