# Proxmox VMs Configuration

This directory contains OpenTofu configurations for managing Proxmox VMs.

## Directory Structure

```
proxmox/
├── main.tf          # Main Terraform configuration
├── variables.tf     # Input variables
└── outputs.tf       # Output values
```

## Purpose

This configuration manages Proxmox VMs, specifically:
- Creates and configures VMs
- Applies VM policies
- Configured for use as a Terraform backend for state storage
