# Kubernetes Deployments & CI/CD

**Part of the [Projekte Repository](../README.md)** 📁

This sub-project contains Kubernetes deployment configurations, CI/CD pipelines, and container build tools for Shuffle and related applications.

## Repository Structure

```
k8s-deployments/
├── README.md
├── shuffle-deployment/          # Shuffle platform deployment configs
│   ├── shuffle-values.yaml     # Helm values for Shuffle deployment
│   ├── ingress-nginx.yaml      # Nginx ingress configuration
│   ├── longhorn-values.yaml    # Longhorn storage configuration
│   ├── longhorn-ingress.yaml   # Longhorn ingress setup
│   ├── iris-values.yaml        # IRIS system configuration
│   └── pull_and_save_shuffle_images.sh  # Offline deployment script
├── buildah-ci/                 # Container build and CI/CD pipelines
│   ├── buildah-pipeline.yaml   # Tekton pipeline for Buildah
│   ├── buildah-task.yaml       # Buildah task definition
│   ├── buildah-pr.yaml         # Pull request pipeline
│   ├── buildah-pr-incluster.yaml # In-cluster PR pipeline
│   ├── docker-config.yaml      # Docker registry configuration
│   ├── registry-conf.yaml      # Registry configuration
│   ├── docker-registry-2.3.0.tgz # Docker registry Helm chart
│   └── flake8.zip              # Python linting tools
└── shuffle-apps/               # Additional Shuffle apps
    └── qradar_app/             # IBM QRadar integration app
        └── 1.0.0/
            ├── Dockerfile
            ├── api.yml
            ├── requirements.txt
            └── src/
                └── app.py
```

## Components

### 🚀 Shuffle Deployment

Production-ready Kubernetes deployment for Shuffle 2.0.0+ with:

- **Air-gapped Support**: Complete offline deployment capability
- **High Availability**: Production scaling with proper resource management
- **Storage Integration**: Longhorn distributed storage
- **Ingress Management**: Nginx-based web access
- **Security**: TLS/SSL configuration and secure defaults

#### Key Files:
- `shuffle-values.yaml` - Main Helm configuration for Shuffle
- `pull_and_save_shuffle_images.sh` - Downloads all required Docker images for offline deployment
- `longhorn-*.yaml` - Distributed storage configuration
- `ingress-nginx.yaml` - Web access and load balancing

### 🔧 CI/CD Pipeline (Buildah)

Tekton-based container build pipeline using Buildah for:

- **Container Building**: Buildah-based image construction
- **Multi-arch Support**: Build for different architectures
- **Registry Integration**: Push to private/public registries
- **Pull Request Workflows**: Automated PR testing and building
- **Security Scanning**: Container vulnerability assessment

#### Key Files:
- `buildah-pipeline.yaml` - Main Tekton pipeline definition
- `buildah-task.yaml` - Individual build task
- `buildah-pr.yaml` - Pull request automation
- `docker-config.yaml` - Registry authentication
- `registry-conf.yaml` - Registry routing configuration

### 📱 Shuffle Apps

Additional Shuffle applications for extended functionality:

#### QRadar App v1.0.0
Complete IBM QRadar SIEM integration with 20+ actions:

**Core Features:**
- Offense management (list, get, update, close, add notes)
- Rule management (list, get, update, delete, contributions)
- Ariel search capabilities (create, execute, get results)
- Authorized services management
- Custom API actions

**Available Actions:**
- `get_list_offenses` - Retrieve all offenses
- `get_offense` - Get specific offense details
- `post_update_offense` - Update offense properties
- `post_close_offense` - Close an offense
- `post_add_offense_note` - Add notes to offenses
- `get_rules` - List QRadar rules
- `get_rule` - Get specific rule details
- `post_update_a_rule` - Update rule configuration
- `delete_the_rule` - Remove rules
- `get_rule_offense_contributions` - Rule offense statistics
- `get_ariel_searches` - List Ariel searches
- `create_ariel_search` - Create new searches
- `post_new_search` - Alternative search creation
- `get_ariel_search_results` - Retrieve search results
- `get_authorized_services` - List authorized services
- `post_create_an_authorized_services` - Create services
- `custom_action` - Generic API requests

## Quick Start

### Air-Gapped Deployment

1. **Download Required Images:**
```bash
cd shuffle-deployment
./pull_and_save_shuffle_images.sh
```

2. **Transfer to Target Environment:**
```bash
# Copy shuffle-2.0.0-complete.tar.gz to your air-gapped environment
scp shuffle-2.0.0-complete.tar.gz user@target-server:/tmp/
```

3. **Load Images:**
```bash
# On target server
tar -xzf /tmp/shuffle-2.0.0-complete.tar.gz
for image in shuffle-2.0.0-export/*.tar; do 
    docker load -i $image
done
```

4. **Deploy with Helm:**
```bash
helm install shuffle -f shuffle-deployment/shuffle-values.yaml shuffle/shuffle
```

### CI/CD Pipeline Setup

1. **Install Tekton:**
```bash
kubectl apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
```

2. **Deploy Buildah Pipeline:**
```bash
kubectl apply -f buildah-ci/buildah-task.yaml
kubectl apply -f buildah-ci/buildah-pipeline.yaml
```

3. **Configure Registry Access:**
```bash
kubectl apply -f buildah-ci/docker-config.yaml
kubectl apply -f buildah-ci/registry-conf.yaml
```

4. **Run Pipeline:**
```bash
tkn pipeline start buildah-pipeline \
  --param git-url=https://github.com/your-org/your-app \
  --param branch-name=main \
  --param image-name=your-registry/your-app:latest \
  --workspace name=shared-data,claimName=build-pvc
```

## Configuration

### Shuffle Deployment Configuration

Key configuration options in `shuffle-values.yaml`:

```yaml
# Resource Configuration
orborus:
  extraEnvVars:
    - name: SHUFFLE_ORBORUS_EXECUTION_CONCURRENCY
      value: "10"
    - name: SHUFFLE_APP_SDK_VERSION
      value: "0.0.25"

# Storage Configuration
persistence:
  apps:
    size: 5Gi
    storageClass: longhorn

# Ingress Configuration
ingress:
  enabled: true
  hostname: your-shuffle-domain.com
  tls: true
```

### Buildah Pipeline Configuration

Pipeline parameters:

- `git-url` - Source repository URL
- `branch-name` - Git branch to build
- `image-name` - Target image name and tag
- `subdirectory` - Source subdirectory (optional)
- `verify-ssl` - SSL verification (default: false)

## Security Considerations

### Air-Gapped Environment
- All required images are pre-downloaded
- No external dependencies during deployment
- Secure registry configuration included

### Container Security
- Buildah provides rootless container builds
- Security scanning integration available
- Registry authentication and TLS support

### Network Security
- Ingress with TLS termination
- Network policies for pod isolation
- Service mesh integration ready

## Requirements

### Infrastructure
- **Kubernetes**: v1.20+
- **Helm**: v3.8+
- **Storage**: Longhorn or compatible CSI driver
- **Ingress**: Nginx ingress controller
- **Registry**: Private container registry (for air-gapped)

### CI/CD
- **Tekton Pipelines**: v0.40+
- **Buildah**: v1.23+
- **Git**: v2.30+

## Monitoring and Observability

### Included Configurations
- Prometheus metrics collection
- Grafana dashboard templates
- Log aggregation with OpenSearch
- Distributed tracing ready

### Health Checks
- Kubernetes readiness/liveness probes
- Application health endpoints
- Database connectivity monitoring

## Troubleshooting

### Common Issues

**Image Pull Errors in Air-Gapped:**
```bash
# Verify all images are loaded
docker images | grep shuffle

# Check image pull policy
kubectl get deployment shuffle-backend -o yaml | grep imagePullPolicy
```

**Pipeline Failures:**
```bash
# Check pipeline run status
tkn pipelinerun list

# Get detailed logs
tkn pipelinerun logs <pipeline-run-name>
```

**Storage Issues:**
```bash
# Check Longhorn status
kubectl get pods -n longhorn-system

# Verify PVC status
kubectl get pvc
```

## Contributing

1. **Adding New Apps**: Place in `shuffle-apps/` directory
2. **Pipeline Updates**: Modify `buildah-ci/` configurations
3. **Deployment Changes**: Update `shuffle-deployment/` files

## Support

- **Documentation**: See individual component READMEs
- **Issues**: Report via GitHub Issues
- **Community**: Shuffle Discord/Slack channels

---

🤖 **Generated with [Claude Code](https://claude.ai/code)**

**Co-Authored-By: Claude <noreply@anthropic.com>**