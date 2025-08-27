# MISP Deployment - Malware Information Sharing Platform

## Overview

MISP (Malware Information Sharing Platform) is a threat intelligence sharing platform deployed on RKE2 for collaborative threat analysis and incident response.

### Deployment Variants

#### Production Deployment (`misp/misp-main/`)
- Full-featured MISP with enterprise security
- Vault integration for secrets management
- OIDC authentication via Keycloak
- Advanced logging and monitoring

#### Test Deployment (`projekte/k8s-deployments/misp-deployment-test/`)
- Lightweight version for testing/development
- Simplified security contexts
- Basic authentication
- Local storage focus

#### Container Images (`misp/container-images-main-misp/`)
- Custom MISP container builds
- Multi-stage Dockerfile configurations
- Security-hardened base images
- Helper scripts for deployment

## Architecture

### RKE2 Cluster MISP Deployment
```mermaid
graph TB
    subgraph "External Access"
        ANALYST[Security Analyst]
        DNS[DNS Resolution]
        LB[External Load Balancer]
    end
    
    subgraph "RKE2 Kubernetes Cluster"
        subgraph "Control Plane Nodes"
            CP1[Control Plane 1<br/>etcd + kube-apiserver]
            CP2[Control Plane 2<br/>etcd + kube-apiserver]
            CP3[Control Plane 3<br/>etcd + kube-apiserver]
        end
        
        subgraph "Worker Nodes"
            W1[Worker Node 1<br/>containerd + kubelet]
            W2[Worker Node 2<br/>containerd + kubelet]
            W3[Worker Node 3<br/>containerd + kubelet]
        end
        
        subgraph "nginx-ingress-system namespace"
            NGINX_CTRL[Nginx Ingress Controller]
            NGINX_SVC[LoadBalancer Service]
        end
        
        subgraph "misp-test namespace"
            subgraph "MISP Application Pod"
                MISP_INIT[Init Container<br/>fix-permissions]
                MISP_MAIN[MISP Container<br/>Apache + PHP]
                MISP_VOLUME[Config Volume Mount]
            end
            
            subgraph "MariaDB Pod"
                MARIA_DB[MariaDB 10.6]
                MARIA_PVC[Database PVC<br/>Longhorn]
            end
            
            subgraph "Redis Pod"
                REDIS_CACHE[Redis Cache]
                REDIS_PVC[Cache PVC<br/>Longhorn]
            end
            
            MISP_SVC[MISP Service<br/>ClusterIP:80]
            MISP_INGRESS[Ingress Resource<br/>misp.local]
            MISP_FILES_PVC[Files PVC<br/>Longhorn 5Gi]
        end
        
        subgraph "longhorn-system namespace"
            LH_MGR[Longhorn Manager]
            LH_ENGINE[Longhorn Engine]
            LH_CSI[CSI Driver]
        end
        
        subgraph "Longhorn Storage Nodes"
            STORAGE1[Storage Node 1<br/>Replicas]
            STORAGE2[Storage Node 2<br/>Replicas]
            STORAGE3[Storage Node 3<br/>Replicas]
        end
    end
    
    %% External connections
    ANALYST --> DNS
    DNS --> LB
    LB --> NGINX_SVC
    
    %% Ingress routing
    NGINX_SVC --> NGINX_CTRL
    NGINX_CTRL --> MISP_INGRESS
    MISP_INGRESS --> MISP_SVC
    MISP_SVC --> MISP_MAIN
    
    %% Pod initialization
    MISP_INIT --> MISP_MAIN
    MISP_INIT --> MISP_VOLUME
    
    %% Application connections
    MISP_MAIN --> MARIA_DB
    MISP_MAIN --> REDIS_CACHE
    MISP_MAIN --> MISP_FILES_PVC
    
    %% Storage connections
    MARIA_PVC --> LH_ENGINE
    REDIS_PVC --> LH_ENGINE
    MISP_FILES_PVC --> LH_ENGINE
    LH_ENGINE --> LH_MGR
    LH_MGR --> STORAGE1
    LH_MGR --> STORAGE2
    LH_MGR --> STORAGE3
    
    %% Pod placement
    MISP_MAIN -.-> W1
    MARIA_DB -.-> W2
    REDIS_CACHE -.-> W3
    NGINX_CTRL -.-> W1
    
    %% Styling
    classDef controlPlane fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef worker fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef misp fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef database fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef storage fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef network fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef external fill:#f5f5f5,stroke:#616161,stroke-width:2px
    
    class CP1,CP2,CP3 controlPlane
    class W1,W2,W3 worker
    class MISP_INIT,MISP_MAIN,MISP_SVC,MISP_INGRESS misp
    class MARIA_DB,REDIS_CACHE,MARIA_PVC,REDIS_PVC database
    class LH_MGR,LH_ENGINE,LH_CSI,STORAGE1,STORAGE2,STORAGE3,MISP_FILES_PVC storage
    class NGINX_CTRL,NGINX_SVC,DNS,LB network
    class ANALYST external
```

### MISP Container Initialization Flow
```mermaid
sequenceDiagram
    participant Kubelet as RKE2 Kubelet
    participant Init as Init Container<br/>(fix-permissions)
    participant MISP as MISP Container
    participant Storage as Longhorn PVC
    participant DB as MariaDB
    participant Cache as Redis
    
    Note over Kubelet,Cache: MISP Pod Startup Sequence
    
    Kubelet->>Storage: Mount PVC to Pod
    Storage-->>Kubelet: Volume ready
    
    Kubelet->>Init: Start init container (runAsUser: 0)
    Init->>Storage: Create directories
    Init->>Storage: chown -R 33:33 /var/www/MISP/app/
    Init->>Storage: chmod 755 directories
    Init-->>Kubelet: Init complete (exit 0)
    
    Kubelet->>MISP: Start MISP container (runAsUser: 33)
    
    Note over MISP: Skip chown operations
    MISP->>MISP: Check SKIP_CHOWN=true
    MISP->>Storage: Access files (33:33 ownership)
    Storage-->>MISP: Permissions OK
    
    MISP->>DB: Connect to MariaDB
    DB-->>MISP: Connection established
    
    MISP->>Cache: Connect to Redis
    Cache-->>MISP: Cache ready
    
    MISP->>MISP: Initialize MISP application
    MISP-->>Kubelet: Ready (HTTP 200 on :80)
    
    Note over Kubelet,Cache: MISP Pod Running
```

### Storage Architecture in RKE2
```mermaid
graph TB
    subgraph "MISP Namespace"
        MISP_POD[MISP Pod]
        MISP_PVC["Files PVC<br/>5Gi<br/>ReadWriteOnce"]
        MARIA_PVC["MariaDB PVC<br/>2Gi<br/>ReadWriteOnce"]
        REDIS_PVC["Redis PVC<br/>1Gi<br/>ReadWriteOnce"]
    end
    
    subgraph "Longhorn Storage System"
        LH_CSI[Longhorn CSI Driver]
        LH_ENGINE[Longhorn Engine]
        
        subgraph "Volume Replicas"
            REP1["Replica 1<br/>Worker Node 1"]
            REP2["Replica 2<br/>Worker Node 2"]
            REP3["Replica 3<br/>Worker Node 3"]
        end
    end
    
    subgraph "File System Mounts"
        FILES_MOUNT["/var/www/MISP/app/files<br/>Upload files & artifacts"]
        TMP_MOUNT["/var/www/MISP/app/tmp<br/>Temporary processing"]
        CONFIG_MOUNT["/var/www/MISP/app/Config<br/>Configuration files"]
    end
    
    MISP_POD --> MISP_PVC
    MISP_PVC --> LH_CSI
    MARIA_PVC --> LH_CSI
    REDIS_PVC --> LH_CSI
    
    LH_CSI --> LH_ENGINE
    LH_ENGINE --> REP1
    LH_ENGINE --> REP2
    LH_ENGINE --> REP3
    
    MISP_PVC --> FILES_MOUNT
    MISP_PVC --> TMP_MOUNT
    MISP_PVC --> CONFIG_MOUNT
    
    classDef pvc fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef longhorn fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef mount fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    
    class MISP_PVC,MARIA_PVC,REDIS_PVC pvc
    class LH_CSI,LH_ENGINE,REP1,REP2,REP3 longhorn
    class FILES_MOUNT,TMP_MOUNT,CONFIG_MOUNT mount
```

## File Structure

### Test Deployment
```
projekte/k8s-deployments/misp-deployment-test/
├── Chart.yaml                 # Helm chart metadata
├── values.yaml               # Default configuration
├── values-fix-permissions.yaml  # Permission fixes
├── templates/
│   ├── deployment.yaml       # Main MISP deployment
│   ├── service.yaml          # Service definition
│   ├── ingress.yaml          # Ingress configuration
│   ├── pvc.yaml             # Persistent volume claims
│   ├── secret.yaml          # Basic secrets
│   └── _helpers.tpl         # Template helpers
├── README.md                # Deployment guide
├── docker/                  # Container build variants
│   ├── Dockerfile.*         # Multiple Dockerfile variants
│   ├── entrypoint-*.sh     # Entry point scripts
│   └── build-*.sh          # Build automation
└── scripts/
    ├── deploy.sh           # Deployment script
    ├── check-storage.sh    # Storage verification
    └── force-cleanup.sh    # Cleanup script
```

### Production Deployment
```
misp/misp-main/
├── Chart.yaml              # Production Helm chart
├── values.yaml            # Production configuration
├── community-values.yaml  # Community edition config
├── templates/
│   ├── deployment.yaml    # Production deployment
│   ├── extra-certs.yaml  # Certificate management
│   ├── networkpolicy.yaml # Network security
│   ├── secret-vault.yaml # HashiCorp Vault integration
│   └── hpa.yaml          # Horizontal pod autoscaling
├── CHANGELOG.md           # Release notes
├── TESTS.md              # Testing procedures
└── README.md             # Production deployment guide
```

### Container Images
```
misp/container-images-main-misp/misp/
├── core/
│   ├── Dockerfile            # Multi-stage production build
│   └── files/
│       ├── entrypoint.sh    # Main entry point
│       ├── configure_misp.sh # MISP configuration
│       ├── utilities.sh     # Helper utilities
│       └── etc/             # Configuration files
└── helper_scripts/
    ├── misp-docker.sh       # Docker build helper
    └── misp-kaniko.sh       # Kaniko build helper
```

## Configuration

### Key Values (`values.yaml`)

#### MISP Configuration
```yaml
misp:
  image:
    repository: registry.gitlab.com/jupiter8595746/container-images/misp
    tag: "2.4.214"
    pullPolicy: IfNotPresent
  
  config:
    admin:
      email: admin@misp.local
      password: "admin123"  # Change for production
      orgName: "Test Organization"
    
    baseUrl: "http://misp.local"
    
    security:
      saltKey: "test-salt-key-change-me"
      enableCSP: false
      disableSSLRedirect: true
```

#### Security Context
```yaml
misp:
  securityContext:
    runAsUser: 33      # www-data
    runAsGroup: 33
    fsGroup: 33
    runAsNonRoot: true

  containerSecurityContext:
    runAsUser: 33
    runAsGroup: 33
    runAsNonRoot: true
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: false
    capabilities:
      drop: [ALL]
```

#### Storage Configuration
```yaml
misp:
  persistence:
    enabled: true
    storageClass: "longhorn"
    accessMode: ReadWriteOnce
    size: 5Gi
```

### Dependencies

#### MariaDB (Database)
```yaml
mariadb:
  enabled: true
  auth:
    rootPassword: "rootpassword"
    username: "misp"
    password: "misppassword"
    database: "misp"
  primary:
    persistence:
      storageClass: "longhorn"
      size: 2Gi
```

#### Redis (Cache)
```yaml
redis:
  enabled: true
  auth:
    enabled: false  # Simplified for testing
  master:
    persistence:
      enabled: true
      storageClass: "longhorn"
      size: 1Gi
```

## Permission Handling

### Problem
MISP container tries to `chown` files on mounted volumes, causing "Operation not permitted" errors in restrictive Kubernetes environments.

### Solution: Init Container Pattern
```yaml
initContainers:
  fixPermissions:
    enabled: true
    image:
      repository: busybox
      tag: "1.35"
    securityContext:
      runAsUser: 0          # Root for chown operations
      runAsNonRoot: false
      capabilities:
        add: [CHOWN, FOWNER]
    command:
      - /bin/sh
      - -c
      - |
        mkdir -p /var/www/MISP/app/{files,tmp,Config}
        chown -R 33:33 /var/www/MISP/app/{files,tmp,Config}
        chmod 755 /var/www/MISP/app/{files,tmp,Config}
```

### Environment Variables
```yaml
env:
  - name: SKIP_CHOWN
    value: "true"
  - name: SKIP_CHMOD
    value: "true" 
  - name: MISP_SKIP_OWNERSHIP
    value: "true"
```

## Deployment Commands

### Installation
```bash
# Navigate to test deployment directory
cd projekte/k8s-deployments/misp-deployment-test/

# Basic installation
helm install misp-test . -n misp-test --create-namespace

# With permission fixes
helm install misp-test . -n misp-test --create-namespace \
  --values values.yaml --values values-fix-permissions.yaml

# Custom domain
helm install misp-test . -n misp-test --create-namespace \
  --set ingress.hosts[0].host=misp.your-domain.com \
  --set misp.config.baseUrl=https://misp.your-domain.com

# Production deployment (from different location)
cd ../../../misp/misp-main/
helm install misp-prod . -n misp-prod --create-namespace \
  --values values.yaml
```

### Upgrade
```bash
# Apply configuration changes (test deployment)
cd projekte/k8s-deployments/misp-deployment-test/
helm upgrade misp-test . -n misp-test

# Upgrade with new values
helm upgrade misp-test . -n misp-test --values new-values.yaml

# Production deployment upgrade
cd ../../../misp/misp-main/
helm upgrade misp-prod . -n misp-prod --values values.yaml
```

### Access
```bash
# Port forwarding for testing
kubectl port-forward -n misp-test service/misp-test 8080:80

# Check deployment status
kubectl get pods,svc,ingress -n misp-test

# View logs
kubectl logs -f deployment/misp-test -n misp-test
```

## Troubleshooting

### Common Issues

#### Permission Errors
```bash
# Symptoms
chown: changing ownership of '/var/www/MISP/app/Config': Operation not permitted

# Solution
helm upgrade misp-test . -n misp-test --values values-fix-permissions.yaml
```

#### Pod Stuck in Init
```bash
# Check init container logs
kubectl logs misp-test-xxx -c wait-for-dependencies -n misp-test
kubectl logs misp-test-xxx -c fix-permissions -n misp-test

# Verify dependencies
kubectl get pods -l app.kubernetes.io/name=mariadb -n misp-test
kubectl get pods -l app.kubernetes.io/name=redis -n misp-test
```

#### Storage Issues
```bash
# Check PVC status
kubectl get pvc -n misp-test
kubectl describe pvc misp-test-data -n misp-test

# Verify Longhorn
kubectl get pods -n longhorn-system
```

### Debug Commands
```bash
# Exec into MISP container
kubectl exec -it deployment/misp-test -n misp-test -- /bin/bash

# Check file permissions
kubectl exec -it deployment/misp-test -n misp-test -- \
  ls -la /var/www/MISP/app/

# Database connectivity test
kubectl exec -it deployment/misp-test -n misp-test -- \
  mysql -h misp-test-mariadb -u misp -pmisppassword misp
```

## Security Considerations

### Test Environment
- Default passwords (change for production)
- TLS optional/disabled
- Simplified security contexts
- No advanced authentication

### Production Requirements
- Strong passwords and secrets management
- TLS/HTTPS enforcement
- OIDC integration
- Network policies
- Regular security updates

## Integration Points

### Data Sources
- Log ingestion from SIEM systems
- Threat feed integration
- API-based data sharing

### Outputs
- STIX/TAXII feeds
- REST API for automation
- Export formats (JSON, XML, CSV)

## Monitoring

### Health Checks
```yaml
livenessProbe:
  httpGet:
    path: /
    port: 8080
  initialDelaySeconds: 60

readinessProbe:
  httpGet:
    path: /
    port: 8080
  initialDelaySeconds: 30
```

### Metrics Collection
- Application logs via kubectl
- Database performance monitoring
- Storage utilization tracking

## Related Documentation
- [[Kubernetes-Deployments]]
- [[Longhorn-Storage]]
- [[Security-Hardening]]