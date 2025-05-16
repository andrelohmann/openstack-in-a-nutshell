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
* 2 x Compute Node
  * 1 x management network device - private_network (10.0.0.21)
  * 1 x provider network device - public_network (dhcp)

The self-service network options requires to link the provider network interface to a bridge and then route all traffic over that bridge, instead of the interface.

Please read the Vagrantfile, to figure out, how this is done.

```ascii
                                       +----------------------------+
                                       |   Office Router/Gateway    |
                                       | (Default GW: 192.168.x.1)  |
                                       +-------------+--------------+
                                                     |
                                                     | .10  .11   .12 (IPs an den senkrechten Linien unten)
==+==OpenStack Provider Network (192.168.x.0/24)====================================
  |                           +                            +
                 |                           |                            |
                 |                           |                            | .10  .11   .12
====================OpenStack Public Network (OS-API, 10.0.4.0/24)===================
                   +                             +                          +
                   |                             |                          |
                   |                             |                          | .10  .11   .12
======================OpenStack Management Network (Mgmt, 10.0.0.0/24)=================
                     +                               +                        +
192.168.178.10       |                               |                        | 192.168.178.12
10.0.4.10            |        192.168.178.11         |                        | 10.0.4.12
10.0.0.10            |        10.0.4.11              |         192.168.178.12 | 10.0.0.12
                     |        10.0.0.11              |         10.0.4.12      |
+----------------------------+ +----------------------------+ +----------------------------+
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
+----------------------------+ +----------------------------+ +----------------------------+
10.0.3.10            |        10.0.3.11              |         10.0.3.12      |
10.0.1.10            |        10.0.1.11              |         10.0.1.12      |
10.0.2.10            |        10.0.2.11              |         10.0.2.12      |
                     +                               +                        +
======================OpenStack Tenant Network (Tenant, 10.0.3.0/24)===================
                   |                             |                          |
                   |                             |                          | .10  .11   .12
====================Ceph Public Network (CephPub, 10.0.1.0/24)=======================
                 +                           +                            +
                 |                           |                            |
                 |                           |                            | .10  .11   .12
=================Ceph Cluster Network (CephClus, 10.0.2.0/24)=====================
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


# CEPH Install Tests

## Install Chrony to all nodes

```
# Auf Ihrem externen Knoten, SSH in controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal '
sudo apt update
sudo apt install -y chrony
sudo systemctl enable chrony
sudo systemctl start chrony
sleep 5 # Gib chrony einen Moment zum Synchronisieren
sudo chronyc sources
sudo chronyc tracking
date # Überprüfe die aktuelle Zeit
'

# Auf Ihrem externen Knoten, SSH in compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal '
sudo apt update
sudo apt install -y chrony
sudo systemctl enable chrony
sudo systemctl start chrony
sleep 5 # Gib chrony einen Moment zum Synchronisieren
sudo chronyc sources
sudo chronyc tracking
date # Überprüfe die aktuelle Zeit
'

# Auf Ihrem externen Knoten, SSH in compute2
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal '
sudo apt update
sudo apt install -y chrony
sudo systemctl enable chrony
sudo systemctl start chrony
sleep 5 # Gib chrony einen Moment zum Synchronisieren
sudo chronyc sources
sudo chronyc tracking
date # Überprüfe die aktuelle Zeit
'
```

## Manual Installation and configuration of the first monitor node

### Purpose of monitor

Der Ceph Monitor (MON) ist das "Gehirn" und die zentrale Autorität des Ceph-Clusters. Ohne ein funktionierendes Monitor-Quorum kann der Cluster nicht operieren. Monitore sind zuständig für die Aufrechterhaltung des Cluster-Zustands und der Konsistenz der Cluster-Maps.

Hier sind die wichtigsten Services und Funktionen, für die der `ceph-mon` benötigt wird:

1.  **Cluster Map Management (Monitor Map, OSD Map, PG Map, CRUSH Map, MDS Map):**
    *   **Zentrale Funktion:** MONs verwalten die kritischen Zustandsinformationen des Clusters in Form von "Maps".
    *   **Monitor Map:** Enthält Informationen über die Monitore selbst: ihre Epoche, Namen, Adressen und den aktuellen Quorum-Status.
    *   **OSD Map:** Verfolgt den Zustand aller OSDs (up/down, in/out), ihre Adressen, Gewichte und die CRUSH-Hierarchie (implizit durch die CRUSH Map).
    *   **Placement Group (PG) Map:** Enthält den Zustand aller PGs, ihre Zuordnung zu OSDs und Informationen über Peering-Prozesse.
    *   **CRUSH Map:** Definiert die Regeln, wie Daten im Cluster platziert werden (Controlled Replication Under Scalable Hashing). MONs speichern und verteilen die CRUSH Map. Änderungen an der CRUSH Map werden über die MONs propagiert.
    *   **MDS Map:** (Für CephFS) Verfolgt den Zustand der Metadata Server (MDS).
    *   Diese Maps werden in Epochen versioniert. Jede signifikante Änderung im Cluster-Zustand führt zu einer neuen Epoche der entsprechenden Map.

2.  **Authentifizierung und Autorisierung (CephX):**
    *   MONs sind verantwortlich für die Verwaltung des CephX-Authentifizierungssystems.
    *   Sie speichern die Schlüssel für Clients und Daemons (OSDs, MGRs, MDSs).
    *   Wenn sich ein Client oder Daemon mit dem Cluster verbinden will, authentifiziert er sich gegenüber einem MON. Der MON prüft den Schlüssel und erteilt bei Erfolg ein Ticket mit den entsprechenden Berechtigungen (Capabilities).

3.  **Quorum und Konsens (Paxos):**
    *   Um die Konsistenz der Cluster-Maps sicherzustellen, verwenden MONs einen Konsensalgorithmus (eine Variante von Paxos).
    *   Ein Quorum (Mehrheit der Monitore, typischerweise (n/2)+1 bei n Monitoren) muss zustimmen, bevor Änderungen an den Maps vorgenommen und als verbindlich erklärt werden.
    *   Dies verhindert "Split-Brain"-Szenarien und stellt sicher, dass alle Komponenten des Clusters eine konsistente Sicht auf den Cluster-Zustand haben.

4.  **Cluster Log (nicht zu verwechseln mit Debug-Logs):**
    *   MONs führen ein kompaktes, versioniertes Log der wichtigsten Cluster-Ereignisse und -Zustandsänderungen.
    *   Dies ist entscheidend für die Wiederherstellung und Konsistenz.

5.  **Schnittstelle für Cluster-Management-Befehle:**
    *   Viele `ceph`-CLI-Befehle, die den Cluster-Zustand modifizieren oder abfragen (z.B. `ceph osd in`, `ceph health`, `ceph auth add`), kommunizieren direkt oder indirekt mit den MONs.
    *   Die MONs sind der zentrale Punkt, um Konfigurationsänderungen (gespeichert in der Monitor-DB, z.B. via `ceph config set`) entgegenzunehmen und zu verteilen.

6.  **Client-Bootstrapping:**
    *   Wenn ein Client (oder ein anderer Daemon) startet, kontaktiert er einen der in seiner `ceph.conf` definierten MONs, um die aktuelle Cluster Map und Authentifizierungsinformationen zu erhalten.

7.  **Gesundheitsüberwachung (Basislevel):**
    *   MONs sammeln grundlegende Zustandsinformationen von anderen Daemons (z.B. Heartbeats von OSDs).
    *   Basierend auf diesen Informationen und den Maps bestimmen sie den allgemeinen Gesundheitszustand des Clusters (HEALTH_OK, HEALTH_WARN, HEALTH_ERR). Der `ceph-mgr` baut darauf auf, um detailliertere Analysen und Metriken bereitzustellen.

8.  **Speicherung der zentralen Konfigurationsdatenbank:**
    *   Einstellungen, die über `ceph config set <daemon> <option> <value>` vorgenommen werden, werden in einer Datenbank gespeichert, die von den Monitoren verwaltet wird. Diese Konfiguration wird dann an die jeweiligen Daemons verteilt.

**Warum sind MONs so kritisch?**

*   **Single Source of Truth:** Die von den MONs verwalteten Maps sind die maßgebliche Wahrheit über den Zustand und die Topologie des Clusters.
*   **Konsistenz:** Der Paxos-basierte Konsensmechanismus stellt sicher, dass diese Wahrheit konsistent ist, selbst bei Ausfällen einzelner Monitore (solange ein Quorum besteht).
*   **Verfügbarkeit:** Ohne ein funktionierendes Monitor-Quorum können keine Lese- oder Schreiboperationen zuverlässig durchgeführt werden, da Clients und OSDs keine aktuellen Maps erhalten oder ihren Zustand nicht melden können.

**Unterschiede zum `ceph-mgr`:**

| Aspekt            | Ceph Monitor (`ceph-mon`)                                  | Ceph Manager (`ceph-mgr`)                                       |
| :---------------- | :--------------------------------------------------------- | :-------------------------------------------------------------- |
| **Kernaufgabe**   | Cluster-Maps, Konsens, Authentifizierung, Basiszustand      | Höherlevelige Management-Dienste, Metriken, APIs, Module         |
| **Kritikalität**  | Extrem hoch (Cluster funktioniert nicht ohne Quorum)        | Hoch für Management-Features, aber Cluster kann Basis-IO ohne aktiven MGR |
| **Anzahl**        | Ungerade Anzahl (typ. 3 oder 5) für Quorum                 | Mind. 1 aktiv, typ. 2+ für HA (Aktiv/Standby)                   |
| **Ressourcen**    | Relativ leichtgewichtig, aber I/O-sensitiv (Paxos-DB)      | Kann ressourcenintensiver sein (je nach Modulen, z.B. Dashboard) |
| **Schnittstelle** | Interne Protokolle, CephX, Basis-CLI-Interaktion          | REST API, Dashboard UI, Prometheus Exporter, Modul-spezifische Interaktionen |
| **Datenhaltung**  | Cluster-Maps, Auth-Schlüssel, Konfig-DB (LevelDB/RocksDB) | Temporäre Zustände, Modul-Daten, sammelt Crash-Dumps            |

### Install dependencies

```
# On your external node, SSH into controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo apt update && sudo apt install -y acl ceph-common ceph-mon'

# On your external node, SSH into controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo bash -c "cat > /etc/ceph/ceph.conf << EOF
[global]
fsid = 7272bf23-0a44-42e6-b591-5569713531fa
# mon_initial_members will ONLY list the node used for mkfs initially
mon_host = 10.0.1.10
public_network = 10.0.1.0/24
cluster_network = 10.0.2.0/24
ms_bind_msgr2 = true

# Optional but good for dev/test
osd_pool_default_size = 2
osd_pool_default_min_size = 1
mon_allow_pool_delete = true

[mon]
# mon_initial_members is used by ´ceph-mon --mkfs´.
# If you are bootstrapping with mkfs on each MON, it might be useful here
# or passed directly to mkfs. For running MONs, it´s not critical.
# For the single-node bootstrap, it was only needed on 'controller' initially.
# If you are updating this file on all nodes for a multi-node setup later, list all:
mon_initial_members = controller

# This setting specifically affects monitor behavior
mon_allow_pool_delete = true

# This is a monitor security setting
auth_allow_insecure_global_id_reclaim = false

# You can also be explicit about monitor-specific bind addresses if needed,
# though ms_bind_msgr2 in [global] should handle it.
# Example:
# mon_data = /var/lib/ceph/mon/ceph-$id  # Default, but can be explicit
# public_bind_addr = [v2:MON_IP:3300,v1:MON_IP:6789] # If you need to be very specific per monitor

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
# Be explicit about v1 and v2 addresses for the controller from the start
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo monmaptool --create --addv controller "[v2:10.0.1.10:3300,v1:10.0.1.10:6789]" --fsid 7272bf23-0a44-42e6-b591-5569713531fa /tmp/monmap.initial'

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

# Address Insecure Global ID Reclaim
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo ceph config set mon auth_allow_insecure_global_id_reclaim false'
```

### Verify the monitor

```
# On your external node, SSH into controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal '
sudo systemctl status ceph-mon@controller.service # Check service status
sleep 10 # Wait a bit
sudo ceph mon stat # Should show quorum [0] controller
sudo ceph -s
'
# Look for 'mon: 1 daemons, quorum 0 controller'
```

## Manual Installation and configuration of further monitors

### Install dependencies on new monitors

```
# On your external node, SSH into compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo apt update && sudo apt install -y acl ceph-common ceph-mon'

# On your external node, SSH into compute2
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal 'sudo apt update && sudo apt install -y acl ceph-common ceph-mon'
```

### Create or update ceph.conf on all nodes

```
# On your external node, SSH into controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo bash -c "cat > /etc/ceph/ceph.conf << EOF
[global]
fsid = 7272bf23-0a44-42e6-b591-5569713531fa
# mon_initial_members will ONLY list the node used for mkfs initially
mon_host = 10.0.1.10,10.0.1.11,10.0.1.12
public_network = 10.0.1.0/24
cluster_network = 10.0.2.0/24
ms_bind_msgr2 = true

# Optional but good for dev/test
osd_pool_default_size = 2
osd_pool_default_min_size = 1
mon_allow_pool_delete = true

[mon]
# mon_initial_members is used by ´ceph-mon --mkfs´.
# If you are bootstrapping with mkfs on each MON, it might be useful here
# or passed directly to mkfs. For running MONs, it´s not critical.
# For the single-node bootstrap, it was only needed on 'controller' initially.
# If you are updating this file on all nodes for a multi-node setup later, list all:
mon_initial_members = controller,compute1,compute2

# This setting specifically affects monitor behavior
mon_allow_pool_delete = true

# This is a monitor security setting
auth_allow_insecure_global_id_reclaim = false

# You can also be explicit about monitor-specific bind addresses if needed,
# though ms_bind_msgr2 in [global] should handle it.
# Example:
# mon_data = /var/lib/ceph/mon/ceph-$id  # Default, but can be explicit
# public_bind_addr = [v2:MON_IP:3300,v1:MON_IP:6789] # If you need to be very specific per monitor

[client.admin]
keyring = /etc/ceph/ceph.client.admin.keyring
EOF
"'

# On your external node, SSH into compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo bash -c "cat > /etc/ceph/ceph.conf << EOF
[global]
fsid = 7272bf23-0a44-42e6-b591-5569713531fa
# mon_initial_members will ONLY list the node used for mkfs initially
mon_host = 10.0.1.10,10.0.1.11,10.0.1.12
public_network = 10.0.1.0/24
cluster_network = 10.0.2.0/24
ms_bind_msgr2 = true

# Optional but good for dev/test
osd_pool_default_size = 2
osd_pool_default_min_size = 1
mon_allow_pool_delete = true

[mon]
# mon_initial_members is used by ´ceph-mon --mkfs´.
# If you are bootstrapping with mkfs on each MON, it might be useful here
# or passed directly to mkfs. For running MONs, it´s not critical.
# For the single-node bootstrap, it was only needed on 'controller' initially.
# If you are updating this file on all nodes for a multi-node setup later, list all:
mon_initial_members = controller,compute1,compute2

# This setting specifically affects monitor behavior
mon_allow_pool_delete = true

# This is a monitor security setting
auth_allow_insecure_global_id_reclaim = false

# You can also be explicit about monitor-specific bind addresses if needed,
# though ms_bind_msgr2 in [global] should handle it.
# Example:
# mon_data = /var/lib/ceph/mon/ceph-$id  # Default, but can be explicit
# public_bind_addr = [v2:MON_IP:3300,v1:MON_IP:6789] # If you need to be very specific per monitor

[client.admin]
keyring = /etc/ceph/ceph.client.admin.keyring
EOF
"'

# On your external node, SSH into compute2
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal 'sudo bash -c "cat > /etc/ceph/ceph.conf << EOF
[global]
fsid = 7272bf23-0a44-42e6-b591-5569713531fa
# mon_initial_members will ONLY list the node used for mkfs initially
mon_host = 10.0.1.10,10.0.1.11,10.0.1.12
public_network = 10.0.1.0/24
cluster_network = 10.0.2.0/24
ms_bind_msgr2 = true

# Optional but good for dev/test
osd_pool_default_size = 2
osd_pool_default_min_size = 1
mon_allow_pool_delete = true

[mon]
# mon_initial_members is used by ´ceph-mon --mkfs´.
# If you are bootstrapping with mkfs on each MON, it might be useful here
# or passed directly to mkfs. For running MONs, it´s not critical.
# For the single-node bootstrap, it was only needed on 'controller' initially.
# If you are updating this file on all nodes for a multi-node setup later, list all:
mon_initial_members = controller,compute1,compute2

# This setting specifically affects monitor behavior
mon_allow_pool_delete = true

# This is a monitor security setting
auth_allow_insecure_global_id_reclaim = false

# You can also be explicit about monitor-specific bind addresses if needed,
# though ms_bind_msgr2 in [global] should handle it.
# Example:
# mon_data = /var/lib/ceph/mon/ceph-$id  # Default, but can be explicit
# public_bind_addr = [v2:MON_IP:3300,v1:MON_IP:6789] # If you need to be very specific per monitor

[client.admin]
keyring = /etc/ceph/ceph.client.admin.keyring
EOF
"'
```

### Prepare the files on the controller node and distribute to the new monitors

```
# Restart the controller to apply the ceph.conf changes
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo systemctl restart ceph-mon@controller.service'

# Create the monmap
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo sh -c "ceph --cluster ceph mon getmap -o /tmp/monmap"'

# Make the temporary monmap readable by vagrant for scp from controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo chown vagrant:vagrant /tmp/monmap'

# Copy ceph.client.admin.keyring
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo cp /etc/ceph/ceph.client.admin.keyring /tmp/ceph.client.admin.keyring'

# Make the temporary ceph.client.admin.keyring readable by vagrant for scp from controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo chown vagrant:vagrant /tmp/ceph.client.admin.keyring'

# Create ceph.mon.keyring
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo sh -c "ceph --cluster ceph auth get mon. -o /tmp/ceph.mon.keyring"'

# Make the temporary key readable by vagrant for scp from controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo chown vagrant:vagrant /tmp/ceph.mon.keyring'

# Copy the temporary monmap from controller to your external node
scp -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal:/tmp/monmap /tmp/monmap.local # Copy to a temp name locally

# Copy the temporary admin key from controller to your external node
scp -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal:/tmp/ceph.client.admin.keyring /tmp/ceph.client.admin.keyring.local # Copy to a temp name locally

# Copy the temporary key from controller to your external node
scp -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal:/tmp/ceph.mon.keyring /tmp/ceph.mon.keyring.local # Copy to a temp name locally

# Copy the monmap from your external node to /tmp/ on compute1
scp -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no \
/tmp/monmap.local \
vagrant@compute1.os.lokal:/tmp/monmap

# Change the owner of monmap to ceph
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo sh -c "chown ceph:ceph /tmp/monmap"'

# Copy the key from your external node to /tmp/ on compute1
scp -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no \
/tmp/ceph.mon.keyring.local \
vagrant@compute1.os.lokal:/tmp/ceph.mon.keyring

# Change the owner of key to ceph
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo sh -c "chown ceph:ceph /tmp/ceph.mon.keyring"'

# Copy the admin key from your external node to /tmp/ on compute1
scp -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no \
/tmp/ceph.client.admin.keyring.local \
vagrant@compute1.os.lokal:/tmp/ceph.client.admin.keyring

# Move the admin key to /etc/ceph
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo mv /tmp/ceph.client.admin.keyring /etc/ceph/ceph.client.admin.keyring'

# Change the owner of admin key to ceph
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo sh -c "chown ceph:ceph /etc/ceph/ceph.client.admin.keyring"'

# Copy the monmap from your external node to /tmp/ on compute2
scp -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no \
/tmp/monmap.local \
vagrant@compute2.os.lokal:/tmp/monmap

# Change the owner of monmap to ceph
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal 'sudo sh -c "chown ceph:ceph /tmp/monmap"'

# Copy the key from your external node to /tmp/ on compute2
scp -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no \
/tmp/ceph.mon.keyring.local \
vagrant@compute2.os.lokal:/tmp/ceph.mon.keyring

# Change the owner of key to ceph
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal 'sudo sh -c "chown ceph:ceph /tmp/ceph.mon.keyring"'

# Copy the admin key from your external node to /tmp/ on compute2
scp -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no \
/tmp/ceph.client.admin.keyring.local \
vagrant@compute2.os.lokal:/tmp/ceph.client.admin.keyring

# Move the admin key to /etc/ceph
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal 'sudo mv /tmp/ceph.client.admin.keyring /etc/ceph/ceph.client.admin.keyring'

# Change the owner of admin key to ceph
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal 'sudo sh -c "chown ceph:ceph /etc/ceph/ceph.client.admin.keyring"'

# Clean up the temporary files on your external node
rm /tmp/monmap.local /tmp/ceph.mon.keyring.local /tmp/ceph.client.admin.keyring.local
```

### Prepare the new monitors

```
# Create Monitor data directory for compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo mkdir -p /var/lib/ceph/mon/ceph-compute1 && sudo chown ceph:ceph /var/lib/ceph/mon/ceph-compute1'

# Create Monitor data directory for compute2
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal 'sudo mkdir -p /var/lib/ceph/mon/ceph-compute2 && sudo chown ceph:ceph /var/lib/ceph/mon/ceph-compute2'

# Initialize the new monitor on compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo -u ceph ceph-mon --mkfs -i compute1 --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring'

# Initialize the new monitor on compute2
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal 'sudo -u ceph ceph-mon --mkfs -i compute2 --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring'

# Activate and start ceph-mon on compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo systemctl enable ceph-mon@compute1.service'
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo systemctl start ceph-mon@compute1.service'

# Activate and start ceph-mon on compute2
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal 'sudo systemctl enable ceph-mon@compute2.service'
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal 'sudo systemctl start ceph-mon@compute2.service'
```

## Manual Installation and configuration of the first mgr node

### Purpose of manager nodes

* Ceph Dashboard
  * Dies ist eine der prominentesten Funktionen. Das Dashboard bietet eine webbasierte Benutzeroberfläche zur Überwachung des Cluster-Zustands, der Performance, der Konfiguration und zur Durchführung einiger Verwaltungsaufgaben. Ohne einen aktiven ceph-mgr gibt es kein Dashboard.
* RESTful API
  * Der ceph-mgr stellt eine REST-API bereit, die es externen Tools und Skripten ermöglicht, Informationen über den Cluster abzurufen und bestimmte Verwaltungsaktionen durchzuführen.
* Prometheus Exporter (Metriken)
  * Das prometheus-Modul im ceph-mgr sammelt detaillierte Leistungsmetriken und Zustandsinformationen vom gesamten Cluster und stellt sie im Prometheus-Format bereit. Dies ermöglicht die Integration mit Monitoring-Systemen wie Prometheus und Grafana für erweiterte Visualisierung und Alarmierung.
* Placement Group (PG) Autoscaler
  * Das pg_autoscaler-Modul kann die Anzahl der PGs für Pools automatisch anpassen, basierend auf der tatsächlichen Datennutzung. Dies hilft, die PGs optimal zu verteilen und die Clusterleistung zu verbessern, ohne dass manuelle Eingriffe erforderlich sind.
* Device Health Management
  * Module wie devicehealth überwachen den Zustand der physischen Speichergeräte (OSDs) und können Warnungen ausgeben oder sogar versuchen, fehlerhafte Geräte basierend auf SMART-Daten oder anderen Metriken vorherzusagen.
* Balancer
  * Das balancer-Modul kann die Verteilung von PGs über OSDs optimieren, um eine gleichmäßigere Auslastung der Geräte sicherzustellen. Es kann im Hintergrund laufen und PGs bei Bedarf verschieben.
* Crash-Modul
  * Das crash-Modul sammelt Absturzinformationen von Ceph-Daemons. Diese Dumps werden vom ceph-mgr gesammelt und gespeichert, was die Fehlersuche erheblich erleichtert.
* Telemetry-Modul
  * Das telemetry-Modul kann (optional und anonymisiert) Nutzungs- und Leistungsdaten an das Ceph-Projekt senden. Diese Daten helfen den Entwicklern, Ceph zu verbessern.
* Orchestrator-Integration (z.B. Rook, cephadm)
  * ceph-mgr beherbergt Module, die als Schnittstelle zu externen Orchestrierungstools dienen (z.B. rook Modul für Kubernetes-Integration, cephadm Modul für die native Ceph-Orchestrierung). Diese Module ermöglichen es dem Orchestrator, den Ceph-Cluster zu verwalten (OSDs hinzufügen/entfernen, Dienste aktualisieren etc.).
* Ausführung von ceph tell mgr ... Befehlen
  * Viele spezifische Konfigurations- und Abfragebefehle für die oben genannten Module werden über ceph tell mgr.<modulname> <befehl> ausgeführt.
* Bereitstellung von "Higher-Level" Cluster-Informationen
  * Während MONs den grundlegenden Cluster-Status (Map-Epochs, Quorum) verwalten, kann der ceph-mgr komplexere Zustandsinformationen aggregieren und bereitstellen, die für Managementzwecke nützlich sind (z.B. detaillierte Pool-Statistiken, OSD-Auslastung).


### Install Dependencies

```
# On your external node, SSH into controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo bash -c "cat > /etc/ceph/ceph.conf << EOF
[global]
fsid = 7272bf23-0a44-42e6-b591-5569713531fa
# mon_initial_members will ONLY list the node used for mkfs initially
mon_host = 10.0.1.10,10.0.1.11,10.0.1.12
public_network = 10.0.1.0/24
cluster_network = 10.0.2.0/24
ms_bind_msgr2 = true

# Optional but good for dev/test
osd_pool_default_size = 2
osd_pool_default_min_size = 1
mon_allow_pool_delete = true

[mon]
# mon_initial_members is used by ´ceph-mon --mkfs´.
# If you are bootstrapping with mkfs on each MON, it might be useful here
# or passed directly to mkfs. For running MONs, it´s not critical.
# For the single-node bootstrap, it was only needed on 'controller' initially.
# If you are updating this file on all nodes for a multi-node setup later, list all:
mon_initial_members = controller,compute1,compute2

# This setting specifically affects monitor behavior
mon_allow_pool_delete = true

# This is a monitor security setting
auth_allow_insecure_global_id_reclaim = false

# You can also be explicit about monitor-specific bind addresses if needed,
# though ms_bind_msgr2 in [global] should handle it.
# Example:
# mon_data = /var/lib/ceph/mon/ceph-$id  # Default, but can be explicit
# public_bind_addr = [v2:MON_IP:3300,v1:MON_IP:6789] # If you need to be very specific per monitor

[client.admin]
keyring = /etc/ceph/ceph.client.admin.keyring

# --- Ceph Manager Einstellungen ---
[mgr]
# Allgemeine Einstellungen für alle Manager-Daemons
# Pfad zu den Manager-Daten. $id wird durch den Manager-Namen ersetzt (z.B. controller)
#mgr_data = /var/lib/ceph/mgr/ceph-\$id
# Aktivieren, dass Module auf Standby-Managern laufen können (falls das Modul dies unterstützt)
mgr_standby_modules = true
# Standard-Logging-Einstellungen (können bei Bedarf feiner justiert werden)
debug_mgr = 10/20
debug_mgr_modules = 10/20 # Gilt für alle Module, wenn nicht spezifischer überschrieben

# Spezifische Einstellungen für einzelne Manager-Instanzen können hier hinzugefügt werden,
# sind aber oft nicht nötig, wenn $id im Pfad verwendet wird und Hostnamen übereinstimmen.
# [mgr.controller]
# host = controller
# [mgr.compute1]
# host = compute1
# [mgr.compute2]
# host = compute2
EOF
"'

# On your external node, SSH into controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo apt update && sudo apt install -y ceph-mgr ceph-mgr-dashboard'
```

### Configure Ceph Manager

```
# Auf Ihrem externen Knoten, SSH in controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo ceph auth get-or-create mgr.controller mon "allow profile mgr" osd "allow *" mds "allow *"'

# Erstelle Manager-Datenverzeichnis für controller (gemäß ceph.conf: /var/lib/ceph/mgr/ceph-controller)
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo mkdir -p /var/lib/ceph/mgr/ceph-controller'

# Setze korrekte Eigentümerschaft für das Verzeichnis
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo chown ceph:ceph /var/lib/ceph/mgr/ceph-controller'

# Hole den erstellten Schlüssel und speichere ihn in der Keyring-Datei des Managers
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo sh -c "ceph auth get mgr.controller -o /var/lib/ceph/mgr/ceph-controller/keyring"'

# Setze korrekte Eigentümerschaft und Berechtigungen für die Keyring-Datei
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo chown ceph:ceph /var/lib/ceph/mgr/ceph-controller/keyring'
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo chmod 600 /var/lib/ceph/mgr/ceph-controller/keyring'

# Auf Ihrem externen Knoten, SSH in controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo systemctl enable ceph-mgr@controller.service'
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo systemctl start ceph-mgr@controller.service'
```

#### Configure Manager and Manager Plugins

```
# Auf Ihrem externen Knoten, SSH in controller
# Warte kurz, bis der Manager gestartet ist
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sleep 10'

# Aktiviere das Dashboard-Modul
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo ceph mgr module enable dashboard'

# (Für Test/Dev) Deaktiviere SSL für das Dashboard für einfacheren Zugriff
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo ceph config set mgr mgr/dashboard/ssl false'
# Hinweis: Für Produktion sollten Sie ein SSL-Zertifikat konfigurieren:
# sudo ceph dashboard create-self-signed-cert
# sudo ceph config set mgr mgr/dashboard/ssl true

# Auf Ihrem externen Knoten, SSH in controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'echo "StrongPassword123" > /tmp/dashboard_admin_pass.txt && sudo chmod 600 /tmp/dashboard_admin_pass.txt'

# Auf Ihrem externen Knoten, SSH in controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo ceph dashboard ac-user-create admin -i /tmp/dashboard_admin_pass.txt administrator'

# Auf Ihrem externen Knoten, SSH in controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo rm /tmp/dashboard_admin_pass.txt'

# (Optional) Aktiviere andere nützliche Module und konfiguriere sie bei Bedarf
# Prometheus-Modul für Metriken aktivieren
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo ceph mgr module enable prometheus'
# Ggf. Scrape-Intervall für Prometheus anpassen (Standard ist 15s)
# ssh -i ... vagrant@controller.os.lokal 'sudo ceph config set mgr mgr/prometheus/scrape_interval 30'

# PG-Autoscaler aktivieren (empfohlen)
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo ceph mgr module enable pg_autoscaler'
# Den Autoscaler für alle Pools standardmäßig auf 'on' setzen (oder 'warn')
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal 'sudo ceph config set global osd_pool_default_pg_autoscale_mode on'
# Oder spezifisch für das Modul:
# ssh -i ... vagrant@controller.os.lokal 'sudo ceph osd pool set <pool_name> pg_autoscale_mode on'
```

### Validate Manager

```
# Auf Ihrem externen Knoten, SSH in controller
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal '
sudo systemctl status ceph-mgr@controller.service
sleep 5
sudo ceph -s
sudo ceph mgr stat
sudo ceph mgr services # Um Dashboard URL zu sehen
'
```

### Access Dashboard

```
http://10.0.1.10:8080/
admin:StrongPassword123
```

## Add further Manager nodes

### Install dependencies

```
# On your external node, SSH into compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo bash -c "cat > /etc/ceph/ceph.conf << EOF
[global]
fsid = 7272bf23-0a44-42e6-b591-5569713531fa
# mon_initial_members will ONLY list the node used for mkfs initially
mon_host = 10.0.1.10,10.0.1.11,10.0.1.12
public_network = 10.0.1.0/24
cluster_network = 10.0.2.0/24
ms_bind_msgr2 = true

# Optional but good for dev/test
osd_pool_default_size = 2
osd_pool_default_min_size = 1
mon_allow_pool_delete = true

[mon]
# mon_initial_members is used by ´ceph-mon --mkfs´.
# If you are bootstrapping with mkfs on each MON, it might be useful here
# or passed directly to mkfs. For running MONs, it´s not critical.
# For the single-node bootstrap, it was only needed on 'controller' initially.
# If you are updating this file on all nodes for a multi-node setup later, list all:
mon_initial_members = controller,compute1,compute2

# This setting specifically affects monitor behavior
mon_allow_pool_delete = true

# This is a monitor security setting
auth_allow_insecure_global_id_reclaim = false

# You can also be explicit about monitor-specific bind addresses if needed,
# though ms_bind_msgr2 in [global] should handle it.
# Example:
# mon_data = /var/lib/ceph/mon/ceph-$id  # Default, but can be explicit
# public_bind_addr = [v2:MON_IP:3300,v1:MON_IP:6789] # If you need to be very specific per monitor

[client.admin]
keyring = /etc/ceph/ceph.client.admin.keyring

# --- Ceph Manager Einstellungen ---
[mgr]
# Allgemeine Einstellungen für alle Manager-Daemons
# Pfad zu den Manager-Daten. $id wird durch den Manager-Namen ersetzt (z.B. controller)
#mgr_data = /var/lib/ceph/mgr/ceph-\$id
# Aktivieren, dass Module auf Standby-Managern laufen können (falls das Modul dies unterstützt)
mgr_standby_modules = true
# Standard-Logging-Einstellungen (können bei Bedarf feiner justiert werden)
debug_mgr = 10/20
debug_mgr_modules = 10/20 # Gilt für alle Module, wenn nicht spezifischer überschrieben

# Spezifische Einstellungen für einzelne Manager-Instanzen können hier hinzugefügt werden,
# sind aber oft nicht nötig, wenn $id im Pfad verwendet wird und Hostnamen übereinstimmen.
# [mgr.controller]
# host = controller
# [mgr.compute1]
# host = compute1
# [mgr.compute2]
# host = compute2
EOF
"'

# On your external node, SSH into compute2
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal 'sudo bash -c "cat > /etc/ceph/ceph.conf << EOF
[global]
fsid = 7272bf23-0a44-42e6-b591-5569713531fa
# mon_initial_members will ONLY list the node used for mkfs initially
mon_host = 10.0.1.10,10.0.1.11,10.0.1.12
public_network = 10.0.1.0/24
cluster_network = 10.0.2.0/24
ms_bind_msgr2 = true

# Optional but good for dev/test
osd_pool_default_size = 2
osd_pool_default_min_size = 1
mon_allow_pool_delete = true

[mon]
# mon_initial_members is used by ´ceph-mon --mkfs´.
# If you are bootstrapping with mkfs on each MON, it might be useful here
# or passed directly to mkfs. For running MONs, it´s not critical.
# For the single-node bootstrap, it was only needed on 'controller' initially.
# If you are updating this file on all nodes for a multi-node setup later, list all:
mon_initial_members = controller,compute1,compute2

# This setting specifically affects monitor behavior
mon_allow_pool_delete = true

# This is a monitor security setting
auth_allow_insecure_global_id_reclaim = false

# You can also be explicit about monitor-specific bind addresses if needed,
# though ms_bind_msgr2 in [global] should handle it.
# Example:
# mon_data = /var/lib/ceph/mon/ceph-$id  # Default, but can be explicit
# public_bind_addr = [v2:MON_IP:3300,v1:MON_IP:6789] # If you need to be very specific per monitor

[client.admin]
keyring = /etc/ceph/ceph.client.admin.keyring

# --- Ceph Manager Einstellungen ---
[mgr]
# Allgemeine Einstellungen für alle Manager-Daemons
# Pfad zu den Manager-Daten. $id wird durch den Manager-Namen ersetzt (z.B. controller)
#mgr_data = /var/lib/ceph/mgr/ceph-\$id
# Aktivieren, dass Module auf Standby-Managern laufen können (falls das Modul dies unterstützt)
mgr_standby_modules = true
# Standard-Logging-Einstellungen (können bei Bedarf feiner justiert werden)
debug_mgr = 10/20
debug_mgr_modules = 10/20 # Gilt für alle Module, wenn nicht spezifischer überschrieben

# Spezifische Einstellungen für einzelne Manager-Instanzen können hier hinzugefügt werden,
# sind aber oft nicht nötig, wenn $id im Pfad verwendet wird und Hostnamen übereinstimmen.
# [mgr.controller]
# host = controller
# [mgr.compute1]
# host = compute1
# [mgr.compute2]
# host = compute2
EOF
"'

# Auf Ihrem externen Knoten, SSH in compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo apt update && sudo apt install -y ceph-mgr ceph-mgr-dashboard'

# Auf Ihrem externen Knoten, SSH in compute2
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal 'sudo apt update && sudo apt install -y ceph-mgr ceph-mgr-dashboard'
```

### Setup Manager Service

```
# Auf Ihrem externen Knoten, SSH in compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal '
# 1. Erstelle den Authentifizierungsschlüssel für mgr.compute1 direkt auf compute1
#    Dieser Befehl spricht mit den Monitoren und legt den Schlüssel im Cluster an.
sudo ceph auth get-or-create mgr.compute1 mon "allow profile mgr" osd "allow *" mds "allow *"

# 2. Erstelle das Manager-Datenverzeichnis (gemäß mgr_data in ceph.conf)
sudo mkdir -p /var/lib/ceph/mgr/ceph-compute1
sudo chown ceph:ceph /var/lib/ceph/mgr/ceph-compute1

# 3. Hole den gerade erstellten Schlüssel und speichere ihn in der Keyring-Datei des Managers
sudo sh -c "ceph auth get mgr.compute1 -o /var/lib/ceph/mgr/ceph-compute1/keyring"

# 4. Setze korrekte Eigentümerschaft und Berechtigungen für die Keyring-Datei
sudo chown ceph:ceph /var/lib/ceph/mgr/ceph-compute1/keyring
sudo chmod 600 /var/lib/ceph/mgr/ceph-compute1/keyring

# 5. Starte den Ceph Manager Dienst auf compute1
sudo systemctl enable ceph-mgr@compute1.service
sudo systemctl start ceph-mgr@compute1.service
'

# Auf Ihrem externen Knoten, SSH in compute2
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal '
# 1. Erstelle den Authentifizierungsschlüssel für mgr.compute2 direkt auf compute2
sudo ceph auth get-or-create mgr.compute2 mon "allow profile mgr" osd "allow *" mds "allow *"

# 2. Erstelle das Manager-Datenverzeichnis (gemäß mgr_data in ceph.conf)
sudo mkdir -p /var/lib/ceph/mgr/ceph-compute2
sudo chown ceph:ceph /var/lib/ceph/mgr/ceph-compute2

# 3. Hole den gerade erstellten Schlüssel und speichere ihn in der Keyring-Datei des Managers
sudo sh -c "ceph auth get mgr.compute2 -o /var/lib/ceph/mgr/ceph-compute2/keyring"

# 4. Setze korrekte Eigentümerschaft und Berechtigungen für die Keyring-Datei
sudo chown ceph:ceph /var/lib/ceph/mgr/ceph-compute2/keyring
sudo chmod 600 /var/lib/ceph/mgr/ceph-compute2/keyring

# 5. Starte den Ceph Manager Dienst auf compute2
sudo systemctl enable ceph-mgr@compute2.service
sudo systemctl start ceph-mgr@compute2.service
'
```

### Verify the three manager nodes

```
# Auf Ihrem externen Knoten, SSH in controller (oder einen beliebigen Knoten mit admin key und ceph.conf)
ssh -i .vagrant/machines/controller/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@controller.os.lokal '
sleep 10 # Warte, bis sich die Manager registriert haben
sudo ceph -s
sudo ceph mgr stat
sudo ceph mgr dump
'
# Suchen Sie in "ceph -s" oder "ceph mgr stat" nach dem aktiven Manager und den Standby-Managern.
# z.B. "mgr: controller (active, since ...), standbys: compute1, compute2"
# Oder in "ceph mgr dump" unter "available_modules" und "standbys".
```

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

