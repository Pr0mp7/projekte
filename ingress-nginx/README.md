# Lightweight NGINX Ingress for RKE2 Control Plane

This directory contains configuration files for deploying a lightweight NGINX ingress controller specifically for RKE2 clusters running on control plane nodes only.

## Files

- `ingress-nginx-values.yaml` - Helm values for lightweight deployment
- `test-ingress.yaml` - Sample application and ingress for testing
- `helm-deployment-commands.sh` - Automated deployment script

## Quick Deployment

```bash
# Add Helm repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install lightweight ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --values ingress-nginx-values.yaml

# Test with sample app
kubectl apply -f test-ingress.yaml
```

## Configuration Features

- **Control plane only** scheduling with proper tolerations
- **No TLS** (ssl-redirect disabled) for testing
- **Lightweight** resource limits (50m CPU, 64Mi RAM)
- **Single replica** deployment
- **Admission webhooks disabled** for simplicity
- **NodePort** service type for on-premises access

## Access

After deployment, get the NodePort:
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```

Access via: `http://rhostesk8s001.labwi.sva.de:<nodeport>`

## Testing

The `test-ingress.yaml` includes:
- Simple nginx test application
- Ingress rule for `rhostesk8s001.labwi.sva.de`
- Minimal resource requirements for testing