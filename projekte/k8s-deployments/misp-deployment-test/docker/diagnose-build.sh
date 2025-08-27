#!/bin/bash

# Comprehensive Docker Build Diagnostics
# This script helps identify what's preventing the build from working

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Docker Build Diagnostics ===${NC}"
echo ""

echo -e "${YELLOW}1. Testing Docker Basic Functionality:${NC}"

# Test Docker is running
if docker info >/dev/null 2>&1; then
    echo -e "✓ Docker is running"
else
    echo -e "✗ Docker is not running or accessible"
    exit 1
fi

# Test basic container run
if docker run --rm hello-world >/dev/null 2>&1; then
    echo -e "✓ Docker can run containers"
else
    echo -e "✗ Docker cannot run containers"
    exit 1
fi

echo ""
echo -e "${YELLOW}2. Testing Docker Network Connectivity:${NC}"

# Test internet connectivity from Docker
if docker run --rm alpine:3.19 ping -c 2 8.8.8.8 >/dev/null 2>&1; then
    echo -e "✓ Docker containers can reach internet (ping)"
else
    echo -e "✗ Docker containers cannot reach internet"
    echo "  This could be due to corporate firewall or Docker network configuration"
fi

# Test DNS resolution
if docker run --rm alpine:3.19 nslookup google.com >/dev/null 2>&1; then
    echo -e "✓ Docker containers can resolve DNS"
else
    echo -e "✗ Docker containers cannot resolve DNS"
    echo "  Check Docker daemon DNS configuration"
fi

# Test HTTPS connectivity
if docker run --rm alpine:3.19 wget -q -O- https://www.google.com >/dev/null 2>&1; then
    echo -e "✓ Docker containers can make HTTPS requests"
else
    echo -e "✗ Docker containers cannot make HTTPS requests"
    echo "  This could be due to SSL/TLS restrictions or proxy configuration"
fi

echo ""
echo -e "${YELLOW}3. Testing Specific Repository Access:${NC}"

# Test Ubuntu repositories
if docker run --rm ubuntu:22.04 apt-get update >/dev/null 2>&1; then
    echo -e "✓ Ubuntu repositories accessible"
else
    echo -e "✗ Ubuntu repositories not accessible"
fi

# Test GitHub access
if docker run --rm alpine:3.19 wget -q -O- https://api.github.com/repos/MISP/MISP >/dev/null 2>&1; then
    echo -e "✓ GitHub accessible"
else
    echo -e "✗ GitHub not accessible"
    echo "  MISP source code download will fail"
fi

# Test Docker Hub
if docker pull hello-world:latest >/dev/null 2>&1; then
    echo -e "✓ Docker Hub accessible"
else
    echo -e "✗ Docker Hub not accessible"
    echo "  Base image pulls will fail"
fi

echo ""
echo -e "${YELLOW}4. Docker Configuration:${NC}"

# Check Docker daemon configuration
if [ -f /etc/docker/daemon.json ]; then
    echo -e "✓ Docker daemon configuration exists"
    echo "  Contents: $(cat /etc/docker/daemon.json)"
else
    echo -e "⚠ No Docker daemon configuration found"
fi

# Check user Docker configuration
if [ -f ~/.docker/config.json ]; then
    echo -e "✓ User Docker configuration exists"
else
    echo -e "⚠ No user Docker configuration found"
fi

echo ""
echo -e "${YELLOW}5. Attempting Simple Build Test:${NC}"

# Create a minimal test Dockerfile
cat > /tmp/test.Dockerfile << 'EOF'
FROM alpine:3.19
RUN apk update && apk add curl
RUN curl -s https://www.google.com > /dev/null
EOF

echo "Testing minimal build..."
if docker build -f /tmp/test.Dockerfile -t docker-test /tmp >/dev/null 2>&1; then
    echo -e "✓ Simple build with network access works"
    docker rmi docker-test >/dev/null 2>&1
else
    echo -e "✗ Simple build with network access fails"
    echo "  This confirms network connectivity issues during build"
fi

rm /tmp/test.Dockerfile

echo ""
echo -e "${YELLOW}=== Recommendations ===${NC}"

echo "If most tests passed:"
echo "  → Try: ./build-simple.sh basic"
echo "  → Or:  ./build-simple.sh minimal"
echo ""
echo "If network tests failed:"
echo "  → Configure Docker proxy settings"
echo "  → Check corporate firewall rules"
echo "  → Contact IT support for Docker network access"
echo ""
echo "If only specific repositories failed:"
echo "  → Try different base images"
echo "  → Use cached/pre-built images"

echo ""
echo -e "${GREEN}=== Diagnostics Complete ===${NC}"