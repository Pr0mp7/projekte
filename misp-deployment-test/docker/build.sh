#!/bin/bash

# MISP Container Build Script for RHEL
# This script builds the MISP container image for on-premises deployment

set -e

# Configuration
IMAGE_NAME="misp"
IMAGE_TAG="latest"
REGISTRY="localhost:5000"  # Change to your local registry
BUILD_CONTEXT="."
DOCKERFILE="docker/Dockerfile"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MISP Container Build Script ===${NC}"
echo "Building MISP container image for on-premises deployment"
echo ""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running or not accessible${NC}"
    exit 1
fi

# Check if Dockerfile exists
if [[ ! -f "$DOCKERFILE" ]]; then
    echo -e "${RED}Error: Dockerfile not found at $DOCKERFILE${NC}"
    exit 1
fi

echo -e "${YELLOW}Build Configuration:${NC}"
echo "  Image Name: $IMAGE_NAME"
echo "  Image Tag: $IMAGE_TAG"
echo "  Registry: $REGISTRY"
echo "  Build Context: $BUILD_CONTEXT"
echo "  Dockerfile: $DOCKERFILE"
echo ""

# Build arguments
BUILD_ARGS="--build-arg MISP_BRANCH=v2.4.190"
BUILD_ARGS="$BUILD_ARGS --build-arg MISP_TAG=v2.4.190"
BUILD_ARGS="$BUILD_ARGS --build-arg PHP_VER=8.2"

# Build the image
echo -e "${YELLOW}Building MISP container image...${NC}"
docker build \
    $BUILD_ARGS \
    -t $IMAGE_NAME:$IMAGE_TAG \
    -f $DOCKERFILE \
    $BUILD_CONTEXT

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ Container image built successfully!${NC}"
else
    echo -e "${RED}✗ Container build failed!${NC}"
    exit 1
fi

# Tag for registry
if [[ -n "$REGISTRY" ]]; then
    echo -e "${YELLOW}Tagging image for registry...${NC}"
    docker tag $IMAGE_NAME:$IMAGE_TAG $REGISTRY/$IMAGE_NAME:$IMAGE_TAG
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ Image tagged for registry: $REGISTRY/$IMAGE_NAME:$IMAGE_TAG${NC}"
    else
        echo -e "${RED}✗ Failed to tag image for registry${NC}"
        exit 1
    fi
fi

# Show image info
echo -e "${YELLOW}Image Information:${NC}"
docker images | grep $IMAGE_NAME

echo ""
echo -e "${GREEN}=== Build Complete ===${NC}"
echo "Local image: $IMAGE_NAME:$IMAGE_TAG"
if [[ -n "$REGISTRY" ]]; then
    echo "Registry image: $REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
    echo ""
    echo -e "${YELLOW}To push to registry:${NC}"
    echo "  docker push $REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
fi

echo ""
echo -e "${YELLOW}To run the container:${NC}"
echo "  docker run -d -p 8080:80 --name misp-test $IMAGE_NAME:$IMAGE_TAG"

echo ""
echo -e "${YELLOW}To deploy with Helm:${NC}"
echo "  helm install misp ./misp-deployment-test-*.tgz -f misp-values.yaml"