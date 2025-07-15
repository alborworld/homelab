# Ansible Configuration Directory

This directory contains Ansible playbooks, roles, and configuration files for managing the homelab infrastructure.

## Directory Structure

- `playbooks/` - Main Ansible playbooks for different deployment scenarios
- `roles/` - Reusable Ansible roles for common tasks
- `inventory/` - Host inventory files and group definitions
- `vars/` - Variable files for different environments
- `group_vars/` - Group-specific variables
- `host_vars/` - Host-specific variables

## Usage

1. Update the inventory files in `inventory/` with your host information
2. Modify variables in `vars/` and `group_vars/` as needed
3. Run playbooks using:
   ```bash
   ansible-playbook -i inventory/hosts playbooks/main.yml
   ```

## Requirements

- Ansible >= 2.9
- Python >= 3.6
- Access to target hosts

## Security Note

Sensitive information should be encrypted using SOPS. See the repository's root Makefile for encryption/decryption instructions.

## Contributing

1. Create a new branch for your changes
2. Make your modifications
3. Test the changes thoroughly
4. Submit a pull request

## License

See the [LICENSE](../LICENSE) file for details.