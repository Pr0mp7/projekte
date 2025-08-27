# Ingress-NGINX Deployment Guide for RKE2

## Prerequisites
- RKE2 cluster running and accessible
- kubectl configured to connect to your cluster
- Admin privileges on the cluster

## Step 1: Deploy ingress-nginx

```bash
kubectl apply -f ingress-nginx-deployment.yaml
```

## Step 2: Verify Installation

Check if the ingress-nginx pods are running:
```bash
kubectl get pods -n ingress-nginx
```

Check the service:
```bash
kubectl get svc -n ingress-nginx
```

Get the NodePort assigned to the ingress-nginx service:
```bash
kubectl get svc ingress-nginx-controller -n ingress-nginx -o yaml
```

## Step 3: Configure External Access

Since this is a NodePort service, you'll need to:

1. **Find the NodePort**: Look for the `nodePort` values in the service (typically 30000-32767 range)
2. **Configure DNS**: Point `rhostesk8s001.labwi.sva.de` to your node IP
3. **Configure Load Balancer** (recommended): Set up an external load balancer to distribute traffic

### Option A: Direct NodePort Access
Access your applications via: `http://rhostesk8s001.labwi.sva.de:<nodeport>`

### Option B: Load Balancer Setup (Recommended)
Configure an external load balancer (HAProxy, NGINX, etc.) to:
- Listen on ports 80/443
- Forward to your RKE2 nodes on the assigned NodePorts

## Step 4: Test with Sample Application

Deploy the sample application:
```bash
kubectl apply -f sample-ingress.yaml
```

Verify the deployment:
```bash
kubectl get ingress
kubectl get pods
kubectl get svc
```

## Step 5: DNS Configuration

Ensure `rhostesk8s001.labwi.sva.de` resolves to:
- Your load balancer IP (recommended)
- Or one of your RKE2 node IPs

## Troubleshooting

### Check ingress-nginx logs:
```bash
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

### Check ingress status:
```bash
kubectl describe ingress sample-app-ingress
```

### Verify connectivity:
```bash
curl -H "Host: rhostesk8s001.labwi.sva.de" http://<node-ip>:<nodeport>
```

## Security Considerations

1. **TLS/SSL**: Configure TLS certificates for production use
2. **Network Policies**: Implement network policies to restrict traffic
3. **Resource Limits**: Set appropriate resource limits and requests
4. **Regular Updates**: Keep ingress-nginx updated

## Next Steps

1. Configure TLS certificates (Let's Encrypt or custom)
2. Set up monitoring and logging
3. Implement backup strategies
4. Configure autoscaling if needed