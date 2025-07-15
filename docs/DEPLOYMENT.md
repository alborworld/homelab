# Deployment Guide

This document outlines the procedures for deploying and updating services in the homelab environment.

## Prerequisites

- Access to all nodes via SSH
- Docker and Docker Compose installed on all hosts
- SOPS configured (see [SECURITY.md](SECURITY.md))

## Deployment Workflow

### 1. Development Workflow

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/my-new-service
   ```

2. **Make your changes**:
   - Add new service configurations
   - Update existing services
   - Modify infrastructure as needed

3. **Test locally**:
   ```bash
   # For Docker Compose services
   docker-compose up -d
   
   # For Kubernetes
   kubectl apply -f k8s/manifests/
   ```

### 2. Staging Deployment

1. **Merge to staging branch**:
   ```bash
   git checkout staging
   git merge feature/my-new-service
   git push origin staging
   ```

2. **Deploy to staging environment**:
   ```bash
   # On the target host
   git fetch origin
   git checkout staging
   git pull origin staging
   
   # Deploy Docker services
   make deploy-staging
   
   # Or for Kubernetes
   kubectl apply -f k8s/manifests/staging/
   ```

### 3. Production Deployment

1. **Create a release**:
   ```bash
   git checkout main
   git pull origin main
   git merge staging
   git tag -a v1.0.0 -m "Release v1.0.0"
   git push origin v1.0.0
   ```

2. **Deploy to production**:
   ```bash
   # On the production host
   git fetch --tags
   git checkout v1.0.0
   
   # Deploy Docker services
   make deploy-prod
   
   # Or for Kubernetes
   kubectl apply -f k8s/manifests/production/
   ```

## Rollback Procedure

### For Docker Compose

```bash
# List previous container versions
docker ps -a

# Rollback to a previous version
docker-compose up -d --force-recreate <service_name>@<version>
```

### For Kubernetes

```bash
# View rollout history
kubectl rollout history deployment/<deployment-name>

# Rollback to previous version
kubectl rollout undo deployment/<deployment-name>

# Or to a specific revision
kubectl rollout undo deployment/<deployment-name> --to-revision=2
```

## Monitoring and Logs

### View Logs

```bash
# Docker Compose
docker-compose logs -f <service_name>

# Kubernetes
kubectl logs -f deployment/<deployment-name>
```

### Monitor Resources

```bash
# Docker
watch docker ps

# Kubernetes
kubectl get pods -w
kubectl top pod
```

## Maintenance Windows

- **Scheduled Downtime**: 2:00 AM - 4:00 AM daily
- **Emergency Maintenance**: As needed with prior notification

## Backup and Recovery

### Database Backups

```bash
# Create backup
make backup-db

# Restore from backup
make restore-db BACKUP_FILE=backup_20230716.sql
```

### Volume Backups

```bash
# Create volume backup
docker run --rm -v <volume_name>:/source -v $(pwd):/backup alpine tar czf /backup/backup.tar.gz -C /source .

# Restore volume
cat backup.tar.gz | docker run -i --rm -v <volume_name>:/target alpine tar xzf - -C /target
```

## Troubleshooting

### Common Issues

1. **Port Conflicts**:
   ```bash
   # Find process using a port
   lsof -i :80
   ```

2. **Docker Issues**:
   ```bash
   # Clean up unused resources
   docker system prune
   
   # Reset Docker
   docker system prune -a --volumes
   ```

3. **Kubernetes Issues**:
   ```bash
   # Get detailed pod information
   kubectl describe pod <pod-name>
   
   # Check cluster events
   kubectl get events --sort-by='.metadata.creationTimestamp'
   ```
