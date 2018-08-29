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
        - [Edit `inventory/host_vars/*.yml`](#edit-inventoryhost_varsyml)
- [Install](#install)
- [Uninstall](#uninstall)
- [Manually bind DPDK port](#manually-bind-dpdk-port)
- [Memo](#memo)

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

- Let's send public ssh key from ansible host to nodes which you want to install
    - Please chenge `password` to the password which was set by you
    - Please cheange `root@host_ip` to the root@hostname which was exist and can be accessed. (Please make sure that root can ssh into the host.)

```sh
$ cat inventory/keys/id_rsa.pub | ssh root@host_ip 'mkdir -p .ssh && cat >> .ssh/authorized_keys'
```

### 4. Edit two config files
#### Edit `inventory/inventory.ini`

Add nostname or IP address under `[network-setup]` group.  
Like  

```sh
node-1 ansible_ssh_host=10.1.14.14 ip=10.1.14.14
node-2 ansible_ssh_host=10.1.14.86 ip=10.1.14.86

[kube-master]
node-1
node-2

[etcd]
node-1

[kube-node]
node-1
node-2

[network-setup]
node-1
node-2
```

#### Edit `inventory/group_vars/network-setup.yml`

- **ovs_type**: `ovs` or `dpdk`
    - `ovs`: Install pure ovs without dpdk
    - `dpdk`:Install dpdk + ovs
- **Hugepage setting**
    - `default_hugepagesz`: 1G/2M (Need check `/sys/devices/system/node/node0/hugepages/hugepages-*` path)
        - 1G: Check the path `/sys/devices/system/node/node0/hugepages/hugepages-1048576kB/`
        - 2M: Check the path `/sys/devices/system/node/node0/hugepages/hugepages-2048kB/`
    - `nr_hugepages`: Allocate a number of Huge pages

- **ovs_access_mode**: `public` or `private`
    - `public`: Please also set **`ovs_version`**
    - `private`: Please also set **`ovs_tar_path`** and **`ovs_folder_name`**(Your `ovs_tar_path` is on ansible host, and `ovs_folder_name` is the folder name after extracting)
- **kernel_module** option: `igb_uio`

### Edit `inventory/host_vars/*.yml`

- **dpdk_init**: for `other_config:dpdk-init=true or try`
- **dpdk_socket_mem**: for `other_config:dpdk-socket-mem="1024,1024"`
- **cpu_mask**: for `other_config:pmd-cpu-mask=0x2`
- **max_idle**: for `other_config:max-idle=30000`

```sh
$ cp inventory/host_vars/localhost.yml inventory/host_vars/node-1.yml
$ cp inventory/host_vars/localhost.yml inventory/host_vars/node-2.yml
```

## Install

```sh
$ make network-setup
```
or  
```sh
$ ansible-playbook -e "@inventory/group_vars/network-setup.yml" --inventory inventory/inventory.ini network-setup.yml
```

## Uninstall

```sh
$ ansible-playbook -e "@inventory/group_vars/network-setup.yml" --inventory inventory/inventory.ini network-setup-reset.yml
```

## Manually bind DPDK port

```sh
$ /usr/src/dpdkbind.sh enp0s10,enp0s17
```

## Memo
- Vagrant version:
    - ✅  v2.0.1
    - ❎  v2.1.2
    - ❎  v1.8.1
