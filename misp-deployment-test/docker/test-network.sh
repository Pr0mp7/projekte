#!/bin/bash

# Network Connectivity Test for Docker Builds
# This script tests connectivity to required repositories

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Docker Build Network Connectivity Test ===${NC}"
echo ""

# Test DNS resolution
echo -e "${YELLOW}Testing DNS Resolution:${NC}"
test_dns() {
    local host=$1
    local desc=$2
    if nslookup "$host" >/dev/null 2>&1; then
        echo -e "✓ $desc ($host) - ${GREEN}OK${NC}"
        return 0
    else
        echo -e "✗ $desc ($host) - ${RED}FAILED${NC}"
        return 1
    fi
}

# Test HTTP connectivity
test_http() {
    local url=$1
    local desc=$2
    if curl -s --connect-timeout 10 --max-time 30 "$url" >/dev/null 2>&1; then
        echo -e "✓ $desc ($url) - ${GREEN}OK${NC}"
        return 0
    else
        echo -e "✗ $desc ($url) - ${RED}FAILED${NC}"
        return 1
    fi
}

# Essential DNS tests
dns_success=0
test_dns "github.com" "GitHub" && ((dns_success++))
test_dns "docker.io" "Docker Hub" && ((dns_success++))
test_dns "archive.ubuntu.com" "Ubuntu Archives" && ((dns_success++))

echo ""
echo -e "${YELLOW}Testing HTTP Connectivity:${NC}"

# Essential HTTP tests
http_success=0
test_http "https://github.com" "GitHub HTTPS" && ((http_success++))
test_http "https://archive.ubuntu.com" "Ubuntu Archives HTTPS" && ((http_success++))
test_http "https://dl-cdn.alpinelinux.org" "Alpine Linux CDN" && ((http_success++))

# Test problematic repositories
echo ""
echo -e "${YELLOW}Testing Problematic Repositories:${NC}"
test_http "https://mirrors.centos.org" "CentOS Mirrors" || echo -e "  ${YELLOW}↳ This explains CentOS build failure${NC}"
test_http "https://cdn-ubi.redhat.com" "Red Hat UBI CDN" || echo -e "  ${YELLOW}↳ This explains RHEL build failure${NC}"

echo ""
echo -e "${YELLOW}=== Network Summary ===${NC}"
echo "DNS Resolution: $dns_success/3 working"
echo "HTTP Connectivity: $http_success/3 working"

echo ""
echo -e "${YELLOW}=== Recommended Build Options ===${NC}"

if [ $http_success -ge 2 ]; then
    echo -e "${GREEN}✓ Try minimal build (Ubuntu):${NC} ./build.sh minimal"
    echo -e "${GREEN}✓ Try Alpine build:${NC} ./build.sh alpine"
elif [ $dns_success -ge 1 ]; then
    echo -e "${YELLOW}⚠ Limited connectivity - try minimal only:${NC} ./build.sh minimal"
else
    echo -e "${RED}✗ No external connectivity detected${NC}"
    echo "Consider:"
    echo "  1. Configure Docker proxy settings"
    echo "  2. Use pre-built images"
    echo "  3. Build on internet-connected machine and transfer"
fi

echo ""
echo -e "${YELLOW}=== Docker Configuration Check ===${NC}"

# Check Docker proxy configuration
if [ -f ~/.docker/config.json ]; then
    if grep -q "proxies" ~/.docker/config.json 2>/dev/null; then
        echo -e "${GREEN}✓ Docker proxy configuration found${NC}"
    else
        echo -e "${YELLOW}⚠ Docker config exists but no proxy settings${NC}"
    fi
else
    echo -e "${YELLOW}⚠ No Docker proxy configuration found${NC}"
    echo "If behind corporate proxy, create ~/.docker/config.json with proxy settings"
fi

# Check Docker daemon configuration
if [ -f /etc/docker/daemon.json ]; then
    echo -e "${GREEN}✓ Docker daemon configuration found${NC}"
else
    echo -e "${YELLOW}⚠ No Docker daemon configuration found${NC}"
fi

echo ""
echo -e "${GREEN}=== Test Complete ===${NC}"