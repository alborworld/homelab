# Security Practices

## Secrets Management with SOPS

### Initial Setup

1. **Install [SOPS](https://github.com/getsops/sops)**:
   ```bash
   # On macOS
   brew install sops
   
   # On Linux
   sudo apt-get install sops
   ```

2. **Generate [age](https://github.com/FiloSottile/age) key** (if you don't have one):
   ```bash
   age-keygen -o ~/.sops/age/keys.txt
   # Your public key will be shown and saved to the file
   ```

3. **Configure SOPS**:
   Create or edit `~/.sops.yaml`:
   ```yaml
   creation_rules:
     - path_regex: .*\.enc\.yaml$
       age: "YOUR_PUBLIC_KEY"  # The public key from age-keygen output
   ```

#### Encryption & Decryption with Makefile

To simplify encryption and decryption of `.env` files, use the provided [Makefile](../Makefile) targets. This ensures consistent usage of SOPS options and reduces manual steps.

**Examples:**

- Encrypt the `.env` file for a target (e.g., diskstation):
  ```bash
  make encrypt-diskstation
  ```
  This will encrypt `diskstation/docker/.env` to `diskstation/docker/.env.sops.enc`.

### 🚀 Getting Started

- Decrypt the `.env.sops.enc` file for a target (e.g., raspberrypi5):
  ```bash
  make decrypt-raspberrypi5
  ```
  This will decrypt `raspberrypi5/docker/.env.sops.enc` to `raspberrypi5/docker/.env`.

- Clean (remove) the decrypted `.env` file for a target:
  ```bash
  make clean-dockerhost
  ```

- Show the decrypted `.env` file for a target (print to stdout):
  ```bash
  make show-diskstation
  ```

#### Manual Encryption
To encrypt an existing `.env` file manually:
```bash
sops --input-type dotenv --output-type dotenv --encrypt .env > .env.sops.enc
```

#### Manual Decryption
To decrypt manually:
```bash
sops --input-type dotenv --output-type dotenv --decrypt .env.sops.enc > .env
```

> **Note**: When decrypting with SOPS, specifying `--input-type dotenv --output-type dotenv` ensures that the file is correctly interpreted and formatted as a dotenv file, preserving its structure and avoiding misinterpretation or formatting issues.

## Network Security

- All services are behind a reverse proxy (Traefik) with HTTPS
- Unnecessary ports are closed by default
- VPN is required for administrative access
- Regular security updates are applied automatically

## Access Control

- Principle of least privilege is enforced
- Multi-factor authentication is enabled where possible
- Single Sign-On (SSO) implemented for many services using PocketID / OIDC
