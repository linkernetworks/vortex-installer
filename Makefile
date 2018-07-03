clean:
	rm -rf *.log *.zip *.retry aurora-installer

submodule:
	git submodule init && git submodule update

.PHONY: ansible
UNAME := $(shell uname)
PORT := $(shell which port)
BREW := $(shell which brew)
ifeq ($(UNAME), Linux)

ansible: submodule
	sudo apt-get upgrade -y && \
		sudo apt-get update && \
		sudo apt-get install -y python3 python3-pip jq
	export LC_ALL=C && \
		sudo pip3 install --upgrade pip && \
		sudo pip3 install --upgrade yq ansible netaddr cryptography && \
		sudo pip3 install -r kubespray/requirements.txt

else ifeq ($(UNAME), Darwin)

ansible: submodule
	if [[ "$(PORT)" != "" ]]; then sudo port install jq coreutils; fi
	if [[ "$(BREW)" != "" ]]; then brew install jq coreutils; fi
	rehash
	sudo pip3 install --upgrade yq ansible netaddr cryptography && \
	sudo pip3 install -r kubespray/requirements.txt

endif

# infrastructure
.PHONY: vagrant
vagrant:
	cp config/vagrant.yml config/config.yml && vagrant up

vagrant-destroy:
	vagrant destroy -f

vagrant-plugin:
	vagrant plugin install vagrant-vbguest vagrant-disksize

gce:
	cp config/gce.yml config/config.yml && ./scrtips/gce-up

# all: main target workflow
all: submodule preflight cluster glusterfs

config-kubespray:
	mkdir -p kubespray/inventory/vortex 
	cp -r inventory/group_vars kubespray/inventory/vortex
	cp inventory/inventory.ini kubespray/inventory/vortex/hosts.ini

# preflight check and library install
.PHONY: preflight
preflight:
	ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook \
		--inventory inventory/preflight/inventory.ini \
		preflight.yml 2>&1 | tee aurora-$(shell date +%F-%H%M%S)-preflight.log

# deploy kubernetes with kubespray
# FIXME make cluster will cause tty pipe line error. Use bash script instead.
.PHONY: cluster
cluster: config-kubespray
	ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook \
		-e "@inventory/group_vars/glusterfs.yml" \
		-e "@inventory/group_vars/all.yml" \
		-e "@inventory/group_vars/k8s-cluster.yml" \
		--inventory inventory/inventory.ini \
		cluster.yml

.PHONY: scale
scale: config-kubespray
	ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook \
		--inventory inventory/inventory.ini \
		kubespray/scale.yml 2>&1 | tee aurora-$(shell date +%F-%H%M%S)-scale.log

# deploy glusterfs with heketi on kubernetes
.PHONY: glusterfs
glusterfs:
	ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook \
		-e "@inventory/group_vars/glusterfs.yml" \
		--inventory inventory/inventory.ini \
		glusterfs.yml 2>&1 | tee aurora-$(shell date +%F-%H%M%S)-glusterfs.log

aurora: preflight
	ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook \
		--inventory inventory/inventory.ini \
		aurora.yml 2>&1 | tee aurora-$(shell date +%F-%H%M%S)-aurora.log

network-setup: config-kubespray
	ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook \
		-e "@inventory/group_vars/network-setup.yml" \
		--inventory inventory/inventory.ini \
		network-setup.yml 2>&1 | tee aurora-$(shell date +%F-%H%M%S)-network-setup.log

# reset kubernetes cluster with kubespray
.PHONY: reset
reset: config-kubespray
	ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook \
		-e reset_confirmation=yes \
		--inventory inventory/inventory.ini \
		kubespray/reset.yml 2>&1 | tee aurora-$(shell date +%F-%H%M%S)-reset.log
