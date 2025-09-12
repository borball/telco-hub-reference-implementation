# Telco Hub Reference Implementation


This repository provides a reference implementation with GitOps/ZTP method for [Telco hub reference](https://github.com/openshift-kni/telco-reference/tree/main/telco-hub).

## Overview

The Telco Hub Reference Implementation contains Kubernetes manifests and policies for deploying essential components required for a Telco Hub cluster, including:

- **Red Hat Advanced Cluster Management (RHACM)** - Multi-cluster management
- **OpenShift GitOps** - GitOps-based application delivery
- **OpenShift Data Foundation (ODF)** - Software-defined storage
- **Local Storage Operator** - Local storage management
- **Topology Aware Lifecycle Manager (TALM)** - Lifecycle management for edge clusters
- **Cluster Logging** - Centralized logging solution
- **AMQ Streams (Apache Kafka)** - Event streaming platform for real-time data processing
- **AMQ Streams Console** - Web-based management console for Kafka clusters

## Repository Structure

```
telco-hub-reference-implementation/
└── policies/
    ├── kustomization.yaml          # Main kustomization file
    ├── resources/                  # Common resources
    │   ├── namespaces.yaml        # Namespace definitions
    │   └── msc-binding.yaml       # ManagedServiceCluster binding
    ├── 4.18/                      # OpenShift 4.18 configurations
    │   ├── hub-418-v1/           # Version 1 configuration
    │   └── hub-418-v2/           # Version 2 configuration
    └── 4.20/                      # OpenShift 4.20 configurations (future)
```

### Hub Configuration Structure

Each hub configuration (e.g., `hub-418-v1`, `hub-418-v2`) contains:

- **kustomization.yaml** - Kustomize configuration
- **subscriptions.yaml** - PolicyGenerator for operator subscriptions
- **configurations.yaml** - PolicyGenerator for operator configurations
- **argocd.yaml** - PolicyGenerator for ArgoCD setup
- **kafka.yaml** - PolicyGenerator for Kafka/AMQ Streams setup
- **validator.yaml** - PolicyGenerator for validation policies
- **operator-versions.yaml** - ConfigMap with specific operator versions
- **source-crs/** - Directory containing source Custom Resources for each component

## Prerequisites

Before using this repository, ensure you have following setup on the management hub:

1. **OpenShift Cluster** - A running OpenShift 4.18+ cluster
2. **RHACM Hub** - Red Hat Advanced Cluster Management installed and configured
3. **GitOps Operator** - OpenShift GitOps operator installed
4. **Topology Aware Lifecycle Manager (TALM)** - Lifecycle management for edge clusters


## Usage

Create an ArgoCD application and point it to this repo or you own clone/fork somewhere, the policies in this repo then later can be applied with Red Hat Advanced Cluster Management on the clusters installed with ZTP methods. 

Policies are configured to target clusters with the following labels:

- `hub: "true"`
- `configuration-version: <ref-config-version>`

## Configuration Details

### Operator Versions

Each hub configuration includes a `operator-versions.yaml` ConfigMap that specifies the exact versions of operators to be deployed, an example in hub-418-v1

- **Local Storage Operator**: v4.18.0-202508201347
- **ODF Operator**: v4.18.9-rhodf
- **Advanced Cluster Management**: v2.13.3
- **OpenShift GitOps Operator**: v1.16.3
- **Topology Aware Lifecycle Manager**: v4.18.1
- **Cluster Logging**: v6.2.4
- **AMQ Streams**: v2.9.2-0
- **AMQ Streams Console**: v2.9.2-1

Example versions in hub-418-v2:

- **Local Storage Operator**: v4.18.0-202507211933
- **ODF Operator**: v4.18.9-rhodf
- **Advanced Cluster Management**: v2.14.0
- **OpenShift GitOps Operator**: v1.17.1
- **Topology Aware Lifecycle Manager**: v4.18.1
- **Cluster Logging**: v6.2.4
- **AMQ Streams**: v2.9.1-2
- **AMQ Streams Console**: v2.9.1-7

### Policy Placement

Policies are configured to target clusters with the following cluster labels:
- `hub: "true"`
- `configuration-version: hub-418-v1` (or `hub-418-v2`)

Make sure you have those settings in the ClusterInstance CR when you install the managed hubs. 

### Deployment Waves

Components are deployed in waves using the `ran.openshift.io/ztp-deploy-wave` annotation:
- **Wave 10**: Operator subscriptions (Local Storage, ODF, RHACM, GitOps, TALM, Cluster Logging, AMQ Streams, AMQ Streams Console)
- **Wave 20**: Operator configurations (Storage configurations)
- **Wave 30**: Operator configurations (RHACM and MultiClusterHub)
- **Wave 50**: ArgoCD applications and configurations
- **Wave 60**: Kafka cluster configuration
- **Wave 65**: AMQ Streams Console configuration
- **Wave 1000**: Validator to check if major configurations are in place and working properly

## Customization

### Modifying Operator Versions

To update operator versions:

1. Edit the `operator-versions.yaml` file in your chosen configuration
2. Update the version strings as needed
3. Apply the changes using kustomize

### Adding New Components

To add new operators or components:

1. Create new source CRs in the `source-crs/` directory
2. Update the appropriate PolicyGenerator file
3. Add the new resources to the kustomization

