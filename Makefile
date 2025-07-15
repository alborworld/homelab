# Makefile for managing encrypted .env files using SOPS and age
# 
# This Makefile provides convenient targets to encrypt, decrypt, clean, 
# and display `.env` files for multiple directories in your homelab setup.
#
# Usage examples (run from the repo root or with `make -C ...`):
#   make decrypt-diskstation   # Decrypt docker/diskstation/.env.sops.enc → .env
#   make encrypt-dockerhost    # Encrypt docker/dockerhost/.env → .env.sops.enc
#   make clean-raspberrypi5    # Remove docker/raspberrypi5/.env
#   make show-diskstation      # Print decrypted docker/diskstation/.env.sops.enc to stdout

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

# Declare targets as phony (not actual files)
.PHONY: $(ENV_TARGETS)
