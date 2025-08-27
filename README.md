# Kubernetes Security Platform Deployment

A comprehensive collection of Kubernetes-based security platforms and infrastructure components designed for air-gapped RKE2 environments.

## 🏗️ Repository Structure

```
Claude/
├── CLAUDE.md                    # Project configuration and instructions
├── README.md                   # This file
├── .gitignore                  # Git ignore patterns
├── aws_s3_app.txt             # AWS S3 application notes
├── misp/                      # MISP Threat Intelligence Platform
│   ├── container-images-main-misp/  # Custom container builds
│   └── misp-main/             # Production Helm chart
└── projekte/                  # Main projects directory
    ├── k8s-deployments/      # Kubernetes deployment configurations
    │   ├── buildah-ci/       # CI/CD build pipelines
    │   ├── buildah/          # Buildah configurations (duplicate)
    │   ├── ingress-nginx/    # Ingress controller deployment
    │   ├── longhorn/         # Distributed storage
    │   ├── misp-deployment-test/ # MISP test deployment
    │   └── shuffle-deployment/   # Shuffle SOAR platform
    └── shuffle-apps/         # SOAR application collection
        ├── aws_s3/          # AWS S3 & MinIO integration
        ├── http/            # HTTP client (current v1.4.0)
        ├── http-versions/   # Legacy HTTP versions
        ├── qradar_app/      # IBM QRadar SIEM integration
        └── test-app/        # SDK testing application
```

## 🛡️ Security Platforms

### MISP - Malware Information Sharing Platform
- **Production**: `misp/misp-main/` - Enterprise-grade deployment with Vault integration
- **Test Environment**: `projekte/k8s-deployments/misp-deployment-test/` - Simplified test deployment
- **Container Images**: `misp/container-images-main-misp/` - Custom hardened containers

### Shuffle - Security Orchestration and Response
- **Platform**: `projekte/k8s-deployments/shuffle-deployment/` - Complete SOAR platform
- **Applications**: `projekte/shuffle-apps/` - Security automation apps
  - HTTP Client v1.4.0 with full REST API support
  - QRadar SIEM integration with 20+ actions
  - AWS S3/MinIO storage operations
  - Testing and development utilities

## 🏗️ Infrastructure Components

### Container Build Automation
- **Buildah CI/CD**: `projekte/k8s-deployments/buildah-ci/` - Tekton-based build pipelines
- **Air-gap Support**: Offline container builds and registry management
- **Security Scanning**: Integrated vulnerability scanning and linting

### Networking & Load Balancing
- **Ingress-Nginx**: `projekte/k8s-deployments/ingress-nginx/` - SSL termination and routing
- **Service Mesh Ready**: Prepared for advanced networking requirements

### Storage Solution
- **Longhorn**: `projekte/k8s-deployments/longhorn/` - Distributed block storage
- **High Availability**: Multi-replica storage with automatic failover
- **Backup Integration**: S3-compatible backup targets

## 🚀 Quick Start

### Prerequisites
- RKE2 Kubernetes cluster
- Helm 3.x installed
- kubectl configured
- Container registry (for air-gapped environments)

### Basic Deployment Order

1. **Storage Foundation**
   ```bash
   # Deploy Longhorn storage
   helm upgrade --install longhorn longhorn/longhorn \
     --namespace longhorn-system --create-namespace \
     --values projekte/k8s-deployments/longhorn/values.yaml
   ```

2. **Ingress Controller**
   ```bash
   # Deploy ingress-nginx
   helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
     --namespace ingress-nginx --create-namespace \
     --values projekte/k8s-deployments/ingress-nginx/ingress-nginx-values.yaml
   ```

3. **Security Platforms**
   ```bash
   # Deploy MISP (test environment)
   cd projekte/k8s-deployments/misp-deployment-test/
   helm install misp-test . --namespace misp-test --create-namespace
   
   # Deploy Shuffle SOAR
   cd ../shuffle-deployment/
   helm install shuffle . --namespace shuffle --create-namespace \
     --values shuffle-values.yaml
   ```

## 🔧 Configuration

### Air-Gapped Environment Setup
- Configure local container registry
- Update image references in values files
- Set up offline Helm chart repositories
- Configure network policies for security

### Storage Classes
- **Default**: Longhorn with 3 replicas
- **Fast**: SSD-backed storage for databases
- **Backup**: S3-compatible backup storage

### Network Configuration
- **Ingress**: SSL/TLS termination with security headers
- **Network Policies**: Microsegmentation between namespaces
- **Service Mesh**: Ready for Istio/Linkerd integration

## 📚 Documentation

Comprehensive technical documentation is available in the Obsidian knowledge base:

- **[[00-Project-Overview]]** - Architecture and overview
- **[[MISP-Deployment]]** - Complete MISP deployment guide
- **[[Shuffle-Apps]]** - SOAR applications documentation
- **[[Kubernetes-Deployments]]** - Infrastructure deployment patterns
- **[[Buildah-CICD]]** - Container build automation
- **[[Longhorn-Storage]]** - Storage system configuration
- **[[Ingress-Nginx]]** - Load balancer and ingress setup

## 🔐 Security Features

### Container Security
- Multi-stage builds for minimal attack surface
- Non-root user execution
- Read-only root filesystems
- Security context enforcement

### Network Security
- Network policies for traffic isolation
- TLS encryption for all communications
- Security headers via ingress
- Certificate management automation

### Platform Security
- RBAC configuration
- Pod Security Standards enforcement
- Secret management integration
- Audit logging capabilities

## 🛠️ Development Workflow

### CI/CD Pipeline
1. **Code Commit** → Git repository
2. **Build Trigger** → Tekton pipeline activation
3. **Container Build** → Buildah rootless builds
4. **Security Scan** → Vulnerability assessment
5. **Registry Push** → Secure container storage
6. **Deployment** → Automated Kubernetes deployment

### Testing Strategy
- Unit tests for application logic
- Integration tests for platform components
- Security tests for compliance
- Performance tests for scalability

## 🤝 Contributing

1. Follow the established directory structure
2. Update documentation for any changes
3. Ensure all deployments work in air-gapped environments
4. Add appropriate security contexts and policies
5. Test thoroughly in RKE2 environment

## 📝 License

This project follows enterprise security best practices and is designed for internal deployment in secure environments.

## 🆘 Support

For issues and troubleshooting:
- Check the comprehensive documentation in Obsidian
- Review deployment logs and Kubernetes events
- Verify network policies and security contexts
- Ensure proper RBAC permissions

---

**Generated with Claude Code** - AI-assisted infrastructure development