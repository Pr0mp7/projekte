#!/bin/bash

# Default values for arguments
CORE_TAG="v2.4.188"
MODULES_TAG="v2.4.188"
PHP_VER="20190902"
LIBFAUP_COMMIT="3a26d0a"
DOCKER_REPO=""
DOCKER_IMAGE="misp"
DOCKER_TAG="v0.2.0-docker"
BUILD_CONTEXT="./core"

# Function to display usage information
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --core-tag TAG                  Set the misp core tag (default: $CORE_TAG)"
    echo "  --modules-tag TAG               Set the misp modules tag (default: $MODULES_TAG)"
    echo "  --php-ver VERSION               Set the PHP version (default: $PHP_VER)"
    echo "  --libfaup-commit COMMIT         Set the libfaup commit (default: $LIBFAUP_COMMIT)"
    echo "  --target-docker-repo REPO       Set your target Docker repo (default: $DOCKER_REPO)"
    echo "  --target-docker-image IMAGE     Set your target Docker image (default: $DOCKER_IMAGE)"
    echo "  --target-docker-tag TAG         Set the target Docker tag (default: $DOCKER_TAG)"
    echo "  -h, --help                      Display this help message"
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --core-tag) CORE_TAG="$2"; shift ;;
        --modules-tag) MODULES_TAG="$2"; shift ;;
        --php-ver) PHP_VER="$2"; shift ;;
        --libfaup-commit) LIBFAUP_COMMIT="$2"; shift ;;
        --target-docker-repo) DOCKER_REPO="$2"; shift ;;
        --target-docker-image) DOCKER_IMAGE="$2"; shift ;;
        --target-docker-tag) DOCKER_TAG="$2"; shift ;;
        --build-context) BUILD_CONTEXT="$2"; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; usage; exit 1 ;;
    esac
    shift
done

# Display the values (for debugging purposes)
echo "CORE_TAG=$CORE_TAG"
echo "MODULES_TAG=$MODULES_TAG"
echo "PHP_VER=$PHP_VER"
echo "LIBFAUP_COMMIT=$LIBFAUP_COMMIT"
echo "DOCKER_REPO=$DOCKER_REPO"
echo "DOCKER_IMAGE=$DOCKER_IMAGE"
echo "DOCKER_TAG=$DOCKER_TAG"
echo "BUILD_CONTEXT=$BUILD_CONTEXT"

# Build the Docker image
docker build --no-cache \
    --build-arg CORE_TAG=$CORE_TAG \
    --build-arg MODULES_TAG=$MODULES_TAG \
    --build-arg PHP_VER=$PHP_VER \
    --build-arg LIBFAUP_COMMIT=$LIBFAUP_COMMIT \
    -t $DOCKER_REPO/$DOCKER_IMAGE:$DOCKER_TAG $BUILD_CONTEXT

# Push the Docker image
docker push $DOCKER_REPO/$DOCKER_IMAGE:$DOCKER_TAG
