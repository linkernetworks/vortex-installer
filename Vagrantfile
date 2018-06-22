# -*- mode: ruby -*-
# vi:set ft=ruby sw=2 ts=2 sts=2:
# Create vm
# node-1: 192.168.26.11
# node-2: 192.168.26.12
# node-3: 192.168.26.13
# ...

NUM_NODE = 3
NODE_IP_NW = "192.168.26."
DISK_SIZE = "100" # 100MB
PRIVATE_KEY_PATH = "inventory/keys"
PRIVATE_KEY = "#{PRIVATE_KEY_PATH}/id_rsa"

Vagrant.configure("2") do |config|

  # linkernetworks/aurora-base is a virtualbox with pre-install pacakges:
  #   docker-ce=17.12.1~ce-0~ubuntu 
  #   pip, glusterfs
  #config.vm.box = "linkernetworks/aurora-base"
  #config.vm.box_version = "0.0.6"

  config.vm.box = "ubuntu/xenial64"
  config.vm.box_version = "20180615.0.0"

  config.vm.box_check_update = false
  config.vbguest.auto_update = false

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048  # 1536 at least for kubespray
    vb.cpus = 2
  end #vb

  # Generate ssh key at .ssh
  unless File.exist?("#{PRIVATE_KEY}")
    `mkdir -p #{PRIVATE_KEY_PATH} && ssh-keygen -b 2048 -f #{PRIVATE_KEY} -t rsa -q -N ''`
  end
  config.vm.provision "file", source: "#{PRIVATE_KEY}.pub", destination: "id_rsa.pub"
  config.vm.provision "append-public-key", :type => "shell", inline: "cat id_rsa.pub >> ~/.ssh/authorized_keys"

  config.vm.provision "shell", privileged: true, inline: <<-SHELL
    apt-get update && apt-get install -y python make
  SHELL

  #config.vm.provision "setup-hosts", :type => "shell", :path => "../scripts/vagrant/setup-hosts" do |s|
  #  s.args = ["enp0s8"]
  #end
  
  (1..NUM_NODE).each do |i|
    config.vm.define "node-#{i}" do |node|

      node.vm.hostname = "node-#{i}"
      node_ip = NODE_IP_NW + "#{10 + i}"
      node.vm.network :private_network, ip: node_ip

      # Add disk for gluster client
      node.vm.provider "virtualbox" do |vb|
        unless File.exist?("disk-#{i}.vmdk")
          vb.customize ["createhd", "--filename", "disk-#{i}.vmdk", "--size", DISK_SIZE]
        end
        vb.customize ['storageattach', :id,  '--storagectl', 'SCSI', '--port', 2, '--device', 0, '--type', 'hdd', '--medium', "disk-#{i}.vmdk"]
      end #vb

      # copy ssh key to vms
      config.vm.provision "file", source: "#{PRIVATE_KEY}.pub", destination: "id_rsa.pub"
      config.vm.provision "file", source: "#{PRIVATE_KEY}", destination: "id_rsa"

      # wipe iso 9660 signature
      config.vm.provision "dd device", :type => "shell", inline: "dd if=/dev/zero of=/dev/sdb || true"

    end #node-i
  end #each node

end
