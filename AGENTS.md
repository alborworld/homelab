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

<!-- BEGIN BEADS INTEGRATION -->
## Issue Tracking with bd (beads)

**IMPORTANT**: This project uses **bd (beads)** for ALL issue tracking. Do NOT use markdown TODOs, task lists, or other tracking methods.

### Why bd?

- Dependency-aware: Track blockers and relationships between issues
- Git-friendly: Dolt-powered version control with native sync
- Agent-optimized: JSON output, ready work detection, discovered-from links
- Prevents duplicate tracking systems and confusion

### Quick Start

**Check for ready work:**

```bash
bd ready --json
```

**Create new issues:**

```bash
bd create "Issue title" --description="Detailed context" -t bug|feature|task -p 0-4 --json
bd create "Issue title" --description="What this issue is about" -p 1 --deps discovered-from:bd-123 --json
```

**Claim and update:**

```bash
bd update <id> --claim --json
bd update bd-42 --priority 1 --json
```

**Complete work:**

```bash
bd close bd-42 --reason "Completed" --json
```

### Issue Types

- `bug` - Something broken
- `feature` - New functionality
- `task` - Work item (tests, docs, refactoring)
- `epic` - Large feature with subtasks
- `chore` - Maintenance (dependencies, tooling)

### Priorities

- `0` - Critical (security, data loss, broken builds)
- `1` - High (major features, important bugs)
- `2` - Medium (default, nice-to-have)
- `3` - Low (polish, optimization)
- `4` - Backlog (future ideas)

### Workflow for AI Agents

1. **Check ready work**: `bd ready` shows unblocked issues
2. **Claim your task atomically**: `bd update <id> --claim`
3. **Work on it**: Implement, test, document
4. **Discover new work?** Create linked issue:
   - `bd create "Found bug" --description="Details about what was found" -p 1 --deps discovered-from:<parent-id>`
5. **Complete**: `bd close <id> --reason "Done"`

### Auto-Sync

bd automatically syncs via Dolt:

- Each write auto-commits to Dolt history
- Use `bd dolt push`/`bd dolt pull` for remote sync
- No manual export/import needed!

### Important Rules

- ✅ Use bd for ALL task tracking
- ✅ Always use `--json` flag for programmatic use
- ✅ Link discovered work with `discovered-from` dependencies
- ✅ Check `bd ready` before asking "what should I work on?"
- ❌ Do NOT create markdown TODO lists
- ❌ Do NOT use external issue trackers
- ❌ Do NOT duplicate tracking systems

For more details, see README.md and docs/QUICKSTART.md.

<!-- END BEADS INTEGRATION -->
