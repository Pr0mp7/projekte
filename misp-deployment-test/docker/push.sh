#!/bin/bash

# MISP Container Push Script
# This script pushes the built MISP container image to a registry

set -e

# Configuration
IMAGE_NAME="misp"
IMAGE_TAG="latest"
REGISTRY="${REGISTRY:-localhost:5000}"  # Default to localhost registry

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MISP Container Push Script ===${NC}"
echo "Pushing MISP container image to registry"
echo ""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running or not accessible${NC}"
    exit 1
fi

# Check if image exists
if ! docker image inspect $REGISTRY/$IMAGE_NAME:$IMAGE_TAG >/dev/null 2>&1; then
    echo -e "${RED}Error: Image $REGISTRY/$IMAGE_NAME:$IMAGE_TAG not found${NC}"
    echo "Please build the image first using: ./build.sh"
    exit 1
fi

echo -e "${YELLOW}Push Configuration:${NC}"
echo "  Registry: $REGISTRY"
echo "  Image: $IMAGE_NAME:$IMAGE_TAG"
echo "  Full Name: $REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
echo ""

# Test registry connectivity (if not localhost)
if [[ "$REGISTRY" != "localhost:5000" ]]; then
    echo -e "${YELLOW}Testing registry connectivity...${NC}"
    if ! curl -f -s "$REGISTRY/v2/" >/dev/null 2>&1; then
        echo -e "${RED}Warning: Cannot connect to registry $REGISTRY${NC}"
        echo "Make sure the registry is running and accessible"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

# Push the image
echo -e "${YELLOW}Pushing image to registry...${NC}"
docker push $REGISTRY/$IMAGE_NAME:$IMAGE_TAG

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ Image pushed successfully!${NC}"
    echo "  Registry: $REGISTRY"
    echo "  Image: $IMAGE_NAME:$IMAGE_TAG"
else
    echo -e "${RED}✗ Failed to push image!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=== Push Complete ===${NC}"
echo "Image is now available at: $REGISTRY/$IMAGE_NAME:$IMAGE_TAG"
echo ""
echo -e "${YELLOW}To deploy with Helm:${NC}"
echo "  helm install misp ./misp-deployment-test-*.tgz -f misp-values.yaml"