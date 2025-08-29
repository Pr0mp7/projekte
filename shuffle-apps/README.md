# Shuffle Apps Collection

**Part of the [Projekte Repository](../README.md)** 📁

This sub-project contains various Shuffle apps for workflow automation and security operations.

## Apps Overview

| App | Version | Description | Actions |
|-----|---------|-------------|---------|
| AWS S3 | 1.0.0 | AWS S3 and MinIO storage operations | 10 actions |
| HTTP | 1.4.0 | HTTP client for web requests | 8 actions |
| Test App | 1.0.0 | Testing app for SDK features | 2 actions |
| QRadar | 1.0.0 | IBM QRadar SIEM integration | 20+ actions |

### HTTP App Version History

| Version | Status | Changes |
|---------|--------|---------|
| 1.0.0 | Legacy | Initial HTTP client implementation |
| 1.1.0 | Legacy | Enhanced HTTP functionality |
| 1.2.0 | Legacy | Improved header handling |
| 1.3.0 | Legacy | Additional HTTP methods |
| 1.4.0 | Current | Complete REST API support |

## AWS S3 App

A comprehensive AWS S3 and MinIO compatible storage operations app for Shuffle.

### Features

- List all S3 buckets
- Create new S3 buckets
- Upload files to S3 buckets
- Download files from S3 buckets
- Delete files from S3 buckets
- Block IP access to buckets (AWS only)
- Get bucket logging configuration
- Get bucket policy status
- Get bucket replication configuration
- Get bucket request payment configuration

### MinIO Support

This app supports MinIO by using the `endpoint_url` parameter. For MinIO in Kubernetes, use:
- endpoint_url: `http://minio.minio-namespace.svc.cluster.local:9000`
- region: `us-east-1` (standard for MinIO)

## HTTP App

HTTP client app for making web requests and API calls.

### Features

- GET requests
- POST requests  
- PUT requests
- PATCH requests
- DELETE requests
- HEAD requests
- OPTIONS requests
- Custom curl command execution

### Parameters

All HTTP methods support:
- Custom headers
- Authentication (username/password)
- SSL certificate verification
- HTTP/HTTPS proxy support
- Request timeout configuration
- Response to file conversion

## Test App

Simple testing app using App SDK 0.0.25 for development and testing purposes.

### Features

- Hello world test function
- Execution isolation testing
- Datastore functionality testing

## QRadar App

Comprehensive IBM QRadar SIEM integration for security operations and incident response.

### Features

**Offense Management:**
- List all offenses from QRadar
- Get detailed offense information
- Update offense properties and status
- Close offenses with resolution notes
- Add investigative notes to offenses

**Rule Management:**
- Retrieve and manage QRadar rules
- Update rule configurations
- Delete obsolete rules
- Get rule offense contribution statistics

**Ariel Search Engine:**
- Create custom Ariel searches
- Execute complex queries across data sources
- Retrieve search results with pagination
- Support for multiple databases and data lakes

**System Management:**
- Manage authorized services
- Custom API requests for extended functionality
- SSL/TLS verification control
- Response formatting and file handling

### Available Actions

| Action | Description | Use Case |
|--------|-------------|----------|
| `get_list_offenses` | Retrieve all QRadar offenses | Monitoring, reporting |
| `get_offense` | Get specific offense details | Investigation, analysis |
| `post_update_offense` | Update offense properties | Status management |
| `post_close_offense` | Close an offense | Incident resolution |
| `post_add_offense_note` | Add notes to offenses | Documentation, collaboration |
| `get_rules` | List QRadar rules | Rule management |
| `get_rule` | Get specific rule details | Rule analysis |
| `post_update_a_rule` | Update rule configuration | Rule tuning |
| `delete_the_rule` | Remove rules | Cleanup, optimization |
| `get_rule_offense_contributions` | Rule offense statistics | Performance analysis |
| `get_ariel_searches` | List Ariel searches | Search management |
| `create_ariel_search` | Create new searches | Data investigation |
| `post_new_search` | Alternative search creation | Query execution |
| `get_ariel_search_results` | Retrieve search results | Data analysis |
| `get_authorized_services` | List authorized services | System administration |
| `post_create_an_authorized_services` | Create services | Access management |
| `custom_action` | Generic API requests | Extended functionality |

## Installation & Usage

### Build and Deploy

1. Build the Docker image for any app:
```bash
cd [app-name]
docker build -t your-registry.local:5000/shuffle/[app-name]:1.0.0 .
```

2. Push to your local registry:
```bash
docker push your-registry.local:5000/shuffle/[app-name]:1.0.0
```

3. Create a ZIP for Shuffle upload:
```bash
zip -r [app-name].zip . -x "*.git*"
```

4. Upload to Shuffle via UI or API

## Related Repositories

This repository focuses exclusively on Shuffle apps. For deployment and infrastructure:

### 🚀 [K8s-Deployments Repository](https://github.com/Pr0mp7/k8s-deployments)

Complete Kubernetes deployment and CI/CD infrastructure:

- **Shuffle Deployment**: Production-ready Helm configurations
- **Air-gapped Support**: Offline deployment capabilities
- **CI/CD Pipelines**: Buildah-based container build automation
- **Storage & Ingress**: Longhorn and Nginx configurations
- **Security**: TLS/SSL and authentication setup

### Directory Structure

```
shuffle-apps/
├── README.md
├── aws_s3/                    # AWS S3 & MinIO integration
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── api.yaml
│   └── src/
│       └── app.py
├── http/                      # HTTP client (current v1.4.0)
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── api.yaml
│   └── src/
│       └── app.py
├── qradar_app/               # IBM QRadar SIEM integration
│   └── 1.0.0/
│       ├── Dockerfile
│       ├── requirements.txt
│       ├── api.yml
│       └── src/
│           └── app.py
├── test-app/                 # SDK testing and development
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── api.yaml
│   └── src/
│       ├── app.py
│       └── shuffle_sdk/
│           └── __init__.py
└── http-versions/            # Legacy HTTP app versions
    ├── 1.0.0/
    ├── 1.1.0/
    ├── 1.2.0/
    └── 1.3.0/
```

## Requirements

- Docker for containerization
- Shuffle platform for deployment
- Python 3.x with shuffle_sdk

## Quick App Deployment

### Using Shuffle UI

1. **Build the app:**
```bash
cd [app-name]
zip -r [app-name].zip . -x "*.git*"
```

2. **Upload to Shuffle:**
   - Go to Shuffle UI → Apps → Upload App
   - Select the ZIP file
   - App will be automatically deployed

### Using Container Registry

1. **Build Docker image:**
```bash
cd [app-name]
docker build -t your-registry/shuffle-[app-name]:1.0.0 .
```

2. **Push to registry:**
```bash
docker push your-registry/shuffle-[app-name]:1.0.0
```

3. **Deploy via Shuffle API or UI**

For complete deployment infrastructure including Kubernetes, CI/CD, and air-gapped environments, see the [K8s-Deployments Repository](https://github.com/Pr0mp7/k8s-deployments).

## Contributing

Feel free to add more Shuffle apps to this collection. Each app should follow the standard Shuffle app structure with:
- `Dockerfile` for containerization
- `api.yaml` for app definition
- `requirements.txt` for Python dependencies  
- `src/app.py` for main application logic

### Version Management

When adding new versions:
1. Place them in `http-versions/` for version history
2. Update the current version in the main app directory
3. Document changes in the version history table