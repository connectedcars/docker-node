NODE_VERSIONS="18.7.0"
# 16.16.0 14.20.0 12.22.12"
YARN_VERSION="1.22.19"
NPM_VERSION="8.16.0"
TARGETS="base builder"
BUILD_PLATFORMS='linux/amd64 linux/arm64'


PROJECT_ID="connectedcars-staging"
BRANCH_NAME="master"


for NODE_VERSION in $NODE_VERSIONS; do 
    NODE_MAJOR_VERSION=$(echo $NODE_VERSION | cut -d. -f1)
    DOCKER_PLATFORMS=$(echo $BUILD_PLATFORMS | sed "s/ /,/g")
    for TARGET in $TARGETS; do
        echo "Building node $NODE_VERSION $TARGET image for $BUILD_PLATFORMS";
        docker buildx build --platform=${DOCKER_PLATFORMS} --output=type=image \
            --target=$TARGET \
            --build-arg=NODE_VERSION=${NODE_VERSION} \
            --build-arg=NPM_VERSION=${NPM_VERSION} \
            --build-arg=YARN_VERSION=${YARN_VERSION} \
            --tag=gcr.io/${PROJECT_ID}/node-base.${BRANCH_NAME}:${NODE_VERSION} \
            --tag=gcr.io/${PROJECT_ID}/node-base.${BRANCH_NAME}:$NODE_MAJOR_VERSION.x \
            .
        echo
    done
    echo "Building test image for node $NODE_VERSION for $BUILD_PLATFORMS";
    echo docker buildx build --platform=${BUILD_PLATFORMS} \
        --build-arg=NODE_VERSION=${NODE_VERSION} \
        --build-arg=BRANCH_NAME=${BRANCH_NAME} \
        --build-arg=SSH_KEY_PASSWORD=${GITHUB_PAT} \
        --build-arg=NPM_TOKEN=${NPM_TOKEN} \
        --tag=test:${NODE_VERSION} \
        test/
    echo
    for PLATFORM in $BUILD_PLATFORMS; do
        echo "Running test image for node $NODE_VERSION for $BUILD_PLATFORMS";
        echo docker run --platform=${PLATFORM} test:${NODE_VERSION}
        echo
    done
    echo "Building fat-base image for node $NODE_VERSION for $BUILD_PLATFORMS";
     echo docker buildx build --platform=${DOCKER_PLATFORMS} \
        --target=$TARGET \
        --build-arg=NODE_VERSION=${NODE_VERSION} \
        --build-arg=BRANCH_NAME=${BRANCH_NAME} \
        --tag=gcr.io/${PROJECT_ID}/node-fat-base.${BRANCH_NAME}:${NODE_VERSION} \
        --tag=gcr.io/${PROJECT_ID}/node-fat-base.${BRANCH_NAME}:$NODE_MAJOR_VERSION.x \
        .
    echo
done