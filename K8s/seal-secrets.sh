#!/bin/bash

# Script to seal all secrets in base directories using kubeseal
# Prerequisites:
#   1. Kubernetes cluster running
#   2. Sealed Secrets controller installed (https://github.com/bitnami-labs/sealed-secrets)
#   3. kubeseal CLI installed: brew install kubeseal

set -e

KUSTOMIZE_BASE_DIR="base"
CONTROLLER_NAME="sealed-secrets"
CONTROLLER_NAMESPACE="kube-system"

echo "Starting to seal all secrets..."
echo "Controller: $CONTROLLER_NAME in namespace: $CONTROLLER_NAMESPACE"
echo ""

sealed_count=0

for secret_file in $(find "$KUSTOMIZE_BASE_DIR" -name 'secret.yaml' -type f | sort); do
  dir=$(dirname "$secret_file")
  sealed_file="$dir/sealed-secret.yaml"
  
  echo "📦 Processing: $secret_file"
  
  if kubeseal \
    --format yaml \
    --controller-name "$CONTROLLER_NAME" \
    --controller-namespace "$CONTROLLER_NAMESPACE" \
    < "$secret_file" \
    > "$sealed_file"; then
    echo "   ✓ Sealed → $sealed_file"
    sealed_count=$((sealed_count + 1))
  else
    echo "   ✗ Failed to seal $secret_file"
    exit 1
  fi
done

echo "Successfully sealed $sealed_count secrets!"

