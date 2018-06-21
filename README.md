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

[virtualbox](https://www.virtualbox.org/wiki/Downloads)

[vagrant](https://www.vagrantup.com/downloads.html)

Install vagrant plugins, bring up vms, run all ansible scritps by
```
make vagrant-plugin vagrant all
```

# Bare metal / Cloud servers

Edit config
In `config/config.yml`, setup IPs of master and minion nodes.

Or use template:
```
cp config/taipei.yml config/config.yml
```

Start
```
make all
```

# GlusterFS

[heketi on kubernetes](https://github.com/heketi/heketi/tree/master/extras/kubernetes)
