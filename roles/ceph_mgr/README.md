# CEPH Manager

## Manually Installation Tests

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


### Manual Installation and configuration of the first manager node

#### Install Dependencies

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

#### Configure Ceph Manager

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

### Add further Manager nodes

#### Install dependencies

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

#### Setup Manager Service

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
