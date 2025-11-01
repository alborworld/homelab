# GitHub Actions Workflows

## Deploy Workflow

Manually deploy services to homelab hosts using self-hosted GitHub runners.

### Usage

1. Go to **Actions** tab in GitHub
2. Select **Deploy Homelab Services**
3. Click **Run workflow**
4. Choose which host(s) to deploy to:
   - **all** - Deploy to all hosts (raspberrypi5, dockerhost, diskstation)
   - **raspberrypi5** - Deploy only to raspberrypi5
   - **dockerhost** - Deploy only to dockerhost
   - **diskstation** - Deploy only to diskstation (TraefikKop only)

### What It Does

**For raspberrypi5 and dockerhost:**
1. Pulls latest changes from main branch
2. Pulls latest Docker images
3. Recreates containers with new images
4. Shows service status

**For diskstation:**
1. Pulls latest TraefikKop image
2. Restarts TraefikKop container
3. Shows container status

> **Note:** Diskstation has limited git support, so only critical services (TraefikKop) are managed via this workflow.

### Self-Hosted Runners

The workflow uses three self-hosted runners:

| Runner | Host | Labels | Location |
|--------|------|--------|----------|
| homelab-raspberrypi5-runner | raspberrypi5 | `self-hosted, raspberrypi5` | `docker/raspberrypi5/github-runner-rp/` |
| homelab-dockerhost-runner | dockerhost | `self-hosted, dockerhost` | `docker/dockerhost/github-runner-dh/` |
| homelab-diskstation-runner | diskstation | `self-hosted, diskstation` | `docker/diskstation/github-runner-ds/` |

### Troubleshooting

**Runner not found:**
- Check that the runner container is running: `docker ps | grep GitHubRunner`
- Check runner logs: `docker logs GitHubRunner-RP` (or -DH/-DS)
- Verify runner is connected in GitHub Settings → Actions → Runners

**Permission denied:**
- Diskstation requires `sudo` for docker commands
- Other hosts should run docker without sudo (user in docker group)

**Deployment failed:**
- Check workflow logs in GitHub Actions tab
- Manually verify on the host:
  ```bash
  cd ~/homelab && git status
  cd ~/docker/compose && docker compose ps
  ```

### Security Notes

- Runners have access to `/var/run/docker.sock` (Docker-in-Docker)
- Runners can execute any code in your repository
- Only trusted collaborators should have write access to this repo
- Consider using GitHub Environments for approval gates if needed