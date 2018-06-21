Ansible
===

Deploy aurora-installer with ansible

# Prerequisites

Install packages:

- python
- pip
- ansible: executor to run ansible-playbook
- jq: json processor
- yq: yaml processor

```
make ansible
```

# Quick Start on localhost with Vagrant and virtualbox

Must have virtualbox and vagrant on localhost

```
make vagrant-plugin
make vagrant all
```

# Ansible

**Edit config**
In `config/config.yml`, setup IPs of master and minion nodes.

Or use template:
```
cp config/taipei.yml config/config.yml
```

**Start**
make prefight kubespray glusterfs

# GlusterFS

[heketi on kubernetes](https://github.com/heketi/heketi/tree/master/extras/kubernetes)

# Troubleshoot

The following usage of ansible playbook will fail.
```
- import_playbook: ../kubespray/cluster.yml
```
