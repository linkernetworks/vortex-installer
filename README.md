footer: Che-Chia David Chang @ Linkernetworks 2018
slidenumbers: true

# Vortex Installer

### Deploy Vortex with kubespray and ansible

---

# Quick Start

- Deploy a vortex on localhost with Vagrant and virtualbox
- Not for production. Test purpose only.
  - [virtualbox](https://www.virtualbox.org/wiki/Downloads)
  - [vagrant](https://www.vagrantup.com/downloads.html)

```bash
git clone https://github.com/linkernetworks/vortex-installer.git

cd vortex-installer && ./scripts/deploy-in-vagrant
```

---

# Step by Step Details

- Install Prerequisites
- Edit config file
- Make sure servers are ready (Bare metal / Cloud servers)
  - Prepare ssh-key to access servers
- Install

---

# Install Prerequisites

- [Ansible](https://www.ansible.com/): prepare and run installer scripts based on python
  - python and pip
  - jq: json processor
  - yq: yaml processor

```
make ansible
```
---

# Edit config file

Edit `config/config.yml`, setup IPs of master and minion nodes.

```
cp config/taipei.yml config/config.yml
```

---

# Start Install

```
make all
```

---

# GlusterFS

[heketi on kubernetes](https://github.com/heketi/heketi/tree/master/extras/kubernetes)
