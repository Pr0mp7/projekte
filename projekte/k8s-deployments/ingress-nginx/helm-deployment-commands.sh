#!/bin/bash

# Lightweight NGINX Ingress Deployment for RKE2 Control Plane Only

echo "Adding ingress-nginx Helm repository..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

echo "Installing lightweight ingress-nginx on control plane..."
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --values ingress-nginx-values.yaml

echo "Waiting for deployment to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

echo "Getting service information..."
kubectl get svc -n ingress-nginx ingress-nginx-controller

echo "Getting NodePort..."
NODEPORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.ports[0].nodePort}')
echo "HTTP NodePort: $NODEPORT"

echo "Getting control plane node IP..."
NODE_IP=$(kubectl get nodes -l node-role.kubernetes.io/control-plane=true -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "Control plane IP: $NODE_IP"

echo ""
echo "Deployment complete!"
echo "Access your ingress at: http://$NODE_IP:$NODEPORT"
echo "Or configure DNS: rhostesk8s001.labwi.sva.de -> $NODE_IP:$NODEPORT"