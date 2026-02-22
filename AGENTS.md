# Repository Guidelines

## Project Structure & Module Organization
The homelab stays modular by keeping each layer in its own top-level directory. `docker/<node>/` stores Compose bundles and service folders such as `watchtower-dh`; host-specific env lives in that node’s `.env`. `ansible/` contains provisioning playbooks referenced from `docs/SETUP.md`, while `k8s/` is reserved for future manifests—group experiments under the relevant cluster or host. `tofu/<stack>/` (cloudflare, minio, proxmox) houses OpenTofu projects that can reuse shared code in `tofu/modules/`. Update `docs/` whenever architecture, security, or runbook details change so diagrams and guides stay authoritative.

## Build, Test, and Development Commands
Use the root Makefile for SOPS workflows: `make decrypt-dockerhost`, `make encrypt-raspberrypi5`, and `make clean-diskstation` manage `.env` ↔ `.env.sops.enc`. Bring stacks online with `docker compose -f docker/<node>/docker-compose.yaml up -d`, then sanity-check via `docker compose ... config`. Infrastructure edits require `tofu -chdir=tofu/<stack> init`, `plan`, and `apply`. Use `sops -d docker/<node>/.env.sops.enc | head` only for spot-checking values.

## Coding Style & Naming Conventions
Compose, YAML, and Ansible files use 2-space indentation, lowercase keys, and comments that explain intent. Reuse the `<service>-<host>` naming already present in `portainer-agent-dh` and `traefik-kop-dh` so logs stay searchable. Environment variables remain SCREAMING_SNAKE_CASE and should map directly to Compose or Ansible inputs. OpenTofu variables stay snake_case, resources kebab-case, and modules should expose only the inputs consumed by multiple stacks.

## Testing Guidelines
Every change needs a validation note: `docker compose ... config` and `docker compose ... ps` for each affected node, `ansible-playbook --syntax-check ansible/<playbook>.yml` (plus `--check` when feasible), and `tofu -chdir=tofu/<stack> plan` for IaC updates. Capture any UI or API spot-checks (dashboard loads, Traefik route tests) as plain text or screenshots.

## Commit & Pull Request Guidelines
When committing:
- Check the changes by doing a git diff.
- Use single-line commit messages with conventional commits format and gitmoji. Avoid Codex attributions.
- Match the current log style: `<emoji> <type>(scope): summary` such as `🐛 fix(runners): add startup delay`. 
- Keep commits narrow (docs, secrets, infra separated) and include any generated files (diagrams, screenshots) in the same change. 
- The single line is mandatory, except for breaking changes - which will have a second comment line.
- PRs need a short summary, links to issues or project cards, and a checklist of the commands above that were executed, plus pasted `tofu plan`/`docker compose config` diffs when relevant.

## Security & Configuration Tips
Never commit decrypted `.env` files; purge them with `make clean-<target>` before switching tasks. Keep `SOPS_AGE_KEY_FILE` outside the repo and load it through your shell profile. Prefer dedicated service accounts for Cloudflare, Proxmox, and GitHub runners, rotating tokens per `docs/SECURITY.md`. Redact hostnames (`raspberrypi5`, `diskstation`, `dockerhost`) from shared logs to preserve the homelab’s privacy model.

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
