# Sealed Secrets Setup Guide

## Overview
Sealed Secrets encrypts Kubernetes secrets so they can be safely committed to git. Only the cluster with the private key can decrypt them.

## Prerequisites

### 1. Install Sealed Secrets Controller on your cluster
```bash
# Using Helm (recommended)
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm install sealed-secrets -n kube-system sealed-secrets/sealed-secrets

# Or using kubectl directly
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml
```

### 2. Install kubeseal CLI locally
```bash
# macOS
brew install kubeseal

# Linux
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz
tar xfz kubeseal-0.24.0-linux-amd64.tar.gz
sudo mv kubeseal /usr/local/bin/
```

### 3. Verify installation
```bash
kubeseal --version
kubectl get pods -n kube-system | grep sealed-secrets
```

## Usage

### Seal all secrets at once
```bash
cd /path/to/K8s
chmod +x seal-secrets.sh
./seal-secrets.sh
```

### Seal a single secret
```bash
kubeseal --format yaml < base/payment/secret.yaml > base/payment/sealed-secret.yaml
```

### Seal with custom controller
```bash
kubeseal \
  --format yaml \
  --controller-name my-controller \
  --controller-namespace my-namespace \
  < secret.yaml \
  > sealed-secret.yaml
```

## Update Kustomization Files

After sealing, update each `kustomization.yaml` to use `sealed-secret.yaml`:

**Before:**
```yaml
resources:
  - deployment.yaml
  - secret.yaml
```

**After:**
```yaml
resources:
  - deployment.yaml
  - sealed-secret.yaml
```

## Backup the Sealing Key

Critical: Keep the sealing key safe!
```bash
# Extract and backup the sealing key
kubectl get secret -n kube-system sealed-secrets-key -o yaml > sealing-key-backup.yaml
```

## Git Strategy

```bash
# Safe to commit
git add base/**/sealed-secret.yaml

# Remove original secrets from git
git rm --cached base/**/secret.yaml
echo "base/**/secret.yaml" >> .gitignore
```

## Troubleshooting

**Error: "services 'sealed-secrets-controller' not found"**
- Sealed Secrets controller isn't running
- Install it using the steps above

**Keys don't match after cluster migration**
- Sealed Secrets are tied to the cluster's key
- Restore the backed-up key or re-seal secrets on the new cluster

**Cannot decrypt in another cluster**
- This is expected - Sealed Secrets only work within the cluster they were created in
- Re-seal for production cluster
