#!/bin/bash
# MISP Stable Deployment Script
# This script deploys MISP v2.4.188 with all CSRF/security fixes applied

set -e

echo "Deploying MISP Stable v2.4.188..."

# Create namespace
echo "Creating namespace..."
kubectl apply -f namespace.yaml

# Wait for namespace to be ready
kubectl wait --for=condition=Active namespace/misp --timeout=30s

# Apply configurations in correct order
echo "Applying secrets and config..."
kubectl apply -f secrets.yaml
kubectl apply -f configmap.yaml

echo "Applying storage..."
kubectl apply -f storage.yaml

# Wait for PVCs to be bound
echo "Waiting for storage to be ready..."
kubectl wait --for=condition=Bound pvc/misp-data -n misp --timeout=120s
kubectl wait --for=condition=Bound pvc/misp-database-data -n misp --timeout=120s

echo "Deploying database and Redis..."
kubectl apply -f database.yaml
kubectl apply -f redis.yaml

# Wait for database and Redis to be ready
echo "Waiting for database to be ready..."
kubectl wait --for=condition=Available deployment/misp-database -n misp --timeout=300s

echo "Waiting for Redis to be ready..."
kubectl wait --for=condition=Available deployment/misp-redis -n misp --timeout=300s

echo "Deploying MISP modules..."
kubectl apply -f modules.yaml

echo "Waiting for modules to be ready..."
kubectl wait --for=condition=Available deployment/misp-modules -n misp --timeout=300s

echo "Deploying MISP application..."
kubectl apply -f misp-app.yaml

echo "Creating services..."
kubectl apply -f services.yaml

echo "Waiting for MISP application to be ready..."
kubectl wait --for=condition=Available deployment/misp-app -n misp --timeout=600s

echo ""
echo "MISP deployment completed successfully!"
echo ""
echo "Access options:"
echo "1. Port-forward: kubectl port-forward -n misp svc/misp-app 8080:80"
echo "   Then visit: http://localhost:8080"
echo ""
echo "2. NodePort (if accessible): http://YOUR_NODE_IP:30080"
echo ""
echo "Default login:"
echo "Username: admin@admin.test"
echo "Password: StrongAdminPassword123!"
echo ""
echo "Check status with: kubectl get pods -n misp"