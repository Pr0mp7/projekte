#!/bin/bash

# Default values for arguments
CORE_TAG="v2.4.188"
MODULES_TAG="v2.4.188"
PHP_VER="20190902"
LIBFAUP_COMMIT="3a26d0a"
DOCKER_REPO=""
DOCKER_IMAGE="misp"
DOCKER_TAG="v0.2.0-kaniko"
BUILD_CONTEXT="./core/"
BUILD_CONTEXT=$(cd "$BUILD_CONTEXT" && pwd)


# Function to display usage information
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --username USERNAME             Set the docker hub username (default: $USERNAME)"
    echo "  --password PASSWORD             Set the docker hub API Key (default: $PASSWORD)"
    echo "  --core-tag TAG                  Set the core tag (default: $CORE_TAG)"
    echo "  --modules-tag TAG               Set the modules tag (default: $MODULES_TAG)"
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
        --username) USERNAME="$2"; shift ;;
        --password) PASSWORD="$2"; shift ;;
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
echo "USERNAME=$USERNAME"
echo "PASSWORD=$PASSWORD"

# Parse arguments
while getopts "u:p:" opt; do
    case $opt in
        u) USERNAME=$OPTARG ;;
        p) PASSWORD=$OPTARG ;;
        *) usage ;;
    esac
done

# Check if username and password are provided
if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    usage
fi

# Encode username:password to base64
API_KEY=$(echo -n "$USERNAME:$PASSWORD" | base64)

# Path to the Dockerfile within the build context
DOCKERFILE_PATH="$BUILD_CONTEXT/Dockerfile"

# Define the registry URL and your API key
REGISTRY_URL="https://index.docker.io/v1/"

# Create the Docker authentication file for Kaniko
AUTH_JSON=$(jq -n --arg url "$REGISTRY_URL" --arg token "$API_KEY" \
'{
    "auths": {
        ($url): {
            "auth": $token
        }
    }
}')

# Save the authentication file
mkdir -p ~/.docker
echo "$AUTH_JSON" > ~/.docker/config.json

# Ensure the Dockerfile exists at the specified path
if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo "Dockerfile not found at $DOCKERFILE_PATH"
    exit 1
fi

# Run Kaniko to build and push the Docker image
docker run --rm -v $BUILD_CONTEXT:/workspace -v ~/.docker:/kaniko/.docker gcr.io/kaniko-project/executor:latest \
    --context /workspace --dockerfile /workspace/Dockerfile \
    --destination $DOCKER_REPO/$DOCKER_IMAGE:$DOCKER_TAG \
    --build-arg CORE_TAG=$CORE_TAG \
    --build-arg MODULES_TAG=$MODULES_TAG \
    --build-arg PHP_VER=$PHP_VER \
    --build-arg LIBFAUP_COMMIT=$LIBFAUP_COMMIT
