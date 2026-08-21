# Kubernetes (planned)

> **Nothing here yet.** No cluster exists. The homelab runs on Docker Compose across
> three hosts — see [docs/DEPLOYMENT.md](../docs/DEPLOYMENT.md) for how that actually
> works today.

Scope and rationale live in GitHub [#43](https://github.com/alborworld/homelab/issues/43)
(beads epic `homelab-jl0`). This file is the short version.

## What this will be

A **single-node k3s cluster on the NUC13, as an additive second platform — not a
migration off Compose.**

The reason is didactic and portfolio value, and it is stated plainly rather than dressed
up as an operational need: the cluster exercises the things Compose structurally cannot
teach — reconciliation loops, CRDs and operators, Helm, ingress with cert-manager,
StorageClasses and CSI, RBAC, probe semantics, GitOps drift detection. Nothing under
`docker/` exercises any of that.

The argument in the [main README](../README.md) for Compose over Kubernetes on *this*
fleet still holds: three heterogeneous, mostly single-node hosts do not need a
scheduler. This cluster is justified as a learning platform, and by filling the
monitoring and CI gaps — not by an orchestration deficiency.

## Planned shape

| Piece       | Choice                                                                 |
|-------------|------------------------------------------------------------------------|
| Node        | One Proxmox **VM** on nuc13, 4 vCPU / 12 GB / 100 GB, on the tailnet    |
| Provisioning| OpenTofu (the repo's first `proxmox_virtual_environment_vm`) + Ansible  |
| Distribution| k3s, pinned version, bundled Traefik and servicelb disabled            |
| GitOps      | **Flux**                                                               |
| Secrets     | SOPS + age, decrypted by Flux — the same mechanism the repo already uses|
| Storage     | `local-path`                                                           |
| Ingress     | Terminates on raspberrypi5's Traefik; cert-manager with Cloudflare DNS-01 |

A VM rather than an LXC because k3s in an unprivileged LXC means fighting nesting,
cgroup delegation and kernel modules indefinitely.

**Flux over ArgoCD** for coherence, not features: Flux decrypts SOPS+age natively, which
is exactly this repo's existing secrets backbone, so it needs almost no glue where ArgoCD
needs ksops. Tradeoff accepted knowingly — ArgoCD has the better UI.

`local-path` because Longhorn only becomes interesting with a second node. Ingress stays
on the Pi because two cert-issuing proxies would duplicate ACME state and split the
certificate story.

## Planned layout

```
k8s/
├── clusters/nuc13-k3s/   # Flux's own manifests for this cluster
├── infrastructure/       # cluster components (cert-manager, monitoring, ingress)
└── apps/                 # workloads
```

Kustomize, with no overlay hierarchy until there is a second environment to justify one.

## Order of work

1. OpenTofu stack for the VM (after the shared Proxmox module is extracted)
2. Ansible role: k3s install + tailnet join
3. Flux bootstrap with SOPS+age
4. **`kube-prometheus-stack`** — the first workload
5. cert-manager + Cloudflare DNS-01, routed through the Pi's Traefik
6. Migrate the good-citizen services
7. *(optional)* Actions Runner Controller for ephemeral CI runners

`kube-prometheus-stack` goes first on purpose: it is greenfield so there is no migration
risk, it is Helm- and CRD-heavy so the learning is real, and it scrapes all three Docker
hosts over the tailnet — so the cluster earns its keep on day one instead of being a
parking lot for services moved off Compose.

## What is explicitly out of scope

- **Cluster API, management + workload clusters.** Previously the plan for this
  directory. CAPI on one NUC, with no fleet, no tenants and no second cluster to manage,
  is enterprise scaffolding: a large time sink that reads as over-engineering rather than
  judgment. Deferred, not planned — GitHub
  [#101](https://github.com/alborworld/homelab/issues/101).
- **Velero, multi-tenancy.** Ceremony on a single node. Backups go through the existing
  Proxmox Backup Server / HyperBackup path.
- **Talos.** Attractive, but an immutable OS plus a new toolchain on top of a new
  orchestrator is too many unknowns at once. Revisit once k3s is boring.

## What stays on Compose

Single-node k3s has *worse* availability than Compose-on-the-Pi — one node reboot takes
everything on it down — so nothing the household notices belongs on the cluster:

- **DNS** (AdGuard Home / Unbound) — the one service whose failure takes the house offline
- **Home Assistant** — privileged, `network_mode: host`
- **Plex** — iGPU passthrough
- **gluetun / qBittorrent** — `NET_ADMIN`, kill-switch semantics
- **Garage** — NAS-local, and the OpenTofu state backend
- Anything with large NAS bind mounts (booklore, audiobookshelf, `*arr` media paths)

## Related

- [Architecture](../docs/ARCHITECTURE.md)
- [Deployment](../docs/DEPLOYMENT.md)
- [Security](../docs/SECURITY.md)
