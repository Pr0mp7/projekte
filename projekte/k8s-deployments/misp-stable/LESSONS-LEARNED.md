# MISP Deployment - Lessons Learned

## Issue Summary
During the initial MISP deployment, we encountered persistent CSRF (Cross-Site Request Forgery) errors that prevented successful login to the web interface.

## Root Causes Identified

### 1. MISP Version Issues
- **Problem:** MISP v2.5.20 introduced secure cookie requirements that cause CSRF errors over HTTP
- **Impact:** Login form repeatedly showed "cross-site request forgery protection" error
- **Solution:** Downgraded to MISP v2.4.188 which doesn't have the secure cookie requirement

### 2. Base URL Configuration Conflicts  
- **Problem:** MISP's base URL configuration conflicted with port-forwarding access method
- **Impact:** CSRF tokens generated for one hostname but used from another
- **Solution:** Set base URL to empty string in configuration to allow flexible hostname usage

### 3. File Permission Issues
- **Problem:** MISP config files had incorrect ownership/permissions 
- **Impact:** PHP couldn't read config files, causing application errors
- **Solution:** Added init container to fix file permissions before main app starts

### 4. SSL/Security Configuration Conflicts
- **Problem:** MISP configured to expect HTTPS but accessed via HTTP
- **Impact:** Secure cookies not sent over HTTP connections
- **Solution:** Environment variables to disable SSL redirects and secure cookie requirements

### 5. Network Access Configuration
- **Problem:** NodePort services with externalTrafficPolicy: Local
- **Impact:** External traffic couldn't reach services
- **Solution:** Changed to externalTrafficPolicy: Cluster for better external access

## Technical Solutions Implemented

### Environment Variables for Security
```yaml
- name: PHP_SESSION_COOKIE_SECURE
  value: "false"
- name: SECURITY_REQUIRE_SSL  
  value: "false"
- name: DISABLE_SSL_REDIRECT
  value: "true"
- name: NOREDIR_SSL
  value: "true"
- name: BASE_URL
  value: ""
- name: MISP_BASEURL
  value: ""
```

### Init Container for Permissions
```yaml
initContainers:
- name: fix-permissions
  image: ghcr.io/misp/misp-docker/misp-core:v2.4.188
  command: ["/bin/bash", "-c"]
  args:
  - |
    mkdir -p /var/www/MISP/app/files /var/www/MISP/app/tmp /var/www/MISP/app/Config
    chown -R www-data:www-data /var/www/MISP/app/files /var/www/MISP/app/tmp /var/www/MISP/app/Config
    chmod -R 755 /var/www/MISP/app/files /var/www/MISP/app/tmp /var/www/MISP/app/Config
  securityContext:
    runAsUser: 0
```

### Service Configuration for External Access
```yaml
spec:
  type: NodePort
  externalTrafficPolicy: Cluster  # Not Local
  selector:
    app: misp-app
```

## Alternative Access Methods

### 1. Port-Forward (Recommended for Development)
```bash
kubectl port-forward -n misp svc/misp-app 8080:80
# Access: http://localhost:8080
```

### 2. NodePort (For External Network Access)  
```bash
# Service automatically gets NodePort (e.g., 30080)
# Access: http://NODE_IP:30080
```

### 3. API Access (Bypass Web Login)
```bash
# Generate API key via CLI
kubectl exec -n misp deployment/misp-app -- /var/www/MISP/app/Console/cake user change_authkey 1
# Use API key for programmatic access
```

## Prevention Measures

1. **Always check MISP version compatibility** before deployment
2. **Test with empty base URL configuration** to avoid hostname conflicts  
3. **Include permission-fixing init containers** for file system issues
4. **Use externalTrafficPolicy: Cluster** for better external access
5. **Document all environment variables** needed for HTTP-only access

## Recommended Version Stack

- **MISP Core:** v2.4.188 (stable, no secure cookie issues)
- **MISP Modules:** v2.4.188 (matching version)
- **Database:** MariaDB 10.11 (stable, well-tested)
- **Cache:** Redis 7-alpine (lightweight, fast)

## Future Considerations

- For production HTTPS deployment, use proper TLS certificates
- Consider using Helm charts for easier upgrades and management
- Implement proper backup strategies for persistent data
- Monitor resource usage and adjust limits as needed