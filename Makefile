# Makefile for managing encrypted .env files using SOPS and age
# 
# This Makefile provides convenient targets to encrypt, decrypt, clean, 
# and display `.env` files for multiple directories in your homelab setup.
#
# Usage examples (run from the repo root or with `make -C ...`):
#   make decrypt-diskstation   # Decrypt diskstation/.env.sops.enc → .env
#   make encrypt-dockerhost    # Encrypt dockerhost/.env → .env.sops.enc
#   make clean-raspberrypi5    # Remove raspberrypi5/.env
#   make show-diskstation      # Print decrypted diskstation/.env.sops.enc to stdout

# List of target environments (each must have its own .env and .env.sops.enc)
ENV_TARGETS := diskstation dockerhost raspberrypi5

# Encrypt .env to .env.sops.enc for a given target
encrypt-%:
	sops --input-type dotenv --output-type dotenv --encrypt $*/.env > $*/.env.sops.enc

# Decrypt .env.sops.enc to .env for a given target
decrypt-%:
	sops --input-type dotenv --output-type dotenv --decrypt $*/.env.sops.enc > $*/.env

# Delete the decrypted .env file for a given target
clean-%:
	rm -f $*/.env

# Print the decrypted .env file to stdout without writing it to disk
show-%:
	sops --input-type dotenv --output-type dotenv --decrypt $*/.env.sops.enc

# Declare targets as phony (not actual files)
.PHONY: $(ENV_TARGETS)

