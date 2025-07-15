# Kubernetes Configuration Directory

This directory contains Kubernetes manifests and configuration files for the homelab infrastructure.

## Directory Structure

```
k8s/
├── manifests/           # Kubernetes manifest files
│   ├── apps/          # Application deployments
│   ├── ingress/       # Ingress configurations
│   ├── secrets/       # Encrypted secrets (using SOPS)
│   └── configmaps/    # Configuration maps
├── helm/              # Helm charts and values
└── scripts/           # Helper scripts for k8s operations
```

## Purpose

This directory holds all Kubernetes-related configuration for the homelab, including:
- Application deployments
- Ingress configurations
- Secrets management
- Helm charts
- Configuration maps

## Security Note

Sensitive information (secrets) should be encrypted using SOPS. See the repository's root Makefile for encryption/decryption instructions.

## Usage

1. Apply manifests using:
   ```bash
   kubectl apply -f manifests/
   ```
2. Deploy Helm charts:
   ```bash
   helm install -f helm/values.yaml ./helm/chart-name
   ```

## Adding New Services

To add a new service:
1. Create a new manifest file in `manifests/apps/`
2. Add any required secrets in `manifests/secrets/` (using SOPS encryption)
3. Create configuration maps in `manifests/configmaps/` if needed
4. Update the ingress configuration in `manifests/ingress/` if applicable

## License

See the [LICENSE](../LICENSE) file for details.