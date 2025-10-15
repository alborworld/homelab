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

Place the `beszel-agent` binary and the `beszel-agent.env` file in `/opt/beszel/`.

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

To update the Beszel Agent, run:

```bash
bash /opt/beszel/beszel-agent update
```

> Note:
> This update command is automatically executed at boot via the DSM Task Scheduler.
