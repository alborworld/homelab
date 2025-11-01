# Traefik + TraefikKop Setup

This Traefik instance acts as the main reverse proxy for all services across multiple Docker hosts (raspberrypi5, dockerhost, diskstation).

## Architecture

- **Traefik** runs on raspberrypi5 (this host)
- **Redis** runs on raspberrypi5 for service discovery
- **TraefikKop** runs on dockerhost and diskstation
  - Reads Docker labels from remote hosts
  - Writes service configurations to Redis
  - Traefik reads these configurations via Redis provider

## Version Compatibility

**Current versions:**
- Traefik: `3.5.4`
- TraefikKop: `0.19`

Versions are pinned to prevent unexpected compatibility issues. TraefikKop must support the specific Traefik version in use. The maintainer actively updates TraefikKop to match new Traefik releases.

### If You See Redis Provider Errors

If you encounter errors like:
```
ERR Provider error error="field not found, node: ..."
```

**Check TraefikKop compatibility:**
1. Visit: https://github.com/jittering/traefik-kop/releases
2. Check the latest release notes for compatibility information
3. Look for breaking changes or version requirements

**Common solutions:**
- TraefikKop may need to be upgraded to support newer Traefik features
- Or Traefik may need to be pinned to a specific version until TraefikKop catches up
- Check the issue tracker: https://github.com/jittering/traefik-kop/issues

### Version History

- **2024-11-01**: Upgraded to Traefik v3.5.4 for compatibility with TraefikKop v0.19
  - TraefikKop v0.19 requires Traefik v3.5+ (adds support for new observability fields)
  - TraefikKop v0.18.1 works with Traefik v3.0-v3.4

## Configuration Files

- `config/traefik.yaml` - Main Traefik configuration
- `dynamic/` - Dynamic configuration files
- `.env` - Environment variables (in parent directory)

## Related Services

- Redis: `../redis/`
- TraefikKop (dockerhost): `../../dockerhost/traefik-kop-dh/`
- TraefikKop (diskstation): `../../diskstation/traefik-kop-ds/`
