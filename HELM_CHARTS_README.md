# RKE2 Cluster Helm Charts

This directory contains Helm charts for deploying essential services on your RKE2 cluster.

> **⚠️ Single Control Plane Configuration**: These charts are optimized for RKE2 clusters with a single control plane node. Replica counts and high availability features have been adjusted accordingly.

## Charts Available

### 1. Longhorn - Distributed Block Storage
- **Path**: `./longhorn/values.yaml`
- **Purpose**: Provides persistent storage for your RKE2 cluster
- **Chart Source**: Official Longhorn repository
- **Version**: 1.5.3

### 2. Ingress-NGINX - Load Balancer
- **Path**: `./ingress-nginx/values.yaml`
- **Purpose**: Separate instance of NGINX Ingress Controller for external traffic routing
- **Chart Source**: Official Kubernetes ingress-nginx repository  
- **Version**: 4.8.3

> **📝 Note**: These are custom values files for official Helm charts, not standalone chart packages. This approach ensures you always get the latest stable versions from official repositories.

## Prerequisites

- RKE2 cluster up and running (single control plane)
- kubectl configured to access your cluster  
- Helm 3.x installed
- At least one worker node with available storage space (for Longhorn)

> **💡 Single Control Plane Note**: While these charts work with single control plane setups, consider adding worker nodes for better resource distribution and storage availability.

## Deployment Instructions

### 1. Deploy Longhorn Storage

```bash
# Add Longhorn Helm repository
helm repo add longhorn https://charts.longhorn.io
helm repo update

# Install Longhorn with custom values file
helm install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  --create-namespace \
  --timeout 10m \
  --values projekte/longhorn/values.yaml

# Verify installation
kubectl get pods -n longhorn-system
kubectl get storageclass
```

**Post-installation verification:**
```bash
# Check if Longhorn is ready
kubectl get pods -n longhorn-system -w

# Create a test PVC to verify storage
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-longhorn-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: longhorn
EOF

# Check PVC status
kubectl get pvc test-longhorn-pvc
```

### 2. Deploy Ingress-NGINX Controller

```bash
# Add Ingress-NGINX Helm repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install Ingress-NGINX with custom values file
helm install nginx-custom ingress-nginx/ingress-nginx \
  --namespace ingress-nginx-custom \
  --create-namespace \
  --timeout 10m \
  --values projekte/ingress-nginx/values.yaml

# Verify installation
kubectl get pods -n ingress-nginx-custom
kubectl get svc -n ingress-nginx-custom
```

**Get LoadBalancer IP (if using LoadBalancer service type):**
```bash
kubectl get svc -n ingress-nginx-custom nginx-custom-ingress-nginx-controller
```

## Configuration Details

### Longhorn Configuration

Key configurations in `longhorn/values.yaml` for single control plane:
- **Default Replica Count**: 1 (optimized for single control plane)
- **Storage Over-provisioning**: 100%
- **Default Storage Class**: Enabled
- **CSI Driver**: Single replica components for efficient resource usage

**Important Settings:**
- `kubeletRootDir`: Set to `/var/lib/kubelet` (RKE2 default)
- `defaultDataLocality`: "best-effort" (prefer local storage for single node)
- `replicaSoftAntiAffinity`: false (appropriate for single control plane)
- `defaultClassReplicaCount`: 1 (single replica for storage class)

**Single Control Plane Optimizations:**
- CSI components reduced to 1 replica each (attacher, provisioner, resizer, snapshotter)
- Data locality set to "best-effort" for better performance
- Replica counts minimized while maintaining functionality

### Ingress-NGINX Configuration

Key configurations in `ingress-nginx/values.yaml` for single control plane:
- **Service Type**: LoadBalancer (change to NodePort if needed)
- **Ingress Class**: `nginx-custom` (to avoid conflicts)
- **Replica Count**: 1 (optimized for single control plane)
- **Resource Limits**: Conservative settings that can be adjusted

**Single Control Plane Optimizations:**
- Pod Disruption Budget disabled to prevent blocking updates
- Anti-affinity rules removed (not needed with single replica)
- Autoscaling configured for min/max of 1 replica
- Simplified resource allocation

**Service Types:**
- **LoadBalancer**: Requires external load balancer (MetalLB, cloud provider)
- **NodePort**: Exposes on all nodes (ports 30080/30443 by default)

## Accessing Services

### Longhorn UI (if enabled)
```bash
# Port-forward to access UI locally
kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80

# Access at http://localhost:8080
```

### Ingress-NGINX Status
```bash
# Check ingress controller status
kubectl get ingressclass
kubectl describe ingressclass nginx-custom

# Test with a sample application
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx-custom
  rules:
  - host: test.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: test-service
            port:
              number: 80
EOF
```

## Troubleshooting

### Longhorn Issues

1. **Node not ready for storage:**
   ```bash
   # Check node conditions
   kubectl get nodes -o wide
   
   # Check Longhorn node status
   kubectl get lhnodes -n longhorn-system
   ```

2. **PVC stuck in Pending:**
   ```bash
   # Check storage class
   kubectl get storageclass
   
   # Check PVC events
   kubectl describe pvc <pvc-name>
   ```

### Ingress-NGINX Issues

1. **Controller pods not starting:**
   ```bash
   # Check pod logs
   kubectl logs -n ingress-nginx-custom -l app.kubernetes.io/component=controller
   
   # Check service account permissions
   kubectl describe sa -n ingress-nginx-custom nginx-custom-ingress-nginx
   ```

2. **LoadBalancer IP pending:**
   ```bash
   # Check if you have a LoadBalancer provider
   kubectl get nodes -o wide
   
   # Consider switching to NodePort if no LoadBalancer available
   ```

## Maintenance

### Updating Charts

```bash
# Update Helm repositories
helm repo update

# Check for available updates
helm search repo longhorn/longhorn
helm search repo ingress-nginx/ingress-nginx

# Upgrade installations
helm upgrade longhorn ./longhorn -n longhorn-system
helm upgrade nginx-custom ./ingress-nginx -n ingress-nginx-custom
```

### Monitoring

Consider deploying monitoring stack (Prometheus + Grafana) to monitor:
- Longhorn storage metrics
- Ingress-NGINX performance metrics
- Cluster resource utilization

### Backup Considerations

- Configure Longhorn backup targets (S3, NFS) for persistent data
- Regular cluster state backups using RKE2's built-in etcd snapshots
- Document your configuration changes for disaster recovery

## Single Control Plane Considerations

### Resource Limitations
- All workloads run on the control plane node (if no worker nodes)
- Limited resources compared to multi-node clusters
- Storage replicas set to 1 for optimal resource usage

### Scaling Considerations
```bash
# To add worker nodes later and increase replicas:
helm upgrade longhorn ./longhorn -n longhorn-system --set longhorn.defaultSettings.defaultReplicaCount=3
helm upgrade nginx-custom ./ingress-nginx -n ingress-nginx-custom --set ingress-nginx.controller.replicaCount=2
```

### High Availability Limitations
- Single point of failure with one control plane
- No automatic failover for ingress controller
- Storage availability depends on single node health

### Recommendations for Production
1. **Add Worker Nodes**: Distribute workload off control plane
2. **External Load Balancer**: Use MetalLB or cloud provider LB
3. **Backup Strategy**: Regular etcd snapshots and data backups
4. **Monitoring**: Set up alerts for node health and resource usage

## Security Notes

- Both charts follow security best practices with non-root users
- RBAC is properly configured with minimal required permissions
- Consider network policies for additional isolation
- Regular security updates through chart updates
- Single control plane increases security risk - monitor access carefully