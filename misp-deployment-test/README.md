# MISP Test Deployment for RKE2

This is a lightweight Helm chart for deploying MISP (Malware Information Sharing Platform) in your RKE2 test environment. It's based on the full MISP chart from your `/misp` folder but simplified for testing purposes.

## Overview

This chart deploys:
- MISP application server (single replica)
- MariaDB database (simplified configuration)
- Redis cache (memory-only for testing)
- Ingress for external access
- Persistent volume for MISP data

## Prerequisites

- Kubernetes cluster (RKE2)
- Helm 3.x
- Storage class `local-path` available (RKE2 default)
- Ingress controller (nginx recommended)

## Quick Start

### 1. Install the Chart

```bash
# Add dependencies
helm dependency update

# Install MISP
helm install misp-test . --namespace misp-test --create-namespace

# Or install with custom values
helm install misp-test . --namespace misp-test --create-namespace --values my-values.yaml
```

### 2. Access MISP

```bash
# Check deployment status
kubectl get pods -n misp-test

# Port forward to access locally
kubectl port-forward -n misp-test service/misp-test 8080:80

# Access MISP at http://localhost:8080
```

### 3. Default Credentials

- **Username**: `admin@misp.local`
- **Password**: `admin123`

## Configuration

### Key Values to Customize

```yaml
# values.yaml
misp:
  config:
    admin:
      email: "admin@your-domain.com"
      password: "your-secure-password"
      orgName: "Your Organization"
    baseUrl: "http://misp.your-domain.com"

ingress:
  enabled: true
  hosts:
    - host: misp.your-domain.com
      paths:
        - path: /
          pathType: Prefix
```

### Storage Configuration

```yaml
misp:
  persistence:
    enabled: true
    storageClass: "local-path"  # RKE2 default
    size: 5Gi
```

### Resource Limits

```yaml
misp:
  resources:
    requests:
      memory: "256Mi"
      cpu: "200m"
    limits:
      memory: "1Gi"
      cpu: "1000m"
```

## Dependencies

This chart includes two subchart dependencies:

- **MariaDB** (`mariadb`): Database for MISP
- **Redis** (`redis`): Caching layer

### Dependency Management

```bash
# Update dependencies
helm dependency update

# List dependencies
helm dependency list
```

## Differences from Production Chart

This test chart is simplified compared to the full MISP chart:

| Feature | Production Chart | Test Chart |
|---------|-----------------|------------|
| Security Context | Full read-only filesystem | Simplified |
| Vault Integration | Full HashiCorp Vault | Basic secrets |
| OIDC Authentication | Keycloak integration | Disabled |
| Logging | Advanced logging containers | Basic logs |
| Workers | Multiple worker types | Minimal workers |
| Persistence | Multiple volume types | Single PVC |
| TLS | Full certificate management | Optional/disabled |

## Deployment Commands

### Install

```bash
# Basic installation
helm install misp-test . -n misp-test --create-namespace

# With custom domain
helm install misp-test . -n misp-test --create-namespace \
  --set ingress.hosts[0].host=misp.local \
  --set misp.config.baseUrl=http://misp.local
```

### Upgrade

```bash
# Upgrade with new values
helm upgrade misp-test . -n misp-test --values new-values.yaml
```

### Uninstall

```bash
# Uninstall (keeps PVC)
helm uninstall misp-test -n misp-test

# Delete namespace and all resources
kubectl delete namespace misp-test
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n misp-test
kubectl describe pod -n misp-test misp-test-xxx
```

### View Logs

```bash
# MISP application logs
kubectl logs -n misp-test -l app.kubernetes.io/name=misp-test -f

# Database logs
kubectl logs -n misp-test -l app.kubernetes.io/name=mariadb -f

# Redis logs
kubectl logs -n misp-test -l app.kubernetes.io/name=redis -f
```

### Common Issues

1. **Pod stuck in Pending**: Check storage class and PVC creation
2. **Pod stuck in Init**: Dependencies (MariaDB/Redis) not ready
3. **Connection refused**: Check service names and ports
4. **Permission denied**: Review security context settings

### Debug Commands

```bash
# Check services
kubectl get svc -n misp-test

# Check ingress
kubectl get ingress -n misp-test

# Check PVC
kubectl get pvc -n misp-test

# Exec into MISP pod
kubectl exec -it -n misp-test deployment/misp-test -- /bin/bash
```

## Development

### Chart Structure

```
misp-deployment-test/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration
├── templates/
│   ├── _helpers.tpl        # Template helpers
│   ├── deployment.yaml     # MISP deployment
│   ├── service.yaml        # Service definition
│   ├── ingress.yaml        # Ingress configuration
│   ├── serviceaccount.yaml # Service account
│   ├── pvc.yaml           # Persistent volume claim
│   ├── secret.yaml        # Basic secrets
│   └── NOTES.txt          # Post-install notes
└── README.md              # This file
```

### Adding Features

To add features from the production chart:
1. Copy relevant templates from `/misp/misp-main/templates/`
2. Update `values.yaml` with new configuration options
3. Add helper functions in `_helpers.tpl` if needed
4. Test thoroughly

## Testing

### Validate Templates

```bash
# Render templates locally
helm template misp-test . --values values.yaml

# Validate against Kubernetes
helm template misp-test . --values values.yaml | kubectl apply --dry-run=client -f -
```

### Load Testing

```bash
# Install with specific resource limits
helm install misp-test . -n misp-test --create-namespace \
  --set misp.resources.limits.memory=512Mi \
  --set misp.resources.limits.cpu=500m
```

## Security Notes

⚠️ **This is a test configuration** with relaxed security settings:

- Default passwords are used
- TLS is optional/disabled
- Security contexts are simplified
- No advanced authentication

**For production deployment**:
- Change all default passwords
- Enable TLS/HTTPS
- Configure proper authentication (OIDC)
- Review security contexts
- Enable network policies
- Use proper secret management

## Contributing

1. Test changes in your RKE2 environment
2. Update this README with any new features
3. Ensure compatibility with the source chart in `/misp/misp-main/`
4. Document any breaking changes

## License

This chart follows the same license as the original MISP project and the source chart it's based on.