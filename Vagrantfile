# -*- mode: ruby -*-
# vi: set ft=ruby :

# load configs
require 'yaml'
current_dir    = File.dirname(File.expand_path(__FILE__))
configs        = YAML.load_file("#{current_dir}/config.yaml")
vagrant_config = configs['configs']

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|

  config.vagrant.plugins = ["vagrant-hostmanager"]

  # hostmanager configuration
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.manage_guest = true
  config.hostmanager.include_offline = true

  # OpenStack Controller
  config.vm.define "controller" do |b|
    #b.vm.box = "cloudcourse/noble64" # Ubuntu 24.04
    b.vm.box = "ubuntu/jammy64" # Ubuntu 22.04

    b.vm.provider "virtualbox" do |vb|
      vb.memory = vagrant_config['vms']['controller']['memory']
      vb.cpus = vagrant_config['vms']['controller']['cpus']
      vb.customize ["modifyvm", :id, "--audio", "none"]
    end

    b.vm.disk :disk, size: vagrant_config['vms']['controller']['disk_size'], primary: true

    # Additional Disks
    #(0..2).each do |i|
    #  b.vm.disk :disk, size: "10GB", name: "disk-#{i}"
    #end

    # OpenStack Management Network
    b.vm.network "private_network", ip: vagrant_config['vms']['controller']['internal_ip'], netmask: "255.255.255.0", name: "os-mgt", virtualbox__intnet: "os-mgt"
    b.vm.network "public_network"

    # Hostname Domains
    b.vm.hostname = vagrant_config['vms']['controller']['domain']
    b.hostmanager.aliases = vagrant_config['vms']['controller']['aliases']

    b.vm.synced_folder ".", "/vagrant", disabled: true
    b.vm.synced_folder ".", "/vagrant/ansible_vagrant", create: true, owner: "vagrant", group: "vagrant", mount_options: ["dmode=775,fmode=775"]

    # Run Ansible from the Vagrant VM
    b.vm.provision "shell", inline: "apt update && apt install python3-pip tree net-tools openvswitch-switch tcptraceroute -yqq"

    # Build the provider network bridge with openvswitch
    # shut down enp0s9 (public_network interface)
    # create the provider bridge and add enp0s9
    # startup the bridge and the interface
    # run dhclient on the provider bridge
    b.vm.provision "shell",
      run: "always",
      inline: "ifconfig enp0s9 down && ovs-vsctl add-br prvbr0 && ovs-vsctl add-port prvbr0 enp0s9 && ifconfig prvbr0 up && ifconfig enp0s9 up && dhclient prvbr0"

    # Delete the default route, to apply the provider network route
    b.vm.provision "shell",
      run: "always",
      inline: "ip route del default via 10.0.2.2 || true"

    if vagrant_config['ansible_version'] == "latest"
      # Noble variant with --break-system-packages
      # b.vm.provision "shell", inline: "pip3 install --break-system-packages --upgrade --no-warn-script-location ansible-core"
      b.vm.provision "shell", inline: "pip3 install --upgrade --no-warn-script-location ansible-core"
    else
      # if you need to test with a specific version
      # e.g. Ansible Version 2.11 is important for kubespray
      # b.vm.provision "shell", inline: "pip install --upgrade ansible-core~=2.11.0"
      # Noble variant with --break-system-packages
      # b.vm.provision "shell", inline: "pip3 install --break-system-packages --upgrade --no-warn-script-location ansible-core~=#{vagrant_config['ansible_version']}"
      b.vm.provision "shell", inline: "pip3 install --upgrade --no-warn-script-location ansible-core~=#{vagrant_config['ansible_version']}"
    end

    b.vm.provision "ansible_local" do |ansible|
      ansible.install = false
      ansible.playbook = "ansible_vagrant/playbook-controller.yml"
      ansible.galaxy_role_file = "ansible_vagrant/requirements.yml"
      #Uncomment when ansible 2.10 is available
      #ansible.galaxy_command = "sudo ansible-galaxy install -r %{role_file} --force; sudo ansible-galaxy collection install -r %{role_file} --force"
      ansible.extra_vars = {
        ansible_python_interpreter:"/usr/bin/python3"
      }
    end
  end

  # OpenStack Compute1
  config.vm.define "compute1" do |b|
    #b.vm.box = "cloudcourse/noble64" # Ubuntu 24.04
    b.vm.box = "ubuntu/jammy64" # Ubuntu 22.04

    b.vm.provider "virtualbox" do |vb|
      vb.memory = vagrant_config['vms']['compute1']['memory']
      vb.cpus = vagrant_config['vms']['compute1']['cpus']
      vb.customize ["modifyvm", :id, "--nested-hw-virt", "on", "--audio", "none"]
    end

    b.vm.disk :disk, size: vagrant_config['vms']['compute1']['disk_size'], primary: true

    # Additional Disks
    #(0..2).each do |i|
    #  b.vm.disk :disk, size: "10GB", name: "disk-#{i}"
    #end

    # OpenStack Management Network
    b.vm.network "private_network", ip: vagrant_config['vms']['compute1']['internal_ip'], netmask: "255.255.255.0", name: "os-mgt", virtualbox__intnet: "os-mgt"
    b.vm.network "public_network"

    # Hostname Domains
    b.vm.hostname = vagrant_config['vms']['compute1']['domain']
    b.hostmanager.aliases = vagrant_config['vms']['compute1']['aliases']

    b.vm.synced_folder ".", "/vagrant", disabled: true
    b.vm.synced_folder ".", "/vagrant/ansible_vagrant", create: true, owner: "vagrant", group: "vagrant", mount_options: ["dmode=775,fmode=775"]

    # Run Ansible from the Vagrant VM
    b.vm.provision "shell", inline: "apt update && apt install python3-pip tree net-tools openvswitch-switch tcptraceroute -yqq"

    # Build the provider network bridge with openvswitch
    # shut down enp0s9 (public_network interface)
    # create the provider bridge and add enp0s9
    # startup the bridge and the interface
    # run dhclient on the provider bridge
    b.vm.provision "shell",
      run: "always",
      inline: "ifconfig enp0s9 down && ovs-vsctl add-br prvbr0 && ovs-vsctl add-port prvbr0 enp0s9 && ifconfig prvbr0 up && ifconfig enp0s9 up && dhclient prvbr0"

    # Delete the default route, to apply the provider network route
    b.vm.provision "shell",
      run: "always",
      inline: "ip route del default via 10.0.2.2 || true"

    if vagrant_config['ansible_version'] == "latest"
      # Noble variant with --break-system-packages
      # b.vm.provision "shell", inline: "pip3 install --break-system-packages --upgrade --no-warn-script-location ansible-core"
      b.vm.provision "shell", inline: "pip3 install --upgrade --no-warn-script-location ansible-core"
    else
      # if you need to test with a specific version
      # e.g. Ansible Version 2.11 is important for kubespray
      # b.vm.provision "shell", inline: "pip install --upgrade ansible-core~=2.11.0"
      # Noble variant with --break-system-packages
      # b.vm.provision "shell", inline: "pip3 install --break-system-packages --upgrade --no-warn-script-location ansible-core~=#{vagrant_config['ansible_version']}"
      b.vm.provision "shell", inline: "pip3 install --upgrade --no-warn-script-location ansible-core~=#{vagrant_config['ansible_version']}"
    end

    b.vm.provision "ansible_local" do |ansible|
      ansible.install = false
      ansible.playbook = "ansible_vagrant/playbook-compute1.yml"
      ansible.galaxy_role_file = "ansible_vagrant/requirements.yml"
      #Uncomment when ansible 2.10 is available
      #ansible.galaxy_command = "sudo ansible-galaxy install -r %{role_file} --force; sudo ansible-galaxy collection install -r %{role_file} --force"
      ansible.extra_vars = {
        ansible_python_interpreter:"/usr/bin/python3"
      }
    end
  end
end
