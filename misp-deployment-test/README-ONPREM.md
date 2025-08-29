# MISP On-Premises Deployment for RKE2

This Helm chart provides a complete MISP (Malware Information Sharing Platform) deployment optimized for on-premises RKE2 environments with custom container images.

## Overview

This chart deploys a complete MISP instance with:
- Custom MISP application server (RHEL-based container)
- MariaDB database (optional, can use external)
- Redis cache (optional, can use external)
- Persistent storage using Longhorn
- Ingress configuration for external access
- Container build pipeline for on-premises deployment

## Prerequisites

- Kubernetes 1.23+
- Helm 3.8+
- Docker for building custom images
- Longhorn storage class (or another persistent storage solution)
- Ingress controller (e.g., ingress-nginx)
- RHEL-based system for container builds

## Quick Start

### 1. Build Custom MISP Container

```bash
# Make build script executable
chmod +x docker/build.sh docker/push.sh

# Build the MISP container image
./docker/build.sh

# Push to your local registry (optional)
export REGISTRY=your-registry:5000
./docker/push.sh
```

### 2. Package Helm Chart

```bash
# Make packaging script executable
chmod +x package-helm.sh

# Package the chart
./package-helm.sh
```

### 3. Deploy MISP

```bash
# Deploy with custom values
helm install misp ./dist/misp-deployment-test-1.0.0.tgz \
  -f misp-values.yaml \
  --namespace misp \
  --create-namespace
```

## Container Build Process

### Custom Dockerfile Features

- **RHEL 9 UBI base image** for enterprise compatibility
- **MISP v2.4.190** with all dependencies
- **Apache + PHP 8.2** web server configuration
- **Python 3.9** with MISP-specific libraries
- **Supervisor** for process management
- **Health checks** and proper logging

### Build Configuration

The build process supports these arguments:

```bash
docker build \
  --build-arg MISP_BRANCH=v2.4.190 \
  --build-arg PHP_VER=8.2 \
  --build-arg RHEL_VERSION=9 \
  -t misp:latest \
  -f docker/Dockerfile .
```

### Local Registry Setup

For air-gapped deployments, set up a local registry:

```bash
# Start local registry
docker run -d -p 5000:5000 --name registry registry:2

# Tag and push your image
docker tag misp:latest localhost:5000/misp:latest
docker push localhost:5000/misp:latest
```

## Configuration

### On-Premises Values (`misp-values.yaml`)

Key differences from the test deployment:

```yaml
misp:
  image:
    repository: localhost:5000/misp  # Local registry
    tag: "latest"
    pullPolicy: IfNotPresent
  
  config:
    baseUrl: "http://rhostesk8s001.labwi.sva.de"  # Your hostname
    admin:
      orgName: "On-Premises Organization"
  
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "2000m"

ingress:
  hosts:
    - host: rhostesk8s001.labwi.sva.de  # Your hostname
```

### Environment Variables

The container supports these environment variables:

```yaml
misp:
  env:
    - name: MYSQL_HOST
      value: "misp-mariadb"
    - name: MYSQL_DATABASE
      value: "misp"
    - name: REDIS_HOST
      value: "misp-redis-master"
    - name: MISP_BASEURL
      value: "http://rhostesk8s001.labwi.sva.de"
```

## Deployment Process

### 1. Prepare Environment

```bash
# Create namespace
kubectl create namespace misp

# Verify storage
kubectl get storageclass longhorn

# Verify ingress controller
kubectl get pods -n ingress-nginx
```

### 2. Build and Push Image

```bash
# Build custom image
./docker/build.sh

# Push to registry (if using remote registry)
export REGISTRY=your-registry.com:5000
./docker/push.sh
```

### 3. Package Chart

```bash
# Package Helm chart
./package-helm.sh

# Verify package
ls -la dist/
```

### 4. Deploy Application

```bash
# Deploy with custom values
helm install misp ./dist/misp-deployment-test-*.tgz \
  -f misp-values.yaml \
  --namespace misp \
  --create-namespace

# Monitor deployment
kubectl get pods -n misp -w
```

### 5. Access Application

```bash
# Get ingress details
kubectl get ingress -n misp

# Get NodePort (if using NodePort service)
kubectl get svc -n ingress-nginx

# Access via browser
# http://rhostesk8s001.labwi.sva.de
```

## Monitoring and Troubleshooting

### Container Logs

```bash
# MISP application logs
kubectl logs -l app.kubernetes.io/name=misp-test -n misp

# Database logs
kubectl logs -l app.kubernetes.io/name=mariadb -n misp

# Init container logs
kubectl logs -l app.kubernetes.io/name=misp-test -n misp -c wait-for-dependencies
```

### Health Checks

```bash
# Check pod status
kubectl get pods -n misp

# Check service endpoints
kubectl get endpoints -n misp

# Test internal connectivity
kubectl exec -it deployment/misp-deployment-test -n misp -- curl localhost
```

### Common Issues

#### Image Pull Errors
- Verify registry connectivity
- Check image tag exists
- Validate pull secrets if using private registry

#### Database Connection Issues
- Verify MariaDB pod is running
- Check service DNS resolution
- Validate credentials in secrets

#### Storage Issues
- Check PVC status: `kubectl get pvc -n misp`
- Verify Longhorn health: `kubectl get pods -n longhorn-system`
- Check node storage capacity

## Backup and Recovery

### Application Backup

```bash
# Backup database
kubectl exec deployment/misp-mariadb -n misp -- mysqldump -u misp -p misp > backup.sql

# Backup persistent volumes (Longhorn)
kubectl create -f - <<EOF
apiVersion: longhorn.io/v1beta1
kind: BackupTarget
metadata:
  name: misp-backup
  namespace: misp
EOF
```

### Disaster Recovery

```bash
# Export current configuration
helm get values misp -n misp > misp-backup-values.yaml

# Export secrets
kubectl get secrets -n misp -o yaml > misp-secrets-backup.yaml
```

## Maintenance

### Updates

```bash
# Update container image
./docker/build.sh
./docker/push.sh

# Package new chart version
./package-helm.sh

# Upgrade deployment
helm upgrade misp ./dist/misp-deployment-test-*.tgz -f misp-values.yaml -n misp
```

### Cleanup

```bash
# Uninstall application
helm uninstall misp -n misp

# Remove persistent data (⚠️ irreversible)
kubectl delete pvc -n misp --all
kubectl delete namespace misp
```

## Support

### Version Compatibility

| Chart Version | MISP Version | Kubernetes | Helm | RHEL |
|---------------|--------------|------------|------|------|
| 1.0.x         | 2.4.190      | 1.23+      | 3.8+ | 9+   |

## License

This Helm chart and container configuration are provided under the same license as MISP itself.