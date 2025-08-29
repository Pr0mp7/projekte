#!/bin/bash

# MISP Test Deployment Script for RKE2
# This script helps deploy MISP in your RKE2 test environment

set -euo pipefail

# Configuration
NAMESPACE="${NAMESPACE:-misp-test}"
RELEASE_NAME="${RELEASE_NAME:-misp-test}"
VALUES_FILE="${VALUES_FILE:-values.yaml}"
CHART_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is required but not installed"
        exit 1
    fi
    
    # Check if helm is available
    if ! command -v helm &> /dev/null; then
        log_error "helm is required but not installed"
        exit 1
    fi
    
    # Check if we can connect to cluster
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Update helm dependencies
update_dependencies() {
    log_info "Updating Helm dependencies..."
    cd "$CHART_DIR"
    
    if helm dependency update; then
        log_success "Dependencies updated"
    else
        log_error "Failed to update dependencies"
        exit 1
    fi
}

# Deploy MISP
deploy_misp() {
    log_info "Deploying MISP..."
    
    cd "$CHART_DIR"
    
    # Create namespace if it doesn't exist
    if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log_info "Creating namespace: $NAMESPACE"
        kubectl create namespace "$NAMESPACE"
    fi
    
    # Install or upgrade
    if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
        log_info "Upgrading existing release: $RELEASE_NAME"
        helm upgrade "$RELEASE_NAME" . \
            --namespace "$NAMESPACE" \
            --values "$VALUES_FILE" \
            --wait \
            --timeout 10m
    else
        log_info "Installing new release: $RELEASE_NAME"
        helm install "$RELEASE_NAME" . \
            --namespace "$NAMESPACE" \
            --values "$VALUES_FILE" \
            --wait \
            --timeout 10m
    fi
    
    log_success "MISP deployment completed"
}

# Check deployment status
check_status() {
    log_info "Checking deployment status..."
    
    # Check pods
    echo -e "\n${BLUE}Pods:${NC}"
    kubectl get pods -n "$NAMESPACE"
    
    # Check services
    echo -e "\n${BLUE}Services:${NC}"
    kubectl get services -n "$NAMESPACE"
    
    # Check ingress
    echo -e "\n${BLUE}Ingress:${NC}"
    kubectl get ingress -n "$NAMESPACE" 2>/dev/null || echo "No ingress found"
    
    # Check PVC
    echo -e "\n${BLUE}Persistent Volume Claims:${NC}"
    kubectl get pvc -n "$NAMESPACE"
    
    # Wait for deployment to be ready
    log_info "Waiting for MISP deployment to be ready..."
    if kubectl wait --for=condition=available deployment/"$RELEASE_NAME" -n "$NAMESPACE" --timeout=300s; then
        log_success "MISP is ready!"
    else
        log_warning "MISP deployment may not be fully ready yet"
    fi
}

# Show access information
show_access_info() {
    log_info "Getting access information..."
    
    # Get service details
    SERVICE_TYPE=$(kubectl get service "$RELEASE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.type}')
    
    echo -e "\n${GREEN}=== MISP Access Information ===${NC}"
    
    if kubectl get ingress "$RELEASE_NAME" -n "$NAMESPACE" &> /dev/null; then
        INGRESS_HOST=$(kubectl get ingress "$RELEASE_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.rules[0].host}')
        echo -e "External URL: ${BLUE}http://$INGRESS_HOST${NC}"
        echo -e "Note: Make sure '$INGRESS_HOST' resolves to your ingress controller IP"
    fi
    
    echo -e "\nPort Forward Access:"
    echo -e "Run: ${YELLOW}kubectl port-forward -n $NAMESPACE service/$RELEASE_NAME 8080:80${NC}"
    echo -e "Then visit: ${BLUE}http://localhost:8080${NC}"
    
    echo -e "\n${GREEN}=== Default Credentials ===${NC}"
    echo -e "Username: ${BLUE}admin@misp.local${NC}"
    echo -e "Password: ${BLUE}admin123${NC}"
    
    echo -e "\n${GREEN}=== Useful Commands ===${NC}"
    echo -e "View logs: ${YELLOW}kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=misp-test -f${NC}"
    echo -e "Shell access: ${YELLOW}kubectl exec -it -n $NAMESPACE deployment/$RELEASE_NAME -- /bin/bash${NC}"
    echo -e "Delete deployment: ${YELLOW}helm uninstall $RELEASE_NAME -n $NAMESPACE${NC}"
}

# Show logs
show_logs() {
    log_info "Showing MISP logs..."
    kubectl logs -n "$NAMESPACE" -l "app.kubernetes.io/name=misp-test" --tail=50 -f
}

# Cleanup function
cleanup() {
    log_warning "Cleaning up MISP deployment..."
    
    if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
        log_info "Uninstalling Helm release with timeout..."
        helm uninstall "$RELEASE_NAME" -n "$NAMESPACE" --wait --timeout=300s || {
            log_warning "Helm uninstall timed out, forcing cleanup..."
            helm uninstall "$RELEASE_NAME" -n "$NAMESPACE" --no-hooks || true
        }
        log_success "Helm release uninstalled"
    fi
    
    # Force cleanup PVCs first (prevents stuck namespace)
    log_info "Cleaning up Persistent Volume Claims..."
    kubectl delete pvc --all -n "$NAMESPACE" --grace-period=0 --force 2>/dev/null || true
    kubectl patch pvc -n "$NAMESPACE" --all -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
    
    # Optionally delete namespace
    read -p "Delete namespace '$NAMESPACE'? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deleting namespace with timeout..."
        kubectl delete namespace "$NAMESPACE" --timeout=60s --ignore-not-found=true || {
            log_warning "Namespace deletion timed out, trying force cleanup..."
            kubectl patch namespace "$NAMESPACE" -p '{"spec":{"finalizers":[]}}' --type=merge 2>/dev/null || true
            kubectl patch namespace "$NAMESPACE" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
        }
        log_success "Namespace cleaned up"
    fi
}

# Main function
main() {
    case "${1:-deploy}" in
        "deploy")
            check_prerequisites
            update_dependencies
            deploy_misp
            check_status
            show_access_info
            ;;
        "status")
            check_status
            show_access_info
            ;;
        "logs")
            show_logs
            ;;
        "cleanup")
            cleanup
            ;;
        "help")
            echo "Usage: $0 [command]"
            echo "Commands:"
            echo "  deploy   - Deploy MISP (default)"
            echo "  status   - Check deployment status"
            echo "  logs     - Show MISP logs"
            echo "  cleanup  - Remove MISP deployment"
            echo "  help     - Show this help message"
            echo
            echo "Environment variables:"
            echo "  NAMESPACE    - Kubernetes namespace (default: misp-test)"
            echo "  RELEASE_NAME - Helm release name (default: misp-test)"
            echo "  VALUES_FILE  - Values file to use (default: values.yaml)"
            ;;
        *)
            log_error "Unknown command: $1"
            echo "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"