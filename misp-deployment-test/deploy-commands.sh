#!/bin/bash

# Manual MISP Deployment Commands
# Run these step by step if the package script has issues

set -e

echo "=== MISP Deployment Commands ==="
echo "Run these commands step by step:"
echo ""

echo "1. Add Bitnami repository for dependencies:"
echo "   helm repo add bitnami https://charts.bitnami.com/bitnami"
echo "   helm repo update"
echo ""

echo "2. Download chart dependencies:"
echo "   helm dependency update ."
echo ""

echo "3. Install MISP directly (without packaging):"
echo "   helm install misp . -f misp-values.yaml --namespace misp --create-namespace"
echo ""

echo "4. Monitor the deployment:"
echo "   kubectl get pods -n misp -w"
echo ""

echo "5. Check ingress:"
echo "   kubectl get ingress -n misp"
echo "   kubectl get svc -n ingress-nginx"
echo ""

echo "=== Running commands automatically ==="
echo ""

# Add Bitnami repo
echo "Adding Bitnami repository..."
helm repo add bitnami https://charts.bitnami.com/bitnami || echo "Repository might already exist"
helm repo update

echo ""
echo "Downloading dependencies..."
helm dependency update .

echo ""
echo "Installing MISP..."
helm install misp . \
  -f misp-values.yaml \
  --namespace misp \
  --create-namespace

echo ""
echo "Deployment initiated!"
echo "Monitor with: kubectl get pods -n misp -w"