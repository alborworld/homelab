# Docker Nodes Configuration Directory

This directory contains Docker configuration for different nodes in the homelab infrastructure. Each subdirectory represents a different Docker node with its own Docker Compose configuration.

## Directory Structure

```
docker/
├── diskstation/          # Synology DiskStation configuration
├── dockerhost/          # Main Docker host configuration
├── raspberrypi5/        # Raspberry Pi 5 configuration
└── ...                 # Additional Docker nodes
```

Each node directory contains:
- `docker-compose.yml` - Main Docker Compose configuration
- `.env` - Environment variables (encrypted with SOPS)
- `.env.sops.enc` - Encrypted environment variables
- Additional configuration files specific to the node

## Purpose

Each subdirectory represents a different Docker node in the homelab infrastructure:
- `diskstation/` - Configuration for Synology DiskStation services
- `dockerhost/` - Configuration for the main Docker host
- `raspberrypi5/` - Configuration for Raspberry Pi 5 services
- Additional nodes can be added as needed

## Security Note

Environment variables are encrypted using SOPS. Use the root Makefile to manage encryption/decryption of `.env` files.

## Adding New Nodes

To add a new Docker node:
1. Create a new subdirectory under `docker/`
2. Add your `docker-compose.yml` configuration
3. Create a `.env` file with environment variables
4. Encrypt the `.env` file using the root Makefile

## License

See the [LICENSE](../LICENSE) file for details.