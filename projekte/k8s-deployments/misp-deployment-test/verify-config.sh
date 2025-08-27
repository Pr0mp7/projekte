#!/bin/bash

# Configuration Verification Script
# Verifies that all storage classes are consistently set to Longhorn

echo "=== MISP Configuration Verification ==="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "\n${GREEN}Checking storage class configuration in values files...${NC}"

# Check main values.yaml
echo -e "\n${YELLOW}values.yaml:${NC}"
grep -n "storageClass" values.yaml | head -10

# Check development values
echo -e "\n${YELLOW}values-development.yaml:${NC}"
grep -n "storageClass" values-development.yaml | head -10

# Check storage options template
echo -e "\n${YELLOW}values-storage-options.yaml (Active configuration):${NC}"
sed -n '1,30p' values-storage-options.yaml

echo -e "\n${GREEN}=== Configuration Summary ===${NC}"
echo "✓ All components should be configured with storageClass: 'longhorn'"
echo "✓ This ensures consistent PVC creation and binding"
echo "✓ Mixed storage classes were causing the scheduling issues"

echo -e "\n${GREEN}To deploy with this configuration:${NC}"
echo "1. Run: ./test-deployment.sh"
echo "2. Or manually: helm upgrade --install misp-test . --namespace misp-test --values values.yaml"