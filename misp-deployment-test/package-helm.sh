#!/bin/bash

# MISP Helm Chart Packaging Script
# This script packages the MISP Helm chart into a .tgz file

set -e

# Configuration
CHART_NAME="misp-deployment-test"
CHART_VERSION="1.0.0"
OUTPUT_DIR="./dist"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== MISP Helm Chart Packaging Script ===${NC}"
echo "Packaging MISP Helm chart for deployment"
echo ""

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo -e "${RED}Error: Helm is not installed or not in PATH${NC}"
    echo "Please install Helm first: https://helm.sh/docs/intro/install/"
    exit 1
fi

# Check if Chart.yaml exists
if [[ ! -f "Chart.yaml" ]]; then
    echo -e "${RED}Error: Chart.yaml not found in current directory${NC}"
    echo "Please run this script from the chart directory"
    exit 1
fi

echo -e "${YELLOW}Chart Information:${NC}"
helm show chart . | grep -E "^(name|version|description):"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Download dependencies first
echo -e "${YELLOW}Downloading chart dependencies...${NC}"
helm dependency update .

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ Dependencies downloaded${NC}"
else
    echo -e "${RED}✗ Failed to download dependencies${NC}"
    exit 1
fi

# Lint the chart first
echo -e "${YELLOW}Linting Helm chart...${NC}"
helm lint .

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ Chart passed lint checks${NC}"
else
    echo -e "${RED}✗ Chart failed lint checks${NC}"
    exit 1
fi

# Package the chart
echo -e "${YELLOW}Packaging Helm chart...${NC}"
helm package . -d "$OUTPUT_DIR"

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ Chart packaged successfully!${NC}"
else
    echo -e "${RED}✗ Chart packaging failed!${NC}"
    exit 1
fi

# Find the packaged file
PACKAGE_FILE=$(ls -t "$OUTPUT_DIR"/*.tgz | head -1)

if [[ -f "$PACKAGE_FILE" ]]; then
    echo -e "${GREEN}✓ Package created: $PACKAGE_FILE${NC}"
    
    # Show package details
    echo ""
    echo -e "${YELLOW}Package Details:${NC}"
    echo "  File: $(basename $PACKAGE_FILE)"
    echo "  Size: $(du -h $PACKAGE_FILE | cut -f1)"
    echo "  Path: $(realpath $PACKAGE_FILE)"
    
    # Verify package contents
    echo ""
    echo -e "${YELLOW}Package Contents:${NC}"
    tar -tzf "$PACKAGE_FILE" | head -20
    
    if [[ $(tar -tzf "$PACKAGE_FILE" | wc -l) -gt 20 ]]; then
        echo "  ... and $(( $(tar -tzf "$PACKAGE_FILE" | wc -l) - 20 )) more files"
    fi
else
    echo -e "${RED}✗ Package file not found!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=== Packaging Complete ===${NC}"
echo "Your Helm chart is ready for deployment!"
echo ""
echo -e "${YELLOW}To deploy:${NC}"
echo "  helm install misp $PACKAGE_FILE -f misp-values.yaml --namespace misp --create-namespace"
echo ""
echo -e "${YELLOW}To upgrade existing deployment:${NC}"
echo "  helm upgrade misp $PACKAGE_FILE -f misp-values.yaml --namespace misp"
echo ""
echo -e "${YELLOW}To test deployment:${NC}"
echo "  helm install misp $PACKAGE_FILE -f misp-values.yaml --namespace misp --create-namespace --dry-run --debug"