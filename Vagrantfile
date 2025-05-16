# -*- mode: ruby -*-
# vi: set ft=ruby :

# load configs
require 'yaml'
current_dir    = File.dirname(File.expand_path(__FILE__))
configs        = YAML.load_file("#{current_dir}/config.yml")
vagrant_config = configs['configs']

# Add a deep_merge method to Hash
class ::Hash
    def deep_merge(second)
        merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : [:undefined, nil, :nil].include?(v2) ? v1 : v2 }
        self.merge(second, &merger)
    end
end

# Override the configs with your custom configs
if File.exist?("#{current_dir}/config.override.yml")
  configs_override = YAML.load_file("#{current_dir}/config.override.yml")
  configs = configs.deep_merge(configs_override)
  # puts configs.to_yaml
end
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
  config.hostmanager.ignore_private_ip = false

  # OpenStack Controller
  config.vm.define "controller", autostart: vagrant_config['vms']['controller']['autostart'] do |b|
    b.vm.box = vagrant_config['vagrant_image']

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

    # OpenStack Provider Network
    b.vm.network "public_network"
    # OpenStack Public Network
    b.vm.network "private_network", ip: vagrant_config['vms']['controller']['os_pub_ip'], netmask: "255.255.255.0"
    # OpenStack Management Network
    b.vm.network "private_network", ip: vagrant_config['vms']['controller']['os_mgt_ip'], netmask: "255.255.255.0"
    # OpenStack SDN Underlay Network
    b.vm.network "private_network", ip: vagrant_config['vms']['controller']['os_sdn_ip'], netmask: "255.255.255.0"
    # OpenStack Ceph Public Network
    b.vm.network "private_network", ip: vagrant_config['vms']['controller']['ceph_public_ip'], netmask: "255.255.255.0"
    # OpenStack Ceph Cluster Network
    b.vm.network "private_network", ip: vagrant_config['vms']['controller']['ceph_cluster_ip'], netmask: "255.255.255.0"

    # Hostname Domains
    b.vm.hostname = vagrant_config['vms']['controller']['domain']
    b.hostmanager.aliases = vagrant_config['vms']['controller']['aliases']

    b.vm.synced_folder ".", "/vagrant", disabled: true
    #b.vm.synced_folder ".", "/vagrant/ansible_vagrant", create: true, owner: "vagrant", group: "vagrant", mount_options: ["dmode=775,fmode=775"]

    # Run Ansible from the Vagrant VM
    b.vm.provision "shell",
      run: "once",
      inline: "apt update && apt install python3-pip tree net-tools openvswitch-switch tcptraceroute isc-dhcp-client -yqq"

    # Build the provider network bridge with openvswitch
    # shut down enp0s8 (public_network interface)
    # create the provider bridge and add enp0s8
    # startup the bridge and the interface
    # run dhclient on the provider bridge
    b.vm.provision "shell",
      run: "once",
      # Noble variant with different network interfaces
      inline: "(ovs-vsctl add-br prvbr0 && ifconfig eth1 down && ovs-vsctl add-port prvbr0 eth1 && ifconfig prvbr0 up && ifconfig eth1 up && dhclient prvbr0) || true"
      #inline: "(ovs-vsctl add-br prvbr0 && ifconfig enp0s8 down && ovs-vsctl add-port prvbr0 enp0s8 && ifconfig prvbr0 up && ifconfig enp0s8 up && dhclient prvbr0) || true"

    # Delete the default route, to apply the provider network route
    b.vm.provision "shell",
      run: "always",
      inline: "ip route del default via 10.0.2.2 || true"
  end

  # OpenStack Compute1
  config.vm.define "compute1", autostart: vagrant_config['vms']['compute1']['autostart'] do |b|
    b.vm.box = vagrant_config['vagrant_image']

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
    b.vm.disk :disk, size: vagrant_config['vms']['compute1']['storage_disk_size'], name: "disk-0"
    b.vm.disk :disk, size: vagrant_config['vms']['compute1']['storage_disk_size'], name: "disk-1"

    # OpenStack Provider Network
    b.vm.network "public_network"
    # OpenStack Public Network
    b.vm.network "private_network", ip: vagrant_config['vms']['compute1']['os_pub_ip'], netmask: "255.255.255.0"
    # OpenStack Management Network
    b.vm.network "private_network", ip: vagrant_config['vms']['compute1']['os_mgt_ip'], netmask: "255.255.255.0"
    # OpenStack SDN Underlay Network
    b.vm.network "private_network", ip: vagrant_config['vms']['compute1']['os_sdn_ip'], netmask: "255.255.255.0"
    # OpenStack Ceph Public Network
    b.vm.network "private_network", ip: vagrant_config['vms']['compute1']['ceph_public_ip'], netmask: "255.255.255.0"
    # OpenStack Ceph Cluster Network
    b.vm.network "private_network", ip: vagrant_config['vms']['compute1']['ceph_cluster_ip'], netmask: "255.255.255.0"

    # Hostname Domains
    b.vm.hostname = vagrant_config['vms']['compute1']['domain']
    b.hostmanager.aliases = vagrant_config['vms']['compute1']['aliases']

    b.vm.synced_folder ".", "/vagrant", disabled: true
    #b.vm.synced_folder ".", "/vagrant/ansible_vagrant", create: true, owner: "vagrant", group: "vagrant", mount_options: ["dmode=775,fmode=775"]

    # Run Ansible from the Vagrant VM
    b.vm.provision "shell",
      run: "once",
      inline: "apt update && apt install python3-pip tree net-tools openvswitch-switch tcptraceroute isc-dhcp-client -yqq"

    # Build the provider network bridge with openvswitch
    # shut down enp0s8 (public_network interface)
    # create the provider bridge and add enp0s8
    # startup the bridge and the interface
    # run dhclient on the provider bridge
    b.vm.provision "shell",
      run: "once",
      # Noble variant with different network interfaces
      inline: "(ovs-vsctl add-br prvbr0 && ifconfig eth1 down && ovs-vsctl add-port prvbr0 eth1 && ifconfig prvbr0 up && ifconfig eth1 up && dhclient prvbr0) || true"
      #inline: "(ovs-vsctl add-br prvbr0 && ifconfig enp0s8 down && ovs-vsctl add-port prvbr0 enp0s8 && ifconfig prvbr0 up && ifconfig enp0s8 up && dhclient prvbr0) || true"

    # Delete the default route, to apply the provider network route
    b.vm.provision "shell",
      run: "always",
      inline: "ip route del default via 10.0.2.2 || true"
  end

  # OpenStack Compute2
  config.vm.define "compute2", autostart: vagrant_config['vms']['compute2']['autostart'] do |b|
    b.vm.box = vagrant_config['vagrant_image']

    b.vm.provider "virtualbox" do |vb|
      vb.memory = vagrant_config['vms']['compute2']['memory']
      vb.cpus = vagrant_config['vms']['compute2']['cpus']
      vb.customize ["modifyvm", :id, "--nested-hw-virt", "on", "--audio", "none"]
    end

    b.vm.disk :disk, size: vagrant_config['vms']['compute2']['disk_size'], primary: true

    # Additional Disks
    #(0..2).each do |i|
    #  b.vm.disk :disk, size: "10GB", name: "disk-#{i}"
    #end
    b.vm.disk :disk, size: vagrant_config['vms']['compute2']['storage_disk_size'], name: "disk-0"
    b.vm.disk :disk, size: vagrant_config['vms']['compute2']['storage_disk_size'], name: "disk-1"

    # OpenStack Provider Network
    b.vm.network "public_network"
    # OpenStack Public Network
    b.vm.network "private_network", ip: vagrant_config['vms']['compute2']['os_pub_ip'], netmask: "255.255.255.0"
    # OpenStack Management Network
    b.vm.network "private_network", ip: vagrant_config['vms']['compute2']['os_mgt_ip'], netmask: "255.255.255.0"
    # OpenStack SDN Underlay Networ
    b.vm.network "private_network", ip: vagrant_config['vms']['compute2']['os_sdn_ip'], netmask: "255.255.255.0"
    # OpenStack Ceph Public Network
    b.vm.network "private_network", ip: vagrant_config['vms']['compute2']['ceph_public_ip'], netmask: "255.255.255.0"
    # OpenStack Ceph Cluster Network
    b.vm.network "private_network", ip: vagrant_config['vms']['compute2']['ceph_cluster_ip'], netmask: "255.255.255.0"

    # Hostname Domains
    b.vm.hostname = vagrant_config['vms']['compute2']['domain']
    b.hostmanager.aliases = vagrant_config['vms']['compute2']['aliases']

    b.vm.synced_folder ".", "/vagrant", disabled: true
    #b.vm.synced_folder ".", "/vagrant/ansible_vagrant", create: true, owner: "vagrant", group: "vagrant", mount_options: ["dmode=775,fmode=775"]

    # Run Ansible from the Vagrant VM
    b.vm.provision "shell",
      run: "once",
      inline: "apt update && apt install python3-pip tree net-tools openvswitch-switch tcptraceroute isc-dhcp-client -yqq"

    # Build the provider network bridge with openvswitch
    # shut down enp0s8 (public_network interface)
    # create the provider bridge and add enp0s8
    # startup the bridge and the interface
    # run dhclient on the provider bridge
    b.vm.provision "shell",
      run: "once",
      # Noble variant with different network interfaces
      inline: "(ovs-vsctl add-br prvbr0 && ifconfig eth1 down && ovs-vsctl add-port prvbr0 eth1 && ifconfig prvbr0 up && ifconfig eth1 up && dhclient prvbr0) || true"
      #inline: "(ovs-vsctl add-br prvbr0 && ifconfig enp0s8 down && ovs-vsctl add-port prvbr0 enp0s8 && ifconfig prvbr0 up && ifconfig enp0s8 up && dhclient prvbr0) || true"

    # Delete the default route, to apply the provider network route
    b.vm.provision "shell",
      run: "always",
      inline: "ip route del default via 10.0.2.2 || true"
  end
end
