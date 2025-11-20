# Lab: Infrastructure as Code (IaC) with KVM using Vagrant and VMware

## Overview

This lab demonstrates how to implement **Infrastructure as Code (IaC)** principles using Vagrant, KVM (Kernel-based Virtual Machine) on CentOS 9 Stream, and VMware Workstation/Player as the provider. 

**Infrastructure as Code (IaC)** is the practice of managing and provisioning computing infrastructure through machine-readable definition files, rather than physical hardware configuration or interactive configuration tools. This approach enables version control, automated deployment, and reproducible infrastructure environments.

We will deploy:

- **kvm1**: KVM hypervisor server with bridge networking
- **client1**: KVM client machine with management tools

These VMs are connected through a private network (VMnet11) for internal communication and a NAT/public network for Internet access. The KVM server is configured with a network bridge (kvmbr0) that allows guest VMs to communicate on the same network segment.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Host Machine                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │         VMware Workstation/Player                │   │
│  │                                                   │   │
│  │  ┌──────────────┐        ┌──────────────┐       │   │
│  │  │    kvm1      │        │   client1    │       │   │
│  │  │  (Server)    │◄──────►│   (Client)   │       │   │
│  │  │              │        │              │       │   │
│  │  │ IP: 10.10.0.1│        │ IP: 10.10.0.10│      │   │
│  │  │ RAM: 2GB     │        │ RAM: 1GB     │       │   │
│  │  │ CPUs: 2      │        │ CPUs: 1      │       │   │
│  │  │              │        │              │       │   │
│  │  │ KVM Bridge:  │        │ virt-manager │       │   │
│  │  │ kvmbr0       │        │ virt-viewer  │       │   │
│  │  │ (eth1)       │        │              │       │   │
│  │  └──────┬───────┘        └──────┬───────┘       │   │
│  │         │                       │                │   │
│  │         └───────────┬───────────┘                │   │
│  │                     │                            │   │
│  │              VMnet11 (Private Network)           │   │
│  │                     │                            │   │
│  │              NAT Network (Internet)              │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Prerequisites

Before starting the lab, ensure you have the following installed and configured:

### Software Requirements

1. **Host Operating System**
   - Windows 10/11, Linux (Ubuntu/Debian/RHEL/CentOS), or macOS
   - Minimum 8GB RAM (recommended 16GB+)
   - At least 20GB free disk space

2. **Vagrant**
   - Version 2.0.0 or later
   - Download from: https://www.vagrantup.com/downloads
   - Verify installation: `vagrant --version`

3. **VMware Workstation or VMware Player**
   - VMware Workstation Pro/Player (latest version recommended)
   - Valid license for VMware Workstation Pro (if using Pro version)
   - VMware Player is free for personal use
   - Download from: https://www.vmware.com/products/workstation-player.html

4. **Vagrant VMware Plugin**
   - Install the VMware desktop plugin:
     ```bash
     vagrant plugin install vagrant-vmware-desktop
     ```
   - This plugin enables Vagrant to work with VMware instead of VirtualBox
   - **Note**: This plugin requires a license (separate from VMware Workstation)

5. **Vagrant Box**
   - CentOS 9 Stream box (generic/centos9s)
   - Add the box:
     ```bash
     vagrant box add generic/centos9s
     ```
   - Verify box is added: `vagrant box list`

### System Requirements

- CPU with virtualization support (Intel VT-x or AMD-V) enabled in BIOS
- Sufficient system resources to run multiple VMs simultaneously
- Administrator/root privileges for installing software

## Project Structure

```
vagrant/
├── Vagrantfile                  # Main Vagrant configuration file
├── installServerKVM.sh          # Provisioning script for kvm1 (KVM server)
├── installClientKVM.sh          # Provisioning script for client1 (KVM client)
├── site/                        # Shared folder (optional web content)
│   └── index.html              # Sample HTML file
└── README.md                    # This file
```

## Detailed Configuration

### Vagrantfile Analysis

The `Vagrantfile` configures two VMs:

#### kvm1 - KVM Hypervisor Server

```ruby
config.vm.define "kvm1" do |kvm1|
  kvm1.vm.box = "generic/centos9s"           # Base OS image
  kvm1.vm.hostname = "kvm1.esi.dz"          # FQDN hostname
  kvm1.vm.network "private_network", ip: "10.10.0.1"  # Private IP on VMnet11
  
  kvm1.vm.provider "vmware_desktop" do |v|
    v.vmx["displayName"] = "kvm1"            # VM name in VMware
    v.memory = 2048                          # 2GB RAM
    v.cpus = 2                               # 2 CPU cores
  end
  
  kvm1.vm.provision "shell", path: "./installServerKVM.sh"  # Provisioning script
end
```

**Key Features:**
- **Hostname**: `kvm1.esi.dz`
- **IP Address**: `10.10.0.1/24` (static on private network)
- **Memory**: 2048 MB (2 GB)
- **CPUs**: 2 cores
- **Network Interfaces**:
  - `eth0`: NAT interface (automatic, for Internet access)
  - `eth1`: Private network interface (VMnet11, IP: 10.10.0.1)

#### client1 - KVM Client Machine

```ruby
config.vm.define "client1" do |client1|
  client1.vm.box = "generic/centos9s"
  client1.vm.hostname = "client1.esi.dz"
  client1.vm.network "private_network", ip: "10.10.0.10"
  
  client1.vm.provider "vmware_desktop" do |v|
    v.vmx["displayName"] = "client1"
    v.memory = 1024                          # 1GB RAM
    v.cpus = 1                               # 1 CPU core
  end
  
  client1.vm.provision "shell", path: "./installClientKVM.sh"
end
```

**Key Features:**
- **Hostname**: `client1.esi.dz`
- **IP Address**: `10.10.0.10/24` (static on private network)
- **Memory**: 1024 MB (1 GB)
- **CPUs**: 1 core
- **Network Interfaces**:
  - `eth0`: NAT interface (automatic, for Internet access)
  - `eth1`: Private network interface (VMnet11, IP: 10.10.0.10)

### Provisioning Scripts

#### installServerKVM.sh - KVM Server Setup

This script performs the following operations:

1. **System Update** (`[1/6]`)
   - Updates all installed packages: `dnf -y update`

2. **Repository Configuration** (`[2/6]`)
   - Installs `dnf-plugins-core` for repository management
   - Enables CRB (CodeReady Builder) repository
   - Installs and configures EPEL (Extra Packages for Enterprise Linux) repository
   - Updates system packages

3. **KVM Installation** (`[3/6]`)
   - Installs core KVM packages:
     - `qemu-kvm`: QEMU hypervisor with KVM acceleration
     - `libvirt`: Virtualization API daemon and tools
     - `virt-install`: Command-line tool for creating VMs
     - `virt-manager`: GUI tool for VM management
     - `bridge-utils`: Network bridge utilities
     - `libvirt-daemon`: Libvirt daemon process
     - `libvirt-daemon-driver-qemu`: QEMU driver for libvirt
     - `libvirt-client`: Client libraries and tools

4. **Service Activation** (`[4/6]`)
   - Enables and starts `libvirtd` service: `systemctl enable --now libvirtd`
   - This service manages virtualization capabilities

5. **User Configuration** (`[5/6]`)
   - Adds the current user to the `libvirt` group
   - Allows non-root users to manage VMs
   - **Note**: Requires logout/login or new shell session to take effect

6. **Network Bridge Setup** (`[6/6]`)
   - Creates a network bridge `kvmbr0` on interface `eth1`
   - Configures static IP `10.10.0.1/24` on the bridge
   - Attaches physical interface `eth1` to the bridge as a slave
   - Restarts NetworkManager to apply changes
   - Uses `nmcli` (NetworkManager Command Line Interface) for configuration

**Network Bridge Configuration Details:**
- **Bridge Name**: `kvmbr0`
- **Physical Interface**: `eth1` (VMnet11 private network)
- **Bridge IP**: `10.10.0.1/24`
- **Purpose**: Allows KVM guest VMs to use the same network segment as the host

#### installClientKVM.sh - KVM Client Setup

This script performs the following operations:

1. **System Update**
   - Updates all installed packages: `dnf -y update`

2. **Repository Configuration**
   - Installs `dnf-plugins-core`
   - Enables CRB repository
   - Installs EPEL repository

3. **Client Tools Installation**
   - Installs client-side virtualization tools:
     - `virt-manager`: GUI application for managing VMs
     - `virt-viewer`: Tool for viewing VM consoles
     - `libvirt-client`: Client libraries and command-line tools
     - `openssh-clients`: SSH client tools for remote connection
     - `qemu-kvm`: QEMU/KVM support (for local testing)

4. **User Configuration**
   - Adds current user to `libvirt` group
   - Enables non-root VM management

**Purpose**: This client can connect to the kvm1 server remotely via SSH and manage VMs using virt-manager or libvirt tools.

## Step-by-Step Setup Guide

### Step 1: Verify Prerequisites

Check that all required software is installed:

```bash
# Check Vagrant version
vagrant --version

# Check VMware plugin
vagrant plugin list

# Check available boxes
vagrant box list

# Verify VMware is installed and accessible
# (Open VMware Workstation/Player GUI)
```

### Step 2: Navigate to Project Directory

```bash
cd /path/to/vagrant
# Or on Windows:
cd C:\Users\MICROSOFT PRO\vagrant
```

### Step 3: Initialize and Start VMs

Start the entire environment:

```bash
vagrant up
```

**What happens during `vagrant up`:**

1. Vagrant checks if the required box (`generic/centos9s`) exists locally
2. If not found, downloads the box from Vagrant Cloud
3. Creates VMware VM configurations based on Vagrantfile
4. Powers on the VMs in VMware
5. Configures networking (NAT and private network)
6. Waits for SSH to be available
7. Executes provisioning scripts (`installServerKVM.sh` and `installClientKVM.sh`)
8. Sets hostnames and network configurations

**Expected output:**
- Both VMs will be created and provisioned
- Installation process for KVM packages may take 5-10 minutes
- You'll see progress from the provisioning scripts

### Step 4: Verify VM Status

Check the status of your VMs:

```bash
vagrant status
```

Expected output:
```
Current machine states:

kvm1                      running (vmware_desktop)
client1                   running (vmware_desktop)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status <name>`.
```

### Step 5: Access the VMs

#### SSH Access

Connect to kvm1:
```bash
vagrant ssh kvm1
```

Connect to client1:
```bash
vagrant ssh client1
```

**Default credentials:**
- Username: `vagrant`
- Password: `vagrant`
- SSH key: Automatically configured by Vagrant

#### VMware GUI Access

1. Open VMware Workstation/Player
2. You'll see two VMs:
   - `kvm1`
   - `client1`
3. Right-click on a VM to:
   - Power On/Off
   - Suspend/Resume
   - Open Console (for GUI access)
   - Access Settings

### Step 6: Verify Network Connectivity

#### From client1 to kvm1:

```bash
# SSH to client1
vagrant ssh client1

# Test ping to kvm1
ping -c 4 10.10.0.1

# Test hostname resolution
ping -c 4 kvm1.esi.dz
```

#### From kvm1 to client1:

```bash
# SSH to kvm1
vagrant ssh kvm1

# Test ping to client1
ping -c 4 10.10.0.10

# Test hostname resolution
ping -c 4 client1.esi.dz
```

#### Verify KVM Bridge Configuration

On kvm1, check the bridge:

```bash
vagrant ssh kvm1

# Check bridge status
ip addr show kvmbr0

# Check bridge connections
brctl show kvmbr0

# Or using NetworkManager
nmcli connection show kvmbr0
```

**Expected output:**
- Bridge `kvmbr0` should have IP `10.10.0.1/24`
- Interface `eth1` should be attached to the bridge

### Step 7: Verify KVM Installation

On kvm1, verify KVM is properly installed:

```bash
vagrant ssh kvm1

# Check KVM module
lsmod | grep kvm

# Check libvirt service
systemctl status libvirtd

# Check libvirt version
libvirtd --version

# List virtualization capabilities
virsh capabilities

# Check connection to hypervisor
virsh list --all
```

### Step 8: Verify Client Tools Installation

On client1, verify client tools are installed:

```bash
vagrant ssh client1

# Check virt-manager installation
virt-manager --version

# Check libvirt client
virsh version

# Test SSH connectivity to kvm1
ssh vagrant@10.10.0.1
```

## Advanced Operations

### Re-run Provisioning Scripts

If you need to re-run provisioning without destroying VMs:

```bash
# Re-provision kvm1
vagrant provision kvm1

# Re-provision client1
vagrant provision client1

# Re-provision both
vagrant provision
```

### Reload VMs (Apply Configuration Changes)

After modifying Vagrantfile, reload VMs:

```bash
# Reload and re-provision
vagrant reload --provision

# Reload specific VM
vagrant reload kvm1
```

### Suspend and Resume VMs

Suspend (save current state):
```bash
vagrant suspend
# Or individually:
vagrant suspend kvm1
vagrant suspend client1
```

Resume:
```bash
vagrant resume
```

### Stop and Start VMs

Stop VMs (graceful shutdown):
```bash
vagrant halt
# Or individually:
vagrant halt kvm1
```

Start stopped VMs:
```bash
vagrant up
```

### Destroy VMs

**Warning**: This permanently deletes the VMs and all data:

```bash
# Destroy all VMs
vagrant destroy

# Destroy specific VM
vagrant destroy kvm1
```

### Access VM Files from Host

Vagrant creates a `.vagrant` directory containing:
- VM metadata
- SSH keys
- Provider-specific files

Location: `./.vagrant/machines/<vm-name>/vmware_desktop/`

### View VM Logs

Check Vagrant logs:
```bash
vagrant up --debug  # Verbose output during creation
```

Check libvirt logs (inside kvm1):
```bash
vagrant ssh kvm1
sudo journalctl -u libvirtd -f
```

## Networking Details

### Network Interfaces

Each VM has two network interfaces:

1. **eth0 (NAT Interface)**
   - Automatically configured by Vagrant/VMware
   - Provides Internet access
   - Uses VMware NAT network (usually VMnet8)
   - DHCP-assigned IP (typically 192.168.x.x)

2. **eth1 (Private Network Interface)**
   - Configured in Vagrantfile
   - Uses VMware private network (VMnet11)
   - Static IP configuration:
     - kvm1: `10.10.0.1/24`
     - client1: `10.10.0.10/24`

### VMnet11 Configuration

VMnet11 is a VMware virtual network switch:
- Type: Host-only or Private Network
- Purpose: Internal communication between VMs
- Host access: Typically not accessible from host (private)
- Configuration: Managed by VMware Workstation/Player

**To view/configure in VMware:**
1. Edit → Virtual Network Editor
2. Look for VMnet11
3. Configure subnet if needed (default: 10.10.0.0/24)

### Network Testing Commands

#### Test connectivity between VMs:
```bash
# From client1
ping 10.10.0.1
ping kvm1.esi.dz

# From kvm1
ping 10.10.0.10
ping client1.esi.dz
```

#### Test DNS resolution:
```bash
# On either VM
nslookup kvm1.esi.dz
nslookup client1.esi.dz
```

#### View network interfaces:
```bash
# Show all interfaces
ip addr show

# Show routing table
ip route show

# Show NetworkManager connections
nmcli connection show
```

### Firewall Configuration

CentOS 9 Stream uses `firewalld` by default. If connectivity issues occur:

```bash
# Check firewall status
sudo systemctl status firewalld

# Allow libvirt traffic (on kvm1)
sudo firewall-cmd --permanent --add-service=libvirt
sudo firewall-cmd --reload

# Or disable firewall for testing (not recommended for production)
sudo systemctl stop firewalld
sudo systemctl disable firewalld
```

## Infrastructure as Code (IaC) Concepts Demonstrated

This lab demonstrates several key Infrastructure as Code (IaC) concepts:

### 1. Declarative Infrastructure Definition
- **Vagrantfile** defines infrastructure using declarative syntax
- Infrastructure configuration stored as code in version control
- Reproducible and consistent environment deployments
- Human-readable infrastructure specifications

### 2. Automated Provisioning
- **Automated VM creation** and configuration through Vagrant
- **Shell script provisioning** for software installation and setup
- **Idempotent operations** - scripts can be run multiple times safely
- **Zero-touch deployment** from code to running infrastructure

### 3. Version Control and Collaboration
- Infrastructure definitions tracked in Git
- **Infrastructure changes** managed through standard development workflows
- **Collaborative development** of infrastructure configurations
- **Rollback capabilities** through version control history

### 4. Environment Consistency
- **Identical environments** across development, testing, and production
- **Elimination of configuration drift** through code-defined infrastructure
- **Standardized deployments** reducing manual errors
- **Documentation through code** - infrastructure is self-documenting

### 5. Virtualization Management
- **KVM hypervisor** deployment and configuration as code
- **Network topology** defined declaratively (bridges, private networks)
- **Resource allocation** (CPU, RAM, storage) specified in configuration
- **Multi-VM orchestration** with defined relationships

### 6. Configuration Management
- **Automated software installation** via provisioning scripts
- **Service configuration** and startup automation
- **Network bridge setup** and IP address assignment
- **User and permission management** through scripts

### 7. Infrastructure Testing and Validation
- **Rapid environment creation** for testing infrastructure changes
- **Destroy and recreate** capabilities for clean testing
- **Infrastructure validation** through automated deployment
- **Continuous integration** of infrastructure changes

## Additional Resources

### Official Documentation

- **Vagrant**: https://www.vagrantup.com/docs
- **KVM**: https://www.linux-kvm.org/page/Documents
- **Libvirt**: https://libvirt.org/docs.html
- **VMware Workstation**: https://docs.vmware.com/en/VMware-Workstation-Pro/
- **CentOS 9 Stream**: https://www.centos.org/centos-stream/

### Useful Commands Reference

#### Vagrant Commands
```bash
vagrant up              # Start VMs
vagrant halt            # Stop VMs
vagrant destroy         # Delete VMs
vagrant suspend         # Suspend VMs
vagrant resume          # Resume VMs
vagrant reload          # Reboot VMs
vagrant provision       # Re-run provisioning
vagrant ssh <name>      # SSH to VM
vagrant status          # Show VM status
vagrant box list        # List available boxes
vagrant box update      # Update boxes
```

#### KVM/Libvirt Commands
```bash
virsh list --all        # List all VMs
virsh dominfo <vm>      # VM information
virsh start <vm>        # Start VM
virsh shutdown <vm>     # Shutdown VM
virsh destroy <vm>      # Force stop VM
virt-manager            # GUI tool
virt-install            # Create new VM
```

#### Network Commands
```bash
ip addr show            # Show IP addresses
ip route show           # Show routing table
nmcli connection show   # Show NetworkManager connections
nmcli device status     # Show device status
brctl show              # Show bridges
```

## Conclusion

This lab provides a complete Infrastructure as Code (IaC) environment setup using modern tools. You've learned how to:

- Use Vagrant for infrastructure as code
- Deploy and configure KVM hypervisor
- Set up network bridges and private networks
- Provision VMs with automated scripts
- Manage multi-VM environments
- Troubleshoot common issues

The environment is now ready for:
- Creating and managing additional KVM guest VMs
- Testing virtualization concepts
- Learning Infrastructure as Code (IaC) principles
- Developing cloud infrastructure skills

## License and Credits

- **Author**: Based on configuration by Idriss Ziadi
- **Scripts**: Adapted for CentOS 9 Stream
- **Box Provider**: Generic Cloud Images (generic/centos9s)

## Support and Contributions

For issues or improvements:
1. Check the troubleshooting section
2. Review Vagrant and VMware logs
3. Consult official documentation
4. Test in a clean environment

---


