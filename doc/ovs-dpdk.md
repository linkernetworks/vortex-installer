# Install OVS or DPDK-OVS

> Deploy OVS or DPDK-OVS with ansible independently

## Table of Contents
- [Before using ansible](#before-using-ansible)
    - [1. Make Sure Servers are Ready](#1-make-sure-servers-are-ready)
    - [2. Get project and install Ansible on ansible host](#2-get-project-and-install-ansible-on-ansible-host)
    - [3. Prepare ssh-key for root](#3-prepare-ssh-key-for-root)
    - [4. Edit two config files](#4-edit-two-config-files)
        - [Edit `inventory/inventory.ini`](#edit--inventory-inventoryini-)
        - [Edit `inventory/group_vars/network-setup.yml`](#edit--inventory-group-vars-network-setupyml-)
- [Install](#install)

## Before using ansible
### 1. Make Sure Servers are Ready
- Supported OS: Ubuntu 16.04
- All Servers can be accessed.

### 2. Get project and install Ansible on ansible host
- **Get project**
```sh
$ git clone https://github.com/linkernetworks/vortex-installer.git
$ cd vortex-installer
```

- **Install Ansible**  
There are two methods you could use.  

- First method:
```sh
$ make ansible
```

- Second method:

```sh
$ sudo apt-add-repository ppa:ansible/ansible
$ sudo apt-get update && sudo apt-get install ansible -y
```

### 3. Prepare ssh-key for root
- On ansible host
```sh
$ cd vortex-installer
$ mkdir inventory/keys/ && ssh-keygen -t rsa -b 4096 -C "" -f  inventory/keys/id_rsa -q -N ''
```

- Let's send public ssh key fron ansible host to nodes which you want to install
    - Please chenge `password` to the password which was set by you
    - Please cheange `root@host_ip` to the root@hostname which was exist and can be accessed. (Please make sure that root can ssh into the host.)
```sh
$ cat inventory/keys/id_rsa.pub | sshpass -p password ssh root@host_ip  'mkdir -p .ssh && cat >> .ssh/authorized_keys'
```

### 4. Edit two config files
#### Edit `inventory/inventory.ini`
Add nostname or IP address under `[network-setup]` group.  
Like  
```sh
[network-setup]
10.1.15.14
10.1.15.15
```

#### Edit `inventory/group_vars/network-setup.yml`
- **ovs_type**: `ovs` or `dpdk`
    - If `ovs`: Install pure ovs without dpdk
    - If `dpdk`:Install dpdk + ovs
- **ovs_access_mode**: `public` or `private`
    - If `public`: Please set **`ovs_version`**
    - If `private`: Please set **`ovs_tar_path`** and **`ovs_folder_name`**(Your `ovs_tar_path` is on ansible host, and `ovs_folder_name` is the folder name after extracting)
- **dpdk_iface**: Need to set the Network interface of nodes.


## Install
```sh
$ ansible-playbook -e "@inventory/group_vars/network-setup.yml" --inventory inventory/inventory.ini network-setup.yml
```
