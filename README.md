# openstack-in-a-nutshell

Documentation and ansible role collection to setup an openstack environment from scratch.

## Usage

Configure the virtualbox network

/etc/vbox/networks.conf

```
* 10.0.0.0/16
* 192.168.56.0/21
```

Just clone the repo and run

```
vagrant up
```

If your hardware does not fulfill the requirements in config.yml, you can create a config.override.yml to override some of the values.

During the installation, you will be asked several things:

* Install vagrant-hostmanager plugin
* Select the network interface, that is connected to the internet
* Give Root password for the hostmanager plugin

After the installation has finished, you can open the Dashboard

* http://controller.os.lokal/horizon/

Login:

* admin
* qwertz

## Useful links and

* [Running OpenStack in Production](https://www.youtube.com/watch?v=wsy9OY-ot7E)
* Installing a Minimal Openstack from scratch
  * [Keystone](https://www.youtube.com/watch?v=mCiyTsMvnko)
  * [Glance](https://www.youtube.com/watch?v=UvgMak7DQ9Q)
  * [Horizon and Cinder](https://www.youtube.com/watch?v=sOm6nha-6aQ)
  * [Placement and Nova](https://www.youtube.com/watch?v=ySTNN9gB-Nw)
  * [Neutron](https://www.youtube.com/watch?v=eLJ26JMmi-U)
  * [Compute node](https://www.youtube.com/watch?v=7AFe6RPWdqg)
  * [Testing the cluster](https://www.youtube.com/watch?v=0iILJ2tYKc8)
* Installing Ceph (for later improvement of the Blockstorage Component)
  * [Ceph Cluster Backbone](https://www.youtube.com/watch?v=LxDQyFWDNHI)
  * [Ceph Add OSDs](https://www.youtube.com/watch?v=JLBflREMs2k)
* OpenStack Documentations
  * [Hardware Requirements](https://docs.openstack.org/install-guide/overview.html)
  * [Network self-service](https://docs.openstack.org/install-guide/launch-instance-networks-selfservice.html)
  * [Minimal Installation guide](https://docs.openstack.org/install-guide/openstack-services.html)
  * [Minimal Installation Prerequesites](https://docs.openstack.org/de/install-guide/environment-packages-ubuntu.html)
  * [Full Installation guide](https://docs.openstack.org/install-guide/index.html)
  * [openstack client](https://docs.openstack.org/python-openstackclient/2024.1/)
  * [A guide to applications on openstack](https://www.openstack.org/use-cases/enterprise/)
  * [High Availability](https://docs.openstack.org/arch-design/arch-requirements/arch-requirements-ha.html)
  * [Software and Components overview](https://www.openstack.org/software/)

## Network

The simple [Host Networking](https://docs.openstack.org/install-guide/environment-networking.html) Stack is chosen, which consists of a management and a provider network. There are two options available, provider network and self-service network. The ansible role, installing neutron, is configured to deploy the self-service network option.

The vagrant machine emulates these two networks the following way:

* 1 x Controller Node
  * 1 x management network device - private_network (10.0.0.11)
  * 1 x provider network device - public_network (dhcp)
* 1 x Compute Node
  * 1 x management network device - private_network (10.0.0.21)
  * 1 x provider network device - public_network (dhcp)

The self-service network options requires to link the provider network interface to a bridge and then route all traffic over that bridge, instead of the interface.

Please read the Vagrantfile, to figure out, how this is done.

## Nodes

* https://docs.openstack.org/install-guide/openstack-services.html

### Controller

#### Dependencies

* MariaDB
* RabbitMQ
* Memcache
* Etcd
* Chrony

* https://docs.openstack.org/de/install-guide/environment-packages-ubuntu.html
* https://docs.openstack.org/install-guide/environment-ntp.html

Also add an openstack admin user and configuration for convenience (not recommended on production systems).

#### Keystone

Installing Keystone - the OpenStack Identity Service

* https://docs.openstack.org/keystone/2024.1/install/index-ubuntu.html

##### Test

Set your openstack cli environment variables properly

```
export OS_USERNAME=admin
export OS_PASSWORD=qwertz
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
```

Cheat Sheet

```
openstack command list
openstack catalog list
openstack catalog show keystone
openstack configuration show
openstack versions show
openstack service list
openstack service show keystone
```

General resources overview

```
openstack project list
openstack domain list
openstack user list
openstack quota list --compute
openstack quota list --volume
openstack quota list --network
```

Create project for services

```
openstack project create --domain default --description "Service Project" service
```

Create demo project

```
openstack project create --domain default --description "Demo Project" demo
```

Create a user "demo" for the demo project

```
openstack user create --domain default --password-prompt demo
```

Create the "user" role

```
openstack role create user
```

Put all together

```
openstack role add --project demo --user demo user
```

#### glance

Install glance - the OpenStack Image Service

* https://docs.openstack.org/glance/latest/install/install-ubuntu.html

##### Test

Set your openstack cli environment variables properly

```
export OS_USERNAME=admin
export OS_PASSWORD=qwertz
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
```

Download the cirros image

```
wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
```

Upload the cirros image

```
openstack image create --file ./cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare --public cirros
```

Verify the image was uploaded

```
openstack image list
```

###### Todo

Following commands are failing currently:

```
glance image-create --name "cirros" --file cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare --visibility=public
glance image-list
```

#### placement

Install placement - the OpenStack placement service used to track resource provider inventories and usages

* https://docs.openstack.org/placement/2024.1/install/install-ubuntu.html

##### Test

Set your openstack cli environment variables properly

```
export OS_USERNAME=admin
export OS_PASSWORD=qwertz
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
```

Perform status checks - user needs to be in group placement

```
placement-status upgrade check
```

List available resources and traits

```
openstack --os-placement-api-version 1.2 resource class list --sort-column name
openstack --os-placement-api-version 1.6 trait list --sort-column name
```

#### neutron

Install neutron - the OpenStack networking service

* https://docs.openstack.org/neutron/2024.1/install/install-ubuntu.html

The self-service networking option is chosen by default

##### Test

Set your openstack cli environment variables properly

```
export OS_USERNAME=admin
export OS_PASSWORD=qwertz
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
```

Verify neutron

```
openstack extension list --network
openstack network agent list
```

#### nova

Install nova - the OpenStack compute service

* https://docs.openstack.org/nova/2024.1/install/controller-install-ubuntu.html

##### Test

Verify nova cell0 and cell1 are registered correctly

```
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova
```

#### cinder

Install cinder - the OpenStack block-storage service

* https://docs.openstack.org/cinder/2024.1/install/index-ubuntu.html

##### Test

Verify cinder

```
?
```

#### horizon

Install horizon - the OpenStack dashboard service

* https://docs.openstack.org/horizon/2024.1/install/install-debian.html

##### Test

Verify horizon

```
?
```

### Compute1

#### Dependencies

* Chrony

* https://docs.openstack.org/install-guide/environment-ntp.html

Also add an openstack admin user and configuration for convenience (not recommended on production systems).

#### neutron

Install neutron - the OpenStack networking service

* https://docs.openstack.org/neutron/2024.1/install/compute-install-ubuntu.html

The self-service networking option is chosen by default

##### Test

Verify neutron

```
?
```

#### nova

Install nova - the OpenStack compute service

* https://docs.openstack.org/nova/2024.1/install/compute-install-ubuntu.html

##### Test

* https://docs.openstack.org/nova/2024.1/install/verify.html

Verify nova cell0 and cell1 are registered correctly

```
su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova
```

### Block1

#### Dependencies

* Chrony

* https://docs.openstack.org/install-guide/environment-ntp.html

Also add an openstack admin user and configuration for convenience (not recommended on production systems).

#### Cinder

* https://docs.openstack.org/cinder/2024.1/install/cinder-storage-install-ubuntu.html

#### Tests

```
?
```

### Object1

@Todo

* https://docs.openstack.org/swift/2024.1/install/
* https://docs.openstack.org/cinder/2024.1/install/cinder-backup-install-ubuntu.html

# CEPH Install Tests

## Manual Installation and configuration of the three monitoring nodes

### Install dependencies

```
# On your external node, SSH into controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo apt update && sudo apt install -y acl ceph-common ceph-mon'

# On your external node, SSH into compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo apt update && sudo apt install -y acl ceph-common ceph-mon'

# On your external node, SSH into compute2
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal 'sudo apt update && sudo apt install -y acl ceph-common ceph-mon'
```

### Create ceph.conf on all nodes

```
# On your external node, SSH into controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo bash -c "cat > /etc/ceph/ceph.conf << EOF
[global]
fsid = 7272bf23-0a44-42e6-b591-5569713531fa
# mon_initial_members will ONLY list the node used for mkfs initially
mon_initial_members = controller
mon_host = 10.0.1.10,10.0.1.11,10.0.1.12 # List ALL potential mon IPs so new MONs can find cluster
public_network = 10.0.1.0/24

# Optional but good for dev/test
osd_pool_default_size = 2
osd_pool_default_min_size = 1
mon_allow_pool_delete = true

[client.admin]
keyring = /etc/ceph/ceph.client.admin.keyring
EOF
"'

# On your external node, SSH into compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo bash -c "cat > /etc/ceph/ceph.conf << EOF
[global]
fsid = 7272bf23-0a44-42e6-b591-5569713531fa
# mon_initial_members is not strictly needed on nodes not doing initial mkfs
mon_host = 10.0.1.10,10.0.1.11,10.0.1.12 # List ALL potential mon IPs so new MONs can find cluster
public_network = 10.0.1.0/24

# Optional but good for dev/test
osd_pool_default_size = 2
osd_pool_default_min_size = 1
mon_allow_pool_delete = true

[client.admin]
keyring = /etc/ceph/ceph.client.admin.keyring
EOF
"'

# On your external node, SSH into compute2
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal 'sudo bash -c "cat > /etc/ceph/ceph.conf << EOF
[global]
fsid = 7272bf23-0a44-42e6-b591-5569713531fa
# mon_initial_members is not strictly needed on nodes not doing initial mkfs
mon_host = 10.0.1.10,10.0.1.11,10.0.1.12 # List ALL potential mon IPs so new MONs can find cluster
public_network = 10.0.1.0/24

# Optional but good for dev/test
osd_pool_default_size = 2
osd_pool_default_min_size = 1
mon_allow_pool_delete = true

[client.admin]
keyring = /etc/ceph/ceph.client.admin.keyring
EOF
"'
```

### Initialize the bootstrap node

```
# On your external node, SSH into controller

# Generate Admin Keyring (/etc/ceph/ceph.client.admin.keyring)
# This key is needed by 'ceph' CLI commands to talk to the cluster
# Using 'sudo sh -c' and careful quoting
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo sh -c "ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --cap mon '\''allow *'\'' --cap mgr '\''allow *'\'' --cap osd '\''allow *'\'' --cap mds '\''allow *'\''"'

# Ensure only root can read the admin keyring initially
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo chmod 600 /etc/ceph/ceph.client.admin.keyring'

# Generate temporary monitor bootstrap keyring (/tmp/ceph.mon.keyring.bootstrap)
# This key is used by the mon daemon during mkfs
# Using 'sudo sh -c' and careful quoting
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo sh -c "ceph-authtool --create-keyring /tmp/ceph.mon.keyring.bootstrap --gen-key -n mon. --cap mon '\''allow *'\''"'

# Import admin key into the temporary monitor bootstrap keyring (so mkfs includes admin key)
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo ceph-authtool /tmp/ceph.mon.keyring.bootstrap --import-keyring /etc/ceph/ceph.client.admin.keyring'

# Generate initial monmap (/tmp/monmap.initial) - ONLY includes the first monitor
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo monmaptool --create --add controller 10.0.1.10 --fsid 7272bf23-0a44-42e6-b591-5569713531fa /tmp/monmap.initial'

# Ensure ceph user can read temporary files before mkfs - Change Ownership
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo chown ceph:ceph /tmp/ceph.mon.keyring.bootstrap /tmp/monmap.initial'

# Ensure ceph user can read temporary files before mkfs - Set Permissions (Temp key readable only by owner)
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo chmod 600 /tmp/ceph.mon.keyring.bootstrap'

# Ensure ceph user can read temporary files before mkfs - Set Permissions (Monmap readable by owner/group/others)
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo chmod 644 /tmp/monmap.initial'

# Create Monitor data directory for controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo mkdir -p /var/lib/ceph/mon/ceph-controller'

# Ensure Monitor data directory ownership is correct
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo chown ceph:ceph /var/lib/ceph/mon/ceph-controller'

# Initialize Monitor data store (mkfs) on controller, running as ceph user
# This uses the temp key and monmap
# Using 'sudo sh -c' and careful quoting around the command itself
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo sh -c '\''sudo -u ceph ceph-mon --mkfs -i controller --monmap /tmp/monmap.initial --keyring /tmp/ceph.mon.keyring.bootstrap'\'''

# Create systemd 'done' file for controller monitor
# Signal systemd that this monitor is configured
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo touch /var/lib/ceph/mon/ceph-controller/done'

# Ensure systemd done file ownership is correct
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo chown ceph:ceph /var/lib/ceph/mon/ceph-controller/done'


# Start Ceph Monitor service on controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo systemctl enable ceph-mon@controller.service'
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo systemctl start ceph-mon@controller.service'
```

### Verify the monitor

```
# On your external node, SSH into controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal '
sudo systemctl status ceph-mon@controller.service # Check service status
sleep 10 # Wait a bit
sudo ceph mon stat # Should show quorum [0] controller
'
# Look for 'mon: 1 daemons, quorum 0 controller'
```

### Create a second monitor

#### Prepare Data Directory on the New Monitor Node

```

# On your external node, SSH into compute1

# Create Monitor data directory for compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo mkdir -p /var/lib/ceph/mon/ceph-compute1'

# Ensure Monitor data directory ownership is correct on compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo chown ceph:ceph /var/lib/ceph/mon/ceph-compute1'

# Create standard subdirectories for the monitor's RocksDB data store
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo mkdir -p /var/lib/ceph/mon/ceph-compute1/store.db /var/lib/ceph/mon/ceph-compute1/store.db.log'

# Ensure correct ownership and permissions for the new subdirectories
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo chown ceph:ceph /var/lib/ceph/mon/ceph-compute1/store.db /var/lib/ceph/mon/ceph-compute1/store.db.log'
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo chmod 0750 /var/lib/ceph/mon/ceph-compute1/store.db /var/lib/ceph/mon/ceph-compute1/store.db.log'
```

#### Generate Key for the New Monitor (mon.compute1) and Get Latest Monmap (from controller)

```

# On your external node, SSH into controller

# Generate key for mon.compute1 using the running cluster
# Output temporary keyring for mon.compute1
# Using 'sudo sh -c' and careful quoting around 'allow profile bootstrap-mon'
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo sh -c "ceph --cluster ceph auth get-or-create mon.compute1 mon '\''allow profile bootstrap-mon'\'' -o /tmp/ceph.mon.compute1.keyring"'

# Make the temporary key readable by vagrant for scp from controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo chown vagrant:vagrant /tmp/ceph.mon.compute1.keyring'

# Get the latest monitor map from the running cluster (output to /tmp/monmap.latest)
# This command outputs binary data
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo ceph --cluster ceph mon getmap -o /tmp/monmap.latest'

# Make the temporary monmap readable by vagrant for scp from controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo chown vagrant:vagrant /tmp/monmap.latest'
```

#### Distribute Key and Monmap to the New Monitor Node (compute1)


```
# On your external node (where you run ssh)

# Copy the temporary key from controller to your external node
scp -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal:/tmp/ceph.mon.compute1.keyring /tmp/mon.compute1.keyring.local # Copy to a temp name locally

# Copy the temporary monmap from controller to your external node
scp -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal:/tmp/monmap.latest /tmp/monmap.latest.local # Copy to a temp name locally

# Copy the key from your external node to /tmp/ on compute1
scp -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no /tmp/mon.compute1.keyring.local vagrant@compute1.os.lokal:/tmp/ceph.mon.compute1.keyring.tmp

# Copy the monmap from your external node to /tmp/ on compute1
scp -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no /tmp/monmap.latest.local vagrant@compute1.os.lokal:/tmp/monmap.latest.tmp

# Clean up the temporary files on your external node
rm /tmp/mon.compute1.keyring.local /tmp/monmap.latest.local
```

#### Initialize Monitor Data Store (mkfs) on the New Monitor Node (compute1)

```
# On your external node, SSH into compute1

# Ensure ceph user can read temporary files in /tmp/ before mkfs
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo chown ceph:ceph /tmp/ceph.mon.compute1.keyring.tmp /tmp/monmap.latest.tmp' # Use .tmp names here
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo chmod 600 /tmp/ceph.mon.compute1.keyring.tmp' # Temp key
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo chmod 644 /tmp/monmap.latest.tmp' # Monmap


# Initialize Monitor data store (mkfs) on compute1, running as ceph user
# Use the temporary key and the latest monmap copied to /tmp/
# This command *creates* the store.db/ directory and its initial files.
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo -u ceph ceph-mon --mkfs -i compute1 --monmap /tmp/monmap.latest.tmp --keyring /tmp/ceph.mon.compute1.keyring.tmp'

# Ensure recursive ownership of the data directory after mkfs
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo chown -R ceph:ceph /var/lib/ceph/mon/ceph-compute1' # Should already be ceph, but good measure

# Clean up temporary files from /tmp/ on compute1 after mkfs
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo rm /tmp/ceph.mon.compute1.keyring.tmp /tmp/monmap.latest.tmp'
```















#### Move Files and Finalize Permissions on the New Monitor Node (compute1) (old)

```
# On your external node, SSH into compute1

# Move the key from /tmp/ to the monitor data directory using sudo
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo mv /tmp/ceph.mon.compute1.keyring.tmp /var/lib/ceph/mon/ceph-compute1/keyring'

# Ensure key ownership is correct (should be ceph:ceph)
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo chown ceph:ceph /var/lib/ceph/mon/ceph-compute1/keyring'

# Ensure key permissions are correct (should be 0600)
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo chmod 600 /var/lib/ceph/mon/ceph-compute1/keyring'


# Move the monmap from /tmp/ to the monitor data directory using sudo
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo mv /tmp/monmap.latest.tmp /var/lib/ceph/mon/ceph-compute1/monmap'

# Ensure monmap ownership is correct (should be ceph:ceph)
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo chown ceph:ceph /var/lib/ceph/mon/ceph-compute1/monmap'

# Ensure monmap permissions are correct (0644 is typical)
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo chmod 644 /var/lib/ceph/mon/ceph-compute1/monmap'


# Create systemd 'done' file for compute1 monitor
# Signal systemd that this monitor is configured
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo touch /var/lib/ceph/mon/ceph-compute1/done'

# Ensure systemd done file ownership is correct
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo chown ceph:ceph /var/lib/ceph/mon/ceph-compute1/done'
```

#### Start Monitor Service on the New Node (compute1)

```
# On your external node, SSH into compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo systemctl enable ceph-mon@compute1.service'
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo systemctl start ceph-mon@compute1.service'
```


#### Verify the monitor on the New Node (compute1)

```
# On your external node, SSH into controller
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal '
sudo systemctl status ceph-mon@compute1.service # Check service status
sudo ceph mon stat # Should show quorum [0] compute1
'
# Look for 'mon: 1 daemons, quorum 0 comoute1'
```

#### Add Monitor to the Quorum

```
# On your external node, SSH into controller
# This tells the running cluster about the new monitor
# Note: This also requires permissions on controller to run ceph commands.
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo ceph mon add compute1 10.0.1.11'
```

#### Create 'done' file and Start Service on the New Node (compute1)

```
# On your external node, SSH into compute1

# Create systemd 'done' file for compute1 monitor
# Signal systemd that this monitor is configured
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo touch /var/lib/ceph/mon/ceph-compute1/done'

# Ensure systemd done file ownership is correct
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo chown ceph:ceph /var/lib/ceph/mon/ceph-compute1/done'


# Start Ceph Monitor service on compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo systemctl enable ceph-mon@compute1.service'
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo systemctl start ceph-mon@compute1.service'
```

#### Add Monitor to the Quorum (from controller)

```
# On your external node, SSH into controller
# This tells the running cluster about the new monitor
# Note: This also requires permissions on controller to run ceph commands.
# This command should ideally be run AFTER the service on compute1 has started
# and is attempting to join. You might need to wait a few seconds between starting service and running 'mon add'.
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo ceph mon add compute1 10.0.1.11'
```

#### Following error occures

```
andre@t480:~/Workspace/openstack-in-a-nutshell$ # On your external node, SSH into controller
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal '
sudo systemctl status ceph-mon@compute1.service # Check service status
sudo ceph mon stat # Should show quorum [0] compute1
'
# Look for 'mon: 1 daemons, quorum 0 comoute1'
× ceph-mon@compute1.service - Ceph cluster monitor daemon
     Loaded: loaded (/usr/lib/systemd/system/ceph-mon@.service; enabled; preset: enabled)
     Active: failed (Result: exit-code) since Tue 2025-05-13 18:29:56 UTC; 1min 54s ago
   Duration: 102ms
    Process: 6307 ExecStart=/usr/bin/ceph-mon -f --cluster ${CLUSTER} --id compute1 --setuser ceph --setgroup ceph (code=exited, status=1/FAILURE)
   Main PID: 6307 (code=exited, status=1/FAILURE)
        CPU: 95ms

May 13 18:29:56 compute1 systemd[1]: ceph-mon@compute1.service: Scheduled restart job, restart counter is at 5.
May 13 18:29:56 compute1 systemd[1]: ceph-mon@compute1.service: Start request repeated too quickly.
May 13 18:29:56 compute1 systemd[1]: ceph-mon@compute1.service: Failed with result 'exit-code'.
May 13 18:29:56 compute1 systemd[1]: Failed to start ceph-mon@compute1.service - Ceph cluster monitor daemon.
2025-05-13T18:31:51.071+0000 7b2a8d2006c0 -1 auth: unable to find a keyring on /etc/ceph/ceph.client.admin.keyring: (2) No such file or directory
2025-05-13T18:31:51.071+0000 7b2a8d2006c0 -1 AuthRegistry(0x7b2a880650b0) no keyring found at /etc/ceph/ceph.client.admin.keyring, disabling cephx
2025-05-13T18:31:51.076+0000 7b2a8d2006c0 -1 auth: unable to find a keyring on /etc/ceph/ceph.client.admin.keyring: (2) No such file or directory
2025-05-13T18:31:51.076+0000 7b2a8d2006c0 -1 AuthRegistry(0x7b2a88069568) no keyring found at /etc/ceph/ceph.client.admin.keyring, disabling cephx
2025-05-13T18:31:51.077+0000 7b2a8d2006c0 -1 auth: unable to find a keyring on /etc/ceph/ceph.client.admin.keyring: (2) No such file or directory
2025-05-13T18:31:51.077+0000 7b2a8d2006c0 -1 AuthRegistry(0x7b2a8d1ff3d0) no keyring found at /etc/ceph/ceph.client.admin.keyring, disabling cephx
2025-05-13T18:36:51.080+0000 7b2a8d2006c0  0 monclient(hunting): authenticate timed out after 300
2025-05-13T18:36:51.080+0000 7b2a8d2006c0 -1 monclient(hunting): authenticate NOTE: no keyring found; disabled cephx authentication
[errno 110] RADOS timed out (error connecting to the cluster)
```














### Create second monitor  (old)

```
# On your external node, SSH into compute1

# Create Monitor data directory for compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo mkdir -p /var/lib/ceph/mon/ceph-compute1'

# Ensure Monitor data directory ownership is correct on compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo chown ceph:ceph /var/lib/ceph/mon/ceph-compute1'


# On your external node, SSH into controller (to generate key for compute1 and get the latest monmap)
# ... (Commands to generate key and get monmap on controller, and chown them to vagrant in /tmp/ are the same as before) ...
# (Output files: /tmp/ceph.mon.compute1.keyring and /tmp/monmap.latest on controller, owned by vagrant)


# On your external node (to copy key and monmap to compute1 - TWO STEPS)

# --- Copy mon.compute1.keyring to /tmp/ on compute1 ---
# Copy the temporary key from controller to your external node
scp -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal:/tmp/ceph.mon.compute1.keyring /tmp/mon.compute1.keyring.local # Copy to a temp name locally
# Copy the key from your external node to /tmp/ on compute1 (where vagrant has write access)
scp -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no /tmp/mon.compute1.keyring.local vagrant@compute1.os.lokal:/tmp/ceph.mon.compute1.keyring.tmp

# --- Copy monmap.latest to /tmp/ on compute1 ---
# Copy the temporary monmap from controller to your external node
scp -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal:/tmp/monmap.latest /tmp/monmap.latest.local # Copy to a temp name locally
# Copy the monmap from your external node to /tmp/ on compute1 (where vagrant has write access)
scp -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no /tmp/monmap.latest.local vagrant@compute1.os.lokal:/tmp/monmap.latest.tmp

# Clean up the temporary files on your external node
rm /tmp/mon.compute1.keyring.local /tmp/monmap.latest.local


# On your external node, SSH into compute1 (to move files and finalize permissions/start service)

# Move the key from /tmp/ to the monitor data directory using sudo
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo mv /tmp/ceph.mon.compute1.keyring.tmp /var/lib/ceph/mon/ceph-compute1/keyring'

# Ensure key ownership is correct (should be ceph:ceph)
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo chown ceph:ceph /var/lib/ceph/mon/ceph-compute1/keyring'

# Ensure key permissions are correct (should be 0600)
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo chmod 600 /var/lib/ceph/mon/ceph-compute1/keyring'


# Move the monmap from /tmp/ to the monitor data directory using sudo
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo mv /tmp/monmap.latest.tmp /var/lib/ceph/mon/ceph-compute1/monmap'

# Ensure monmap ownership is correct (should be ceph:ceph)
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo chown ceph:ceph /var/lib/ceph/mon/ceph-compute1/monmap'

# Ensure monmap permissions are correct (0644 is typical)
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo chmod 644 /var/lib/ceph/mon/ceph-compute1/monmap'


# Create systemd 'done' file for compute1 monitor
# Signal systemd that this monitor is configured
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo touch /var/lib/ceph/mon/ceph-compute1/done'

# Ensure systemd done file ownership is correct
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo chown ceph:ceph /var/lib/ceph/mon/ceph-compute1/done'


# Start Ceph Monitor service on compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo systemctl enable ceph-mon@compute1.service'
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo systemctl start ceph-mon@compute1.service'


# On your external node, SSH into controller (to add compute1 to the quorum)
# This tells the running cluster about the new monitor
# Note: This also requires permissions on controller to run ceph commands.
# This command should ideally be run AFTER the service on compute1 has started
# and is attempting to join. You might need to wait a few seconds between starting service and running 'mon add'.
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo ceph mon add compute1 10.0.1.11'
```

###


```
sudo ceph mon dump
sudo systemctl status ceph-mon@controller.service
```