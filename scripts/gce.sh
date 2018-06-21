#!/bin/bash
#
# Test installer on gce
# Prerequisites:
#   gcloud login

set -o errexit
set -o pipefail

IMAGE_FAMILY="ubuntu-1604-lts" ZONE="asia-east1-a"
MACHINE_TYPE="n1-standard-2"
PACKAGE_NAME="aurora-installer.zip"

gcloud::engine::inject_sshkey(){
  local node_name=$1

  if [[ ! -f ${SSH_KEY_PATH} ]]; then
    ssh-keygen -f ${SSH_KEY_PATH} -t rsa -N '' 
  fi

  gcloud compute scp ${SSH_KEY_PATH}.pub ${node_name}:.
  gcloud compute ssh ${node_name} --command "sudo mkdir -p /root/.ssh/ \
    && sudo bash -c 'cat id_rsa.pub >> /root/.ssh/authorized_keys'"
}

gcloud::engine::locale(){
  local node_name=$1
  gcloud compute ssh ${node_name} --command "sudo bash -c 'echo LC_ALL=en_US.UTF-8 >> /etc/environment' \
    && sudo bash -c 'echo LANG=en_US.UTF-8 >> /etc/environment'"
}

gcloud::engine::up(){

  for (( i=0 ; i<${#NODE_NAMES[@]} ; i++)); do
    local node_name=${NODE_NAMES[$i]}
    local disk_name="${node_name}-glusterfs-dev"
    local private_ip="${NODES[$i]}"

    echo "[GCE] Creating node: ${node_name} disk: ${disk_name} ip: ${private_ip}"

    gcloud compute disks create ${disk_name} \
      --size=100 \
      --type=pd-standard \
      --zone=${ZONE} 
    gcloud compute instances create ${node_name} \
      --boot-disk-device-name="${node_name}-boot" \
      --boot-disk-size=100 \
      --machine-type=${MACHINE_TYPE} \
      --disk "name=${disk_name},device-name=${disk_name},mode=rw,boot=no" \
      --image-project "ubuntu-os-cloud" \
      --image-family=${IMAGE_FAMILY} \
      --zone=${ZONE} \
      --private-network-ip=${private_ip} \
      --tags=allow-cv-server-service,allow-all #FIXME remove allow-all

    sleep 30 #FIXME: wait for ssh server up

    # Can't generate key on master without gcloud key
    gcloud::engine::inject_sshkey ${node_name}
    gcloud::engine::locale ${node_name}
  done
  
}

gcloud::engine::delete(){
  for (( i=0 ; i<${#NODE_NAMES[@]} ; i++)); do
    gcloud compute instances delete ${NODE_NAMES[$i]} \
      --delete-disks=all \
      --quiet
  done
}

system::package(){
  rm -f *.zip
  rm -rf aurora-installer && mkdir aurora-installer
  # --exclude keys/id_rsa
  rsync -a . aurora-installer/ --exclude *.git* --exclude aurora-installer --exclude *.vmdk --exclude *.vagrant --exclude */.DS_Store
  PACKAGE_NAME="$(pwd)/aurora-installer.zip"
	zip -qr -X ${PACKAGE_NAME} aurora-installer
}

gcloud::engine::install(){
  if [[ -f ${PACKAGE_NAME} ]]; then
    echo "[GCE] Scp ${PACKAGE_NAME} to ${NODE_NAMES[0]}."
    gcloud compute scp ${PACKAGE_NAME} ${NODE_NAMES[0]}:.
    gcloud compute ssh ${NODE_NAME[0]} --command 'sudo apt-get install -y unzip make
      && cd aurora-installer \
	    && sudo apt-get upgrade && apt-get update \
	    && sudo apt-get install -y python3 python3-pip jq \
	    && sudo pip3 install yq ansible netaddr \
	    && sudo pip3 install -r kubespray/requirements.txt \
      && make cluster'
  else
    echo "[GCE] Error: installer package file not found."
    exit 1
  fi
}
