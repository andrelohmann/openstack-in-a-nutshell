# CEPH Monitor

## Manually Installation Tests

### Install Chrony to all nodes

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

### Manual Installation and configuration of the first monitor node

#### Purpose of monitor

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

#### Install dependencies

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

#### Initialize the bootstrap node

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

#### Verify the monitor

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

### Manual Installation and configuration of further monitors

#### Install dependencies on new monitors

```
# On your external node, SSH into compute1
ssh -i .vagrant/machines/compute1/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute1.os.lokal 'sudo apt update && sudo apt install -y acl ceph-common ceph-mon'

# On your external node, SSH into compute2
ssh -i .vagrant/machines/compute2/virtualbox/private_key -o StrictHostKeyChecking=no vagrant@compute2.os.lokal 'sudo apt update && sudo apt install -y acl ceph-common ceph-mon'
```

#### Create or update ceph.conf on all nodes

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

#### Prepare the files on the controller node and distribute to the new monitors

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

#### Prepare the new monitors

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
