# Kubernetes Configuration (Planned)

> **⚠️ Work in Progress**: This directory is being prepared for a future Kubernetes migration. The homelab currently runs on Docker.  
> For current setup instructions, see the [main documentation](../docs/).

## 🚧 Planned Architecture

### Goals
- **Proxmox-based Kubernetes** on Intel NUC 13
- **Cluster Architecture**:
  - **Management Cluster**: k3s-based CAPI (Cluster API) management cluster deployed with Terraform
  - **Workload Clusters**: Managed via Cluster API for declarative cluster lifecycle
- **GitOps workflow** with ArgoCD/Flux
- **Secrets Management**: SOPS integration
- **Monitoring**: Prometheus, Grafana, Loki stack
- **Storage**: CSI drivers for Synology/Longhorn
- **Automated Backups**: Velero for cluster and volume backups
- **Multi-tenancy**: Logical separation of workloads

### Proposed Structure
```
k8s/
├── clusters/           # Cluster API definitions
├── infrastructure/     # Base cluster components
│   ├── cert-manager/   # TLS certificates
│   ├── ingress-nginx/  # Ingress controller
│   └── monitoring/     # Monitoring stack
└── apps/              # Application deployments
    ├── base/          # Common configurations
    └── overlays/      # Environment-specific configs
```

## 📅 Next Steps
1. Set up initial cluster using [Cluster API](https://cluster-api.sigs.k8s.io/) for declarative cluster management
2. Implement GitOps workflow with ArgoCD/Flux
3. Set up monitoring and observability stack
4. Migrate services incrementally from Docker

## 🔗 Related Documentation
- [Architecture Overview](../docs/ARCHITECTURE.md)
- [Security Practices](../docs/SECURITY.md)
- [Setup Guide](../docs/SETUP.md)

