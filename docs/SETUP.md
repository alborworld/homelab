# Homelab Setup Guide

How to bring a host into the fleet from scratch. For deploying changes to a host that
already exists, see [DEPLOYMENT.md](DEPLOYMENT.md).

## Prerequisites

**On your workstation:**

- Git
- [SOPS](https://github.com/getsops/sops) and an age private key — `brew install sops age`
- SSH access to each host (all hosts are defined in `~/.ssh/config`)

**On each host:**

- Docker Engine and Docker Compose **v2.21.0+**, for the `include` directive.
  raspberrypi5 and dockerhost currently run Compose v5.x; diskstation runs v2.24.0, which
  sets the floor.

## Secrets

Secrets are encrypted in the repo with SOPS using **age** — there is no GPG key involved.
`.sops.yaml` in the repo root holds the creation rules, covering `docker/**/.env`,
`tofu/**/.env` and `ansible/secrets.yml`.

Your age private key belongs at `~/.config/sops/age/keys.txt`, mode `600`. Without it
nothing decrypts. See [SECURITY.md](SECURITY.md).

There are no `.env.example` files to copy. Each host has a committed `.env.sops.enc`, and
you produce its plaintext `.env` with the Makefile targets below.

## Host setup

Every host runs its own Compose project from a symlink into a clone of this repo. The
pattern is identical; only the paths differ.

| Host           | Clone       | Compose dir               | Symlink target                  |
|----------------|-------------|---------------------------|---------------------------------|
| `raspberrypi5` | `~/homelab` | `~/docker/compose`        | `~/homelab/docker/raspberrypi5` |
| `dockerhost`   | `~/homelab` | `~/docker/compose`        | `~/homelab/docker/dockerhost`   |
| `diskstation`  | `~/homelab` | `/volume1/docker/compose` | `~/homelab/docker/diskstation`  |

### 1. Clone and symlink

On the host:

```bash
git clone git@github.com:alborworld/homelab.git ~/homelab

# raspberrypi5 / dockerhost — substitute the host's directory name
mkdir -p ~/docker
ln -s ~/homelab/docker/dockerhost ~/docker/compose

# diskstation
ln -s ~/homelab/docker/diskstation /volume1/docker/compose
```

> Create the **parent** directory, not the link itself. `mkdir -p ~/docker/compose`
> followed by `ln -s … ~/docker/compose` puts the symlink *inside* that directory rather
> than creating it — a confusing failure to debug later.

### 2. Ship the secrets

Run these from the repo root **on your workstation**, not on the host:

```bash
make deploy-dockerhost      # decrypt and pipe the .env to the host over ssh
```

Or handle the plaintext yourself:

```bash
make show-dockerhost        # print it, write nothing
make decrypt-dockerhost     # write docker/dockerhost/.env locally
make clean-dockerhost       # remove the local plaintext when done
```

The suffix is the directory name under `docker/` — `raspberrypi5`, `dockerhost` or
`diskstation`.

> `make deploy-%` writes to `~/docker/compose/.env`. That is right for raspberrypi5 and
> dockerhost but wrong for diskstation, whose compose dir is `/volume1/docker/compose` —
> ship that one manually.

That `.env` carries both the secrets and the host's paths: `VOLUMEDIR`, `LOCAL_DOMAIN`,
`UID`/`GID`, and `MEDIADIR` on dockerhost. Nothing needs exporting from your login profile.

### 3. Start the services

```bash
cd ~/docker/compose         # /volume1/docker/compose on diskstation
docker compose up -d
```

Each host's `docker-compose.yaml` is a list of `include:` entries, one per service
directory, so a service is enabled or disabled by editing that list.

### 4. Survive a reboot

`raspberrypi5` is always on. `dockerhost` and `diskstation` go down nightly with the NUC
and the NAS and need a boot script — Docker's restart policies alone cannot repair the
Gluetun network-namespace binding. See
[DEPLOYMENT.md](DEPLOYMENT.md#boot-and-the-nightly-power-cycle) for both mechanisms, and
[ARCHITECTURE.md](ARCHITECTURE.md#dockerhost-boot-sequence) for the full sequence.

## Synology DiskStations

- **DS218+ (primary)** — storage, Garage S3, AdGuard replica, Syncthing
- **DS214 (backup)** — offsite HyperBackup target

DSM ships no `git`, so diskstation's checkout cannot pull; see
[DEPLOYMENT.md](DEPLOYMENT.md#2-update-the-checkout-on-the-host). For the backup target,
see the [Synology Backup NAS Setup Guide](README_Synology_DS214.md).

## Verifying the setup

```bash
cd ~/docker/compose && docker compose ps
```

Then check the services are actually routed rather than merely running — Traefik published
the route, the Homepage tile resolves, the Uptime Kuma monitor is green. Details in
[DEPLOYMENT.md](DEPLOYMENT.md#verifying-a-deployment).

## Troubleshooting

- **Service logs** — `docker compose logs -f <service>` from the compose dir. Note
  `docker compose`; the v1 `docker-compose` is not installed on these hosts.
- **SOPS cannot decrypt** — check `~/.config/sops/age/keys.txt` exists and its public key
  is a recipient in `.sops.yaml`.
- **A service is up but Traefik returns 404** — most likely the Gluetun network-namespace
  problem; see [DEPLOYMENT.md](DEPLOYMENT.md#4-apply).
- **A host is behind the repo** — hosts are updated by hand and drift; see the drift check
  in [DEPLOYMENT.md](DEPLOYMENT.md#checking-for-drift).
