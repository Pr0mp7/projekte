# Ingress-Nginx - Load Balancer & Ingress Controller

## Overview

Nginx-based Kubernetes ingress controller providing load balancing, SSL termination, and traffic routing for applications in air-gapped RKE2 environments. Handles external access to MISP, Shuffle, Longhorn UI, and other services.

## Architecture

### RKE2 Ingress Traffic Flow Architecture
```mermaid
graph TB
    subgraph "External Network"
        ANALYST[Security Analyst<br/>10.1.1.100]
        API_CLIENT[API Client<br/>10.1.1.101]
        AUTOMATION[Automation System<br/>10.1.1.102]
        DNS[DNS Server<br/>10.1.1.53]
        EXT_LB[External Load Balancer<br/>F5/HAProxy<br/>10.1.1.10]
    end
    
    subgraph "RKE2 Kubernetes Cluster Network - 10.42.0.0/16"
        subgraph "Control Plane Nodes"
            CP1[Control Plane 1<br/>10.42.0.10]
            CP2[Control Plane 2<br/>10.42.0.11]
            CP3[Control Plane 3<br/>10.42.0.12]
        end
        
        subgraph "Worker Nodes"
            W1[Worker Node 1<br/>10.42.0.20<br/>nginx-ingress pods]
            W2[Worker Node 2<br/>10.42.0.21<br/>nginx-ingress pods]
            W3[Worker Node 3<br/>10.42.0.22<br/>application pods]
        end
        
        subgraph "nginx-ingress-system namespace - Service Network"
            NGINX_LB_SVC["LoadBalancer Service<br/>nginx-ingress-controller<br/>External IP: 10.42.1.100<br/>Ports: 80/443"]
            
            subgraph "Ingress Controller Pods (DaemonSet/Deployment)"
                NGINX_POD_1["Nginx Controller Pod 1<br/>Node: W1<br/>IP: 10.42.1.10<br/>Ports: 80/443/8443/10254"]
                NGINX_POD_2["Nginx Controller Pod 2<br/>Node: W2<br/>IP: 10.42.1.11<br/>Ports: 80/443/8443/10254"]
            end
            
            NGINX_ADMISSION["Admission Webhook<br/>Validates Ingress Resources<br/>Port: 8443"]
            NGINX_METRICS["Metrics Endpoint<br/>Prometheus Integration<br/>Port: 10254/metrics"]
        end
        
        subgraph "Ingress Resources & SSL Management"
            INGRESS_MISP["Ingress: misp-test<br/>Host: misp.local<br/>Backend: misp-test-service:80<br/>TLS: misp-tls-secret"]
            INGRESS_SHUFFLE["Ingress: shuffle<br/>Host: shuffle.local<br/>Backend: shuffle-frontend:3001<br/>TLS: shuffle-tls-secret"]
            INGRESS_LONGHORN["Ingress: longhorn-ui<br/>Host: longhorn.local<br/>Backend: longhorn-frontend:80<br/>TLS: longhorn-tls-secret"]
            INGRESS_REGISTRY["Ingress: registry<br/>Host: registry.local<br/>Backend: registry:5000<br/>TLS: registry-tls-secret"]
            
            TLS_SECRETS["TLS Secrets<br/>- misp-tls-secret<br/>- shuffle-tls-secret<br/>- longhorn-tls-secret<br/>- registry-tls-secret"]
        end
        
        subgraph "Application Services & Pods"
            subgraph "misp-test namespace - 10.42.2.0/24"
                MISP_SVC["MISP Service<br/>misp-test-service<br/>ClusterIP: 10.42.2.10<br/>Port: 80"]
                MISP_POD["MISP Pod<br/>IP: 10.42.2.20<br/>Port: 80"]
            end
            
            subgraph "shuffle namespace - 10.42.3.0/24"
                SHUFFLE_FE_SVC["Shuffle Frontend Service<br/>shuffle-frontend<br/>ClusterIP: 10.42.3.10<br/>Port: 3001"]
                SHUFFLE_BE_SVC["Shuffle Backend Service<br/>shuffle-backend<br/>ClusterIP: 10.42.3.11<br/>Port: 5001"]
                SHUFFLE_FE_POD["Shuffle Frontend Pod<br/>IP: 10.42.3.20<br/>Port: 3001"]
                SHUFFLE_BE_POD["Shuffle Backend Pod<br/>IP: 10.42.3.21<br/>Port: 5001"]
            end
            
            subgraph "longhorn-system namespace - 10.42.4.0/24"
                LONGHORN_SVC["Longhorn UI Service<br/>longhorn-frontend<br/>ClusterIP: 10.42.4.10<br/>Port: 80"]
                LONGHORN_POD["Longhorn UI Pod<br/>IP: 10.42.4.20<br/>Port: 8000"]
            end
            
            subgraph "registry namespace - 10.42.5.0/24"
                REGISTRY_SVC["Registry Service<br/>registry<br/>ClusterIP: 10.42.5.10<br/>Port: 5000"]
                REGISTRY_POD["Registry Pod<br/>IP: 10.42.5.20<br/>Port: 5000"]
            end
        end
    end
    
    %% External DNS resolution
    ANALYST --> DNS
    API_CLIENT --> DNS
    AUTOMATION --> DNS
    DNS --> EXT_LB
    
    %% External load balancer to K8s ingress
    EXT_LB --> NGINX_LB_SVC
    
    %% LoadBalancer service to ingress pods
    NGINX_LB_SVC --> NGINX_POD_1
    NGINX_LB_SVC --> NGINX_POD_2
    
    %% Ingress controller to ingress resources
    NGINX_POD_1 --> INGRESS_MISP
    NGINX_POD_1 --> INGRESS_SHUFFLE
    NGINX_POD_1 --> INGRESS_LONGHORN
    NGINX_POD_1 --> INGRESS_REGISTRY
    
    NGINX_POD_2 --> INGRESS_MISP
    NGINX_POD_2 --> INGRESS_SHUFFLE
    NGINX_POD_2 --> INGRESS_LONGHORN
    NGINX_POD_2 --> INGRESS_REGISTRY
    
    %% SSL/TLS management
    TLS_SECRETS --> NGINX_POD_1
    TLS_SECRETS --> NGINX_POD_2
    
    %% Ingress to services
    INGRESS_MISP --> MISP_SVC
    INGRESS_SHUFFLE --> SHUFFLE_FE_SVC
    INGRESS_LONGHORN --> LONGHORN_SVC
    INGRESS_REGISTRY --> REGISTRY_SVC
    
    %% Services to pods
    MISP_SVC --> MISP_POD
    SHUFFLE_FE_SVC --> SHUFFLE_FE_POD
    SHUFFLE_BE_SVC --> SHUFFLE_BE_POD
    LONGHORN_SVC --> LONGHORN_POD
    REGISTRY_SVC --> REGISTRY_POD
    
    %% Application interconnections
    SHUFFLE_FE_POD --> SHUFFLE_BE_POD
    
    %% Management and monitoring
    NGINX_POD_1 --> NGINX_ADMISSION
    NGINX_POD_1 --> NGINX_METRICS
    NGINX_POD_2 --> NGINX_ADMISSION
    NGINX_POD_2 --> NGINX_METRICS
    
    %% Pod placement indicators
    NGINX_POD_1 -.-> W1
    NGINX_POD_2 -.-> W2
    MISP_POD -.-> W3
    SHUFFLE_FE_POD -.-> W3
    SHUFFLE_BE_POD -.-> W3
    
    %% Styling
    classDef external fill:#f5f5f5,stroke:#616161,stroke-width:2px
    classDef controlPlane fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef worker fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef ingress fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef ingressResource fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef service fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef pod fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef security fill:#ffebee,stroke:#c62828,stroke-width:2px
    
    class ANALYST,API_CLIENT,AUTOMATION,DNS,EXT_LB external
    class CP1,CP2,CP3 controlPlane
    class W1,W2,W3 worker
    class NGINX_LB_SVC,NGINX_POD_1,NGINX_POD_2,NGINX_ADMISSION,NGINX_METRICS ingress
    class INGRESS_MISP,INGRESS_SHUFFLE,INGRESS_LONGHORN,INGRESS_REGISTRY ingressResource
    class MISP_SVC,SHUFFLE_FE_SVC,SHUFFLE_BE_SVC,LONGHORN_SVC,REGISTRY_SVC service
    class MISP_POD,SHUFFLE_FE_POD,SHUFFLE_BE_POD,LONGHORN_POD,REGISTRY_POD pod
    class TLS_SECRETS security
```

### Ingress Request Processing Flow in RKE2
```mermaid
sequenceDiagram
    participant Client as Security Analyst
    participant DNS as DNS Server
    participant LB as External LB
    participant NginxSvc as Nginx LoadBalancer Service
    participant NginxPod as Nginx Controller Pod
    participant IngressRes as Ingress Resource
    participant K8sAPI as Kubernetes API
    participant Service as Application Service
    participant Pod as Application Pod
    participant TLS as TLS Secret
    
    Note over Client,Pod: HTTPS Request Flow - shuffle.local
    
    Client->>DNS: Resolve shuffle.local
    DNS-->>Client: Return 10.1.1.10 (External LB IP)
    
    Client->>LB: HTTPS GET /workflows (SNI: shuffle.local)
    Note over LB: Load balancer forwards to K8s
    LB->>NginxSvc: Forward to 10.42.1.100:443
    
    Note over NginxSvc: Service selects available nginx pod
    NginxSvc->>NginxPod: Route to nginx controller (10.42.1.10)
    
    Note over NginxPod: SSL termination and host routing
    NginxPod->>TLS: Load TLS certificate for shuffle.local
    TLS-->>NginxPod: Return SSL cert and key
    
    NginxPod->>NginxPod: Terminate SSL, decrypt request
    
    Note over NginxPod: Match request to ingress resource
    NginxPod->>IngressRes: Find matching host (shuffle.local)
    IngressRes-->>NginxPod: Return backend service (shuffle-frontend:3001)
    
    Note over NginxPod: Route to backend service
    NginxPod->>Service: HTTP GET /workflows (to 10.42.3.10:3001)
    
    Note over Service: Service load balances to pods
    Service->>Pod: Forward to shuffle pod (10.42.3.20:3001)
    
    Note over Pod: Application processes request
    Pod->>Pod: Process /workflows request
    Pod-->>Service: Return response (200 OK)
    
    Service-->>NginxPod: Return HTTP response
    
    Note over NginxPod: Re-encrypt response for client
    NginxPod->>TLS: Use certificate for encryption
    TLS-->>NginxPod: Encrypted response ready
    
    NginxPod-->>NginxSvc: HTTPS response
    NginxSvc-->>LB: Forward encrypted response
    LB-->>Client: HTTPS 200 OK + workflow data
    
    Note over Client,Pod: Request complete - end-to-end encryption maintained
```

### Nginx Configuration Management in RKE2
```mermaid
graph TB
    subgraph "Configuration Sources"
        HELM_VALUES["Helm Values<br/>ingress-nginx-values.yaml<br/>Global nginx settings"]
        CONFIGMAP["Nginx ConfigMap<br/>nginx-ingress-controller<br/>Runtime configuration"]
        INGRESS_ANNOTATIONS["Ingress Annotations<br/>Per-service settings<br/>nginx.ingress.kubernetes.io/*"]
        TLS_SECRETS["TLS Secrets<br/>Certificate management<br/>Per-hostname SSL"]
    end
    
    subgraph "nginx-ingress-system namespace"
        subgraph "Nginx Controller Pod Configuration"
            NGINX_CONF["nginx.conf<br/>Main configuration<br/>Generated dynamically"]
            STREAM_CONF["stream configuration<br/>TCP/UDP load balancing"]
            SERVER_BLOCKS["Server blocks<br/>Per-hostname virtual hosts"]
            UPSTREAM_BLOCKS["Upstream blocks<br/>Backend service endpoints"]
            LUA_MODULES["Lua modules<br/>Advanced traffic control"]
        end
        
        NGINX_PROCESS["Nginx Master Process<br/>Configuration reload<br/>Worker management"]
        NGINX_WORKERS["Nginx Worker Processes<br/>Request processing<br/>Auto-scaling based on traffic"]
    end
    
    subgraph "Runtime Configuration Updates"
        K8S_API["Kubernetes API Server<br/>Watch ingress resources<br/>Certificate updates"]
        CONTROLLER_MANAGER["Ingress Controller Manager<br/>Configuration reconciliation<br/>Nginx reload triggering"]
        ADMISSION_WEBHOOK["Admission Webhook<br/>Validate ingress resources<br/>Prevent misconfigurations"]
    end
    
    subgraph "Generated Configuration Example"
        EXAMPLE_CONFIG["# Generated nginx.conf<br/>upstream shuffle-frontend-80 {<br/>  server 10.42.3.20:3001 max_fails=1;<br/>}<br/><br/>server {<br/>  listen 443 ssl http2;<br/>  server_name shuffle.local;<br/>  ssl_certificate /etc/certs/shuffle-tls.crt;<br/>  ssl_certificate_key /etc/certs/shuffle-tls.key;<br/>  <br/>  location / {<br/>    proxy_pass http://shuffle-frontend-80;<br/>    proxy_set_header Host $host;<br/>    proxy_set_header X-Real-IP $remote_addr;<br/>  }<br/>}"]
    end
    
    %% Configuration flow
    HELM_VALUES --> CONFIGMAP
    CONFIGMAP --> NGINX_CONF
    INGRESS_ANNOTATIONS --> SERVER_BLOCKS
    TLS_SECRETS --> SERVER_BLOCKS
    
    %% Runtime updates
    K8S_API --> CONTROLLER_MANAGER
    CONTROLLER_MANAGER --> NGINX_CONF
    CONTROLLER_MANAGER --> UPSTREAM_BLOCKS
    
    %% Configuration validation
    INGRESS_ANNOTATIONS --> ADMISSION_WEBHOOK
    ADMISSION_WEBHOOK --> K8S_API
    
    %% Nginx process management
    NGINX_CONF --> NGINX_PROCESS
    STREAM_CONF --> NGINX_PROCESS
    SERVER_BLOCKS --> NGINX_PROCESS
    UPSTREAM_BLOCKS --> NGINX_PROCESS
    LUA_MODULES --> NGINX_PROCESS
    
    NGINX_PROCESS --> NGINX_WORKERS
    
    %% Configuration example
    SERVER_BLOCKS --> EXAMPLE_CONFIG
    UPSTREAM_BLOCKS --> EXAMPLE_CONFIG
    
    %% Styling
    classDef config fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef nginx fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef runtime fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef example fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    
    class HELM_VALUES,CONFIGMAP,INGRESS_ANNOTATIONS,TLS_SECRETS config
    class NGINX_CONF,STREAM_CONF,SERVER_BLOCKS,UPSTREAM_BLOCKS,LUA_MODULES,NGINX_PROCESS,NGINX_WORKERS nginx
    class K8S_API,CONTROLLER_MANAGER,ADMISSION_WEBHOOK runtime
    class EXAMPLE_CONFIG example
```

## File Structure

### Ingress Configuration Files Structure
```
projekte/k8s-deployments/ingress-nginx/
├── README.md                    # Deployment guide
├── deployment-guide.md         # Detailed deployment guide
├── helm-deployment-commands.sh # Automated deployment script
├── ingress-nginx-deployment.yaml # Direct deployment manifest
├── ingress-nginx-values.yaml   # Helm values configuration
├── sample-ingress.yaml         # Sample ingress resource
└── test-ingress.yaml          # Test ingress resource
```

**Note**: This is the centralized location for all ingress-nginx configurations under the new organized structure.

## Configuration

### Helm Values Configuration
```yaml
# ingress-nginx-values.yaml
controller:
  # Resource allocation
  resources:
    limits:
      cpu: 1000m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 128Mi
  
  # Replica configuration
  replicaCount: 2
  
  # Service configuration
  service:
    type: LoadBalancer
    externalTrafficPolicy: Local
    loadBalancerIP: ""  # Set for static IP
    
  # Node selector for placement
  nodeSelector:
    kubernetes.io/os: linux
    
  # Tolerations for node taints
  tolerations: []
  
  # Affinity rules
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app.kubernetes.io/name
              operator: In
              values:
              - ingress-nginx
          topologyKey: kubernetes.io/hostname
  
  # ConfigMap settings
  config:
    # SSL configuration
    ssl-protocols: "TLSv1.2 TLSv1.3"
    ssl-ciphers: "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256"
    
    # Client body size
    client-max-body-size: "100m"
    
    # Proxy settings
    proxy-body-size: "100m"
    proxy-read-timeout: "60"
    proxy-send-timeout: "60"
    
    # Keep-alive settings
    keep-alive: "75"
    keep-alive-requests: "100"
    
    # Worker processes
    worker-processes: "auto"
    worker-connections: "16384"
    
    # Logging
    log-format-json: "true"
    access-log-path: "/var/log/nginx/access.log"
    error-log-path: "/var/log/nginx/error.log"
    
    # Security headers
    add-headers: "ingress-nginx/security-headers"
    
    # Rate limiting
    limit-req-status-code: "429"
    
    # Compression
    enable-brotli: "true"
    gzip-level: "6"
    
    # Real IP configuration
    use-forwarded-headers: "true"
    compute-full-forwarded-for: "true"
    
  # Metrics configuration
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      namespace: monitoring
      interval: 30s
      
  # Admission webhook
  admissionWebhooks:
    enabled: true
    failurePolicy: Fail
    port: 8443
    
  # Health checks
  livenessProbe:
    httpGet:
      path: "/healthz"
      port: 10254
      scheme: HTTP
    initialDelaySeconds: 10
    periodSeconds: 10
    timeoutSeconds: 1
    successThreshold: 1
    failureThreshold: 5
    
  readinessProbe:
    httpGet:
      path: "/healthz"
      port: 10254
      scheme: HTTP
    initialDelaySeconds: 10
    periodSeconds: 10
    timeoutSeconds: 1
    successThreshold: 1
    failureThreshold: 3

# Default backend
defaultBackend:
  enabled: true
  image:
    registry: registry.local:5000
    image: nginx/nginx-unprivileged
    tag: "1.25-alpine"
  resources:
    limits:
      cpu: 10m
      memory: 20Mi
    requests:
      cpu: 10m
      memory: 20Mi
```

### Security Headers ConfigMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: security-headers
  namespace: ingress-nginx
data:
  X-Frame-Options: "SAMEORIGIN"
  X-Content-Type-Options: "nosniff"
  X-XSS-Protection: "1; mode=block"
  Referrer-Policy: "strict-origin-when-cross-origin"
  Content-Security-Policy: "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; font-src 'self'; connect-src 'self'; frame-ancestors 'self'"
  Strict-Transport-Security: "max-age=31536000; includeSubDomains"
  Permissions-Policy: "geolocation=(), microphone=(), camera=()"
```

## Ingress Resources

### MISP Ingress
```yaml
# misp-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: misp-ingress
  namespace: misp
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "300"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
spec:
  ingressClassName: nginx
  rules:
  - host: misp.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: misp-service
            port:
              number: 80
  tls:
  - hosts:
    - misp.local
    secretName: misp-tls-secret
```

### Shuffle Ingress
```yaml
# shuffle-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: shuffle-ingress
  namespace: shuffle
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/proxy-body-size: "100m"
    nginx.ingress.kubernetes.io/websocket-services: "shuffle-backend"
    nginx.ingress.kubernetes.io/upstream-hash-by: "$request_uri"
spec:
  ingressClassName: nginx
  rules:
  - host: shuffle.local
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: shuffle-backend
            port:
              number: 5001
      - path: /
        pathType: Prefix
        backend:
          service:
            name: shuffle-frontend
            port:
              number: 3000
  tls:
  - hosts:
    - shuffle.local
    secretName: shuffle-tls-secret
```

### Longhorn UI Ingress
```yaml
# longhorn-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: longhorn-ingress
  namespace: longhorn-system
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: longhorn-auth
    nginx.ingress.kubernetes.io/auth-realm: "Longhorn Storage Dashboard"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
spec:
  ingressClassName: nginx
  rules:
  - host: longhorn.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: longhorn-frontend
            port:
              number: 80
  tls:
  - hosts:
    - longhorn.local
    secretName: longhorn-tls-secret
```

### Container Registry Ingress
```yaml
# registry-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: registry-ingress
  namespace: registry
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/proxy-body-size: "1000m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "900"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "900"
    nginx.ingress.kubernetes.io/client-body-buffer-size: "1m"
spec:
  ingressClassName: nginx
  rules:
  - host: registry.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: registry-service
            port:
              number: 5000
  tls:
  - hosts:
    - registry.local
    secretName: registry-tls-secret
```

## SSL/TLS Configuration

### Certificate Generation
```bash
#!/bin/bash
# generate-certs.sh

# Generate CA private key
openssl genrsa -out ca-key.pem 4096

# Generate CA certificate
openssl req -new -x509 -days 3650 -key ca-key.pem -sha256 -out ca.pem -subj \
  "/C=US/ST=CA/L=SF/O=Local/OU=IT/CN=Local CA"

# Generate server private key
openssl genrsa -out server-key.pem 4096

# Generate certificate signing request
openssl req -subj "/C=US/ST=CA/L=SF/O=Local/OU=IT/CN=*.local" \
  -sha256 -new -key server-key.pem -out server.csr

# Create extensions file
echo "subjectAltName = DNS:*.local,DNS:localhost,IP:127.0.0.1" > extfile.cnf

# Generate server certificate
openssl x509 -req -days 365 -in server.csr -CA ca.pem -CAkey ca-key.pem \
  -out server-cert.pem -extfile extfile.cnf -CAcreateserial

# Create Kubernetes TLS secret
kubectl create secret tls local-tls-secret \
  --cert=server-cert.pem \
  --key=server-key.pem \
  --namespace=ingress-nginx
```

### Wildcard Certificate Secret
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: wildcard-local-tls
  namespace: ingress-nginx
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTi... # Base64 encoded certificate
  tls.key: LS0tLS1CRUdJTi... # Base64 encoded private key
```

## Deployment

### Helm Installation
```bash
#!/bin/bash
# deploy-ingress-nginx.sh

set -e

NAMESPACE="ingress-nginx"
CHART_VERSION="4.11.3"
RELEASE_NAME="ingress-nginx"
CONFIG_DIR="projekte/k8s-deployments/ingress-nginx"

echo "Deploying ingress-nginx ${CHART_VERSION} to ${NAMESPACE}"

# Navigate to configuration directory
cd $CONFIG_DIR

# Add ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Create namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Deploy security headers ConfigMap
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: security-headers
  namespace: $NAMESPACE
data:
  X-Frame-Options: "SAMEORIGIN"
  X-Content-Type-Options: "nosniff"
  X-XSS-Protection: "1; mode=block"
  Referrer-Policy: "strict-origin-when-cross-origin"
  Strict-Transport-Security: "max-age=31536000; includeSubDomains"
EOF

# Deploy ingress-nginx with correct values path
helm upgrade --install $RELEASE_NAME ingress-nginx/ingress-nginx \
    --namespace $NAMESPACE \
    --values ingress-nginx-values.yaml \
    --version $CHART_VERSION \
    --wait

# Verify deployment
echo "Verifying ingress-nginx deployment..."
kubectl get pods -n $NAMESPACE
kubectl get svc -n $NAMESPACE

# Check ingress class
kubectl get ingressclass

# Apply sample ingress resources
echo "Applying sample ingress configurations..."
kubectl apply -f sample-ingress.yaml
kubectl apply -f test-ingress.yaml

echo "Ingress-nginx deployment complete!"
echo "Configuration files available in: $CONFIG_DIR"
```

### Manual Deployment (Air-Gap)
```yaml
# ingress-nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-ingress-controller
  namespace: ingress-nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ingress-nginx
    spec:
      serviceAccountName: nginx-ingress-serviceaccount
      containers:
      - name: nginx-ingress-controller
        image: registry.local:5000/ingress-nginx/controller:v1.11.2
        args:
          - /nginx-ingress-controller
          - --configmap=$(POD_NAMESPACE)/nginx-configuration
          - --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services
          - --udp-services-configmap=$(POD_NAMESPACE)/udp-services
          - --publish-service=$(POD_NAMESPACE)/ingress-nginx
          - --annotations-prefix=nginx.ingress.kubernetes.io
        securityContext:
          allowPrivilegeEscalation: true
          capabilities:
            drop:
            - ALL
            add:
            - NET_BIND_SERVICE
          runAsUser: 101
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        ports:
        - name: http
          containerPort: 80
        - name: https
          containerPort: 443
        livenessProbe:
          httpGet:
            path: /healthz
            port: 10254
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 1
          successThreshold: 1
          failureThreshold: 5
        readinessProbe:
          httpGet:
            path: /healthz
            port: 10254
            scheme: HTTP
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 1
          successThreshold: 1
          failureThreshold: 3
        resources:
          limits:
            cpu: 1000m
            memory: 512Mi
          requests:
            cpu: 100m
            memory: 128Mi
```

## Load Balancing Strategies

### Session Affinity
```yaml
# Session-based routing
metadata:
  annotations:
    nginx.ingress.kubernetes.io/affinity: "cookie"
    nginx.ingress.kubernetes.io/affinity-mode: "sticky"
    nginx.ingress.kubernetes.io/session-cookie-name: "route"
    nginx.ingress.kubernetes.io/session-cookie-max-age: "86400"
```

### Load Balancing Algorithms
```yaml
# Upstream hashing
metadata:
  annotations:
    nginx.ingress.kubernetes.io/upstream-hash-by: "$remote_addr"
    
# Least connections
metadata:
  annotations:
    nginx.ingress.kubernetes.io/load-balance: "least_conn"
```

### Health Checks
```yaml
# Custom health checks
metadata:
  annotations:
    nginx.ingress.kubernetes.io/server-snippet: |
      location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
      }
```

## Monitoring & Observability

### Prometheus Metrics
```yaml
# ServiceMonitor for Prometheus
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: nginx-ingress
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

### Grafana Dashboard
```yaml
# Ingress-nginx dashboard ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-ingress-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  nginx-ingress.json: |
    {
      "dashboard": {
        "id": 9614,
        "title": "NGINX Ingress controller",
        "tags": ["kubernetes", "ingress", "nginx"],
        "panels": [
          {
            "title": "Request Rate",
            "type": "graph",
            "targets": [
              {
                "expr": "rate(nginx_ingress_controller_requests_total[5m])"
              }
            ]
          }
        ]
      }
    }
```

### Log Configuration
```yaml
# Fluent Bit configuration for nginx logs
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-nginx-config
data:
  nginx.conf: |
    [INPUT]
        Name tail
        Path /var/log/nginx/access.log
        Parser nginx_json
        Tag nginx.access
        
    [INPUT]
        Name tail
        Path /var/log/nginx/error.log
        Parser nginx_error
        Tag nginx.error
        
    [OUTPUT]
        Name opensearch
        Match nginx.*
        Host opensearch.logging.svc.cluster.local
        Port 9200
        Index nginx-logs
```

## Security Hardening

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ingress-nginx-policy
  namespace: ingress-nginx
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from: []  # Allow from any (ingress traffic)
    ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 443
  - from:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: TCP
      port: 8443  # Admission webhook
  egress:
  - to:
    - podSelector: {}  # Allow to any pod in namespace
  - to: []  # Allow to backend services
    ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 5000  # Registry
    - protocol: TCP
      port: 3000  # Frontend services
    - protocol: TCP
      port: 5001  # Backend services
```

### Pod Security Policy
```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: nginx-ingress-psp
spec:
  privileged: false
  allowPrivilegeEscalation: true  # Required for NET_BIND_SERVICE
  runAsUser:
    rule: MustRunAs
    ranges:
    - min: 101
      max: 101
  seLinux:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  volumes:
  - secret
  - configMap
  - emptyDir
  - projected
  allowedCapabilities:
  - NET_BIND_SERVICE
  requiredDropCapabilities:
  - ALL
```

### Rate Limiting
```yaml
# Global rate limiting
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-configuration
  namespace: ingress-nginx
data:
  # Rate limiting
  limit-rate-after: "1024"
  limit-rate: "1024"
  
  # Connection limiting
  limit-connections: "20"
  
  # Request rate limiting
  http-snippet: |
    limit_req_zone $binary_remote_addr zone=global:10m rate=10r/s;
    limit_req zone=global burst=20 nodelay;
```

## Troubleshooting

### Common Issues

#### Controller Not Starting
```bash
# Check controller logs
kubectl logs -f deployment/nginx-ingress-controller -n ingress-nginx

# Check admission webhook
kubectl get validatingwebhookconfiguration
kubectl get mutatingwebhookconfiguration

# Verify RBAC permissions
kubectl auth can-i create ingresses --as=system:serviceaccount:ingress-nginx:nginx-ingress-serviceaccount
```

#### SSL Certificate Issues
```bash
# Check certificate secrets
kubectl get secrets -n ingress-nginx
kubectl describe secret local-tls-secret -n ingress-nginx

# Test certificate validity
openssl x509 -in certificate.crt -text -noout

# Check ingress annotations
kubectl describe ingress app-ingress -n namespace
```

#### Backend Connection Failures
```bash
# Check service endpoints
kubectl get endpoints -n app-namespace
kubectl describe service app-service -n app-namespace

# Test backend connectivity
kubectl run debug --image=busybox -it --rm -- \
  wget -qO- http://service-name.namespace:port/health

# Check ingress backend configuration
kubectl get ingress app-ingress -o yaml
```

### Debug Commands
```bash
# Check ingress controller status
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# View nginx configuration
kubectl exec -n ingress-nginx nginx-ingress-controller-xxx -- cat /etc/nginx/nginx.conf

# Test ingress routing
curl -H "Host: app.local" http://ingress-ip/

# Check metrics endpoint
curl http://controller-ip:10254/metrics

# Validate ingress resource
kubectl get ingress --all-namespaces
kubectl describe ingress app-ingress -n namespace
```

### Performance Troubleshooting
```bash
# Check resource usage
kubectl top pods -n ingress-nginx

# Monitor request rates
kubectl exec -n ingress-nginx controller-pod -- \
  curl -s localhost:10254/metrics | grep nginx_ingress_controller_requests_total

# Check upstream response times
kubectl logs -f deployment/nginx-ingress-controller -n ingress-nginx | \
  grep "upstream_response_time"
```

## Integration Points

### Application Integration
- **MISP**: SSL termination, file upload handling
- **Shuffle**: WebSocket support, API routing
- **Longhorn**: Authentication, dashboard access
- **Registry**: Large file uploads, SSL termination

### Monitoring Integration
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Dashboard visualization
- **Logging Stack**: Access and error log forwarding

## Related Documentation
- [[Kubernetes-Deployments]]
- [[Security-Hardening]]
- [[SSL-Certificate-Management]]
- [[Load-Balancing-Strategies]]