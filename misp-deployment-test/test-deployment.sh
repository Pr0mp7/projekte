#!/bin/bash

# MISP Deployment Testing Script
# This script tests the deployment after fixing storage class consistency issues

set -e

echo "=== MISP Deployment Test Script ==="
echo "Testing deployment with consistent Longhorn storage..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}[ERROR]${NC} kubectl is not available. Please ensure you have cluster access."
        exit 1
    fi
}

# Function to check cluster connectivity
check_cluster() {
    echo -e "${BLUE}[INFO]${NC} Checking cluster connectivity..."
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}[ERROR]${NC} Cannot connect to Kubernetes cluster."
        echo "Please ensure your cluster is running and kubeconfig is properly configured."
        exit 1
    fi
    echo -e "${GREEN}[SUCCESS]${NC} Connected to cluster."
}

# Function to check storage classes
check_storage_classes() {
    echo -e "${BLUE}[INFO]${NC} Checking available storage classes..."
    kubectl get storageclass
    
    echo -e "\n${BLUE}[INFO]${NC} Checking if Longhorn storage class exists..."
    if kubectl get storageclass longhorn &> /dev/null; then
        echo -e "${GREEN}[SUCCESS]${NC} Longhorn storage class is available."
    else
        echo -e "${YELLOW}[WARNING]${NC} Longhorn storage class not found. Available storage classes:"
        kubectl get storageclass -o name
        echo -e "${YELLOW}[WARNING]${NC} You may need to adjust storage class in values.yaml"
    fi
}

# Function to clean up previous deployment
cleanup_deployment() {
    echo -e "${BLUE}[INFO]${NC} Cleaning up any existing deployment..."
    
    # Delete namespace if it exists
    if kubectl get namespace misp-test &> /dev/null; then
        echo -e "${YELLOW}[INFO]${NC} Deleting existing misp-test namespace..."
        kubectl delete namespace misp-test --timeout=60s || true
        
        # Wait for namespace to be fully deleted
        echo -e "${BLUE}[INFO]${NC} Waiting for namespace deletion..."
        kubectl wait --for=delete namespace/misp-test --timeout=120s || {
            echo -e "${RED}[ERROR]${NC} Namespace deletion timed out. You may need to force cleanup."
            echo "Run: ./force-cleanup.sh"
            exit 1
        }
    fi
    
    echo -e "${GREEN}[SUCCESS]${NC} Cleanup completed."
}

# Function to deploy MISP
deploy_misp() {
    echo -e "${BLUE}[INFO]${NC} Deploying MISP with consistent Longhorn storage..."
    
    # Create namespace
    kubectl create namespace misp-test
    
    # Deploy using Helm
    helm upgrade --install misp-test . \
        --namespace misp-test \
        --values values.yaml \
        --timeout 10m \
        --wait
    
    echo -e "${GREEN}[SUCCESS]${NC} MISP deployment initiated."
}

# Function to monitor PVC status
monitor_pvcs() {
    echo -e "${BLUE}[INFO]${NC} Monitoring PVC creation and binding..."
    
    # Wait for PVCs to be created
    echo -e "${BLUE}[INFO]${NC} Waiting for PVCs to be created..."
    sleep 10
    
    # Check PVC status
    echo -e "\n${BLUE}[INFO]${NC} Current PVC status:"
    kubectl get pvc -n misp-test -o wide
    
    # Check for unbound PVCs
    UNBOUND_PVCS=$(kubectl get pvc -n misp-test --no-headers | grep -c "Pending" || true)
    
    if [ "$UNBOUND_PVCS" -gt 0 ]; then
        echo -e "${YELLOW}[WARNING]${NC} Found $UNBOUND_PVCS unbound PVCs. Checking details..."
        kubectl describe pvc -n misp-test | grep -E "(Name:|Status:|Events:)" -A 10
    else
        echo -e "${GREEN}[SUCCESS]${NC} All PVCs are bound!"
    fi
}

# Function to check pod status
check_pods() {
    echo -e "${BLUE}[INFO]${NC} Checking pod status..."
    
    # Wait for pods to start
    echo -e "${BLUE}[INFO]${NC} Waiting for pods to initialize..."
    sleep 30
    
    # Show current pod status
    kubectl get pods -n misp-test -o wide
    
    # Check for pods with issues
    PENDING_PODS=$(kubectl get pods -n misp-test --no-headers | grep -c "Pending\|ContainerCreating\|Error\|CrashLoopBackOff" || true)
    
    if [ "$PENDING_PODS" -gt 0 ]; then
        echo -e "${YELLOW}[WARNING]${NC} Found pods with issues. Checking details..."
        kubectl describe pods -n misp-test | grep -E "(Name:|Status:|Events:)" -A 5
    else
        echo -e "${GREEN}[SUCCESS]${NC} All pods are running!"
    fi
}

# Function to show deployment summary
show_summary() {
    echo -e "\n${BLUE}=== DEPLOYMENT SUMMARY ===${NC}"
    
    echo -e "\n${BLUE}Storage Classes:${NC}"
    kubectl get storageclass
    
    echo -e "\n${BLUE}PVCs Status:${NC}"
    kubectl get pvc -n misp-test -o wide
    
    echo -e "\n${BLUE}Pods Status:${NC}"
    kubectl get pods -n misp-test -o wide
    
    echo -e "\n${BLUE}Services:${NC}"
    kubectl get svc -n misp-test
    
    echo -e "\n${BLUE}Ingress:${NC}"
    kubectl get ingress -n misp-test
    
    echo -e "\n${GREEN}[INFO]${NC} If all PVCs are bound and pods are running, your deployment is successful!"
    echo -e "${GREEN}[INFO]${NC} You can access MISP through the ingress or port-forward:"
    echo -e "${GREEN}[INFO]${NC} kubectl port-forward -n misp-test svc/misp-test 8080:80"
}

# Main execution
main() {
    check_kubectl
    check_cluster
    check_storage_classes
    cleanup_deployment
    deploy_misp
    monitor_pvcs
    check_pods
    show_summary
}

# Run the script
main "$@"