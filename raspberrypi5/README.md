# 🧪 Raspberry Pi 5 — HomeLab Docker Stack

This folder contains the Docker Compose configuration and related files for services running on the Raspberry Pi 5 in the [alborworld/homelab](https://github.com/alborworld/homelab) setup.

---

## 📦 Services

The services are defined by the `docker-compose.yaml` file in each relative subfolder.

## 📂 Local Folder Structure

```bash
~/docker/
├── compose/           # ← This repo's content is symlinked here
│   ├── docker-compose.yaml
│   ├── .env.sops.enc
│   └── ...
└── volumes/           # ← Local persistent data (NOT versioned)
~/homelab/             # ← Cloned repo
```

## 🔐 Secrets

- Secrets are stored in `.env.sops.enc` and decrypted locally using [Mozilla SOPS](https://github.com/mozilla/sops).
- To encrypt an existing `.env` file:
  ```bash
  sops --encrypt .env > .env.sops.enc
  ```
- After cloning, decrypt with:
  ```bash
  sops --input-type dotenv --output-type dotenv --decrypt .env.sops.enc > .env
  ```

NOTE: When decrypting with SOPS, specifying `--input-type dotenv --output-type dotenv` ensures that the file is correctly interpreted and formatted as a dotenv file, preserving its structure and avoiding misinterpretation or formatting issues.

---

## 🚀 Usage

### Clone and setup symlink

```bash
git clone git@github.com:alborworld/homelab.git ~/homelab
ln -s ~/homelab/raspberrypi5 ~/docker/compose
```

### Deploy the stack

```bash
cd ~/docker/compose
sops --input-type dotenv --output-type dotenv --decrypt .env.sops.enc > .env
docker compose up -d
```

---

## 📋 Notes

- This stack is designed to be lightweight and always-on (24/7).
- `~/docker/compose` is a symlink to `~/homelab/raspberrypi5`.
- `~/docker/volumes` is preserved and excluded from Git.
- Each service may have its own subfolder with `docker-compose.yaml`.
