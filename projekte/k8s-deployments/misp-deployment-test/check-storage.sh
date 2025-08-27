#!/bin/bash

# Storage class diagnosis script
echo "=== Available Storage Classes ==="
kubectl get storageclass

echo -e "\n=== Default Storage Class ==="
kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}'
echo

echo -e "\n=== Current PVC Status ==="
kubectl get pvc -n misp-test -o wide 2>/dev/null || echo "No misp-test namespace found"

echo -e "\n=== PVC Details ==="
kubectl describe pvc -n misp-test 2>/dev/null || echo "No PVCs found"

echo -e "\n=== Events Related to PVCs ==="
kubectl get events -n misp-test --field-selector reason=FailedBinding 2>/dev/null || echo "No binding failure events"