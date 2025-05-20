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

The vagrant machine emulates the self-service network the following way:

* 1 x Controller Node
  * 1 x OpenStack Provider Network Device - public_network (dhcp)
  * 1 x OpenStack Management Network Device - private_network (10.0.10.10)
  * 1 x OpenStack Public Network Device - private_network (10.0.20.10)
  * 1 x OpenStack Tenant Network Device - private_network (10.0.30.10)
  * 1 x Ceph Public Network Device - private_network (10.0.40.10)
  * 1 x Ceph Cluster Network Device - private_network (10.0.50.10)
* 2 x Compute Node
  * 1 x OpenStack Provider Network Device - public_network (dhcp)
  * 1 x OpenStack Management Network Device - private_network (10.0.10.11/.12)
  * 1 x OpenStack Public Network Device - private_network (10.0.20.11/.12)
  * 1 x OpenStack Tenant Network Device - private_network (10.0.30.11/.12)
  * 1 x Ceph Public Network Device - private_network (10.0.40.11/.12)
  * 1 x Ceph Cluster Network Device - private_network (10.0.50.11/.12)

The self-service network options requires to link the provider network interface to a bridge and then route all traffic over that bridge, instead of the interface.

Please read the Vagrantfile, to figure out, how this is done.

```ascii
                                       +----------------------------+
                                       |   Office Router/Gateway    |
                                       | (Default GW: 192.168.x.1)  |
                                       +-------------+--------------+
                                                     |
                                                     |
===+==============================+==============================+==========================
   |                              |                              |           OS Prov. Net
   |                              |                              |           192.168.x.0/24
   |                              |                              |
   |                              |                              |
========+==============================+==============================+=====================
   |    |                         |    |                         |    |      OS Mgmt Net
   |    |                         |    |                         |    |      10.0.10.0/24
   |    |                         |    |                         |    |
   |    |                         |    |                         |    |
=============+==============================+==============================+================
   |    |    |                    |    |    |                    |    |    | OS Pub. Net
   |.10 |    |                    |.11 |    |                    |.12 |    | 10.0.20.0/24
   |    |    |                    |    |    |                    |    |    |
   |    |.10 |                    |    |.11 |                    |    |.12 |
   |    |    |                    |    |    |                    |    |    |
   |    |    |.10                 |    |    |.11                 |    |    |.12
   |    |    |                    |    |    |                    |    |    |
+--+----+----+---------------+ +--+----+----+---------------+ +--+----+----+---------------+
| controller1                | | compute1                   | | compute2                   |
+----------------------------+ +----------------------------+ +----------------------------+
| - Ceph MON, MGR            | | - Ceph MON, MGR, OSDs      | | - Ceph MON,MGR,OSDs        |
| - Chrony (Server)          | | - Chrony (Client)          | | - Chrony (Client)          |
| - ETCD, MariaDB            | | - KVM/QEMU                 | | - KVM/QEMU                 |
| - Memcache,RabbitMQ        | | - Nova (Compute)           | | - Nova (Compute)           |
| - Keystone,Glance-C        | | - Neutron (Comp Agent)     | | - Neutron (Comp Ag)        |
| - Placement,Nova-C         | | - Cinder (Storage)         | | - Cinder (Storage)         |
| - Neutron-C,Cinder-C       | |                            | |                            |
| - Horizon                  | |                            | |                            |
+---------------+----+----+--+ +---------------+----+----+--+ +---------------+----+----+--+
                |    |    |                    |    |    |                    |    |    |
                |.10 |    |                    |.11 |    |                    |.12 |    |
                |    |    |                    |    |    |                    |    |    |
                |    |.10 |                    |    |.11 |                    |    |.12 |
                |    |    |                    |    |    |                    |    |    |
 OS Tenant Net  |    |    |.10                 |    |    |.11                 |    |    |.12
 10.0.30.0/24   |    |    |                    |    |    |                    |    |    |
================+==============================+==============================+=============
                     |    |                         |    |                         |    |
 Ceph Pub. Net       |    |                         |    |                         |    |
 10.0.40.0/24        |    |                         |    |                         |    |
=====================+==============================+==============================+========
                          |                              |                              |
 Ceph Cluster Net         |                              |                              |
 10.0.50.0/24             |                              |                              |
==========================+==============================+==============================+===
```

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


--

Ich befinde mich in der Entwicklung eines Ansible Setups für das ausrollen eines OpenStack cluster mit Ceph als Storage Backebone.

Das Cluster wird Controller Nodes und HCI Nodes (Compute + Storage) beinhalten.

Insgesamt nutzt das Cluster vier Netzwerke:
* OpenStack Management Network
* OpenStack SDN physical Backbone Network
* Ceph Public Network
* Ceph cluster Network

Die Entwicklung findet in einem Vagrant Setup auf basis von drei Virtual Box Maschinen statt.

* controller
  * Ceph Monitor
  * Ceph Manager
  * OpenStack Controller Services
* compute1
  * Ceph Monitor
  * Ceph Manager
  * Ceph OSDs
  * Neutron
  * Nova
  * Cinder 
* compute2
  * Ceph Monitor
  * Ceph Manager
  * Ceph OSDs
  * Neutron
  * Nova
  * Cinder

Das Inventory File ist dazu wie folgt aufgebaut:

```
all:
  # Define all hosts and their specific variables here
  hosts:
    controller:
      ansible_host: controller.os.lokal
      ansible_ssh_common_args: '-i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no'
      ansible_user: vagrant
      ceph_public_ip: 10.0.1.10 # <-- Use the actual IP on the Ceph Public Network
    compute1:
      ansible_host: compute1.os.lokal
      ansible_ssh_common_args: '-i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no'
      ansible_user: vagrant
      ceph_public_ip: 10.0.1.11 # <-- Use the actual IP on the Ceph Public Network
    compute2:
      ansible_host: compute1.os.lokal
      ansible_ssh_common_args: '-i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no'
      ansible_user: vagrant
      ceph_public_ip: 10.0.1.12 # <-- Use the actual IP on the Ceph Public Network

  # Define group structure and membership
  children:
    # --- Functional Groups ---
    ceph_mons:
      hosts:
        controller: {} # Variables inherited from all.hosts.controller
        compute1: {}   # Variables inherited from all.hosts.compute1
        compute2: {}   # Variables inherited from all.hosts.compute2
    ceph_mgrs:
      hosts:
        controller:
        compute1: {}
        compute2: {}
    ceph_osds:
      hosts:
        compute1: {}
        compute2: {}
    ceph_admin_nodes:
      hosts:
        controller: {}
    openstack_controller:
      hosts:
        controller: {}
    openstack_hci:
      hosts:
        compute1: {}
        compute2: {}
    # --- Group of Groups ---
    ceph_cluster:
      children:
        ceph_mons: {} # References the 'ceph_mons' group defined above
        ceph_mgrs: {} # References the 'ceph_mgrs' group defined above
        ceph_osds: {} # References the 'ceph_osds' group defined above
```

Die folgenden Commandlines richten ceph monitore, ceph mgr daemons und OSD nodes ein. In einem nächsten Schritt möchte ich die Kommandos in eine oder mehrere Ansible Rollen aufsplitten. Die Rollen sollen später idempotent sein. Über das Inventory sollten weitere Nodes auf einfache Art hinzugefügt werden können. Dies gillt sowohl für controller als auch compute nodes.

Erstelle Vorschläge für das Playbook und die ceph betreffenden ansible Rollen. Die Rollen müssen dabei noch nicht ausgeführt sein. Ein Rollen Name und Aufgabe der Rolle, sowie die Einordnung in die Rollout Reihenfolge genügen vorerst.







## Manual Installation and configuration of the first mgr node


## OSDs

### Zweck von OSDs (Object Storage Daemons)

Der Ceph OSD (Object Storage Daemon) ist die Komponente, die für die tatsächliche Speicherung der Daten zuständig ist. Jeder OSD verwaltet einen Teil der Daten auf einem lokalen Speichergerät (Festplatte, SSD).

Hier sind die wichtigsten Services und Funktionen, für die `ceph-osd` benötigt wird:

1.  **Datenspeicherung:**
    *   OSDs speichern Objekte auf den ihnen zugewiesenen lokalen Speichergeräten. Jedes Objekt erhält eine eindeutige ID.
    *   Sie sind verantwortlich für das Lesen und Schreiben von Daten auf die physischen Medien.

2.  **Datenreplikation und Erasure Coding:**
    *   Um Datenverlust zu verhindern, replizieren OSDs Objekte über mehrere andere OSDs im Cluster (Standard ist 3 Replikate).
    *   Alternativ kann Erasure Coding verwendet werden, um Speicherplatz effizienter zu nutzen und dennoch Redundanz zu gewährleisten. OSDs führen die Kodierungs- und Dekodierungsoperationen durch.

3.  **Datenintegrität und Scrubbing:**
    *   OSDs führen regelmäßig "Scrubbing"-Operationen durch, um die Integrität der gespeicherten Daten zu überprüfen und Inkonsistenzen zwischen Replikaten zu erkennen und zu reparieren.

4.  **Peering und Recovery:**
    *   OSDs arbeiten in Placement Groups (PGs) zusammen. Wenn ein OSD ausfällt, übernehmen andere OSDs in derselben PG dessen Aufgaben.
    *   Sie sind für den "Peering"-Prozess verantwortlich, bei dem sich OSDs über den Zustand der PGs abstimmen.
    *   Bei Änderungen im Cluster (z.B. OSD-Ausfall, Hinzufügen eines neuen OSDs) sind OSDs für die Datenwiederherstellung ("Recovery") und das Rebalancing ("Backfilling") zuständig.

5.  **Heartbeating und Reporting an Monitore:**
    *   OSDs senden regelmäßig Heartbeats an die Ceph Monitore, um ihren Status (up/down, in/out) zu melden.
    *   Diese Informationen werden von den Monitoren verwendet, um die OSD Map aktuell zu halten.

6.  **CRUSH-Map Interaktion:**
    *   OSDs nutzen die CRUSH-Map (verteilt von den Monitoren), um zu bestimmen, wo Replikate von Objekten gespeichert werden sollen. Dies ermöglicht eine intelligente Datenplatzierung basierend auf der Cluster-Topologie.

7.  **Serving Client Requests:**
    *   Clients kommunizieren direkt mit OSDs (nachdem sie die Cluster-Map von den Monitoren erhalten haben), um Lese- und Schreiboperationen durchzuführen.

8.  **BlueStore und Filestore:**
    *   Moderne Ceph-Versionen verwenden **BlueStore** als Backend-Speicherengine für OSDs. BlueStore verwaltet die rohen Blockgeräte direkt, was die Leistung verbessert und Double-Writes vermeidet, die bei dem älteren **Filestore**-Backend (das ein traditionelles Dateisystem wie XFS nutzte) auftraten. `ceph-volume` ist das Werkzeug der Wahl, um OSDs mit BlueStore zu erstellen und zu verwalten.

**Warum sind OSDs so kritisch?**

*   **Datenverfügbarkeit:** Ohne funktionierende OSDs können keine Daten gelesen oder geschrieben werden. Die Anzahl und der Zustand der OSDs bestimmen die Kapazität und Ausfallsicherheit des Clusters.
*   **Performance:** Die Gesamtleistung des Ceph-Clusters hängt stark von der Anzahl, Art (HDD/SSD/NVMe) und Konfiguration der OSDs ab.

### Update ceph.conf

```
# --- Definition des OSD Blocks, der angehängt werden soll ---
# Stelle sicher, dass der Block mit einer Leerzeile beginnt, um ihn optisch
# vom vorherigen Inhalt der Datei zu trennen.
OSD_CONFIG_BLOCK_TO_APPEND="

[osd]
# Für Testumgebungen:
osd_memory_target_autotune = false
osd_memory_target = 1073741824 # 1 GiB, anpassen falls VMs wenig RAM haben
"

# --- Auf Ihrem externen Knoten, SSH in controller ---
echo ">>> Hänge [osd]-Block an ceph.conf auf controller an..."
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal "sudo bash -c \"cat <<'EOF_OSD_BLOCK' | sudo tee -a /etc/ceph/ceph.conf > /dev/null
$OSD_CONFIG_BLOCK_TO_APPEND
EOF_OSD_BLOCK
\""
echo "--- [osd]-Block an ceph.conf auf controller angehängt ---"
echo

# --- Auf Ihrem externen Knoten, SSH in compute1 ---
echo ">>> Hänge [osd]-Block an ceph.conf auf compute1 an..."
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal "sudo bash -c \"cat <<'EOF_OSD_BLOCK' | sudo tee -a /etc/ceph/ceph.conf > /dev/null
$OSD_CONFIG_BLOCK_TO_APPEND
EOF_OSD_BLOCK
\""
echo "--- [osd]-Block an ceph.conf auf compute1 angehängt ---"
echo

# --- Auf Ihrem externen Knoten, SSH in compute2 ---
echo ">>> Hänge [osd]-Block an ceph.conf auf compute2 an..."
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal "sudo bash -c \"cat <<'EOF_OSD_BLOCK' | sudo tee -a /etc/ceph/ceph.conf > /dev/null
$OSD_CONFIG_BLOCK_TO_APPEND
EOF_OSD_BLOCK
\""
echo "--- [osd]-Block an ceph.conf auf compute2 angehängt ---"
echo

echo "Alle ceph.conf Dateien wurden aktualisiert (Block angehängt)."

# WICHTIG: Damit die OSDs die neue Konfiguration aus ceph.conf lesen, müssen sie neu gestartet werden.
# Die MONs und MGRs sollten ebenfalls neu gestartet werden, um eine konsistente Sicht auf die
# Konfigurationsdatei zu haben.

echo "Starte Ceph-Dienste neu, um die geänderte ceph.conf zu laden..."

ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal '
echo "Neustart der Dienste auf controller..."
sudo systemctl restart ceph-mon@controller.service && sudo systemctl restart ceph-mgr@controller.service
'

ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal '
echo "Neustart der Dienste auf compute1..."
sudo systemctl restart ceph-mon@compute1.service
sudo systemctl restart ceph-mgr@compute1.service
# Finde alle OSD-Dienste und starte sie neu (nur wenn OSDs auf diesem Knoten laufen)
if systemctl list-units --full -all "ceph-osd@*.service" --no-legend | grep -q "."; then
    echo "Starte OSD-Dienste auf compute1 neu..."
    sudo systemctl list-units --full -all "ceph-osd@*.service" --no-legend | awk "{print \$1}" | xargs -r sudo systemctl restart
fi
'

ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal '
echo "Neustart der Dienste auf compute2..."
sudo systemctl restart ceph-mon@compute2.service
sudo systemctl restart ceph-mgr@compute2.service
# Finde alle OSD-Dienste und starte sie neu (nur wenn OSDs auf diesem Knoten laufen)
if systemctl list-units --full -all "ceph-osd@*.service" --no-legend | grep -q "."; then
    echo "Starte OSD-Dienste auf compute2 neu..."
    sudo systemctl list-units --full -all "ceph-osd@*.service" --no-legend | awk "{print \$1}" | xargs -r sudo systemctl restart
fi
'

echo "Neustart der Dienste initiiert. Warte kurz, bis sich der Cluster stabilisiert..."
sleep 20

# Überprüfe den Status erneut
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo ceph -s'

echo
echo "WICHTIG: Überprüfe den Inhalt der /etc/ceph/ceph.conf auf allen Nodes manuell, um sicherzustellen, dass der [osd]-Block korrekt und nicht mehrfach vorhanden ist!"
```

### Install dependencies

```
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo apt update && sudo apt install -y ceph-osd gdisk'

# Auf Ihrem externen Knoten, SSH in compute2
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal 'sudo apt update && sudo apt install -y ceph-osd gdisk'
```

### Prepare the osd keyring

```
# Auf Ihrem externen Knoten, SSH in controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal '
sudo ceph auth get-or-create client.bootstrap-osd mon "allow profile bootstrap-osd"

# Hole den Keyring auf dem Controller-Node in eine temporäre Datei
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal '
sudo ceph auth get client.bootstrap-osd -o /tmp/ceph.bootstrap-osd.keyring
sudo chown vagrant:vagrant /tmp/ceph.bootstrap-osd.keyring
'

# Kopiere den Keyring vom Controller zu deinem externen Knoten (lokal)
scp -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no \
vagrant@controller.os.lokal:/tmp/ceph.bootstrap-osd.keyring \
/tmp/ceph.bootstrap-osd.keyring.local

# --- Für compute1 ---
# Kopiere den Keyring von deinem externen Knoten nach compute1
scp -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no \
/tmp/ceph.bootstrap-osd.keyring.local \
vagrant@compute1.os.lokal:/tmp/ceph.bootstrap-osd.keyring

# Auf compute1: Erstelle das Verzeichnis und verschiebe den Keyring dorthin, setze Berechtigungen
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal '
sudo mkdir -p /var/lib/ceph/bootstrap-osd/
sudo mv /tmp/ceph.bootstrap-osd.keyring /var/lib/ceph/bootstrap-osd/ceph.keyring
sudo chown ceph:ceph /var/lib/ceph/bootstrap-osd/ceph.keyring
sudo chmod 600 /var/lib/ceph/bootstrap-osd/ceph.keyring
echo "Bootstrap OSD Keyring auf compute1 eingerichtet."
'

# --- Für compute2 ---
# Kopiere den Keyring von deinem externen Knoten nach compute2
scp -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no \
/tmp/ceph.bootstrap-osd.keyring.local \
vagrant@compute2.os.lokal:/tmp/ceph.bootstrap-osd.keyring

# Auf compute2: Erstelle das Verzeichnis und verschiebe den Keyring dorthin, setze Berechtigungen
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal '
sudo mkdir -p /var/lib/ceph/bootstrap-osd/
sudo mv /tmp/ceph.bootstrap-osd.keyring /var/lib/ceph/bootstrap-osd/ceph.keyring
sudo chown ceph:ceph /var/lib/ceph/bootstrap-osd/ceph.keyring
sudo chmod 600 /var/lib/ceph/bootstrap-osd/ceph.keyring
echo "Bootstrap OSD Keyring auf compute2 eingerichtet."
'

# Bereinige die temporäre lokale Keyring-Datei
rm /tmp/ceph.bootstrap-osd.keyring.local

# Bereinige die temporäre Keyring-Datei auf dem Controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal '
sudo rm /tmp/ceph.bootstrap-osd.keyring
'
```

### Prepare the OSDs

```
# Auf Ihrem externen Knoten, SSH in compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal '
# Überprüfe verfügbare Disks (optional, aber gut zur Verifizierung)
echo "Verfügbare Blockgeräte auf compute1:"
sudo lsblk

# ANNAHME: Die erste virtuelle Disk für OSDs ist /dev/sdb
OSD_DEVICE_1="/dev/sdb"
# ANNAHME: Die zweite virtuelle Disk für OSDs ist /dev/sdc
OSD_DEVICE_2="/dev/sdc"

echo "Lösche Partitionstabelle und Daten auf $OSD_DEVICE_1 (falls vorhanden)..."
sudo ceph-volume lvm zap $OSD_DEVICE_1 --destroy
echo "Erstelle OSD auf $OSD_DEVICE_1..."
sudo ceph-volume lvm create --data $OSD_DEVICE_1

echo "Lösche Partitionstabelle und Daten auf $OSD_DEVICE_2 (falls vorhanden)..."
sudo ceph-volume lvm zap $OSD_DEVICE_2 --destroy
echo "Erstelle OSD auf $OSD_DEVICE_2..."
sudo ceph-volume lvm create --data $OSD_DEVICE_2

echo "OSD Erstellung auf compute1 abgeschlossen."
'

# Auf Ihrem externen Knoten, SSH in compute2
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal '
# Überprüfe verfügbare Disks (optional, aber gut zur Verifizierung)
echo "Verfügbare Blockgeräte auf compute2:"
sudo lsblk

# ANNAHME: Die erste virtuelle Disk für OSDs ist /dev/sdb
OSD_DEVICE_1="/dev/sdb"
# ANNAHME: Die zweite virtuelle Disk für OSDs ist /dev/sdc
OSD_DEVICE_2="/dev/sdc"

echo "Lösche Partitionstabelle und Daten auf $OSD_DEVICE_1 (falls vorhanden)..."
sudo ceph-volume lvm zap $OSD_DEVICE_1 --destroy
echo "Erstelle OSD auf $OSD_DEVICE_1..."
sudo ceph-volume lvm create --data $OSD_DEVICE_1

echo "Lösche Partitionstabelle und Daten auf $OSD_DEVICE_2 (falls vorhanden)..."
sudo ceph-volume lvm zap $OSD_DEVICE_2 --destroy
echo "Erstelle OSD auf $OSD_DEVICE_2..."
sudo ceph-volume lvm create --data $OSD_DEVICE_2

echo "OSD Erstellung auf compute2 abgeschlossen."
'
```

### Verify the OSDs

```
# Auf Ihrem externen Knoten, SSH in controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal '
echo "Warte 20 Sekunden, bis OSDs dem Cluster beitreten und sich stabilisieren..."
sleep 20

echo "Ceph Status (-s):"
sudo ceph -s

echo "Ceph OSD Baum (osd tree):"
sudo ceph osd tree

echo "Ceph OSD Statistik (osd stat):"
sudo ceph osd stat

echo "Ceph Health Details:"
sudo ceph health detail

echo "Ceph Verzeichnisnutzung (df):"
sudo ceph df

echo "Überprüfe, ob alle OSD Dienste laufen (Beispiel für compute1):"
# Dieser Befehl muss eigentlich auf compute1 ausgeführt werden, oder du musst cephadm/rook nutzen,
# um den Status zentral abzufragen. Für eine manuelle Installation kannst du dich direkt auf compute1 einloggen.
# Für eine schnelle Überprüfung kannst du auch in der Ausgabe von `ceph osd tree` schauen, ob alle OSDs `up` und `in` sind.
# Die `ceph-volume lvm list` Ausgabe auf den jeweiligen Nodes zeigt die lokal aktiven OSDs.
'
# SSH in compute1, um lokale OSDs zu listen (optional)
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo ceph-volume lvm list'

# SSH in compute2, um lokale OSDs zu listen (optional)
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal 'sudo ceph-volume lvm list'
```

### Pools for OpenStack

**Überlegungen zur Pool-Konfiguration:**
*   **Replikationsgröße:** Deine `ceph.conf` hat `osd_pool_default_size = 2` und `osd_pool_default_min_size = 1`. Das bedeutet, dass standardmäßig jeder Pool mit einer Replikationsgröße von 2 erstellt wird. Für ein Test-Setup mit nur 4 OSDs (2 pro HCI-Node) ist das eine vernünftige Wahl, um Speicherplatz zu sparen und trotzdem eine gewisse Ausfallsicherheit zu haben (Ausfall eines OSDs pro Replikationsset wird toleriert).
*   **Placement Groups (PGs):** Die Anzahl der PGs ist wichtig für die Datenverteilung. Eine gängige Startempfehlung ist `(Anzahl OSDs * 100) / Replikationsfaktor`, das Ergebnis dann auf die nächste Potenz von 2 aufrunden. In deinem Fall: `(4 * 100) / 2 = 200`. Die nächsten Potenzen von 2 wären 128 oder 256.
    Allerdings ist für sehr kleine Cluster wie deinen (4 OSDs) diese Formel oft zu hoch und führt zu vielen PGs pro OSD.
    Da du den `pg_autoscaler` aktiviert hast (`osd_pool_default_pg_autoscale_mode = on`), können wir mit einer kleineren, vernünftigen Anzahl von PGs starten (z.B. 32 oder 64 pro Pool), und der Autoscaler wird dies bei Bedarf anpassen. Beginnen wir mit **32 PGs** pro Pool. `pgp_num` sollte initial gleich `pg_num` sein.
*   **Application Tagging:** Es ist eine gute Praxis, Pools mit der Anwendung zu taggen, die sie verwenden wird (z.B. `rbd` für diese Pools).

#### Pool for Galnce (Images)

```
# Auf Ihrem externen Knoten, SSH in controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal '
# Pool "images" mit 32 PGs erstellen
# Die Standard-Replikationsgröße (size 2) wird verwendet.
echo "Erstelle Pool images..."
sudo ceph osd pool create images 32 32

# Pool für die RBD-Anwendung initialisieren/taggen
echo "Initialisiere Pool images für RBD..."
sudo ceph osd pool application enable images rbd
# sudo rbd pool init images # Bei neueren Ceph-Versionen ist dies oft implizit durch "application enable"

# Überprüfen (optional)
echo "Pool images Status:"
sudo ceph osd pool ls detail | grep "pool images" -A 5
sudo ceph osd pool get images pg_num
sudo ceph osd pool get images pg_autoscale_mode

echo "Pool images für Glance erstellt."
'
```

#### Pool for Cinder (Volumes)

```
# Auf Ihrem externen Knoten, SSH in controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal '
# Pool "volumes" mit 32 PGs erstellen
echo "Erstelle Pool volumes..."
sudo ceph osd pool create volumes 32 32

# Pool für die RBD-Anwendung initialisieren/taggen
echo "Initialisiere Pool volumes für RBD..."
sudo ceph osd pool application enable volumes rbd
# sudo rbd pool init volumes

# Überprüfen (optional)
echo "Pool volumes Status:"
sudo ceph osd pool ls detail | grep "pool volumes" -A 5
sudo ceph osd pool get volumes pg_num
sudo ceph osd pool get volumes pg_autoscale_mode

echo "Pool volumes für Cinder erstellt."
'
```

#### Pool for Nova (VMs/ephemeral Disks)

```
# Auf Ihrem externen Knoten, SSH in controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal '
# Pool "vms" mit 32 PGs erstellen
echo "Erstelle Pool vms..."
sudo ceph osd pool create vms 32 32

# Pool für die RBD-Anwendung initialisieren/taggen
echo "Initialisiere Pool vms für RBD..."
sudo ceph osd pool application enable vms rbd
# sudo rbd pool init vms

# Überprüfen (optional)
echo "Pool vms Status:"
sudo ceph osd pool ls detail | grep "pool vms" -A 5
sudo ceph osd pool get vms pg_num
sudo ceph osd pool get vms pg_autoscale_mode

echo "Pool vms für Nova erstellt."
'
```

