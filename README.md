# Projekte - Unified Repository Collection

This repository contains multiple sub-projects related to Shuffle automation platform, Kubernetes deployments, and CI/CD infrastructure.

## 📁 Repository Structure

```
projekte/
├── README.md                    # This file
├── shuffle-apps/                # Shuffle automation apps
│   ├── README.md
│   ├── aws_s3/                  # AWS S3 & MinIO integration
│   ├── http/                    # HTTP client app
│   ├── qradar_app/              # IBM QRadar SIEM integration
│   ├── test-app/                # SDK testing app
│   └── http-versions/           # Legacy HTTP app versions
└── k8s-deployments/             # Kubernetes & CI/CD infrastructure
    ├── README.md
    ├── shuffle-deployment/      # Shuffle platform deployment
    ├── buildah-ci/              # Container build pipelines
    └── shuffle-apps/            # Additional apps for K8s
```

## 🚀 Sub-Projects Overview

### 📱 [Shuffle Apps](./shuffle-apps/)

**Collection of Shuffle automation applications**

| App | Version | Description | Actions |
|-----|---------|-------------|---------|
| AWS S3 | 1.0.0 | AWS S3 and MinIO storage operations | 10 actions |
| HTTP | 1.4.0 | HTTP client for web requests | 8 actions |
| QRadar | 1.0.0 | IBM QRadar SIEM integration | 20+ actions |
| Test App | 1.0.0 | SDK testing and development | 2 actions |

**Key Features:**
- Production-ready Shuffle apps
- Complete API integrations
- Docker containerization
- Comprehensive documentation
- Version management

### 🏗️ [K8s Deployments](./k8s-deployments/)

**Kubernetes deployment configurations and CI/CD pipelines**

**Components:**
- **Shuffle Platform Deployment**: Production-ready Helm configurations
- **Buildah CI/CD Pipeline**: Tekton-based container build automation  
- **Air-gapped Support**: Complete offline deployment capabilities
- **Storage & Ingress**: Longhorn and Nginx configurations
- **Security**: TLS/SSL and authentication setup

**Key Features:**
- Production Kubernetes deployment
- Air-gapped environment support
- Automated container build pipelines
- Security-focused configuration
- Comprehensive infrastructure documentation

## 🚀 Quick Start

### For Shuffle App Development
```bash
cd shuffle-apps
# See shuffle-apps/README.md for detailed instructions
```

### For Infrastructure Deployment
```bash
cd k8s-deployments
# See k8s-deployments/README.md for deployment guides
```

## 🔧 Available Applications

### Security Operations
- **QRadar App**: Complete IBM QRadar SIEM integration
  - Offense management and investigation
  - Rule configuration and monitoring
  - Ariel search engine capabilities
  - Custom API request support

### Storage & Data Management
- **AWS S3 App**: Comprehensive cloud storage operations
  - Multi-cloud support (AWS S3, MinIO)
  - Bucket lifecycle management
  - File operations and access control
  - Air-gapped environment support

### Network & Communication
- **HTTP App**: Flexible web request automation
  - Full REST API support
  - Authentication and proxy support
  - SSL/TLS configuration
  - Response formatting options

### Development & Testing
- **Test App**: SDK functionality validation
  - Feature testing capabilities
  - Development environment setup
  - Integration validation

## 🏭 Infrastructure Capabilities

### Deployment Options
- **Cloud-native**: Full Kubernetes deployment
- **Air-gapped**: Offline installation support
- **Hybrid**: Mixed environment compatibility
- **Development**: Local testing configurations

### CI/CD Pipeline
- **Container Building**: Buildah-based image construction
- **Multi-architecture**: Support for different platforms
- **Security Scanning**: Vulnerability assessment
- **Automated Testing**: Pull request validation
- **Registry Integration**: Private/public registry support

### Storage Solutions
- **Longhorn**: Distributed block storage
- **Persistent Volumes**: Application data persistence
- **Backup & Recovery**: Data protection strategies
- **High Availability**: Fault-tolerant storage

## 📖 Documentation

Each sub-project contains comprehensive documentation:

- **[Shuffle Apps Documentation](./shuffle-apps/README.md)**: App development, deployment, and usage
- **[K8s Deployments Documentation](./k8s-deployments/README.md)**: Infrastructure setup and management

## 🛠️ Development Workflow

### Adding New Shuffle Apps
1. Navigate to `shuffle-apps/` directory
2. Create app directory with standard structure
3. Follow the app development guidelines
4. Update the main README with app information

### Infrastructure Updates
1. Navigate to `k8s-deployments/` directory
2. Update relevant configuration files
3. Test in development environment
4. Update deployment documentation

## 🔒 Security Considerations

### Application Security
- Secure API key management
- SSL/TLS enforcement
- Input validation and sanitization
- Access control and authentication

### Infrastructure Security
- Network segmentation
- Pod security policies
- Registry authentication
- Secret management
- TLS termination at ingress

### Air-gapped Environment
- Complete offline capability
- No external dependencies during runtime
- Pre-validated image manifests
- Secure internal communication

## 📊 Monitoring & Observability

### Application Monitoring
- Health check endpoints
- Performance metrics collection
- Error tracking and alerting
- Usage analytics

### Infrastructure Monitoring
- Cluster resource utilization
- Node health monitoring
- Storage performance metrics
- Network traffic analysis

## 🤝 Contributing

### Code Contributions
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add appropriate tests
5. Update documentation
6. Submit a pull request

### Documentation Improvements
- Fix typos and grammar
- Add usage examples
- Improve explanations
- Update screenshots

### Bug Reports
- Use the issue tracker
- Provide detailed reproduction steps
- Include environment information
- Attach relevant logs

## 📋 Requirements

### Development Environment
- **Docker**: v20.10+
- **Git**: v2.30+
- **Python**: v3.8+ (for Shuffle apps)
- **kubectl**: v1.20+ (for Kubernetes)
- **Helm**: v3.8+ (for deployments)

### Production Environment
- **Kubernetes**: v1.20+
- **Container Runtime**: Docker or containerd
- **Storage**: CSI-compatible storage driver
- **Networking**: CNI-compatible network plugin
- **Ingress Controller**: Nginx or compatible

## 🆘 Support & Troubleshooting

### Common Issues
- Check individual project READMEs
- Review deployment logs
- Validate configuration files
- Verify resource requirements

### Getting Help
- GitHub Issues for bug reports
- Discussions for questions
- Wiki for additional documentation
- Community Discord/Slack channels

## 📅 Roadmap

### Planned Features
- Additional Shuffle app integrations
- Enhanced CI/CD pipeline features
- Improved monitoring capabilities
- Extended air-gapped support
- Performance optimizations

### Version Management
- Semantic versioning for all components
- Compatibility matrices
- Upgrade guides
- Migration tools

## 📝 License

This project is licensed under the terms specified in each sub-project directory.

## 🏷️ Tags

`kubernetes` `shuffle` `automation` `security` `siem` `qradar` `aws-s3` `http` `docker` `helm` `tekton` `buildah` `ci-cd` `air-gapped` `monitoring` `observability`

---

🤖 **Generated with [Claude Code](https://claude.ai/code)**

**Co-Authored-By: Claude <noreply@anthropic.com>**

---

## 📚 Sub-Project Navigation

- **📱 [Go to Shuffle Apps →](./shuffle-apps/)**
- **🏗️ [Go to K8s Deployments →](./k8s-deployments/)**