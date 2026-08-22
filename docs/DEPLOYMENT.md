# Deployment Guide

How a change in this repository reaches a running container.

Deployment is **manual and pull-based by hand**: you push to `main`, then update the
checkout on the target host and re-run `docker compose up -d` there. There is no CI/CD,
no staging environment, and no Kubernetes cluster — see
[Not automated yet](#not-automated-yet) for what is planned and where it is tracked.

## Prerequisites

- SSH access to each host (all are configured in `~/.ssh/config`)
- Docker Engine and Docker Compose **v2.21.0+** on each host (`include` support)
- SOPS with the age private key on your workstation — see [SECURITY.md](SECURITY.md)

## Host layout

Each host runs its own independent Compose project from a symlink into a checkout of
this repo. There is no shared control plane.

| Host           | Compose dir (symlink → repo path)                          | Volumes            | `git` on host |
|----------------|------------------------------------------------------------|--------------------|---------------|
| `raspberrypi5` | `~/docker/compose` → `~/homelab/docker/raspberrypi5`       | `~/docker/volumes` | yes           |
| `dockerhost`   | `~/docker/compose` → `~/homelab/docker/dockerhost`         | `~/docker/volumes` | yes           |
| `diskstation`  | `/volume1/docker/compose` → `~/homelab/docker/diskstation` | `/volume1/docker`  | **no**        |

Each host's `docker-compose.yaml` is a list of `include:` entries, one per service
subdirectory, so a service is enabled or disabled by editing that list.

Compose files reference `$COMPOSEDIR`, `$VOLUMEDIR` and `$LOCAL_DOMAIN`, exported from
the host's login profile.

## Deploying a change

### 1. Change the repo

Work on a branch, and push it with an explicit refspec — `push.default=upstream` is set
in the personal gitconfig, so a bare `git push` can be redirected to the tracked
upstream:

```bash
git checkout -b feat/my-service
# edit docker/<host>/<service>/docker-compose.yaml, add it to the host's include list
git diff
git commit -m "feat(my-service): add my-service to dockerhost"
git push origin HEAD:feat/my-service
```

Merge to `main` when ready. `main` is what the hosts track.

### 2. Update the checkout on the host

**raspberrypi5, dockerhost** — a normal pull:

```bash
ssh dockerhost 'cd ~/homelab && git pull'
```

**diskstation** — `git` is **not installed** on DSM, so the checkout cannot pull. It is
a real checkout (`.git` present, HEAD pinned to a `main` commit) that only ever moves by
hand. `scp` also fails, because DSM has the SFTP subsystem disabled and modern `scp`
speaks SFTP; pipe over `ssh` or use `scp -O` instead:

```bash
cat docker/diskstation/<service>/docker-compose.yaml | \
  ssh diskstation 'cat > /volume1/docker/compose/<service>/docker-compose.yaml'
```

This leaves the checkout inconsistent with its own git index, and nothing surfaces the
divergence. Tracked as a known defect (beads `homelab-132e55e2.1`) — run the
[drift check](#checking-for-drift) after touching `docker/diskstation/**`.

### 3. Ship secrets, if they changed

Secrets live in the repo as SOPS+age-encrypted `.env.sops.enc` per host, and are
decrypted to a git-ignored `.env` next to the host's `docker-compose.yaml`. From the
repo root on your workstation:

```bash
make show-dockerhost                 # print the decrypted .env, write nothing
make decrypt-dockerhost              # write docker/dockerhost/.env locally
make encrypt-dockerhost              # re-encrypt after editing
make clean-dockerhost                # remove the plaintext .env
```

To push the decrypted `.env` to a host:

```bash
make deploy-dockerhost               # decrypts and pipes it to ~/docker/compose/.env
```

> **Note:** `deploy-%` hardcodes `~/docker/compose/.env` as the destination, so it works
> for `raspberrypi5` and `dockerhost` but writes to the wrong path on `diskstation`,
> whose compose dir is `/volume1/docker/compose`. Ship diskstation's `.env` manually.

Equivalent targets exist for the OpenTofu stacks and Ansible — `make tofu-decrypt
STACK=proxmox/openclaw`, `make ansible-show`. See the [Makefile](../Makefile).

### 4. Apply

```bash
ssh dockerhost 'cd ~/docker/compose && docker compose up -d --remove-orphans'
```

**Exception — the Gluetun stack on dockerhost.** The media stack
(`sonarr`, `radarr`, `prowlarr`, `listenarr`, `qbittorrent`, `nzbget`, `agregarr`,
`cleanuparr`, `huntarr`, `byparr`) uses `network_mode: "service:gluetun"`, which binds
each container to Gluetun's *container ID*. Recreating Gluetun alone leaves the
dependents pointing at an ID that no longer exists: they come up but have no working
network, traefik-kop never publishes their routes to Redis, and Traefik returns 404.
Recreate the group together:

```bash
ssh dockerhost 'cd ~/docker/compose && \
  docker compose up -d --always-recreate-deps gluetun'
```

or run `scripts/update-gluetun-stack.sh`, which pulls and force-recreates the whole
group atomically. See [ARCHITECTURE.md](ARCHITECTURE.md#vpn-dependency-gluetun).

## Container image updates

**WUD (What's Up Docker)** on raspberrypi5 watches all three hosts and sends Telegram
notifications when a new image is available. It deliberately does **not** update
anything — image updates are a manual action.

```bash
ssh dockerhost 'cd ~/docker/compose && docker compose pull <service> && \
  docker compose up -d <service> && docker image prune -f'
```

The Gluetun stack is the exception again, and is the one thing that *is* automated: a
cron job on dockerhost runs `scripts/update-gluetun-stack.sh` daily at 06:45, which is a
no-op when no images changed.

```
45 6 * * * /home/albor/docker/compose/scripts/update-gluetun-stack.sh >> /home/albor/docker/logs/gluetun-update.log 2>&1
```

## Boot and the nightly power cycle

The NUC13 powers off nightly (**midnight–06:15**) to save energy, which takes the
`dockerhost` VM with it. `diskstation` is also down overnight. `raspberrypi5` is
always-on, which is why DNS and the other critical services live there.

Services are brought back by a boot script on each host, not by Docker restart
policies alone:

| Host          | Mechanism                                                                               |
|---------------|-----------------------------------------------------------------------------------------|
| `dockerhost`  | `docker-compose-up.service` (systemd oneshot) → `scripts/compose-up.sh`                 |
| `diskstation` | `/usr/local/etc/rc.d/compose-up.sh` (from `compose-up-rc.sh`) → `scripts/compose-up.sh` |

Both scripts run `docker compose up -d` with retry logic, because `restart: always`
cannot repair the Gluetun namespace binding described above. The full boot sequence is
documented in [ARCHITECTURE.md](ARCHITECTURE.md#dockerhost-boot-sequence).

Deploying during the overnight window is not possible on `dockerhost` or `diskstation` —
the hosts are off.

### NFS mounts on dockerhost

`diskstation` going down overnight takes with it the NFS shares that Plex and the media
stack read from. Recovery needs no scripting: both shares are `x-systemd.automount`
entries in the host's `/etc/fstab`, so systemd mounts them on first access and remounts
them after the NAS returns.

| Mount            | Source                                  |
|------------------|-----------------------------------------|
| `/mnt/media`     | `diskstation:/volume1/media`             |
| `/mnt/Alessandro`| `diskstation:/volume1/homes/Alessandro`  |

Compose reaches the media share through `$MEDIADIR` (`/mnt/media`), so a container's
bind mount follows the fstab entry rather than hardcoding a path.

That fstab is not version-controlled — it is part of the host state that has yet to move
into Ansible, tracked as beads `homelab-4v6` / GitHub
[#45](https://github.com/alborworld/homelab/issues/45).

## Rollback

There is no release or image-pinning mechanism to roll back to. Rollback means reverting
the repo change and re-applying:

```bash
git revert <commit> && git push origin HEAD:main
ssh dockerhost 'cd ~/homelab && git pull && cd ~/docker/compose && docker compose up -d'
```

To go back to a previous *image*, pin the tag explicitly in the service's compose file
and re-apply — most stacks track floating tags, so `up -d` alone will not go backwards.
(Pinning floating tags on critical infra is tracked as beads `homelab-737beef2`.)

Compose does not snapshot volumes: a rollback restores configuration, not data. Data
recovery comes from Proxmox Backup Server for the `dockerhost` VM, and Synology
HyperBackup from `diskstation` to the offsite `diskstation-backup`.

## Verifying a deployment

```bash
ssh dockerhost 'cd ~/docker/compose && docker compose ps'
ssh dockerhost 'cd ~/docker/compose && docker compose logs -f <service>'
```

Then check the service is actually routed and healthy, not merely running:

- **Traefik** — the route was published (Traefik dashboard; via traefik-kop for
  services on dockerhost/diskstation)
- **Homepage** — the dashboard tile and its widget resolve
- **Uptime Kuma** — the monitor is green
- **Beszel** — host resource impact
- **Dozzle** — aggregated logs across hosts

## Checking for drift

Hosts are updated by hand, so they can sit behind `main` — especially `diskstation`,
which cannot pull at all. To compare a host's compose config against the repo:

```bash
# what commit is the host on?
ssh dockerhost 'cd ~/homelab && git rev-parse --short HEAD'
ssh diskstation 'cat ~/homelab/.git/refs/heads/main'   # no git binary; read the ref

# does anything in docker/ differ between that commit and main?
git log --oneline <host-commit>..main -- docker/
```

A host being behind only matters if the intervening commits touched its own
`docker/<host>/**`.

## Not automated yet

Deliberately absent, so this document does not describe it:

- **CI/CD.** There are no `.github/workflows`, and the `github-runner-*` stacks are
  commented out of the host compose files. Tracked as GitHub
  [#121](https://github.com/alborworld/homelab/issues/121); the intended path is
  Actions Runner Controller on the k3s cluster (beads `homelab-jl0.7`).
- **Staging.** There is one environment. Changes go to `main` and then to the hosts.
- **Kubernetes.** No cluster exists yet. A single-node k3s cluster with Flux GitOps is
  scoped in GitHub [#43](https://github.com/alborworld/homelab/issues/43) / beads
  `homelab-jl0`, as an additive platform rather than a migration — the Compose hosts
  described here stay.
