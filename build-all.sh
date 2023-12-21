#!/bin/bash

set -eux

NODE_STABLE="18"
NODE_VERSIONS=${NODE_VERSIONS:="20.8.1 18.18.2"}
YARN_VERSION=${YARN_VERSION:="1.22.19"}
NPM_VERSION=${NPM_VERSION:="9.8.1"}
BUILD_PLATFORMS=${BUILD_PLATFORMS:='linux/amd64 linux/arm64'}

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
    docker buildx build --platform="${DOCKER_PLATFORMS}" --progress=plain ${DOCKER_NODE_BUILD_ARGS} .

    # Build test images to see it work
    for PLATFORM in $BUILD_PLATFORMS; do
        echo "Load node $NODE_VERSION builder and base image into dockers image store for $PLATFORM"
        docker buildx build --platform="${PLATFORM}" --progress=plain --target=base --load --tag="gcr.io/${PROJECT_ID}/node-base.${BRANCH_NAME}:${NODE_VERSION}" ${DOCKER_NODE_BUILD_ARGS} .
        docker buildx build --platform="${PLATFORM}" --progress=plain --target=builder --load --tag="gcr.io/${PROJECT_ID}/node-builder.${BRANCH_NAME}:${NODE_VERSION}" ${DOCKER_NODE_BUILD_ARGS} .
        docker buildx build --platform="${PLATFORM}" --progress=plain --target=fat-base --load --tag="gcr.io/${PROJECT_ID}/node-fat-base.${BRANCH_NAME}:${NODE_VERSION}" ${DOCKER_NODE_BUILD_ARGS} .

        echo "Building test image with old docker build for node $NODE_VERSION for $PLATFORM"
        DOCKER_BUILDKIT=0 docker build --platform="${PLATFORM}" --tag="test:${NODE_VERSION}" --build-arg=NODE_VERSION="${NODE_VERSION}" --build-arg=BRANCH_NAME="${BRANCH_NAME}" --build-arg=NPM_TOKEN="${NPM_TOKEN}" -f test/Dockerfile.old test/
        echo "Running test image for node $NODE_VERSION for $PLATFORM"
        docker run --platform="${PLATFORM}" "test:${NODE_VERSION}"

        echo "Building test image with buildx for node $NODE_VERSION for $PLATFORM"
        docker images
        docker buildx ls
        docker context ls
        docker --context=default buildx build --platform="${PLATFORM}" --progress=plain --load --tag="test:${NODE_VERSION}" --secret id=NPM_TOKEN --build-arg=NODE_VERSION="${NODE_VERSION}" --build-arg=BRANCH_NAME="${BRANCH_NAME}" test/
        echo "Running test image for node $NODE_VERSION for $PLATFORM"
        docker run --platform="${PLATFORM}" "test:${NODE_VERSION}"
    done

    if [[ -n "$PUSH" ]]; then
        TAG_BASE_STABLE=""
        TAG_BUILDER_STABLE=""
        TAG_FAT_BASE_STABLE=""
        echo  "$NODE_MAJOR_VERSION = $NODE_STABLE" 
        if [ "$NODE_MAJOR_VERSION" = "$NODE_STABLE" ]; then
            TAG_BASE_STABLE="--tag=gcr.io/${PROJECT_ID}/node-base.${BRANCH_NAME}:stable"
            TAG_BUILDER_STABLE="--tag=gcr.io/${PROJECT_ID}/node-builder.${BRANCH_NAME}:stable"
            TAG_FAT_BASE_STABLE="--tag=gcr.io/${PROJECT_ID}/node-fat-base.${BRANCH_NAME}:stable"
        fi

        echo Push base images
        docker buildx build --platform="${DOCKER_PLATFORMS}" --progress=plain --target=base ${DOCKER_NODE_BUILD_ARGS} --push \
        --tag="gcr.io/${PROJECT_ID}/node-base.${BRANCH_NAME}:${NODE_VERSION}-${COMMIT_SHA}" \
        --tag="gcr.io/${PROJECT_ID}/node-base.${BRANCH_NAME}:${NODE_VERSION}" \
        --tag="gcr.io/${PROJECT_ID}/node-base.${BRANCH_NAME}:${NODE_MAJOR_VERSION}.x" \
        $TAG_BASE_STABLE \
        .

        echo Push builder images
        docker buildx build --platform="${DOCKER_PLATFORMS}" --progress=plain --target=builder ${DOCKER_NODE_BUILD_ARGS} --push \
        --tag="gcr.io/${PROJECT_ID}/node-builder.${BRANCH_NAME}:${NODE_VERSION}-${COMMIT_SHA}" \
        --tag="gcr.io/${PROJECT_ID}/node-builder.${BRANCH_NAME}:${NODE_VERSION}" \
        --tag="gcr.io/${PROJECT_ID}/node-builder.${BRANCH_NAME}:${NODE_MAJOR_VERSION}.x" \
        $TAG_BUILDER_STABLE \
        .

        echo Push fat-base images
        docker buildx build --platform="${DOCKER_PLATFORMS}" --progress=plain --target=fat-base ${DOCKER_NODE_BUILD_ARGS} --push \
        --tag="gcr.io/${PROJECT_ID}/node-fat-base.${BRANCH_NAME}:${NODE_VERSION}-${COMMIT_SHA}" \
        --tag="gcr.io/${PROJECT_ID}/node-fat-base.${BRANCH_NAME}:${NODE_VERSION}" \
        --tag="gcr.io/${PROJECT_ID}/node-fat-base.${BRANCH_NAME}:${NODE_MAJOR_VERSION}.x" \
        $TAG_FAT_BASE_STABLE \
        .
    fi
done
