# Secure Infrastructure-as-Code (Secure-IaC)

A comprehensive DevSecOps platform for automated VM provisioning and security hardening on Proxmox using GitOps principles.

## Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
  - [Infrastructure Server Setup](#infrastructure-server-setup)
  - [Client Machine Setup](#client-machine-setup)
  - [Proxmox Configuration](#proxmox-configuration)
  - [Jenkins Configuration](#jenkins-configuration)
- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Pipeline Workflow](#pipeline-workflow)
- [Security Features](#security-features)
- [Troubleshooting](#troubleshooting)

## Overview

Secure-IaC provides single-click provisioning of hardened Proxmox VMs through a complete DevSecOps pipeline. The system follows GitOps principles where all infrastructure changes are driven through git commits.

### Key Features
- **Automated VM Provisioning**: Deploy multiple VMs with custom configurations
- **Security Scanning**: Pre-deployment validation with tflint, tfsec, and Checkov
- **Policy Enforcement**: OPA policies enforce resource limits and security constraints
- **Post-deployment Hardening**: Ansible automatically hardens VMs after creation
- **GitOps Workflow**: All changes tracked and deployed through git

## Architecture

```
┌─────────────────┐     ┌──────────────┐     ┌─────────────────┐
│  Client Machine │────▶│    GitHub    │◀────│ Jenkins Server  │
│ (launch script) │     │ (secure-iac) │     │  (pipelines)    │
└─────────────────┘     └──────────────┘     └────────┬────────┘
                                                       │
                                              ┌────────▼────────┐
                                              │    Proxmox      │
                                              │  Hypervisor     │
                                              │   (VMs)         │
                                              └─────────────────┘
```

### Components
1. **Client Machine**: Runs launch script to trigger deployments
2. **Jenkins Server**: Orchestrates the entire CI/CD pipeline
3. **Proxmox Hypervisor**: Hosts the virtual machines
4. **GitHub Repository**: Stores infrastructure code and configurations

## Prerequisites

### Required Software Versions
- **Proxmox VE**: 7.0 or higher
- **Jenkins**: 2.400 or higher
- **Terraform**: 1.7.0 or higher
- **Ansible**: 2.14 or higher
- **OPA**: 0.60.0 or higher
- **Git**: 2.30 or higher

### Network Requirements
- Jenkins server accessible on port 8080
- Proxmox API accessible on port 8006
- SSH access (port 22) to all servers
- Internet access for package downloads

## Environment Setup

### Infrastructure Server Setup

The infrastructure server (Jenkins host) requires the following tools:

#### 1. Base System Update
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git jq build-essential
```

#### 2. Install Terraform
```bash
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

#### 3. Install Ansible
```bash
sudo apt install -y python3-pip
pip3 install ansible
```

#### 4. Install Security Tools
```bash
# TFLint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# TFSec
curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

# Checkov
pip3 install checkov

# OPA
sudo wget -O /usr/local/bin/opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64_static
sudo chmod +x /usr/local/bin/opa
```

#### 5. Install Jenkins
```bash
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

### Client Machine Setup

The client machine only needs:
```bash
# Install Git
sudo apt install -y git

# Install jq for JSON processing
sudo apt install -y jq

# Clone the repository
git clone git@github.com:fare98/secure-iac.git
cd secure-iac
```

### Proxmox Configuration

#### 1. Create API Token
```bash
# On Proxmox host
pveum user add terraform@pve
pveum aclmod / -user terraform@pve -role Administrator
pveum user token add terraform@pve terraform1 -privsep 0
# Save the token secret!
```

#### 2. Create VM Template

##### Option A: Using Ubuntu Cloud Image (Recommended)
```bash
# Download Ubuntu cloud image
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Create VM
qm create 9000 --name ubuntu-cloud --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# Import disk
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm

# Configure VM
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1

# Convert to template
qm template 9000
```

##### Option B: Manual Ubuntu Installation
1. Create VM with Ubuntu ISO
2. Install Ubuntu Server with:
   - Username: `ubuntu`
   - Password: `temp123`
   - Install OpenSSH server
3. Post-installation setup:
```bash
# Install required packages
sudo apt update && sudo apt install -y cloud-init qemu-guest-agent

# Configure cloud-init
sudo tee /etc/cloud/cloud.cfg.d/99-proxmox.cfg > /dev/null << 'EOF'
datasource_list: [NoCloud, ConfigDrive]

system_info:
  default_user:
    name: ubuntu
    lock_passwd: false
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash

ssh_pwauth: true
network: {config: disabled}
EOF

# Import SSH key (replace with your key)
mkdir -p /home/ubuntu/.ssh
echo "ssh-rsa YOUR_PUBLIC_KEY_HERE ubuntu@idp" >> /home/ubuntu/.ssh/authorized_keys
chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh

# Clean for template
sudo cloud-init clean --logs
sudo rm -f /etc/ssh/ssh_host_*
sudo truncate -s 0 /etc/machine-id /var/log/wtmp /var/log/btmp
history -c
sudo poweroff
```
4. Convert to template: `qm template <VM_ID>`

### Jenkins Configuration

#### 1. Initial Setup
1. Access Jenkins at `http://jenkins-server:8080`
2. Get initial admin password: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`
3. Install suggested plugins
4. Create admin user

#### 2. Required Plugins
Install via Manage Jenkins → Manage Plugins:
- Pipeline
- Git
- Credentials Binding
- SSH Agent

#### 3. Configure Credentials

Go to Manage Jenkins → Manage Credentials → System → Global credentials:

##### a. Proxmox API Token
- Kind: Secret text
- ID: `proxmox-token`
- Secret: `<your-proxmox-token-secret>`
- Description: Proxmox API Token

##### b. VM Password
- Kind: Secret text
- ID: `vm-password`
- Secret: `temp123`
- Description: VM Cloud-Init Password

##### c. Ansible SSH Key
- Kind: SSH Username with private key
- ID: `ansible-ssh-key`
- Username: `ubuntu`
- Private Key: Enter directly (paste contents of `~/.ssh/idp_ansible`)
- Description: Ubuntu SSH Key

##### d. GitHub SSH Key
- Kind: SSH Username with private key
- ID: `git-ssh-key`
- Username: `git`
- Private Key: Your GitHub SSH key
- Description: GitHub SSH Key

#### 4. Create Pipeline Job
1. New Item → Pipeline → Name: "secure-idp"
2. Pipeline → Definition: Pipeline script from SCM
3. SCM: Git
4. Repository URL: `git@github.com:fare98/secure-iac.git`
5. Credentials: git-ssh-key
6. Branch: `*/main`
7. Script Path: `cicd/Jenkinsfile`
8. Build Triggers: Check "GitHub hook trigger for GITScm polling"

#### 5. GitHub Integration Setup

Jenkins automatically detects pushes to the `git@github.com:fare98/secure-iac.git` repository through the **"GitHub hook trigger for GITScm polling"** setting.

**Setup Steps:**
1. In Jenkins job configuration, go to **Build Triggers** section
2. Check the box **"GitHub hook trigger for GITScm polling"**
3. Ensure **Repository URL** is set to `git@github.com:fare98/secure-iac.git`
4. Ensure **Credentials** is set to `git-ssh-key`
5. Click **Save**
6. Jenkins will automatically poll the GitHub repository for changes and trigger builds

## Installation

### 1. Clone Repository
```bash
# On infrastructure server
cd /opt
sudo git clone https://github.com/fare98/secure-iac.git
sudo chown -R $(whoami):$(whoami) secure-iac
cd secure-iac
```

### 2. Generate SSH Keys
```bash
./scripts/setup_ssh_keys.sh
```
This creates:
- `~/.ssh/idp_ansible` (private key)
- `~/.ssh/idp_ansible.pub` (public key)

### 3. Configure Terraform Variables
Edit `terraform/terraform.tfvars.json`:
```json
{
  "vm_count": 1,
  "vm_cpu": 2,
  "vm_memory_mb": 2048,
  "vm_template": "ubuntu-cloud",
  "ssh_public_key": "ssh-rsa AAAA... ubuntu@idp"
}
```

### 4. Update Jenkins Credentials
Add the Jenkins URL and token to `scripts/launch_pipeline.sh`:
```bash
JENKINS_URL="http://192.168.178.50:8080"
JENKINS_USER="admin"
JENKINS_TOKEN="your-jenkins-token"
```

## Usage

### Automated Deployment (Recommended)

From the client machine:
```bash
cd secure-iac
./scripts/launch_pipeline.sh
```

The script will:
1. Prompt for VM configuration (count, CPU, memory, template)
2. Update terraform.tfvars.json
3. Commit and push changes
4. Trigger Jenkins pipeline
5. Monitor pipeline execution

### Manual Deployment

#### Local Testing
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

#### Via Git Push
1. Modify `terraform/terraform.tfvars.json`
2. Commit changes: `git add -A && git commit -m "Update VM config"`
3. Push to trigger pipeline: `git push origin main`

## Project Structure

```
secure-iac/
├── terraform/                  # Terraform infrastructure code
│   ├── main.tf                # Main Terraform configuration
│   ├── variables.tf           # Variable definitions
│   ├── terraform.tfvars.json  # Variable values
│   ├── modules/               # Terraform modules
│   │   └── vm/               # VM module
│   └── opa-policies/         # OPA policy files
│       └── terraform.rego    # Resource constraints
├── ansible/                   # Ansible configuration
│   ├── site.yml              # Main playbook
│   ├── inventory.yml         # Static inventory file
│   ├── tasks.yml             # Security hardening tasks
│   ├── handlers.yml          # Task handlers
│   └── vars.yml              # Variables
├── cicd/                     # CI/CD pipeline
│   └── Jenkinsfile          # Jenkins pipeline definition
├── security/                 # Security policies
│   └── checkov-policies/    # Custom Checkov policies
├── scripts/                  # Utility scripts
│   ├── launch_pipeline.sh   # Pipeline trigger script
│   └── setup_ssh_keys.sh   # SSH key generation
├── docs/                    # Documentation
└── Makefile                # Build automation

```

## Pipeline Workflow

### 1. Checkout Stage
- Clones repository from GitHub
- Uses git-ssh-key credential

### 2. Lint Stage
Runs security scanners in sequence:
- **tflint**: Terraform syntax and best practices
- **tfsec**: Security vulnerability scanning
- **checkov**: Policy-as-code validation

### 3. Plan Stage
- Initializes Terraform providers
- Creates execution plan
- Saves plan for apply stage

### 4. OPA Policy Check Stage
Validates Terraform plan against policies:
- Maximum 8 vCPUs per VM
- Maximum 16GB RAM per VM
- Maximum 10 VMs per deployment
- Approved templates only
- Approved network bridges only

### 5. Apply Stage (main branch only)
- Applies Terraform changes
- Creates/modifies infrastructure
- Generates Ansible inventory

### 6. Configure VMs Stage (main branch only)
- Waits for VMs to boot and cloud-init to complete
- Tests SSH connectivity with ubuntu user
- Runs Ansible security hardening playbook
- Configures firewall, SSH, and system settings

## Security Features

### Pre-deployment Security
1. **TFLint**: Catches Terraform errors and enforces best practices
2. **TFSec**: Scans for security misconfigurations
3. **Checkov**: Custom policies for Proxmox resources
4. **OPA**: Policy enforcement for resource limits

### Post-deployment Security
1. **SSH Hardening**: Key-only authentication, disabled root login
2. **Firewall**: UFW with minimal open ports
3. **System Hardening**: Kernel parameters, service restrictions
4. **Automated Updates**: Security patches applied

### Credentials Management
- All secrets stored in Jenkins credentials store
- No hardcoded passwords in code
- SSH keys for all authentication
- API tokens for Proxmox access

## Current VM Configuration (Working PoC)

### VM Naming and IP Assignment
The project is currently configured for **static IP assignment** as a working Proof of Concept. VMs are created with:

- **VM Names**: Fixed pattern `idp-1`, `idp-2`, `idp-3`, etc.
- **Static IPs**: Sequential assignment starting from `192.168.178.100`
  - idp-1: 192.168.178.100
  - idp-2: 192.168.178.101
  - idp-3: 192.168.178.102
  - And so on...

### Why Static IPs?
During development, **DHCP configuration caused issues** with the homelab setup:
- DHCP lease timing conflicts with cloud-init completion
- Inconsistent IP assignments breaking Ansible inventory
- Network connectivity problems during VM boot process

**Static IP configuration provides**:
- Predictable IP addresses for Ansible automation
- Reliable network connectivity from pipeline start
- Consistent VM accessibility across pipeline stages
- All pipeline stages (Lint → Plan → Apply → Configure) working reliably

### Configuration Details
The static IP setup is implemented through:
- `vm_ip_base = "192.168.178"` (configurable in variables)
- `vm_ip_offset = 100` (starting IP offset)
- `gateway = "192.168.178.1"`
- VMs get IPs: `${vm_ip_base}.${vm_ip_offset + count.index}`

This ensures the complete DevSecOps pipeline works end-to-end with reliable VM provisioning and Ansible configuration management.

## Future Improvements

### DHCP Implementation
Future versions may include DHCP support for more dynamic environments:
- Better cloud-init timing coordination
- Improved network interface detection
- Dynamic inventory management
- Support for various homelab network configurations

### Enhanced VM Configuration
- Configurable VM naming patterns
- Multiple network interface support
- Advanced cloud-init customization
- Template-based VM variations

## Troubleshooting

### Common Issues

#### 1. VM Network Connectivity Issues
**Problem**: VMs created but not accessible via SSH

**Solutions**:
- Ensure cloud-init completed: `cloud-init status`
- Check VM has correct IP: `qm guest cmd <vmid> network-get-interfaces`
- Verify template has cloud-init installed
- Wait 2-3 minutes for cloud-init to complete

#### 2. OPA Binary Issues
**Problem**: OPA shows "Syntax error: newline unexpected"

**Solution**:
```bash
sudo rm /usr/local/bin/opa
sudo wget -O /usr/local/bin/opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64_static
sudo chmod +x /usr/local/bin/opa
opa version  # Should show version info
```

#### 3. Terraform State Issues
**Problem**: "can't remove VM - protection mode enabled"

**Solution**:
```bash
# Disable protection in Proxmox
qm set <vmid> --protection 0

# Or clean Terraform state
cd terraform
terraform state rm module.vm.proxmox_vm_qemu.this[0]
```

#### 4. Jenkins Pipeline Failures
- Check Jenkins console output for detailed errors
- Verify all credentials are configured correctly
- Ensure Jenkins has network access to Proxmox and GitHub
- Check disk space on Jenkins server

### Debug Commands

```bash
# Check Proxmox VM status
qm list
qm status <vmid>

# Check Terraform state
cd terraform && terraform state list

# Test Ansible connectivity
ansible all -i ansible/hosts_dynamic.yml -m ping

# View cloud-init logs on VM
sudo cat /var/log/cloud-init.log
```