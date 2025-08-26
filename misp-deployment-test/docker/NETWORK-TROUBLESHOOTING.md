# Network Troubleshooting for MISP Container Build

## Issue
The original RHEL UBI container build fails with:
```
Curl error (6): Couldn't resolve host name for https://cdn-ubi.redhat.com/
```

## Solutions

### 1. CentOS Stream 9 (Recommended)
Use CentOS Stream which has better network compatibility:
```bash
./build.sh centos
```

### 2. Alpine Linux (Fastest)
Use Alpine for smallest image and fastest build:
```bash
./build.sh alpine
```

### 3. RHEL UBI (If Network Available)
If you have access to Red Hat CDN:
```bash
./build.sh rhel
```

## Network Requirements

### DNS Resolution Required
All builds need to resolve:
- `github.com` (for MISP source code)
- `getcomposer.org` (for PHP dependencies)
- `pypi.org` (for Python packages)

### Base Image Repositories
- **RHEL UBI**: `cdn-ubi.redhat.com` (often blocked in corporate networks)
- **CentOS Stream**: `mirror.stream.centos.org` (better availability)  
- **Alpine**: `dl-cdn.alpinelinux.org` (most reliable)

## Corporate Network Issues

### Proxy Configuration
If behind a corporate proxy, configure Docker:
```bash
# Create or edit ~/.docker/config.json
{
  "proxies": {
    "default": {
      "httpProxy": "http://proxy.company.com:8080",
      "httpsProxy": "http://proxy.company.com:8080"
    }
  }
}
```

### DNS Configuration
Add corporate DNS to Docker daemon:
```json
# /etc/docker/daemon.json
{
  "dns": ["8.8.8.8", "1.1.1.1", "your-corporate-dns"]
}
```

### Certificate Issues
For corporate CA certificates:
```bash
# Copy CA cert to container during build
COPY corporate-ca.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates
```

## Air-Gapped Deployment

For completely offline environments:
1. Build on internet-connected machine
2. Export image: `docker save misp:latest > misp.tar`
3. Transfer to air-gapped environment
4. Import image: `docker load < misp.tar`

## Recommended Build Order

### For Restricted Networks (Your Situation)

1. **Try minimal build first** (Ubuntu 22.04 - most reliable):
   ```bash
   ./build.sh minimal
   ```

2. **If minimal fails, try Alpine** (smallest, different mirrors):
   ```bash
   ./build.sh alpine
   ```

3. **If both fail, check network connectivity**:
   ```bash
   chmod +x test-network.sh
   ./test-network.sh
   ```

### For Networks with Good Connectivity

1. **CentOS Stream** (enterprise-like):
   ```bash
   ./build.sh centos
   ```

2. **RHEL UBI** (requires Red Hat access):
   ```bash
   ./build.sh rhel
   ```

## Build Verification

After successful build:
```bash
# Verify image exists
docker images | grep misp

# Test container startup
docker run --rm -p 8080:80 misp:latest &
sleep 30
curl -f http://localhost:8080 || echo "Container health check failed"

# Clean up
docker stop $(docker ps -q --filter ancestor=misp:latest)
```