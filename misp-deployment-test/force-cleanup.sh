#!/bin/bash

# Force cleanup script for stuck MISP namespace
# This script handles common issues with terminating namespaces

set -euo pipefail

# Configuration
NAMESPACE="${1:-misp-test}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if namespace exists and is terminating
check_namespace_status() {
    if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
        log_success "Namespace $NAMESPACE does not exist - cleanup already complete"
        exit 0
    fi
    
    local status=$(kubectl get namespace "$NAMESPACE" -o jsonpath='{.status.phase}')
    if [ "$status" = "Terminating" ]; then
        log_warning "Namespace $NAMESPACE is stuck in Terminating state"
        return 0
    elif [ "$status" = "Active" ]; then
        log_info "Namespace $NAMESPACE is active - attempting normal cleanup first"
        return 1
    fi
}

# Remove Helm releases
cleanup_helm_releases() {
    log_info "Checking for Helm releases in namespace $NAMESPACE..."
    
    local releases=$(helm list -n "$NAMESPACE" -q 2>/dev/null || true)
    if [ -n "$releases" ]; then
        log_info "Found Helm releases: $releases"
        for release in $releases; do
            log_info "Uninstalling Helm release: $release"
            helm uninstall "$release" -n "$NAMESPACE" --wait --timeout=60s || true
        done
    else
        log_info "No Helm releases found in namespace"
    fi
}

# Force delete all resources in namespace
force_delete_resources() {
    log_info "Force deleting all resources in namespace $NAMESPACE..."
    
    # Get all API resources in the namespace
    local api_resources=$(kubectl api-resources --verbs=list --namespaced -o name 2>/dev/null || true)
    
    for resource in $api_resources; do
        log_info "Checking for $resource resources..."
        local items=$(kubectl get "$resource" -n "$NAMESPACE" --no-headers 2>/dev/null | awk '{print $1}' || true)
        
        if [ -n "$items" ]; then
            log_info "Force deleting $resource: $items"
            for item in $items; do
                # Try graceful delete first
                kubectl delete "$resource" "$item" -n "$NAMESPACE" --grace-period=0 --force 2>/dev/null || true
                
                # Remove finalizers if still exists
                kubectl patch "$resource" "$item" -n "$NAMESPACE" -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
            done
        fi
    done
}

# Remove PVCs specifically (common cause of stuck namespaces)
cleanup_pvcs() {
    log_info "Cleaning up Persistent Volume Claims..."
    
    local pvcs=$(kubectl get pvc -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || true)
    if [ -n "$pvcs" ]; then
        for pvc in $pvcs; do
            log_info "Force deleting PVC: $pvc"
            kubectl delete pvc "$pvc" -n "$NAMESPACE" --grace-period=0 --force || true
            kubectl patch pvc "$pvc" -n "$NAMESPACE" -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
        done
    fi
}

# Remove StatefulSets and their PVCs
cleanup_statefulsets() {
    log_info "Cleaning up StatefulSets..."
    
    local sts=$(kubectl get statefulset -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || true)
    if [ -n "$sts" ]; then
        for statefulset in $sts; do
            log_info "Force deleting StatefulSet: $statefulset"
            kubectl delete statefulset "$statefulset" -n "$NAMESPACE" --grace-period=0 --force || true
            kubectl patch statefulset "$statefulset" -n "$NAMESPACE" -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
        done
    fi
}

# Remove pods with force
cleanup_pods() {
    log_info "Force deleting pods..."
    
    local pods=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || true)
    if [ -n "$pods" ]; then
        for pod in $pods; do
            log_info "Force deleting pod: $pod"
            kubectl delete pod "$pod" -n "$NAMESPACE" --grace-period=0 --force || true
        done
    fi
}

# Remove namespace finalizers (nuclear option)
remove_namespace_finalizers() {
    log_warning "Attempting to remove namespace finalizers (this is the nuclear option)..."
    
    # Check if namespace still exists
    if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
        log_success "Namespace already deleted"
        return 0
    fi
    
    # Get current namespace definition
    log_info "Backing up current namespace definition..."
    kubectl get namespace "$NAMESPACE" -o json > "/tmp/namespace-${NAMESPACE}-backup.json" 2>/dev/null || true
    
    # Remove finalizers
    log_info "Removing namespace finalizers..."
    kubectl patch namespace "$NAMESPACE" -p '{"spec":{"finalizers":[]}}' --type=merge || true
    kubectl patch namespace "$NAMESPACE" -p '{"metadata":{"finalizers":[]}}' --type=merge || true
    
    # Wait a bit and check
    sleep 5
    if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
        log_success "Namespace successfully deleted after removing finalizers"
        return 0
    fi
    
    # Last resort: edit the namespace directly
    log_warning "Trying direct API call to force delete namespace..."
    kubectl get namespace "$NAMESPACE" -o json | \
        jq 'del(.spec.finalizers[])' | \
        kubectl replace --raw "/api/v1/namespaces/$NAMESPACE/finalize" -f - 2>/dev/null || true
}

# Main cleanup sequence
main() {
    log_info "Starting force cleanup of namespace: $NAMESPACE"
    
    # Check current status
    if check_namespace_status; then
        log_info "Namespace is terminating - starting force cleanup sequence"
    else
        log_info "Attempting normal cleanup first"
        cleanup_helm_releases
        kubectl delete namespace "$NAMESPACE" --timeout=60s || true
        sleep 10
        
        # Check if it's now terminating
        if ! check_namespace_status; then
            log_success "Normal cleanup successful"
            exit 0
        fi
    fi
    
    # Force cleanup sequence
    log_info "Starting force cleanup sequence..."
    
    # Step 1: Remove Helm releases
    cleanup_helm_releases
    sleep 2
    
    # Step 2: Force delete specific resource types that commonly cause issues
    cleanup_statefulsets
    sleep 2
    
    cleanup_pvcs
    sleep 2
    
    cleanup_pods
    sleep 2
    
    # Step 3: Force delete all remaining resources
    force_delete_resources
    sleep 5
    
    # Step 4: Check if namespace is gone
    if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
        log_success "Namespace successfully deleted"
        exit 0
    fi
    
    # Step 5: Nuclear option - remove finalizers
    remove_namespace_finalizers
    sleep 5
    
    # Final check
    if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
        log_success "Namespace finally deleted"
    else
        log_error "Namespace is still stuck. Manual intervention may be required."
        echo
        echo "Manual steps to try:"
        echo "1. kubectl get namespace $NAMESPACE -o yaml"
        echo "2. Check for remaining finalizers in the namespace spec"
        echo "3. Contact cluster administrator if this is a managed cluster"
        echo "4. Check for admission controllers or operators that might be interfering"
        exit 1
    fi
    
    log_success "Force cleanup completed successfully"
}

# Show usage
usage() {
    echo "Usage: $0 [namespace]"
    echo "Force cleanup a stuck Kubernetes namespace"
    echo
    echo "Arguments:"
    echo "  namespace  Namespace to cleanup (default: misp-test)"
    echo
    echo "Examples:"
    echo "  $0                    # Clean up misp-test namespace"
    echo "  $0 my-namespace       # Clean up my-namespace"
}

# Handle arguments
if [ "${1:-}" = "help" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

# Run main function
main "$@"