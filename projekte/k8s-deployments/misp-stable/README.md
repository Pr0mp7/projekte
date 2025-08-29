# MISP Stable Deployment (v2.4.188)

This deployment uses MISP v2.4.188 which is stable and avoids the CSRF/secure cookie issues found in newer versions.

## Key Fixes Applied

### 1. CSRF Token Issues
- Uses MISP v2.4.188 which doesn't have the secure cookie requirement
- Empty base URL configuration to avoid hostname conflicts
- Environment variables to disable SSL redirects

### 2. File Permissions
- Init container ensures proper permissions for MISP files
- www-data user ownership for all MISP directories

### 3. Network Configuration
- NodePort service with externalTrafficPolicy: Cluster
- Proper ingress configuration for external access
- Port-forward support for development/testing

## Deployment Instructions

1. **Create namespace:**
   ```bash
   kubectl create namespace misp
   ```

2. **Apply configurations in order:**
   ```bash
   kubectl apply -f secrets.yaml
   kubectl apply -f configmap.yaml
   kubectl apply -f storage.yaml
   kubectl apply -f database.yaml
   kubectl apply -f redis.yaml
   kubectl apply -f modules.yaml
   kubectl apply -f misp-app.yaml
   kubectl apply -f services.yaml
   kubectl apply -f ingress.yaml
   ```

3. **For external access via port-forward:**
   ```bash
   kubectl port-forward -n misp svc/misp-app 8080:80
   ```
   Then access: http://localhost:8080

## Default Login Credentials

- **Username:** admin@admin.test
- **Password:** StrongAdminPassword123!

## Troubleshooting

### If you get CSRF errors:
1. Clear all browser cookies for the domain
2. Try accessing via incognito/private window
3. Use port-forward instead of ingress if issues persist

### If you get permission errors:
1. Check pod logs: `kubectl logs -n misp deployment/misp-app`
2. Restart the deployment: `kubectl rollout restart deployment/misp-app -n misp`

## Architecture

- **MISP Core:** v2.4.188 (stable version without secure cookie issues)
- **Database:** MariaDB 10.11
- **Cache:** Redis 7-alpine
- **Modules:** MISP-modules v2.4.188
- **Storage:** 10Gi persistent volume for MISP data

## Network Access

### Internal (within cluster):
- MISP App: http://misp-app.misp.svc.cluster.local

### External Options:
1. **Port-forward (recommended for testing):**
   ```bash
   kubectl port-forward -n misp svc/misp-app 8080:80
   ```

2. **NodePort (if firewall allows):**
   - Service will be available on any node IP at the assigned NodePort

3. **Ingress (requires ingress controller):**
   - Configure your DNS to point to the ingress controller