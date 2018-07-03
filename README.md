footer: ©Linkernetworks 2018
slidenumbers: true

# Vortex Installer

### Deploy Vortex with kubespray and ansible

---

# Quick Start for Testing

- Deploy a vortex on localhost with Vagrant and virtualbox
- Not for production. Test purpose only.
  - [Install Virtualbox](https://www.virtualbox.org/wiki/Downloads)
  - [Install Vagrant](https://www.vagrantup.com/downloads.html)

```bash
git clone https://github.com/linkernetworks/vortex-installer.git

cd vortex-installer && ./scripts/deploy-in-vagrant
```

---

# Step by Step for Production

- Make sure servers are ready (Bare metal / Cloud servers)
  - Prepare ssh-key to access servers
- Install Prerequisites
- Edit config file
- Install

---

# Make Sure Servers are Ready 

- Supported machine types
  - Bare metal servers / VMs
  - Cloud servers: GCE, AWE...
- Supported OS: Ubuntu 16.04
- Hardware requirements:
  - One additional storage device (ex. /dev/sdb)

---

# Prepare ssh-key for root

- Vortex Installer use ssh key to access server. Ask your system admin or prepare key by

```
ssh-keygen -b 2048 -f id_rsa -t rsa -q -N ''

cat id_rsa.pub | ssh root@node-1 'mkdir -p .ssh && cat >> .ssh/authorized_keys'
cat id_rsa.pub | ssh root@node-2 'mkdir -p .ssh && cat >> .ssh/authorized_keys'

...(for all bare metal servers)

# Test ssh connection
ssh root@node-1 -i id_rsa
```

---

# Install Prerequisites

- [Ansible](https://www.ansible.com/): prepare and run installer scripts based on python
  - python and pip
  - jq: json processor, yq: yaml processor

```
# On node-1 server

git clone https://github.com/linkernetworks/vortex-installer.git

cd vortex-installer && make ansible
```

---

# Edit config file

- Edit config/config.yml
  - setup IPs of master and minion nodes.

```
vim config/config.yml

# Use 5g preset template
cp config/5g.yml config/config.yml
```

---

# Edit Config File

- The following config is High Availibility with 3 masters

```
kubernetes:
  version: 1.9.7
  cluster:
    masters:
    - node:
        hostname: node-1
        ip: 192.168.26.11
    - node:
        hostname: node-2
        ip: 192.168.26.12
    - node:
        hostname: node-3
        ip: 192.168.26.13
    nodes:
```

---

# Start Install

- Clone kubespray from github
- Run preflight checks
- Run scripts
  - Kubespray
  - GlusterFS
- It takes about 15~30 mins to complete, depends on network speed. Most time downloading kubernetes images.

```
make all
```

---

# Check Kubernetes Cluster

- ssh to node-1
- control cluster with kubectl

```
ssh root@node-1 -i id_rsa

kubectl get nodes

NAME     STATUS    AGE       VERSION
node-1   Ready     1d        v1.10.3

```

---

# Other Details

- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [GlusterFS](https://docs.gluster.org/en/v3/)
- [Heketi for Kubernetes](https://github.com/heketi/heketi/tree/master/extras/kubernetes)

---

# End
