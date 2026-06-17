# Production StatefulSet Architecture for PostgreSQL, Kafka, and Valkey

## Overview
This document describes the production-ready StatefulSet setup with headless services for stable pod identities and service discovery.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              PostgreSQL StatefulSet                      │   │
│  ├──────────────────────────────────────────────────────────┤   │
│  │                                                            │   │
│  │  Services:                                               │   │
│  │  ├── postgresql (ClusterIP)     [For Applications]      │   │
│  │  │   └── Resolves to StatefulSet pods                   │   │
│  │  │                                                        │   │
│  │  └── postgresql-headless (None) [For Stable DNS]        │   │
│  │      └── postgresql-0.postgresql-headless.default       │   │
│  │      └── Persistent Volume                              │   │
│  │                                                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                 Kafka StatefulSet                        │   │
│  ├──────────────────────────────────────────────────────────┤   │
│  │                                                            │   │
│  │  Services:                                               │   │
│  │  ├── kafka (ClusterIP)          [For Applications]       │   │
│  │  │   └── Resolves to StatefulSet pods                   │   │
│  │  │   └── Ports: 9092, 9093                              │   │
│  │  │                                                        │   │
│  │  └── kafka-headless (None)      [For Stable DNS]        │   │
│  │      └── kafka-0.kafka-headless.default                 │   │
│  │      └── Persistent Volume                              │   │
│  │                                                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                 Valkey StatefulSet                       │   │
│  ├──────────────────────────────────────────────────────────┤   │
│  │                                                            │   │
│  │  Services:                                               │   │
│  │  ├── valkey (ClusterIP)          [For Applications]      │   │
│  │  │   └── Resolves to StatefulSet pods                   │   │
│  │  │                                                        │   │
│  │  └── valkey-headless (None)      [For Stable DNS]       │   │
│  │      └── valkey-0.valkey-headless.default               │   │
│  │      └── Persistent Volume                              │   │
│  │                                                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │           Application Pods (Microservices)              │   │
│  ├──────────────────────────────────────────────────────────┤   │
│  │                                                            │   │
│  │  All apps connect using:                                │   │
│  │  - postgresql:5432                                       │   │
│  │  - kafka:9092                                            │   │
│  │  - valkey:6379                                           │   │
│  │                                                            │   │
│  │  (No config changes needed!)                            │   │
│  │                                                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## What Changed

### PostgreSQL
- **StatefulSet**: `statefulset.yaml` (already existed)
- **New Services**:
  - `service.yaml` (ClusterIP) → Applications connect to `postgresql:5432`
  - `postgres-headless-service.yaml` (Headless) → StatefulSet stable DNS
- **Persistent Volume**: Configured via volumeClaimTemplates
- **Kustomization**: Updated to include `postgres-headless-service.yaml`

### Kafka
- **StatefulSet**: `statefulset.yaml` (already existed)
- **New Services**:
  - `kafka-service.yaml` (ClusterIP) → Applications connect to `kafka:9092`
  - `kafka-headless-service.yaml` (Headless) → StatefulSet stable DNS
- **Persistent Volume**: Configured via volumeClaimTemplates
- **Kustomization**: Updated to reference new service files
- **Note**: Old `service.yaml` (headless) is now replaced by the two new services

### Valkey
- **Converted**: `deployment.yaml` → `statefulset.yaml`
- **New Services**:
  - `valkey-service.yaml` (ClusterIP) → Applications connect to `valkey:6379`
  - `valkey-headless-service.yaml` (Headless) → StatefulSet stable DNS
- **Persistent Volume**: Converted to volumeClaimTemplates in StatefulSet
- **Kustomization**: Updated to reference StatefulSet and new services

## Key Benefits

✅ **StatefulSets** - Stable pod identities with ordinal naming (pod-0, pod-1, etc.)

✅ **Persistent Volumes** - Data persists across pod restarts

✅ **Stable DNS** - Headless services provide predictable DNS names:
   - `postgresql-0.postgresql-headless.default.svc.cluster.local`
   - `kafka-0.kafka-headless.default.svc.cluster.local`
   - `valkey-0.valkey-headless.default.svc.cluster.local`

✅ **Service Discovery** - Regular ClusterIP services for application connectivity

✅ **Backward Compatible** - Applications continue using simple DNS names:
   - `postgresql`, `kafka`, `valkey` (no config changes needed!)

✅ **Production-Ready** - Follows Kubernetes best practices for stateful workloads

## Files Created/Updated

### PostgreSQL
- ✅ Created: `postgres-headless-service.yaml`
- 📝 Updated: `kustomization.yaml`

### Kafka
- ✅ Created: `kafka-service.yaml`
- ✅ Created: `kafka-headless-service.yaml`
- 📝 Updated: `kustomization.yaml`
- ℹ️ Old: `service.yaml` (can be removed - replaced by new services)

### Valkey
- ✅ Created: `statefulset.yaml` (converted from deployment)
- ✅ Created: `valkey-service.yaml`
- ✅ Created: `valkey-headless-service.yaml`
- 📝 Updated: `kustomization.yaml`
- ℹ️ Old: `deployment.yaml` (can be removed - replaced by StatefulSet)

## Deployment Instructions

No changes needed to your deployment process! Simply:

```bash
kubectl apply -k base/postgres/
kubectl apply -k base/kafka/
kubectl apply -k base/valkey/
```

Or deploy everything:
```bash
kubectl apply -k base/
```

## Cleanup (Optional)

If you want to remove the old files that have been replaced:

```bash
# Remove old Kafka service (replaced by kafka-service.yaml and kafka-headless-service.yaml)
rm base/kafka/service.yaml

# Remove old Valkey deployment (replaced by statefulset.yaml)
rm base/valkey/deployment.yaml
```

## Verification

Check the services:
```bash
kubectl get svc -n default | grep -E "postgresql|kafka|valkey"
```

Expected output:
```
kafka                  ClusterIP      ...  9092/TCP,9093/TCP
kafka-headless         ClusterIP      None ...  9092/TCP,9093/TCP
postgresql             ClusterIP      ...  5432/TCP
postgresql-headless    ClusterIP      None ...  5432/TCP
valkey                 ClusterIP      ...  6379/TCP
valkey-headless        ClusterIP      None ...  6379/TCP
```

Check StatefulSets:
```bash
kubectl get statefulsets -n default | grep -E "postgresql|kafka|valkey"
```

Expected output:
```
kafka       1         1       ...
postgresql  1         1       ...
valkey      1         1       ...
```

Check persistent volumes:
```bash
kubectl get pvc -n default | grep -E "postgresql|kafka|valkey"
```

Check pod DNS resolution:
```bash
# Get a pod from any application
kubectl exec -it <app-pod> -- nslookup postgresql
kubectl exec -it <app-pod> -- nslookup kafka
kubectl exec -it <app-pod> -- nslookup valkey

# Test headless DNS
kubectl exec -it <app-pod> -- nslookup postgresql-headless
kubectl exec -it <app-pod> -- nslookup postgresql-0.postgresql-headless
```
