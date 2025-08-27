# Buildah CI/CD - Container Build Automation

## Overview

Tekton-based CI/CD pipeline using Buildah for secure, rootless container builds in air-gapped Kubernetes environments. Designed for building security applications and custom container images without Docker daemon dependencies.

## Architecture

### Tekton CI/CD Pipeline in RKE2 Cluster
```mermaid
graph TB
    subgraph "External Source Control"
        DEV[Developer]
        GIT[Git Repository<br/>External/Internal GitLab]
        WEBHOOK[Git Webhook<br/>Push/PR Events]
    end
    
    subgraph "RKE2 Kubernetes Cluster"
        subgraph "Control Plane Nodes"
            CP1[Control Plane 1<br/>etcd + kube-apiserver]
            CP2[Control Plane 2<br/>etcd + kube-apiserver]
            CP3[Control Plane 3<br/>etcd + kube-apiserver]
        end
        
        subgraph "Worker Nodes"
            W1[Worker Node 1<br/>containerd]
            W2[Worker Node 2<br/>containerd]
            W3[Worker Node 3<br/>containerd]
        end
        
        subgraph "tekton-pipelines namespace"
            subgraph "Tekton Control Plane"
                TEKTON_CTRL[Tekton Controller]
                TEKTON_WEBHOOK[Tekton Webhook]
                EVENT_LISTENER[Event Listener<br/>Git Webhook Receiver]
            end
            
            subgraph "Pipeline Execution (Dynamic)"
                PIPELINE_RUN[PipelineRun<br/>Created per trigger]
                
                subgraph "Task Execution Pods (Ephemeral)"
                    CLONE_POD["Git Clone Task Pod<br/>Image: gcr.io/tekton-releases/git-init<br/>Workspace: shared-data<br/>Lifecycle: Created → Runs → Terminates"]
                    
                    BUILD_POD["Buildah Task Pod<br/>Image: quay.io/containers/buildah:v1.40.1<br/>Security: privileged=true<br/>Storage: overlay<br/>Lifecycle: Created → Builds → Pushes → Terminates"]
                    
                    SCAN_POD["Security Scan Task Pod<br/>Image: aquasec/trivy<br/>Scans: Container vulnerabilities<br/>Lifecycle: Created → Scans → Reports → Terminates"]
                end
            end
            
            WORKSPACE_PVC[Shared Data PVC<br/>Longhorn<br/>ReadWriteMany]
            DOCKER_CONFIG[Docker Config Secret<br/>Registry Auth]
        end
        
        subgraph "registry namespace"
            LOCAL_REGISTRY[Container Registry<br/>registry.local:5000]
            REGISTRY_PVC[Registry Storage PVC<br/>Longhorn 100Gi]
        end
        
        subgraph "Target Deployment Namespaces"
            SHUFFLE_NS[shuffle namespace<br/>Shuffle Apps Deployment]
            MISP_NS[misp-test namespace<br/>MISP Deployment]
        end
        
        subgraph "longhorn-system namespace"
            LONGHORN_MGR[Longhorn Manager]
            LONGHORN_ENGINE[Longhorn Engine]
        end
    end
    
    %% Development workflow
    DEV --> GIT
    GIT --> WEBHOOK
    WEBHOOK --> EVENT_LISTENER
    
    %% Pipeline orchestration
    EVENT_LISTENER --> TEKTON_CTRL
    TEKTON_CTRL --> PIPELINE_RUN
    PIPELINE_RUN --> CLONE_POD
    CLONE_POD --> BUILD_POD
    BUILD_POD --> SCAN_POD
    
    %% Storage and secrets
    CLONE_POD --> WORKSPACE_PVC
    BUILD_POD --> WORKSPACE_PVC
    BUILD_POD --> DOCKER_CONFIG
    
    %% Registry operations
    BUILD_POD --> LOCAL_REGISTRY
    LOCAL_REGISTRY --> REGISTRY_PVC
    REGISTRY_PVC --> LONGHORN_ENGINE
    WORKSPACE_PVC --> LONGHORN_ENGINE
    
    %% Deployment targets
    LOCAL_REGISTRY --> SHUFFLE_NS
    LOCAL_REGISTRY --> MISP_NS
    
    %% Pod placement
    CLONE_POD -.-> W1
    BUILD_POD -.-> W2
    SCAN_POD -.-> W3
    
    %% Styling
    classDef controlPlane fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef worker fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef tekton fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef tasks fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef storage fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef external fill:#f5f5f5,stroke:#616161,stroke-width:2px
    classDef registry fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef deployment fill:#f1f8e9,stroke:#33691e,stroke-width:2px
    
    class CP1,CP2,CP3 controlPlane
    class W1,W2,W3 worker
    class TEKTON_CTRL,TEKTON_WEBHOOK,EVENT_LISTENER,PIPELINE_RUN tekton
    class CLONE_POD,BUILD_POD,SCAN_POD tasks
    class WORKSPACE_PVC,REGISTRY_PVC,LONGHORN_MGR,LONGHORN_ENGINE storage
    class DEV,GIT,WEBHOOK external
    class LOCAL_REGISTRY registry
    class SHUFFLE_NS,MISP_NS deployment
```

### Buildah Task Execution Flow in RKE2
```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Git as Git Repository
    participant Webhook as Tekton Event Listener
    participant Controller as Tekton Controller
    participant Kubelet as RKE2 Kubelet
    participant Clone as Git Clone Pod
    participant Build as Buildah Build Pod
    participant Registry as Local Registry
    participant Storage as Longhorn PVC
    participant Target as Target Namespace
    
    Note over Dev,Target: CI/CD Pipeline Execution
    
    Dev->>Git: Push code changes
    Git->>Webhook: Trigger webhook (POST /)
    Webhook->>Controller: Create PipelineRun
    
    Note over Controller,Storage: Git Clone Phase
    Controller->>Kubelet: Create git-clone TaskRun
    Kubelet-->>Clone: Start pod with git-init image
    Clone->>Git: Clone repository to workspace
    Clone->>Storage: Store source code in PVC
    Clone-->>Controller: Task completed
    
    Note over Controller,Registry: Container Build Phase
    Controller->>Kubelet: Create buildah TaskRun
    Note over Kubelet: Pod Security Context:<br/>- privileged: true<br/>- runAsUser: 0<br/>- capabilities: [SYS_ADMIN]
    
    Kubelet-->>Build: Start buildah pod
    Build->>Storage: Read source code from PVC
    Build->>Storage: Mount /var/lib/containers (overlay)
    
    Note over Build: Buildah Build Process
    Build->>Build: buildah bud --storage-driver=overlay
    Build->>Build: Multi-stage build execution
    Build->>Build: Apply security contexts
    Build->>Build: Generate OCI image
    
    Build->>Registry: buildah push to registry.local:5000
    Registry-->>Build: Image pushed successfully
    Build-->>Controller: Build task completed
    
    Note over Controller,Target: Deployment Phase
    Controller->>Target: Trigger deployment update
    Target->>Registry: Pull new image
    Registry-->>Target: Image available
    Target->>Kubelet: Rolling update pods
    Kubelet-->>Target: Pods updated
    
    Controller-->>Dev: Pipeline completed (success/failure)
    
    Note over Dev,Target: Cleanup Phase
    Controller->>Kubelet: Delete TaskRun pods
    Kubelet-->>Controller: Pods cleaned up
```

### Buildah Container Build Architecture
```mermaid
graph TB
    subgraph "Buildah Task Pod (Privileged)"
        subgraph "Container Environment"
            BUILDAH_BIN[Buildah Binary<br/>v1.40.1]
            OVERLAY_STORE[Overlay Storage Driver<br/>/var/lib/containers]
            BUILD_CONTEXT[Build Context<br/>Dockerfile + Source]
        end
        
        subgraph "Security Context"
            ROOT_USER["runAsUser: 0<br/>(Root required for container builds)"]
            PRIVILEGED["privileged: true<br/>(Required for overlay mounts)"]
            CAPABILITIES["capabilities:<br/>- SYS_ADMIN<br/>- CHOWN<br/>- FOWNER"]
        end
        
        subgraph "Volume Mounts"
            WORKSPACE_MOUNT["/workspace/source<br/>(from shared PVC)"]
            CONTAINERS_MOUNT["/var/lib/containers<br/>(emptyDir)"]
            DOCKER_CONFIG["/tekton/creds<br/>(registry auth)"]
        end
    end
    
    subgraph "Build Process Steps"
        STEP1["1. Read Dockerfile<br/>FROM python:3.11-slim"]
        STEP2["2. Pull base image<br/>to local storage"]
        STEP3["3. Create build container<br/>Apply RUN commands"]
        STEP4["4. Copy application code<br/>COPY src/ ."]
        STEP5["5. Set security context<br/>USER 33:33"]
        STEP6["6. Commit container<br/>to OCI image"]
        STEP7["7. Push to registry<br/>registry.local:5000"]
    end
    
    subgraph "Output Artifacts"
        OCI_IMAGE["OCI Container Image<br/>sha256:abc123..."]
        IMAGE_MANIFEST["Image Manifest<br/>Layers, Config, Metadata"]
        VULNERABILITY_REPORT["Security Scan Report<br/>(if scan task enabled)"]
    end
    
    WORKSPACE_MOUNT --> BUILD_CONTEXT
    BUILD_CONTEXT --> BUILDAH_BIN
    DOCKER_CONFIG --> BUILDAH_BIN
    BUILDAH_BIN --> OVERLAY_STORE
    
    BUILDAH_BIN --> STEP1
    STEP1 --> STEP2
    STEP2 --> STEP3
    STEP3 --> STEP4
    STEP4 --> STEP5
    STEP5 --> STEP6
    STEP6 --> STEP7
    
    STEP7 --> OCI_IMAGE
    STEP6 --> IMAGE_MANIFEST
    STEP7 --> VULNERABILITY_REPORT
    
    classDef security fill:#ffebee,stroke:#c62828,stroke-width:2px
    classDef process fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef storage fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef output fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    
    class ROOT_USER,PRIVILEGED,CAPABILITIES security
    class STEP1,STEP2,STEP3,STEP4,STEP5,STEP6,STEP7 process
    class WORKSPACE_MOUNT,CONTAINERS_MOUNT,DOCKER_CONFIG,OVERLAY_STORE storage
    class OCI_IMAGE,IMAGE_MANIFEST,VULNERABILITY_REPORT output
```

## File Structure

### Buildah CI Directory Structure

#### Primary Location (`projekte/k8s-deployments/buildah-ci/`)
```
buildah-ci/
├── buidah-task.yaml           # Core Buildah task definition
├── buildah-pipeline.yaml     # Complete CI/CD pipeline  
├── buildah-pr.yaml           # Pull request builds
├── buildah-pr-incluster.yaml # In-cluster PR builds
├── docker-config.yaml        # Registry authentication
├── registry-conf.yaml        # Registry configuration
├── docker-registry-2.3.0.tgz # Registry Helm chart
├── flake8.zip               # Python linting tools
└── qradar_app/              # QRadar app build context
    └── 1.0.0/
        ├── Dockerfile
        ├── api.yml
        ├── requirements.txt
        └── src/app.py
```

#### Duplicate Location (`projekte/k8s-deployments/buildah/`)
```
buildah/
└── [Same structure as buildah-ci - appears to be a duplicate]
```

**Note**: The repository contains both `buildah-ci/` and `buildah/` directories with identical content. Consider consolidating to avoid maintenance overhead.

## Core Task Definition

### Buildah Task Specification
```yaml
# buidah-task.yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: buildah
  labels:
    app.kubernetes.io/version: "0.9"
  annotations:
    tekton.dev/categories: Image Build
    tekton.dev/pipelines.minVersion: "0.50.0"
    tekton.dev/tags: image-build
    tekton.dev/platforms: "linux/amd64,linux/s390x,linux/ppc64le,linux/arm64"
```

### Key Parameters
```yaml
params:
  - name: IMAGE
    description: Reference of the image buildah will produce
  - name: BUILDER_IMAGE
    description: The location of the buildah builder image
    default: quay.io/containers/buildah:v1.40.1
  - name: STORAGE_DRIVER
    description: Set buildah storage driver
    default: overlay
  - name: DOCKERFILE
    description: Path to the Dockerfile to build
    default: ./Dockerfile
  - name: CONTEXT
    description: Path to the directory to use as context
    default: .
  - name: TLSVERIFY
    description: Verify TLS on registry endpoint
    default: "true"
  - name: FORMAT
    description: Container format (oci or docker)
    default: "oci"
```

### Workspace Configuration
```yaml
workspaces:
  - name: source              # Source code workspace
  - name: sslcertdir          # SSL certificates (optional)
    optional: true
  - name: registries-conf     # Registry configuration (optional)
    optional: true  
  - name: dockerconfig        # Docker/Podman auth config (optional)
    optional: true
```

## Build Process

### Build Script Logic
```bash
# Core build script from buildah task
BUILD_ARGS=()
for buildarg in "$@"; do
  BUILD_ARGS+=("--build-arg=$buildarg")
done

# SSL certificate handling
[ "$(workspaces.sslcertdir.bound)" = "true" ] && \
  CERT_DIR_FLAG="--cert-dir=$(workspaces.sslcertdir.path)"

# Docker config handling  
[ "$(workspaces.dockerconfig.bound)" = "true" ] && \
  DOCKER_CONFIG="$(workspaces.dockerconfig.path)" && \
  export DOCKER_CONFIG

# Registry auth file
if [ "$(workspaces.dockerconfig.bound)" = "true" ]; then
  export REGISTRY_AUTH_FILE=$(workspaces.dockerconfig.path)/config.json
fi

# Custom registry configuration
if [ "$(workspaces.registries-conf.bound)" = "true" ]; then
  cp $(workspaces.registries-conf.path)/000-shortnames.conf \
     /etc/containers/registries.conf.d/000-shortnames.conf
fi

# Build the image
buildah ${CERT_DIR_FLAG} "--storage-driver=${PARAM_STORAGE_DRIVER}" bud \
  "${BUILD_ARGS[@]}" ${PARAM_BUILD_EXTRA_ARGS} \
  "--format=${PARAM_FORMAT}" "--tls-verify=${PARAM_TLSVERIFY}" \
  -f "${PARAM_DOCKERFILE}" -t "${PARAM_IMAGE}" "${PARAM_CONTEXT}"

# Push to registry (if not skipped)
[ "${PARAM_SKIP_PUSH}" = "true" ] && echo "Push skipped" && exit 0
buildah ${CERT_DIR_FLAG} "--storage-driver=${PARAM_STORAGE_DRIVER}" push \
  "--tls-verify=${PARAM_TLSVERIFY}" --digestfile /tmp/image-digest \
  ${PARAM_PUSH_EXTRA_ARGS} "${PARAM_IMAGE}" "docker://${PARAM_IMAGE}"
```

### Security Context
```yaml
securityContext:
  privileged: true  # Required for container builds

volumeMounts:
  - name: varlibcontainers
    mountPath: /var/lib/containers

volumes:
  - name: varlibcontainers
    emptyDir: {}
```

## Pipeline Configuration

### Complete CI/CD Pipeline
```yaml
# buildah-pipeline.yaml (conceptual structure)
apiVersion: tekton.dev/v1
kind: Pipeline
metadata:
  name: buildah-pipeline
spec:
  params:
    - name: git-url
      type: string
    - name: git-revision
      type: string
      default: main
    - name: image-reference
      type: string
    - name: registry-secret
      type: string
      default: registry-auth
  
  workspaces:
    - name: shared-data
    - name: docker-credentials
  
  tasks:
    - name: fetch-source
      taskRef:
        name: git-clone
      workspaces:
        - name: output
          workspace: shared-data
      params:
        - name: url
          value: $(params.git-url)
        - name: revision
          value: $(params.git-revision)
    
    - name: build-image
      taskRef:
        name: buildah
      runAfter:
        - fetch-source
      workspaces:
        - name: source
          workspace: shared-data
        - name: dockerconfig
          workspace: docker-credentials
      params:
        - name: IMAGE
          value: $(params.image-reference)
        - name: TLSVERIFY
          value: "false"  # For internal registries
```

### Pull Request Builds
```yaml
# buildah-pr.yaml
apiVersion: tekton.dev/v1
kind: Pipeline
metadata:
  name: pr-build-pipeline
spec:
  params:
    - name: pr-url
    - name: pr-sha
    - name: target-branch
  tasks:
    - name: pr-fetch
      taskRef:
        name: git-clone
      params:
        - name: url
          value: $(params.pr-url)
        - name: revision
          value: $(params.pr-sha)
    - name: lint-check
      taskRef:
        name: flake8-lint
      runAfter:
        - pr-fetch
    - name: security-scan
      taskRef:
        name: container-scan
      runAfter:
        - pr-fetch
    - name: build-test
      taskRef:
        name: buildah
      runAfter:
        - lint-check
        - security-scan
      params:
        - name: SKIP_PUSH
          value: "true"  # Don't push PR builds
```

## Registry Configuration

### Docker Registry Config
```yaml
# docker-config.yaml
apiVersion: v1
kind: Secret
metadata:
  name: registry-auth
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: |
    {
      "auths": {
        "registry.local:5000": {
          "username": "admin",
          "password": "password",
          "auth": "YWRtaW46cGFzc3dvcmQ="
        }
      }
    }
```

### Registry Configuration
```yaml
# registry-conf.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: registries-conf
data:
  000-shortnames.conf: |
    [registries.search]
    registries = ['registry.local:5000', 'docker.io']
    
    [registries.insecure]
    registries = ['registry.local:5000']
    
    [registries.block]
    registries = []
    
    [[registry]]
    prefix = "docker.io"
    location = "registry.local:5000"
    
    [[registry.mirror]]
    location = "registry.local:5000"
    insecure = true
```

## Air-Gap Considerations

### Offline Image Management
```bash
# Pre-pull required images
buildah_images=(
  "quay.io/containers/buildah:v1.40.1"
  "registry.redhat.io/ubi8/ubi:latest" 
  "python:3.11-slim"
)

# Save for offline transport
for image in "${buildah_images[@]}"; do
  podman pull "$image"
  podman save "$image" > "$(basename $image).tar"
done
```

### Internal Registry Setup
```bash
# Deploy internal registry
helm install registry oci://registry.local:5000/charts/docker-registry \
  --version 2.3.0 \
  --namespace registry \
  --create-namespace \
  --set persistence.enabled=true \
  --set persistence.storageClass=longhorn \
  --set persistence.size=100Gi
```

### Certificate Management
```yaml
# SSL certificates for registry
apiVersion: v1
kind: Secret
metadata:
  name: registry-certs
type: Opaque
data:
  ca.crt: LS0tLS1CRUdJTi... # Base64 encoded CA cert
  tls.crt: LS0tLS1CRUdJTi... # Base64 encoded cert
  tls.key: LS0tLS1CRUdJTi... # Base64 encoded key
```

## Security Hardening

### Pod Security Standards
```yaml
# Buildah task security constraints
apiVersion: v1
kind: SecurityContextConstraints
metadata:
  name: buildah-scc
allowHostDirVolumePlugin: false
allowHostIPC: false
allowHostNetwork: false
allowHostPID: false
allowHostPorts: false
allowPrivilegeEscalation: true  # Required for buildah
allowPrivilegedContainer: true  # Required for container builds
allowedCapabilities:
- SETUID
- SETGID
- CHOWN
- DAC_OVERRIDE
- FOWNER
runAsUser:
  type: RunAsAny
seLinuxContext:
  type: RunAsAny
volumes:
- emptyDir
- secret
- configMap
- persistentVolumeClaim
```

### Network Policies
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: buildah-pipeline-policy
spec:
  podSelector:
    matchLabels:
      tekton.dev/pipeline: buildah-pipeline
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: tekton-pipelines
  egress:
  - to: []
    ports:
    - protocol: TCP
      port: 5000  # Registry access
    - protocol: TCP  
      port: 443   # Git/HTTPS
    - protocol: TCP
      port: 80    # HTTP
```

### RBAC Configuration
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: buildah-pipeline-role
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: buildah-pipeline-binding
subjects:
- kind: ServiceAccount
  name: buildah-pipeline-sa
roleRef:
  kind: Role
  name: buildah-pipeline-role
  apiGroup: rbac.authorization.k8s.io
```

## QRadar App Build Example

### Application Structure
```
qradar_app/1.0.0/
├── Dockerfile              # Multi-stage build
├── api.yml                # Shuffle app definition
├── requirements.txt       # Python dependencies
└── src/
    └── app.py            # QRadar integration logic
```

### Dockerfile Analysis
```dockerfile
# Multi-stage build for security
FROM python:3.11-slim as builder
WORKDIR /app
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /wheels -r requirements.txt

FROM python:3.11-slim
RUN groupadd -r qradar && useradd -r -g qradar qradar
WORKDIR /app
COPY --from=builder /wheels /wheels
RUN pip install --no-cache /wheels/*
COPY --chown=qradar:qradar src/ .
USER qradar
EXPOSE 5001
CMD ["python", "app.py"]
```

### Build Parameters
```yaml
# Task parameters for QRadar app (from buildah-ci directory)
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: qradar-app-build
spec:
  taskRef:
    name: buildah
  params:
    - name: IMAGE
      value: registry.local:5000/shuffle/qradar:1.0.0
    - name: CONTEXT
      value: projekte/k8s-deployments/buildah-ci/qradar_app/1.0.0
    - name: DOCKERFILE
      value: projekte/k8s-deployments/buildah-ci/qradar_app/1.0.0/Dockerfile
    - name: TLSVERIFY
      value: "false"
    - name: FORMAT
      value: "oci"
```

### Build from Shuffle Apps
```yaml
# Task parameters for Shuffle app builds
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  name: shuffle-http-app-build
spec:
  taskRef:
    name: buildah
  params:
    - name: IMAGE
      value: registry.local:5000/shuffle/http:1.4.0
    - name: CONTEXT
      value: projekte/shuffle-apps/http
    - name: DOCKERFILE
      value: projekte/shuffle-apps/http/Dockerfile
    - name: TLSVERIFY
      value: "false"
    - name: FORMAT
      value: "oci"
```

## Monitoring & Observability

### Pipeline Monitoring
```yaml
# ServiceMonitor for Tekton metrics
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: tekton-pipelines
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: tekton-pipelines
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

### Build Notifications
```yaml
# Notification task for pipeline results
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: send-notification
spec:
  params:
    - name: status
    - name: message
    - name: webhook-url
  steps:
    - name: notify
      image: curlimages/curl
      script: |
        curl -X POST $(params.webhook-url) \
          -H "Content-Type: application/json" \
          -d '{"status": "$(params.status)", "message": "$(params.message)"}'
```

## Troubleshooting

### Common Build Issues
```bash
# Debug buildah task
kubectl logs -f taskrun/buildah-build-xxx -c step-build-and-push

# Check storage driver issues
kubectl describe taskrun/buildah-build-xxx

# Registry connectivity test
kubectl run debug --image=curlimages/curl -it --rm -- \
  curl -v https://registry.local:5000/v2/
```

### Debug Commands
```bash
# List pipeline runs
tkn pipelinerun list

# Get pipeline run logs
tkn pipelinerun logs buildah-pipeline-run-xxx

# Describe failed task
tkn taskrun describe --last

# Check workspace mounts
kubectl get pvc -l tekton.dev/pipeline=buildah-pipeline
```

### Performance Optimization
```yaml
# Resource optimization for builds
spec:
  steps:
    - name: build-and-push
      resources:
        requests:
          memory: 1Gi
          cpu: 500m
        limits:
          memory: 4Gi
          cpu: 2
      env:
        - name: BUILDAH_LAYERS
          value: "true"  # Enable layer caching
```

## Related Documentation
- [[Kubernetes-Deployments]]
- [[Container-Registry-Setup]]
- [[Security-Hardening]]