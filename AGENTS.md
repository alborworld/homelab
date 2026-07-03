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

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:970c3bf2 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   bd dolt push
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->

<!-- BEGIN BEADS CODEX SETUP: generated by bd setup codex -->
## Beads Issue Tracker

Use Beads (`bd`) for durable task tracking in repositories that include it. Use the `beads` skill at `.agents/skills/beads/SKILL.md` (project install) or `~/.agents/skills/beads/SKILL.md` (global install) for Beads workflow guidance, then use the `bd` CLI for issue operations.

### Quick Reference

```bash
bd ready                # Find available work
bd show <id>            # View issue details
bd update <id> --claim  # Claim work
bd close <id>           # Complete work
bd prime                # Refresh Beads context
```

### Rules

- Use `bd` for all task tracking; do not create markdown TODO lists.
- Run `bd prime` when Beads context is missing or stale. Codex 0.129.0+ can load Beads context automatically through native hooks; use `/hooks` to inspect or toggle them.
- Keep persistent project memory in Beads via `bd remember`; do not create ad hoc memory files.

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.
<!-- END BEADS CODEX SETUP -->
