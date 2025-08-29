# Debug Stuck Namespace - Quick Fix Guide

## Immediate Diagnosis Commands

```bash
# Check namespace status and finalizers
kubectl get namespace misp-test -o yaml

# Check what resources are still in the namespace
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n misp-test

# Check for stuck PVCs (common cause)
kubectl get pvc -n misp-test

# Check for stuck StatefulSets
kubectl get statefulset -n misp-test

# Check for stuck pods
kubectl get pods -n misp-test
```

## Quick Fix Commands (Run These)

### 1. Force Delete Helm Releases
```bash
# List and delete any remaining helm releases
helm list -n misp-test
helm uninstall misp-test -n misp-test --no-hooks || true
```

### 2. Force Delete Stuck Resources
```bash
# Delete PVCs with force
kubectl delete pvc --all -n misp-test --grace-period=0 --force

# Delete StatefulSets with force  
kubectl delete statefulset --all -n misp-test --grace-period=0 --force

# Delete pods with force
kubectl delete pods --all -n misp-test --grace-period=0 --force

# Delete deployments with force
kubectl delete deployment --all -n misp-test --grace-period=0 --force
```

### 3. Remove Finalizers from Resources
```bash
# Remove finalizers from PVCs
kubectl patch pvc -n misp-test --all -p '{"metadata":{"finalizers":null}}' --type=merge

# Remove finalizers from StatefulSets
kubectl get statefulset -n misp-test -o name | xargs -I {} kubectl patch {} -n misp-test -p '{"metadata":{"finalizers":null}}' --type=merge
```

### 4. Nuclear Option - Remove Namespace Finalizers
```bash
# Backup namespace definition first
kubectl get namespace misp-test -o json > misp-test-namespace-backup.json

# Remove finalizers from namespace
kubectl patch namespace misp-test -p '{"spec":{"finalizers":[]}}' --type=merge
kubectl patch namespace misp-test -p '{"metadata":{"finalizers":[]}}' --type=merge

# If still stuck, direct API call
kubectl get namespace misp-test -o json | jq 'del(.spec.finalizers[])' | kubectl replace --raw "/api/v1/namespaces/misp-test/finalize" -f -
```

## Common Causes and Solutions

### 1. **PVC Protection Finalizers**
MariaDB and Redis create PVCs with protection finalizers:
```bash
# Check PVC finalizers
kubectl get pvc -n misp-test -o yaml | grep finalizers -A2

# Remove them
kubectl patch pvc -n misp-test --all -p '{"metadata":{"finalizers":[]}}' --type=merge
```

### 2. **StatefulSet Controller Issues**
```bash
# Delete StatefulSets controlling pods
kubectl delete statefulset --all -n misp-test --cascade=orphan --grace-period=0
```

### 3. **Admission Controllers**
Some clusters have admission controllers that prevent deletion:
```bash
# Try deleting with different strategies
kubectl delete namespace misp-test --grace-period=0 --force --timeout=10s
```

## Run the Automated Script
```bash
# Use the automated force cleanup script
cd /claude/misp-deployment-test
chmod +x force-cleanup.sh
./force-cleanup.sh misp-test
```

## Last Resort - Manual API Editing

If nothing works, you might need to manually edit the namespace:

```bash
# Get namespace in JSON format
kubectl get namespace misp-test -o json > ns.json

# Edit ns.json and remove all finalizers:
# "finalizers": []  # Make this an empty array

# Replace with edited version
kubectl replace --raw "/api/v1/namespaces/misp-test" -f ns.json
```

## Prevention for Next Time

Add this to your cleanup script to avoid the issue:

```bash
# Proper cleanup order
helm uninstall misp-test -n misp-test --wait --timeout=300s
kubectl delete pvc --all -n misp-test --wait=false
kubectl delete namespace misp-test --wait=false --timeout=60s
```

## Check if Issue is Resolved
```bash
# This should return "not found" when successful
kubectl get namespace misp-test
```