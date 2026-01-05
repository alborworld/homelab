# Makefile for managing encrypted .env files using SOPS and age
# 
# This Makefile provides convenient targets to encrypt, decrypt, clean, 
# and display `.env` files for multiple directories in your homelab setup.
#
# Usage examples:
#   make decrypt-diskstation   # Decrypt docker/diskstation/.env.sops.enc → .env
#   make encrypt-dockerhost    # Encrypt docker/dockerhost/.env → .env.sops.enc
#   make clean-raspberrypi5    # Remove docker/raspberrypi5/.env
#   make show-diskstation      # Print decrypted docker/diskstation/.env.sops.enc to stdout
#
# Tofu stacks (supports nested paths):
#   make tofu-encrypt STACK=cloudflare
#   make tofu-decrypt STACK=proxmox/tailscale-exit-nordvpn-nl

# List of target environments (each must have its own .env and .env.sops.enc)
# Automatically detect subdirectories in docker/
ENV_TARGETS := $(shell find docker -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)

# Encrypt .env to .env.sops.enc for a given target
encrypt-%:
	sops --input-type dotenv --output-type dotenv --encrypt docker/$*/.env > docker/$*/.env.sops.enc

# Decrypt .env.sops.enc to .env for a given target
decrypt-%:
	sops --input-type dotenv --output-type dotenv --decrypt docker/$*/.env.sops.enc > docker/$*/.env

# Delete the decrypted .env file for a given target
clean-%:
	rm -f docker/$*/.env

# Print the decrypted .env file to stdout without writing it to disk
show-%:
	sops --input-type dotenv --output-type dotenv --decrypt docker/$*/.env.sops.enc

# Deploy decrypted .env to remote host via SSH
# Usage: make deploy-raspberrypi5
deploy-%:
	@echo "Deploying .env to $*..."
	sops --input-type dotenv --output-type dotenv --decrypt docker/$*/.env.sops.enc | \
		ssh $* "cat > ~/docker/compose/.env"

# Declare targets as phony (not actual files)
.PHONY: $(ENV_TARGETS)

# Tofu targets for managing encrypted .env files in tofu/
# Usage: make tofu-encrypt STACK=cloudflare
#        make tofu-encrypt STACK=proxmox/tailscale-exit-nordvpn-nl
tofu-encrypt:
	@test -n "$(STACK)" || (echo "Usage: make tofu-encrypt STACK=<path>"; exit 1)
	sops --input-type dotenv --output-type dotenv --encrypt tofu/$(STACK)/.env > tofu/$(STACK)/.env.sops.enc

tofu-decrypt:
	@test -n "$(STACK)" || (echo "Usage: make tofu-decrypt STACK=<path>"; exit 1)
	sops --input-type dotenv --output-type dotenv --decrypt tofu/$(STACK)/.env.sops.enc > tofu/$(STACK)/.env

tofu-clean:
	@test -n "$(STACK)" || (echo "Usage: make tofu-clean STACK=<path>"; exit 1)
	rm -f tofu/$(STACK)/.env

tofu-show:
	@test -n "$(STACK)" || (echo "Usage: make tofu-show STACK=<path>"; exit 1)
	sops --input-type dotenv --output-type dotenv --decrypt tofu/$(STACK)/.env.sops.enc

# Ansible targets for managing secrets.yml with SOPS
# Usage: make ansible-encrypt
#        make ansible-decrypt
#        make ansible-show
ansible-encrypt:
	sops --input-type yaml --output-type yaml --encrypt ansible/secrets.yml > ansible/secrets.yml.sops.enc

ansible-decrypt:
	sops --input-type yaml --output-type yaml --decrypt ansible/secrets.yml.sops.enc > ansible/secrets.yml

ansible-show:
	sops --input-type yaml --output-type yaml --decrypt ansible/secrets.yml.sops.enc

ansible-edit:
	sops ansible/secrets.yml.sops.enc

ansible-clean:
	rm -f ansible/secrets.yml

.PHONY: tofu-encrypt tofu-decrypt tofu-clean tofu-show ansible-encrypt ansible-decrypt ansible-show ansible-edit ansible-clean
