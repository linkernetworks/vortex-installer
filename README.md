footer: ©Linkernetworks 2018  
slidenumbers: true  

# Vortex Installer

> Deploy Vortex with kubespray and ansible

## Table of Contents

- [Quick Start for Testing](#quick-start-for-testing)
- [Step by Step for Production installation](#step-by-step-for-production-installation)
  - [Manchine Requirements](#manchine-requirements)
  - [Preparation work on _each host_](#preparation-work-on-each-host)
    - [DNS server setting](#dns-server-setting)
    - [SSH config setting](#ssh-config-setting)
    - [Root password setting](#root-password-setting)
  - [On _Ansible Control Machine_, install ansible and prepare ssh-key for root](#on-ansible-control-machine-install-ansible-and-prepare-ssh-key-for-root)
    - [1. Download repository and install ansible](#1-download-repository-and-install-ansible)
    - [2. Prepare ssh-key for root](#2-prepare-ssh-key-for-root)
  - [On _Ansible Control Machine_, edit config file](#on-ansible-control-machine-edit-config-file)
    - [1. Edit `inventory/inventory.ini`](#1-edit-inventoryinventoryini)
    - [2. Edit `inventory/group_vars/network-setup.yml`](#2-edit-inventorygroup_varsnetwork-setupyml)
    - [3. Edit `inventory/host_vars/*.yml`](#3-edit-inventoryhost_varsyml)
  - [On _Ansible Control Machine_, start install](#on-ansible-control-machine-start-install)
    - [Install NFS server on _one of k8s master_](#install-nfs-server-on-one-of-k8s-master)
    - [Install Helm & setup vortex on _one of k8s master_](#install-helm--setup-vortex-on-one-of-k8s-master)
      - [1. Download Helm binary file](#1-download-helm-binary-file)
      - [2. Setup vortex](#2-setup-vortex)
        * [1. Download vortex repository](#1-download-vortex-repository)
        * [2. Get token](#2-get-token)
        * [3. Edit `deploy/helm/config/production.yaml`](#3-edit-deployhelmconfigproductionyaml)
        * [4. Check pods in kube-system namespace](#4-check-pods-in-kube-system-namespace)
        * [5. Deploy vortex](#5-deploy-vortex)
        * [6. Check vortex](#6-check-vortex)
      - [3. Update vortex](#3-update-vortex)
      - [4. Delete vortex](#4-delete-vortex)
      - [5. Vortex Done](#5-vortex-done)
  - [Reset cluster](#reset-cluster)
- [Check Kubernetes Cluster](#check-kubernetes-cluster)
- [Other Details](#other-details)

## Quick Start for Testing

- Deploy a vortex on localhost with Vagrant and VirtualBox
- Not for production. Test purpose only.
  - [Install Virtualbox](https://www.virtualbox.org/wiki/Downloads)
  - [Install Vagrant](https://www.vagrantup.com/downloads.html)

```bash
git clone https://github.com/linkernetworks/vortex-installer.git

cd vortex-installer && ./scripts/deploy-in-vagrant
```

---

## Step by Step for Production installation
### Manchine Requirements

- Supported OS: Ubuntu 16.04
- Hareware
  - RAM: at least 16 G
  - CPU: 8 cores
- Prepare at least 2 hosts with Ubuntu 16.04
  - One for Ansible Control Machine
  - At least one for Ansible Managed Node to deploy vortex


### Preparation work on _each host_
#### DNS server setting

Edit `/etc/network/interfaces` and reboot every host.  

```sh
dns-nameservers 8.8.8.8
```

#### SSH config setting

1. Edit `/etc/ssh/sshd_config` and update `PermitRootLogin` option to `PermitRootLogin yes`.
2. restart ssh service

```sh
sudo service ssh restart
```

#### Root password setting

```sh
sudo -s
passwd
```

### On _Ansible Control Machine_, install ansible and prepare ssh-key for root
#### 1. Download repository and install ansible

```sh
sudo apt-get install make
cd ~/ && git clone https://github.com/linkernetworks/vortex-installer.git
cd ~/vortex-installer/
make ansible
```

#### 2. Prepare ssh-key for root

1. generate ssh-key  

```sh
mkdir inventory/keys/ && ssh-keygen -t rsa -b 4096 -C "" -f  inventory/keys/id_rsa -q -N ''
```

2. Put ssh public key to each Ansible Managed Node   

```sh
cat inventory/keys/id_rsa.pub | ssh root@host-ip 'mkdir -p .ssh && cat >> .ssh/authorized_keys'
```

eg.  

```sh
cat inventory/keys/id_rsa.pub | ssh root@192.168.1.2 'mkdir -p .ssh && cat >> .ssh/authorized_keys'
cat inventory/keys/id_rsa.pub | ssh root@192.168.1.3 'mkdir -p .ssh && cat >> .ssh/authorized_keys'
... (for all bare metal servers)
```

3. Test ssh connection  

```sh
ssh root@host-ip -i inventory/keys/id_rsa
```

eg.  

```sh
ssh root@192.168.1.2 -i inventory/keys/id_rsa
```

### On _Ansible Control Machine_, edit config file
#### 1. Edit `inventory/inventory.ini`

For example:  

```
node-1 ansible_ssh_host=10.1.14.14 ip=10.1.14.14
[kube-master]
node-1

[etcd]
node-1

[kube-node]
node-1

[network-setup]
node-1
```

#### 2. Edit `inventory/group_vars/network-setup.yml`

**0. Check on Hugepage each _Ansible Managed Node_**

```sh
ls /sys/devices/system/node/node0/hugepages/hugepages-1048576kB/
ls /sys/devices/system/node/node0/hugepages/hugepages-2048kB/
```

**1. Edit `inventory/group_vars/network-setup.yml`**

- If there is no `/sys/devices/system/node/node0/hugepages/hugepages-1048576kB/` path, update the config as the followings:

```
default_hugepagesz: 2M
nr_hugepages: 1024
```

- Update ovs_access_mode
    - If ovs_access_mode is public, you need to setup `ovs_version` option.
    - If ovs_access_mode is private, you need to setup `ovs_tar_path` & `ovs_folder_name` options.

#### 3. Edit `inventory/host_vars/*.yml`

```sh
$ cp inventory/host_vars/localhost.yml inventory/host_vars/host.yml
```

eg.  

```sh
$ cp inventory/host_vars/localhost.yml inventory/host_vars/node-1.yml
$ cp inventory/host_vars/localhost.yml inventory/host_vars/node-2.yml
```

### On _Ansible Control Machine_, start install

- Use the followings for installing DPDK-OVS & Kubernetes cluster

```sh
make vortex-dev
```

P.S. If you want to install DPDK-OVS & Kubernetes cluster step by step, please following these steps:  

```sh
# install DPDK-OVS
make network-setup

# install Kubernetes cluster
make cluster-dev
```

### Install NFS server on _one of k8s master_

```sh
# Install NFS Server
sudo apt-get install -qqy nfs-kernel-server
sudo mkdir -p /nfsshare/influxdb /nfsshare/mongodb /nfsshare/user
echo "/nfsshare *(rw,sync,no_root_squash)" | sudo tee /etc/exports
sudo exportfs -r
sudo showmount -e
```

### Install Helm & setup vortex on _one of k8s master_
#### 1. Download Helm binary file

```
curl -L https://storage.googleapis.com/kubernetes-helm/helm-v2.9.1-linux-amd64.tar.gz > helm-v2.9.1-linux-amd64.tar.gz && tar -zxvf helm-v2.9.1-linux-amd64.tar.gz && chmod +x linux-amd64/helm && sudo mv linux-amd64/helm /usr/local/bin/helm
```

#### 2. Setup vortex
##### 1. Download vortex repository

```sh
cd ~/ && gt clone https://github.com/linkernetworks/vortex.git
cd ~/vortex/
```

##### 2. Get token

**1 Create secret**

```
kubectl create secret docker-registry dockerhub-token --docker-server=https://mydockerhub.url/ --docker-username=root --docker-password=<password> --docker-email=vortex@vortex.com
```

**2 Get secrets & check `dockerconfigjson` value**

```
kubectl get secrets dockerhub-token -o yaml
#  .dockerconfigjson: eyJhdXRocyI6eyJodHRwczovL2RvY2tlcmh1Yi5wdy8iOnsidXNlcm5hbWUiOiJyb290IiwicGFzc3dvcmQiOiJ2b3J0ZXg1ODIwIiwiZW0haWwiOiJ2b3J0ZXhAbGlua2VybmV0d29ya3MuY29tIiwiYXV0aCI6ImNtOXZkRHAyYjNKMFpYZzFPREl3In19fQ==
```

**3 Delete secrets**

```
kubectl delete secrets dockerhub-token
```

##### 3. Edit `deploy/helm/config/production.yaml`

eg.  

```diff
-      dockerToken: "you need to replace this token manually"
+      dockerToken: "eyJhdXRocyI6eyJodHRwczovL2RvY2tlcmh1Yi5wdy8iOnsidXNlcm5hbWUiOiJyb290IiwicGFzc3dvcmQiOiJ2b3J0ZXg1ODIwIiwiZW0haWwiOiJ2b3J0ZXhAbGlua2VybmV0d29ya3MuY29tIiwiYXV0aCI6ImNtOXZkRHAyYjNKMFpYZzFPREl3In19fQ=="
-        smtpPassword: "you need to replace this token manually"
+        smtpPassword: "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"
-        nfsServer: 10.1.14.86
+        nfsServer: 192.168.1.2
-        nfsServer: 10.1.14.86
+        nfsServer: 192.168.1.2
```

##### 4. Check pods in kube-system namespace

```sh
kubectl get pod -n kube-system
```

##### 5. Deploy vortex

```sh
make apps.launch-prod
```

##### 6. Check vortex

```sh
kubectl get pod -n vortex
```

#### 3. Update vortex
After edit `deploy/helm/config/production.yaml`, just exec the followings cmd.  

```sh
make apps.upgrade-prod
```

#### 4. Delete vortex

```sh
make apps.teardown-prod
```

#### 5. Vortex Done

Access https://host-ip:32767 (eg. https://192.168.1.2:32767 ) via the browser.  

### Reset cluster

On _Ansible Control Machine_  

- Reset k8s cluster

```sh
make reset
```

- Reset DPDK-OVS

```sh
ansible-playbook -e "@inventory/group_vars/network-setup.yml" --inventory inventory/inventory.ini network-setup-reset.yml
```

---

## Check Kubernetes Cluster

- ssh to _one of k8s master_

```sh
$ cat /etc/lsb-release
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=16.04
DISTRIB_CODENAME=xenial
DISTRIB_DESCRIPTION="Ubuntu 16.04.5 LTS"

$ uname -msr
Linux 4.15.0-34-generic x86_64

$ cat /proc/meminfo | grep Huge
AnonHugePages:         0 kB
ShmemHugePages:        0 kB
HugePages_Total:       8
HugePages_Free:        8
HugePages_Rsvd:        0
HugePages_Surp:        0
Hugepagesize:    1048576 kB

$ cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
performance
performance
performance
performance
performance
performance
performance
performance
performance
performance
performance
performance

$ sudo ovs-vsctl show
850c9716-cd8e-499f-a071-efe225a8fe20
    ovs_version: "2.9.2"

$ ls /usr/src/dpdk-stable-17.11.4/

$ systemctl status ovsdb-server.service
● ovsdb-server.service - Open vSwitch Database Unit
   Loaded: loaded (/etc/systemd/system/ovsdb-server.service; enabled; vendor preset: enabled)
   Active: active (running) since 二 2018-09-04 11:34:45 CST; 1min 17s ago

$ systemctl status ovs-vswitchd.service
● ovs-vswitchd.service - Open vSwitch Forwarding Unit
   Loaded: loaded (/etc/systemd/system/ovs-vswitchd.service; enabled; vendor preset: enabled)
   Active: active (running) since 二 2018-09-04 11:34:46 CST; 1min 23s ago

$ kubectl get pod -n kube-system

$ kubectl get pod -n vortex

$ kubectl get secret dockerhub-token --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode

```

---

## Other Details

- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [GlusterFS](https://docs.gluster.org/en/v3/)
- [Heketi for Kubernetes](https://github.com/heketi/heketi/tree/master/extras/kubernetes)

