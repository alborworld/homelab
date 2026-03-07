# 🧪 Synology DS214

The Synology DiskStation DS214 is used exclusively for backups.

## Beszel Agent Installation

Since the DS214 does not support Docker, you must install the Beszel Agent using the binary method.

**Reference:** [Beszel Agent Binary Installation Guide](https://beszel.dev/guide/agent-installation#_2-manual-download-and-start-linux-freebsd-others)

### 1. Create the Installation Directory

```bash
sudo mkdir -p /opt/beszel
```

### 2. Download the Beszel Agent Binary and Environment File

Download the `linux_arm` (ARMv7) build and place it in `/opt/beszel/`:

```bash
curl -sL https://github.com/henrygd/beszel/releases/download/v0.17.0/beszel-agent_linux_arm.tar.gz \
  | sudo tar -xzf - -C /opt/beszel/ beszel-agent
```

> **Warning:** The DS214 uses a Marvell Armada XP (ARMv7) CPU. Beszel versions after
> v0.17.0 are built with Go 1.26, which crashes on this processor. **Do not upgrade
> past v0.17.0** until upstream fixes ARM32 compatibility.

Example `beszel-agent.env`:
```env
LISTEN=45876
KEY="[BESZEL AGENT PUBLIC KEY]"
FILESYSTEM=/volume1
#LOG_LEVEL=debug # Uncomment for debug logging if needed
```
> **Note:**  
> It is essential to set `FILESYSTEM=/volume1`. If omitted, it will default to `md0`.

### 3. Create the Systemd Service File

Create `/etc/systemd/system/beszel-agent.service` with the following content:

```ini
[Unit]
Description=Beszel Agent Service
After=network-online.target
Wants=network-online.target

[Service]
# Wait for /volume1 to be available before starting
ExecStartPre=/bin/sh -c 'until grep -q " /volume1 " /proc/mounts; do sleep 1; done'
ExecStart=/opt/beszel/beszel-agent
EnvironmentFile=/opt/beszel/beszel-agent.env
# Environment="EXTRA_FILESYSTEMS=sdb"
Restart=on-failure
RestartSec=5
# StateDirectory=beszel-agent  
# (disabled: this version of systemd reports “Unknown lvalue ‘StateDirectory’ in section ‘Service’”,
# so including it breaks the unit at boot)

# Security/sandboxing settings (optional, uncomment as needed)
#KeyringMode=private
#LockPersonality=yes
#NoNewPrivileges=yes
#ProtectClock=yes
#ProtectHome=read-only
#ProtectHostname=yes
#ProtectKernelLogs=yes
#ProtectSystem=strict
#RemoveIPC=yes
#RestrictSUIDSGID=true

[Install]
WantedBy=multi-user.target
```

**Key points:**
- `ExecStartPre` ensures `/volume1` is mounted before starting the agent (important during reboots).
- `ExecStart` runs the agent from `/opt/beszel/beszel-agent`.
- `EnvironmentFile` loads environment variables from `/opt/beszel/beszel-agent.env`.

---

## Managing the Beszel Agent Service

### Reload and Restart After Changes

Whenever you modify `/etc/systemd/system/beszel-agent.service`, reload the systemd daemon and restart the service:

```bash
sudo systemctl daemon-reload
sudo systemctl restart beszel-agent.service
```

### Viewing Logs

To monitor the Beszel Agent logs in real time:

```bash
sudo journalctl -u beszel-agent.service -f
```

### Updates

To update the Beszel Agent manually:

```bash
sudo systemctl stop beszel-agent.service
curl -sL https://github.com/henrygd/beszel/releases/download/<VERSION>/beszel-agent_linux_arm.tar.gz \
  | sudo tar -xzf - -C /opt/beszel/ beszel-agent
sudo systemctl start beszel-agent.service
```

> **Warning:** Do **not** use `beszel-agent update` — it pulls the latest release which
> may be incompatible with this CPU (see note in step 2). Always download a specific
> tested version manually.

The DSM Task Scheduler previously had an "Upgrade Beszel Agent" bootup task that ran
`/opt/beszel/beszel-agent update`. This task has been **disabled** (March 2026) because
it upgraded to a Go 1.26 build that crashes on the Marvell Armada XP. The task can be
managed via **DSM → Control Panel → Task Scheduler** or directly in the SQLite database:

```bash
# Check status
sudo sqlite3 /usr/syno/etc/esynoscheduler/esynoscheduler.db \
  "SELECT task_name, enable FROM task WHERE task_name = 'Upgrade Beszel Agent';"

# Disable (enable=0) or re-enable (enable=1)
sudo sqlite3 /usr/syno/etc/esynoscheduler/esynoscheduler.db \
  "UPDATE task SET enable = 0 WHERE task_name = 'Upgrade Beszel Agent';"
```
