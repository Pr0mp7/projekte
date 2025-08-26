#!/bin/bash

# Simple MISP Build Script without registry complications
# For testing basic Docker connectivity

set -e

# Configuration
IMAGE_NAME="misp"
IMAGE_TAG="latest"
BUILD_CONTEXT="."
DOCKERFILE_OPTION="${1:-minimal}"

echo "=== Simple MISP Container Build ==="
echo "Building MISP with $DOCKERFILE_OPTION base..."

# Select Dockerfile
case "$DOCKERFILE_OPTION" in
    "minimal"|"ubuntu")
        DOCKERFILE="docker/Dockerfile.minimal"
        ;;
    "alpine")
        DOCKERFILE="docker/Dockerfile.alpine"
        ;;
    "centos")
        DOCKERFILE="docker/Dockerfile.centos"
        ;;
    *)
        echo "Usage: $0 [minimal|alpine|centos]"
        exit 1
        ;;
esac

echo "Using Dockerfile: $DOCKERFILE"

# Test Docker connectivity first
echo ""
echo "Testing Docker network connectivity..."
if docker run --rm alpine:3.19 ping -c 2 8.8.8.8 >/dev/null 2>&1; then
    echo "✓ Docker can reach internet"
else
    echo "✗ Docker cannot reach internet"
    echo "Check Docker network configuration"
    exit 1
fi

if docker run --rm alpine:3.19 nslookup github.com >/dev/null 2>&1; then
    echo "✓ Docker DNS resolution works"
else
    echo "✗ Docker DNS resolution failed"
    echo "Check Docker DNS settings"
    exit 1
fi

echo ""
echo "Building image..."

# Simple build without registry tagging
docker build \
    --build-arg MISP_BRANCH=v2.4.190 \
    -t $IMAGE_NAME:$IMAGE_TAG \
    -f $DOCKERFILE \
    $BUILD_CONTEXT

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Build successful!"
    echo "Image: $IMAGE_NAME:$IMAGE_TAG"
    echo ""
    echo "To test the container:"
    echo "  docker run -d -p 8080:80 --name misp-test $IMAGE_NAME:$IMAGE_TAG"
else
    echo "✗ Build failed!"
    exit 1
fi